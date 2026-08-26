#!/usr/bin/env node

// pi wrapper. Before running pi it sets pi-lens preferences, strips
// terminal title escape sequences from stdout, and re/applies local
// patches to installed pi extensions.
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const PI_CLI = "/usr/lib/node_modules/pi/packages/coding-agent/dist/cli.js";

// Notices go to stderr.
const log = (message) => process.stderr.write(`${message}\n`);

// ----------------------------------------------------------------------
// pi-lens: set home to ~/.pi/lens and never auto-install language
// servers or tools. Ignore environment variables that are already set.
// ----------------------------------------------------------------------
process.env.PI_LENS_HOME = path.join(os.homedir(), ".pi", "lens");
log(`pi-lens: home is ${process.env.PI_LENS_HOME}`);
process.env.PI_LENS_DISABLE_TOOL_INSTALL = "1";
log(`pi-lens: disabled tool install`);
process.env.PI_LENS_DISABLE_LSP_INSTALL = "1";
log(`pi-lens: disabled lsp install`);

// ----------------------------------------------------------------------
// pi-title: remove OSC 0/1/2 escape sequences from stdout so pi
// cannot set the terminal title.
// ----------------------------------------------------------------------
// biome-ignore lint/suspicious/noControlCharactersInRegex: matches OSC escape bytes
const re = /\x1b\][012];[^\x07\x1b]*(?:\x07|\x1b\\)/g;
const write = process.stdout.write.bind(process.stdout);
process.stdout.write = (chunk, ...rest) => {
	const str = typeof chunk === "string" ? chunk : Buffer.from(chunk).toString();
	return write(str.replace(re, ""), ...rest);
};
log("pi-title: setting disabled");

// ----------------------------------------------------------------------
// pi-extension-patching: keep local fixes applied to installed pi
// extensions. Each entry is a package name plus a unified diff next to
// this script.
// ----------------------------------------------------------------------
const PATCHES = [
	["pi-permission-system", "pi-permission-system-fix-skills.patch"],
];

// Split a unified diff into per-file before/after line blocks. Hunk
// line numbers are ignored; hunks are located by their content.
function parsePatch(text) {
	const files = [];
	let file;
	let hunk;

	for (const line of text.split("\n")) {
		if (line.startsWith("+++ b/")) {
			file = { path: line.slice(6).trim(), hunks: [] };
			files.push(file);
			hunk = undefined;
			continue;
		}
		if (line.startsWith("diff --git")) {
			file = undefined;
			hunk = undefined;
			continue;
		}
		if (!file) {
			continue;
		}
		if (line.startsWith("@@")) {
			hunk = { before: [], after: [] };
			file.hunks.push(hunk);
			continue;
		}
		if (!hunk) {
			continue;
		}

		const content = line.slice(1);
		if (line.startsWith(" ")) {
			hunk.before.push(content);
			hunk.after.push(content);
		} else if (line.startsWith("-")) {
			hunk.before.push(content);
		} else if (line.startsWith("+")) {
			hunk.after.push(content);
		} else if (!line.startsWith("\\")) {
			hunk = undefined;
		}
	}

	return files.filter((f) => f.hunks.length > 0);
}

function indexOfBlock(lines, block) {
	if (block.length === 0) {
		return -1;
	}
	for (let i = 0; i + block.length <= lines.length; i += 1) {
		let hit = true;
		for (let j = 0; j < block.length; j += 1) {
			if (lines[i + j] !== block[j]) {
				hit = false;
				break;
			}
		}
		if (hit) {
			return i;
		}
	}
	return -1;
}

// Apply every hunk that is not applied yet. Nothing is written until
// all files resolve, so a stale patch cannot half-apply. Line endings
// of the target file are preserved, so CRLF sources patch cleanly.
// Returns the number of files written.
function applyPatch(root, files) {
	const writes = [];

	for (const file of files) {
		const target = path.join(root, file.path);
		if (!fs.existsSync(target)) {
			throw new Error(`missing ${file.path}`);
		}

		const raw = fs.readFileSync(target, "utf8");
		const eol = raw.includes("\r\n") ? "\r\n" : "\n";
		let lines = raw.split(/\r?\n/);
		let dirty = false;

		for (const hunk of file.hunks) {
			if (indexOfBlock(lines, hunk.after) !== -1) {
				continue;
			}
			const at = indexOfBlock(lines, hunk.before);
			if (at === -1) {
				throw new Error(`stale hunk in ${file.path}`);
			}
			lines = [
				...lines.slice(0, at),
				...hunk.after,
				...lines.slice(at + hunk.before.length),
			];
			dirty = true;
		}

		if (dirty) {
			writes.push([target, lines.join(eol)]);
		}
	}

	for (const [target, content] of writes) {
		fs.writeFileSync(target, content);
	}

	return writes.length;
}

function extensionRoots(name) {
	const agentDir =
		process.env.PI_AGENT_DIR ?? path.join(os.homedir(), ".pi", "agent");
	return [
		path.join(agentDir, "npm", "node_modules", name),
		path.join(agentDir, "extensions", name),
	].filter((root) => fs.existsSync(root));
}

function patchExtensions() {
	const here = path.dirname(fileURLToPath(import.meta.url));

	for (const [name, patchFile] of PATCHES) {
		const roots = extensionRoots(name);
		if (roots.length === 0) {
			continue;
		}

		let files;
		try {
			files = parsePatch(fs.readFileSync(path.join(here, patchFile), "utf8"));
		} catch (error) {
			console.error(`${name}: cannot read ${patchFile}: ${error.message}`);
			continue;
		}

		let patched = 0;
		let failed = false;
		for (const root of roots) {
			try {
				patched += applyPatch(root, files);
			} catch (error) {
				failed = true;
				console.error(`${name}: ${patchFile} not applied: ${error.message}`);
			}
		}

		if (failed) {
			continue;
		}
		if (patched > 0) {
			log(`${name}: patch applied`);
		} else {
			log(`${name}: was previously patched, not applying`);
		}
	}
}

patchExtensions();

await import(PI_CLI);
