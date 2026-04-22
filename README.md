# gtnao/skills

gtnao's Claude Code skills, distributed as a plugin marketplace.

## Use (production)

Install via marketplace. Plugin files are copied to `~/.claude/plugins/cache/` and reused across sessions.

```text
/plugin marketplace add gtnao/skills
/plugin install gtnao-skills@gtnao
```

## Develop (this repo)

For iterating on skills in this repo, use `--plugin-dir` to read the repo in-place. No cache copy, no version bump needed — edits to `SKILL.md` are picked up live within the session.

```bash
claude --plugin-dir /path/to/this/repo
```

The production `install` path does not hot-reload: once installed, plugin files are cached, and edits to this repo won't propagate until you bump the `version` in `.claude-plugin/marketplace.json` and run `/plugin marketplace update gtnao`. Use `--plugin-dir` during development to avoid this.

## Skills

### `/init-ts-cli`

Bootstrap a minimal TypeScript CLI project in the current empty directory. Uses pnpm (with supply-chain hardening via `.npmrc`), tsx for local execution, and citty for the CLI entry point. The project name is taken from the current directory basename.

**Try it:**

```bash
mkdir -p /tmp/try-ts-cli && cd /tmp/try-ts-cli
claude --plugin-dir /path/to/this/repo   # dev
# or, if installed via marketplace:
# claude
```

then in the session:

```text
/init-ts-cli
```

## Structure

```
.
├── .claude-plugin/marketplace.json   # marketplace catalog
└── skills/<skill-name>/               # individual skills (SKILL.md + supporting files)
```
