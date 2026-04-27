# gtnao/skills

gtnao's Claude Code skills, distributed via [APM (Agent Package Manager)](https://github.com/microsoft/apm).

## Install

Install an individual skill into the current project (deploys to `.claude/skills/`):

```bash
apm install gtnao/skills/init-ts-cli
```

In an empty repo (no `.claude/` directory yet), APM cannot auto-detect the target — pass `--target claude` explicitly:

```bash
apm install --target claude gtnao/skills/init-ts-cli
```

Or globally (deploys to `~/.claude/skills/`):

```bash
apm install -g gtnao/skills/init-ts-cli
```

Pin a version:

```bash
apm install gtnao/skills/init-ts-cli#v0.1.0
```

Or declare in `apm.yml`:

```yaml
dependencies:
  apm:
    - gtnao/skills/init-ts-cli
```

then `apm install`.

## Skills

### `init-ts-cli`

Bootstrap a minimal TypeScript CLI project in the current empty directory. Uses pnpm (with supply-chain hardening via `.npmrc`), tsx for local execution, and citty for the CLI entry point. The project name is taken from the current directory basename.

Invoke with `/init-ts-cli` in a Claude Code session opened in an empty directory.

## Structure

```
.
└── <skill-name>/        # one directory per skill
    └── SKILL.md         # required; supporting files (scripts/, references/, assets/) optional
```

Follows the [agentskills.io](https://agentskills.io/specification) open standard. Users install individual skills by path: `apm install gtnao/skills/<skill-name>`.
