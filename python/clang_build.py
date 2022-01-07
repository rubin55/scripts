# Copyright 2020 Arm
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above
#     copyright notice, this list of conditions and the following
#     disclaimer in the documentation and/or other materials
#     provided with the distribution.
#  3. Neither the name of the copyright holder nor the names of its
#     contributors may be used to endorse or promote products
#     derived from this software without specific prior written
#     permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

import sys
import subprocess
import os
from os import path
from argparse import ArgumentParser
import shlex
import shutil
import time
import math

p = ArgumentParser(__file__, description='Fetch and build Clang for Windows')
default_branch = 'release/12.x'
default_arch = 'amd64'
p.add_argument('--branch', help='Used to specify the clang branch to build. (Default: %s)' % (default_branch), default=default_branch)
p.add_argument('--prepare-only', action='store_true', help='Prepare the build as normal, but don\'t run the cmake configuration and ninja build steps. Use this to inspect the commands to run without running them, or to allow you to apply your own patches before building.')
p.add_argument('--no-checkout', action='store_true', help='Don\'t run git checkout before building. Useful for building from a custom commit, or with detatched HEAD')
p.add_argument('--clean', action='store_true', help='Clean all existing build objects and CMake output before running the build.')
p.add_argument('--debug-env', action='store_true', help='Print the environment for each command')
p.add_argument('--no-reconfigure', action='store_true', help='Don\'t run CMake, just run ninja. Use this to restart a build if it failed.')
p.add_argument('--patches', action='store_true', help='Enable patching for WoA build problems in LLVM. This option is known to be needed with versions 10 and 11. Note: version 12 (and possibly higher) is known to be patched.')
p.add_argument('--arch', help='Used to specify the target architecture to use. (Default: %s)' % (default_arch), default=default_arch)
p.add_argument('--clang-cl-exe', help='Specify the path to find clang-cl.exe', default=r'C:\Program Files\LLVM\llvm10\bin\clang-cl.exe')
args = p.parse_args()

errors = False

def error(message):
    global errors
    print(message, file=sys.stderr)
    errors = True

def die_if_errors_encountered():
    global errors
    if errors:
        print('Unable to continue, please fix the previous errors and try again.', file=sys.stderr)

def is_exe(fpath):
    return os.path.isfile(fpath) and os.access(fpath, os.X_OK)

def which(executable):
    fpath, fname = os.path.split(executable)

    suffixes = {'.bat', '.cmd', '.exe', '.py'}

    if fpath:
        # First try without suffix.
        if is_exe(executable):
            return executable

        # Mm, let's attach our suffixes and
        # return the first that matches.
        for s in suffixes:
            if is_exe(executable + s):
                return executable + s

    else:
        for path in os.environ["PATH"].split(os.pathsep):
            exe_file = os.path.join(path, executable)

            # First try without suffix.
            if is_exe(exe_file):
                return exe_file

            # Mm, let's attach our suffixes and
            # return the first that matches.
            for s in suffixes:
                exe_file = os.path.join(path, executable + s)

                if is_exe(exe_file):
                    return exe_file

    return None

def add_dirs_to_path(paths):
    for path in paths:
        path = path.strip()
        os.environ["PATH"] += os.pathsep + path

print('-------------------------------------')
print('Clang build script for Windows')
print('-------------------------------------')

if args.arch:
    default_arch = args.arch

# Sanity checks, to make sure required software is installed
vcvars_bat = f'C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\BuildTools\\VC\\Auxiliary\\Build\\vcvarsx86_{default_arch}.bat'
have_vcvars = path.exists(vcvars_bat)

have_git = False
have_cmake = False
have_ninja = False
have_clang = False

try:
    have_git = subprocess.call(['git', '--version'], stdout=subprocess.DEVNULL) == 0
except Exception as e:
    error('Error while searching for git: ' + str(e))

try:
    have_cmake = subprocess.call(['cmake', '--version'], stdout=subprocess.DEVNULL) == 0
except Exception as e:
    error('Error while searching for cmake: ' + str(e))

c_compiler=args.clang_cl_exe
cpp_compiler=args.clang_cl_exe
try:
    have_clang = subprocess.call([c_compiler, '--version'], stdout=subprocess.DEVNULL) == 0
except Exception as e:
    error('Error while searching for clang: ' + str(e))

ninja_path = which('ninja')

build_ninja = False

try:
    have_ninja = subprocess.call([ninja_path, '--version'], stdout=subprocess.DEVNULL) == 0
except Exception as e:
    print('Warning: Recoverable error while searching for ninja: ' + str(e))
    print('Ninja is required to build clang, but no suitable version was found on the path.')
    print('Ninja will be fetched and built form source instead')
    add_dirs_to_path([os.path.abspath('ninja')])
    ninja_path = which('ninja')
    try:
        have_ninja = subprocess.call([ninja_path, '--version'], stdout=subprocess.DEVNULL) == 0
    except:
        have_ninja = False
    build_ninja = not have_ninja

if not have_vcvars:
    error(f'vcvars batch file not found for building {default_arch} target.\n'
          'Searched for file in: %s\n'
          'Ensure that Visual studio 2019 Build Tools is installed, and all required modules are installed.'
          % (vcvars_bat)
    )

if not have_git:
    error('Git is required to fetch the clang source code, but no suitable version was not found on the path. Make sure git is installed and on the path. https://git-scm.com/downloads')

if not have_cmake:
    error('CMake is required to build clang, but no suitable version was not found on the path. Make sure CMake is installed and on the path. https://cmake.org/download/#latest')

if not have_clang:
    error('Could not find a suitable version of clang to bootstrap this build of clang. Please install a clang first. For example, see Windows (32 bit) download here: https://releases.llvm.org/download.html')

# Fail at this point if required software is not installed
die_if_errors_encountered()

ninja_url = 'https://github.com/ninja-build/ninja.git'
clang_url = 'https://github.com/llvm/llvm-project.git'

print('Build tools:')
print('- cmake detected')
print('- git detected.')
if have_ninja:
    print('- ninja detected.')
else:
    print('- ninja will be built from source.')
print('ready to build.')
if build_ninja:
    print('Ninja will be fetched and built from: %s' % (ninja_url))
print('Clang will be fetched and built from: %s' % (clang_url))
print('Starting...')

# Run vcvars to get the environment for the build
getenv = ['cmd', '/c', 'call', vcvars_bat, '>', 'NUL', '&&', 'set']
env = {key:value for key, value in [s.split('=',2) for s in subprocess.check_output(getenv).decode('ISO-8859-1').strip().split('\r\n')]}


if build_ninja:
    try:
        if not path.isdir(r'.\ninja'):
            print('Cloning ninja repo...')
            subprocess.check_call(['git', 'clone', '--branch=release', ninja_url])
            print('Building ninja...')
        else:
            print('Ninja has already been cloned. Building existing instance...')
        build_ninja = ['cmd', '/c', 'cd', r'.\ninja', '&&', 'python', r'.\configure.py', '--bootstrap']
        subprocess.check_call(build_ninja, env=env)
        have_ninja = subprocess.call([ninja_path, '--version'], stdout=subprocess.DEVNULL) == 0
        if not have_ninja:
            error('Ninja build completed, but resulting exe file does not run.')
    except Exception as e:
        error(str(e))
        error('Failed to fetch and build ninja.')

die_if_errors_encountered()

# Now fetch and build clang
# Fetch first if it doesn't exist
llvmdir = r'.\llvm-project'
if not path.isdir(llvmdir):
    print('Cloning llvm-project...')
    subprocess.check_call(['git', 'clone', '--depth=100', '--branch', args.branch, clang_url])
else:
    if args.no_checkout:
        print('Skipped checkout step.')
    else:
        print('Already cloned llvm, checkout specified branch...')
        try:
            subprocess.check_call(['git', 'fetch', 'origin', args.branch], cwd=llvmdir)
            subprocess.check_call(['git', 'checkout', 'FETCH_HEAD'], cwd=llvmdir)
        except Exception as e:
            error(str(e))
            error('Unable to update llvm-project git repo to the latest commit on branch "origin/%s"\nIf you have made local changes that you want to build, you can run ninja directly, or run this script with the --no-checkout option to skip updating to a specific branch.' % (args.branch))

die_if_errors_encountered()

# Make sure build dir exists and is clean
builddir = path.join(llvmdir, 'build')
print(builddir)
if args.prepare_only or args.no_reconfigure:
    # Don't touch the build tree
    pass
else:
    if args.clean and path.isdir(builddir):
        shutil.rmtree(builddir)
    os.makedirs(builddir, exist_ok=True)

llvmpatch = r"""
diff --git a/llvm/lib/DebugInfo/PDB/CMakeLists.txt b/llvm/lib/DebugInfo/PDB/CMakeLists.txt
index 320ca78b525..5343dfef95a 100644
--- a/llvm/lib/DebugInfo/PDB/CMakeLists.txt
+++ b/llvm/lib/DebugInfo/PDB/CMakeLists.txt
@@ -7,6 +7,10 @@ if(LLVM_ENABLE_DIA_SDK)
   include_directories(${MSVC_DIA_SDK_DIR}/include)
   set(LIBPDB_LINK_FOLDERS "${MSVC_DIA_SDK_DIR}\\lib")
-  if (CMAKE_SIZEOF_VOID_P EQUAL 8)
+  if ("$ENV{VSCMD_ARG_TGT_ARCH}" STREQUAL "arm64")
+    set(LIBPDB_LINK_FOLDERS "${LIBPDB_LINK_FOLDERS}\\arm64")
+  elseif ("$ENV{VSCMD_ARG_TGT_ARCH}" STREQUAL "arm")
+    set(LIBPDB_LINK_FOLDERS "${LIBPDB_LINK_FOLDERS}\\arm")
+  elseif (CMAKE_SIZEOF_VOID_P EQUAL 8)
     set(LIBPDB_LINK_FOLDERS "${LIBPDB_LINK_FOLDERS}\\amd64")
   endif()
   file(TO_CMAKE_PATH "${LIBPDB_LINK_FOLDERS}\\diaguids.lib" LIBPDB_ADDITIONAL_LIBRARIES)
"""

if args.patches:
    try:
        print('Patching known WoA build issue in LLVM repo...')
        patch_filename = 'woa_build.patch'
        with open(path.join(llvmdir, patch_filename), 'wb+') as patchfile:
            patchtext = llvmpatch.replace('\r', '') # ensure no windows line endings
            patchfile.write(patchtext.encode('utf-8'))
        patch_commands = [
            ['git', 'checkout', '--force', 'llvm/lib/DebugInfo/PDB/CMakeLists.txt']
            ,['git', 'apply', patch_filename]
        ]
        for patch_command in patch_commands:
            subprocess.check_call(patch_command, cwd=llvmdir)
        print('Patching done')
    except Exception as e:
        error('Failed to apply required patches to llvm code base: ' + str(e))
        error('This error is expected if one of the following is true:\n' +
              ' 1. This fix is already applied because you are building a release later than 10.x using the --branch option\n' +
              ' 2. This fix has been backported on to the branch you are building.\n' +
              ' 3. You are building a really old version of clang where this fix cannot be applied.\n' +
              'For cases 1 or 2 you can just run this script again with the --no-patches option.')

die_if_errors_encountered()

def escape_path(p):
    ''' make a windows path suitable for consumption by cmake '''
    return p.replace('\\', '/')

if default_arch == 'amd64':
    target_arch = 'X86'
    target_triple = 'x86_64-pc-windows-msvc'
elif default_arch == 'arm64':
    target_arch = 'AArch64'
    target_triple = 'aarch64-unknown-windows-msvc'
else:
    error(f'Failed to recognize target architecture: {default_arch}')
    exit(1)

common_flags = ' '.join([f'--target={target_triple}'])

dash_d = {
        'LLVM_ENABLE_PROJECTS': 'clang;clang-tools-extra;lld;lldb'
        ,'LLVM_TARGETS_TO_BUILD': target_arch
        ,'LLVM_TARGET_ARCH': target_arch
        ,'LLVM_DEFAULT_TARGET_TRIPLE': target_triple
        ,'CMAKE_BUILD_TYPE': 'Release'
        ,'CMAKE_MAKE_PROGRAM': escape_path(ninja_path)
        ,'CMAKE_C_COMPILER': escape_path(c_compiler)
        ,'CMAKE_CXX_COMPILER': escape_path(cpp_compiler)
        ,'CMAKE_ASM_COMPILER': escape_path(c_compiler)
        ,'CMAKE_CXX_FLAGS': common_flags
        ,'CMAKE_C_FLAGS': common_flags
        ,'CMAKE_CXX_STANDARD': '14'
        ,'CMAKE_CXX_STANDARD_REQUIRED': 'YES'
        ,'CMAKE_LINKER': 'link'
        ,'CMAKE_CXX_LINK_EXECUTABLE': '<CMAKE_LINKER> <FLAGS> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>'
        }

cmake_command = [
        'cmake'
        ,'-Wno-dev'
        ,*['-D%s=%s' % (key, value) for key, value in dash_d.items()]
        ,'-GNinja'
        ,'..\llvm']

ninja_command = [
        escape_path(ninja_path)
        ]

try:
    if args.debug_env:
        for k, v in env.items():
            print('%s=%s'%(k,v))
        for l in ['PATH', 'LIB', 'INCLUDE', 'LIBPATH']:
            if l in env:
                print('\nPath list - %s:\n%s\n' % (l, '\n'.join(env[l].split(';'))))
    if not args.no_reconfigure:
        print('CMake command: ' + shlex.join(cmake_command))
        print('Ninja command: ' + shlex.join(ninja_command))
        if not args.prepare_only:
            subprocess.check_call(cmake_command, env=env, cwd=builddir)
    print('CMake command: ' + shlex.join(cmake_command))
    print('Ninja command: ' + shlex.join(ninja_command))
    if not args.prepare_only:
        buildstart = time.time()
        subprocess.check_call(ninja_command, env=env, cwd=builddir)
        buildend = time.time()
        elapsed_mins = (buildend - buildstart) / 60
        elapsed_hours = int(math.floor(elapsed_mins / 60))
        rem_mins = int(math.floor(elapsed_mins - (elapsed_hours * 60)))
        print('Build time (excluding fetches, building ninja, and cmake configuration): %dhr %dmins' % (elapsed_hours, rem_mins))
except Exception as e:
    error(str(e))
    error('Build failed.')

die_if_errors_encountered()

if not args.prepare_only:
    print('Build completed successfully.')
