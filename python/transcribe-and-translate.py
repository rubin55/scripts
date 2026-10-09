#!/usr/bin/python3
# Transcribe a video with Whisper, then let a local Qwen fix and
# translate the cues. Run with -h for the options.
import argparse, gc, importlib.util, json, os, re, shutil, socket, subprocess, sys, tempfile, time, urllib.request
from functools import partial
from pathlib import Path

WHISPER = 'large-v3-turbo'
QWEN_REPO = 'orcarouter/Qwen3.8-27B-Uncensored-GGUF'
QWEN_FILE = 'Qwen3.8-27B-Uncensored-Q4_K_M.gguf'
BATCH = 30


def confirm(question):
    return input(f'{question} [y/N] ').strip().lower() in ('y', 'yes')


def cached(get, what):
    # path of a model in the Hugging Face cache, download on request
    try:
        return get(local_files_only=True)
    except LocalEntryNotFoundError:
        if not confirm(f'{what} is not in the Hugging Face cache. Download it?'):
            sys.exit(1)
        return get()


def llm(port, prompt):
    req = urllib.request.Request(
        f'http://127.0.0.1:{port}/v1/chat/completions',
        json.dumps({'messages': [{'role': 'user', 'content': prompt}],
                    'temperature': 0.3}).encode(),
        {'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=600) as r:
        return json.load(r)['choices'][0]['message']['content']


def ts(t):
    ms = round(t * 1000)
    return f'{ms // 3600000:02}:{ms // 60000 % 60:02}:{ms // 1000 % 60:02},{ms % 1000:03}'


parser = argparse.ArgumentParser(description='Transcribe a video with Whisper, then let a local'
                                 ' Qwen fix the recognition errors and translate the subtitles.')
parser.add_argument('-f', '--file', required=True, help='the video file')
parser.add_argument('-l', '--lang', default='en',
                    help='output language as a 2-letter code (default: en)')
parser.add_argument('-o', '--output', help='output file (default: FILE.LANG.srt, without'
                    ' the extension of FILE)')
args = parser.parse_args()
video, lang = args.file, args.lang.lower()
if not re.fullmatch('[a-z]{2}', lang):
    parser.error(f'{args.lang}: not a 2-letter language code')
out = args.output or os.path.splitext(video)[0] + f'.{lang}.srt'
if not os.path.isfile(video):
    sys.exit(f'{video}: no such file')
if os.path.exists(out):
    sys.exit(f'{out} exists, not overwriting')
if not os.access(os.path.dirname(out) or '.', os.W_OK):
    sys.exit(f'{out}: cannot write to this directory')

# vendors of the display controllers (PCI class 0x03), NVIDIA is 0x10de
gpus = {(d / 'vendor').read_text().strip() for d in Path('/sys/bus/pci/devices').iterdir()
        if (d / 'class').read_text().startswith('0x03')}
nvidia = '0x10de' in gpus

# pacman packages for missing modules and programs
missing = []
if not importlib.util.find_spec('faster_whisper'):
    missing += ['python-ctranslate2-cuda' if nvidia else 'python-ctranslate2', 'python-faster-whisper']
if not shutil.which('llama-server'):
    missing.append('llama.cpp-cuda' if nvidia else 'llama.cpp-vulkan' if gpus else 'llama.cpp')
if missing:
    if not confirm(f'Missing packages: {" ".join(missing)}. Install them with pacman?'):
        sys.exit(1)
    if subprocess.run(['sudo', 'pacman', '-S', '--needed', *missing]).returncode:
        sys.exit(f'pacman failed. Packages from the AUR need: aur sync {" ".join(missing)}')
    importlib.invalidate_caches()

import av, ctranslate2, faster_whisper, huggingface_hub
from huggingface_hub.errors import LocalEntryNotFoundError

if nvidia and not ctranslate2.get_cuda_device_count():
    sys.exit('NVIDIA card found, but CTranslate2 has no CUDA device. '
             'Check python-ctranslate2-cuda and the NVIDIA driver.')
try:
    with av.open(video) as container:
        if not container.streams.audio:
            sys.exit(f'{video}: no audio stream')
except av.FFmpegError as e:
    sys.exit(f'{video}: {e}')

whisper_dir = cached(partial(faster_whisper.download_model, WHISPER), f'Whisper {WHISPER} (1.6 GB)')
gguf = cached(partial(huggingface_hub.hf_hub_download, QWEN_REPO, QWEN_FILE), f'{QWEN_FILE} (16 GB)')

if nvidia:  # the LLM needs its file size plus about 2 GiB of VRAM
    need = os.path.getsize(gguf) + 2 * 2**30
    smi = subprocess.run(['nvidia-smi', '--query-gpu=memory.free', '--format=csv,noheader,nounits'],
                         capture_output=True, text=True)
    free = int(smi.stdout.split()[0]) * 2**20
    if free < need and not confirm(f'Only {free / 2**30:.1f} GiB VRAM free, {need / 2**30:.1f} GiB needed. Continue?'):
        sys.exit(1)

# CTranslate2 has no Vulkan, so without NVIDIA Whisper runs on the CPU
model = faster_whisper.WhisperModel(whisper_dir, device='cuda' if nvidia else 'cpu',
                                    compute_type='float16' if nvidia else 'int8')
segs, info = model.transcribe(video, vad_filter=True, beam_size=5, word_timestamps=True)
# word times are tighter than segment times
cues = [(s.words[0].start, s.words[-1].end, s.text.strip()) for s in segs if s.words]
print(f'{len(cues)} cues, language {info.language}', file=sys.stderr)
if not cues:
    sys.exit('No speech found')
del model
gc.collect()  # free VRAM for the LLM

with socket.socket() as s:
    s.bind(('127.0.0.1', 0))
    port = s.getsockname()[1]
log = tempfile.TemporaryFile()
server = subprocess.Popen(['llama-server', '-m', gguf, '-ngl', '99', '-c', '16384',
                           '--host', '127.0.0.1', '--port', str(port), '-rea', 'off'],
                          stdout=log, stderr=subprocess.STDOUT)

try:
    while True:  # wait until the model is loaded
        if server.poll() is not None:
            log.seek(0)
            sys.exit('llama-server stopped:\n' + log.read().decode(errors='replace')[-3000:])
        try:
            urllib.request.urlopen(f'http://127.0.0.1:{port}/health')
            break
        except OSError:
            time.sleep(2)

    texts = [c[2] for c in cues]
    for i in range(0, len(texts), BATCH):
        before = '\n'.join(texts[max(0, i - 5):i])
        lines = '\n'.join(f'{n}: {texts[n]}' for n in range(i, min(i + BATCH, len(texts))))
        prompt = (
            f'These are subtitle lines from a video in language "{info.language}", '
            'made by speech recognition, so they can contain wrong words. '
            'Fix the recognition errors and give each line in natural, short subtitle '
            f'style, in the language with ISO 639-1 code "{lang}". '
            'Keep the numbers: one output line "N: text" per input line, '
            'no other text.\n\n'
            f'Previous lines, already done (context only):\n{before}\n\n'
            f'Lines:\n{lines}')
        for m in re.finditer(r'^(\d+):\s*(.+)$', llm(port, prompt), re.M):
            n = int(m[1])
            if i <= n < i + BATCH and n < len(texts):
                texts[n] = m[2].strip()
        print(f'{min(i + BATCH, len(texts))}/{len(texts)}', file=sys.stderr)
finally:
    server.terminate()
    server.wait()

with open(out, 'w') as f:
    for n, ((start, end, _), text) in enumerate(zip(cues, texts), 1):
        f.write(f'{n}\n{ts(start)} --> {ts(end)}\n{text}\n\n')
print(out)
