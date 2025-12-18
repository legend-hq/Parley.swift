
# Mercator

Mercator is a full back-end system for the Legend App (non-custodial crypto services).

## Outline

This project has a few sub-projects:

 - `Sources/Mercator` - Core app logic and flows.
 - `Sources/Charter` - A library to map intents to operations.
 - `Sources/Portfolio` - Data about on-chain state for accounts.
 - `Soruces/Server` - HTTP Server for `Charter` [DEPRECATED]
 - `Sources/Tradewinds` - Core optimization algorithm.
 - `Sources/Parley` - The WASM interface (e.g. to `Charter` and other features).

## Style

### Formatting

You may always run `swift format <file>` for any file you have touched.

### Commits

All commits should take the form:

```
<title>

<summary of commit>
```

The title should be direct (e.g. "Add Across Bridge Flows") and always in Title Case (don't add "feat:" "bug:" etc). The body should be a clean summary of changes and relatively concise and provide some simple context. Explain things only when the code review might be otherwise difficult to understand. Don't add "crafted by <AI TOOL>" or anything.

You should likely run `swift format` on all files before commiting them.

IMPORTANT !! You are not to commit unless expressly asked by the user. !! IMPORTANT

When the user _does_ ask you to commit, you made stage your changes (e.g. `git add ...`)

You should not leave any unstaged files when you commit. If you think the files are ready, add them, if they are not, abort the commit process.

## Code Hints

### SwiftNumber `Number` Type

The `Number` type in this project is a `BigUInt`-like type. It cannot be initialized from a string containing a decimal point (e.g., `Number("38.7")` will crash).

To represent decimal values with precision, use scientific notation in the string. The `Number` type can parse this format correctly.

**Correct usage:**
`let n = Number("38.7e6")`

### Parley

Parley is the WASM interface to `Charter` and other systems (e.g. to be embedded in other software).

**NOTE**: This repo is using the Web Assembly SDK that ships with Swift (this is new in Swift 6.2) and **DOES NOT USE SWIFTWASM** which is a different repo. Keep this instruction at top of mind and don't assume anything you know from SwiftWasm.

Building Parley:

 - `scripts/build-parley.sh`: This script builds Parley using the correct versions of Swift and its Web Assembly SDK.

Testing Parley:

 - `bun scripts/test-parley.js`
