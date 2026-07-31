#!/usr/bin/env node
// Strip OSC 0/1/2 (terminal title) sequences from stdout, then run pi.
// pi bin is /usr/lib/node_modules/pi/packages/coding-agent/dist/cli.js
const re = /\x1b\][012];[^\x07\x1b]*(?:\x07|\x1b\\)/g;
const write = process.stdout.write.bind(process.stdout);
process.stdout.write = (chunk, ...rest) => {
	const str = typeof chunk === "string" ? chunk : Buffer.from(chunk).toString();
	return write(str.replace(re, ""), ...rest);
};

await import("/usr/lib/node_modules/pi/packages/coding-agent/dist/cli.js");
