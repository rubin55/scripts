#!/usr/bin/env bun

// This script is tested with the node, deno and bun javascript runtimes.
// When running with deno, you should make sure to also pass --allow-env,
// --allow-read, and --allow-net to the interpreter (not to this script).

import { argv, env, exit, version } from "node:process";
import { parseArgs } from "node:util";
import https from "node:https";

/**
 * Checks if we're running a supported Node.js version.
 * We use util.parseArgs, which exists in v16 since minor version 17,
 * and in v18 since minor version 3 and any version after that.
 * Note that any v17 does *not* support parseArgs.
 * @param {string} version - a version string in semver form (i.e., v1.2.3 or 1.2.3)
 * @returns {boolean} True if either 16.17 or higher, not 17, or 18.3 or higher
 */
function isSupportedVersion(version) {
  const [major, minor, patch] = version.replace("v", "").split(".").map(Number);

  // Minimally version 16.17.x is ok due to backporting of parseArgs:
  if (major === 16 && minor >= 17) {
    return true;
  }

  // Or minimally version 18.3.x or any version higher than that:
  if (major >= 18 && minor >= 3) {
    return true;
  }

  // Any other version (including any 17.x.x!) does not support parseArgs:
  console.error(
    "Node.js v%s.%s.%s is not supported by this script.",
    major,
    minor,
    patch,
  );
  console.error("You need at least v16.17, no v17, or v18.3 or later.");
  return false;
}

/**
 * A help message printer.
 * @param {Object} input - A parseArgs constructed object containing values and positionals.
 * @param {Object} input.values - The values object containing parsed arguments.
 * @param {boolean} input.values.help - Indicates whether help was requested.
 * @param {Array} input.positionals - An array of positional arguments (should contain at least 2 values).
 * @param {string} input.positionals[0] - The first positional value in the array, usually the node interpreter.
 * @param {string} input.positionals[1] - The second positional value in the array, usually this node script.
 * @returns {number} 0 when input.values.help is true, 1 otherwise
 */
function help(input) {
  console.log("Usage: %s [COMMAND] [OPTION]...", input.positionals[1]);
  console.log("");
  console.log("List and upload files in(to) GitHub releases.");
  console.log("");
  console.log("Commands:");
  console.log("  help                        show this help message");
  console.log("  list                        list releases (and files)");
  console.log("  upload                      upload a file (into a release)");
  console.log("");
  console.log("Options:");
  console.log("  -h, --help                  show this help message");
  console.log("  -p, --profile PROFILE       specify github profile");
  console.log("  -r, --repository REPOSITORY specify git repository");
  console.log("  -t, --tag TAG               specify git tag");
  console.log(
    "  -s, --secret SECRET         specify token used to authenticate to github",
  );
  console.log(
    "  -f, --file FILE             specify file(s) (can be specified multiple times)",
  );
  console.log("  -v, --version               show version");
  console.log("");
  console.log("Environment variables:");
  console.log("  GITHUB_PROFILE              specify github profile");
  console.log("  GITHUB_REPOSITORY           specify git repository");
  console.log("  GITHUB_TAG                  specify git tag");
  console.log(
    "  GITHUB_SECRET               specify token used to authenticate to github",
  );
  console.log(
    "  GITHUB_FILE                 specify file(s) (if multiple separate by : or ;)",
  );

  return input.values.help || input.positionals.includes("help") ? 0 : 1;
}

// Not running a supported Node.js version.
if (!isSupportedVersion(version)) {
  exit(2);
}

// An options object for parseArgs.
const options = {
  help: {
    type: "boolean",
    short: "h",
  },
  profile: {
    type: "string",
    short: "p",
  },
  repository: {
    type: "string",
    short: "r",
  },
  tag: {
    type: "string",
    short: "t",
  },
  secret: {
    type: "string",
    short: "s",
  },
  file: {
    type: "string",
    short: "f",
    multiple: true,
  },
  version: {
    type: "boolean",
    short: "v",
  },
};

// Construct a parsed input object.
const input = parseArgs({
  args: argv,
  options: options,
  allowPositionals: true,
});

// No arguments passed (positionals only contains the interpreter and script),
// or help specified? Then execute the help function and exit with appropiate
// exit code (0 if explicitly requested, 1 if no arguments passed).
if (
  input.positionals.length === 2 ||
  input.values.help ||
  input.positionals.includes("help")
) {
  exit(help(input));
}

// Read the name of all string type elements in the options object and construct
// environment variable names. Check if they are set. if set, insert their values
// into the input object, making it indistinguishable from being set on command-line.
// We handle file specially so its value always becomes an array by splitting on ; or ;.
Object.entries(options)
  .filter(([_, value]) => value.type === "string")
  .map(([key]) => key)
  .forEach((key) => {
    const value = env[`GITHUB_${key.toUpperCase()}`];
    if (
      value !== undefined &&
      input.values[key] === undefined &&
      key !== "file"
    ) {
      input.values[key] = value;
    } else if (
      value !== undefined &&
      input.values[key] === undefined &&
      key === "file"
    ) {
      input.values[key] = value
        .split(/[;:]/)
        .map((item) => item.trim())
        .filter(Boolean);
    }
  });

// Show input object.
console.log(input);

// Temporary exit.
exit(255);
//----------------------------------------------------------------------------//
const requestOptions = {
  hostname: "api.github.com",
  path: "/repos/raaftech/session/releases",
  method: "GET",
  headers: {
    Accept: "application/vnd.github+json",
    Authorization: "Bearer fake",
    "X-GitHub-Api-Version": "2022-11-28",
    "User-Agent": "JS/Uploader",
  },
};

const req = https.request(requestOptions, (res) => {
  let data = "";

  // A chunk of data has been received.
  res.on("data", (chunk) => {
    data += chunk;
  });

  // The whole response has been received.
  res.on("end", () => {
    console.log("I fetched a list of releases, trust me.");
  });
});

req.on("error", (e) => {
  console.error(`Problem with request: ${e.message}`);
});

// End the request
req.end();
