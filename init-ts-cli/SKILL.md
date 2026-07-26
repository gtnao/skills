---
name: init-ts-cli
description: Bootstrap a minimal TypeScript CLI project in the current empty directory. Uses pnpm (with supply-chain hardening), tsx for local execution, and citty for the CLI entry point. The project name is taken from the current directory basename.
disable-model-invocation: true
allowed-tools: Write Bash(pnpm *) Bash(basename *) Bash(pwd) Bash(ls -A) Bash(ls) Bash(cp *)
---

# Bootstrap a TypeScript CLI project

Set up a new minimal TypeScript CLI project in the current working directory.

## Preconditions

1. Run `ls -A` — if it returns anything, stop and ask the user before proceeding.
2. Resolve the project name: `basename "$(pwd)"`. Use this value for `<project-name>` below.

## Files

Write these files verbatim. Do not add fields beyond what is shown — minimal is intentional.

### `package.json`

```json
{
  "name": "<project-name>",
  "private": true,
  "type": "module",
  "scripts": {
    "cli": "tsx src/cli/index.ts"
  }
}
```

### `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "types": ["node"]
  },
  "include": ["src/**/*"]
}
```

### `.gitignore`

```
node_modules
```

### `README.md`

Only the project name as a top-level heading — leave the body empty.

```markdown
# <project-name>
```

### `CLAUDE.md`

Copy the shared template from the plugin into the project root (do not inline its content):

```bash
cp "${CLAUDE_SKILL_DIR}/CLAUDE.md" ./CLAUDE.md
```

### `src/cli/index.ts`

```ts
import { defineCommand, runMain } from "citty";

const main = defineCommand({
  meta: {
    name: "<project-name>",
    version: "0.0.0",
    description: "",
  },
  run() {
    console.log("hello");
  },
});

runMain(main);
```

## Install

Always use `pnpm add` (never hand-write versions in `package.json`) so the latest version is resolved, subject to `minimum-release-age`.

```bash
pnpm add -D typescript tsx @types/node
pnpm add citty
```

## Verify

```bash
pnpm cli
```

Expected output: `hello`.
