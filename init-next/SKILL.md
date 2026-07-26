---
name: init-next
description: Bootstrap an opinionated Next.js project in the current empty directory. Uses pnpm + TypeScript + Biome (no Tailwind), Mantine, PostgreSQL via docker compose, Atlas for schema-as-code migrations, and Prisma (db pull only, no prisma migrate).
disable-model-invocation: true
allowed-tools: Write Read Edit Bash(pnpm *) Bash(docker *) Bash(aqua *) Bash(git *) Bash(cp *) Bash(mkdir *) Bash(touch *) Bash(rm *) Bash(printf *) Bash(ls *) Bash(ls) Bash(cat *) Bash(open -a Docker)
---

# Bootstrap a Next.js project

Build the template in the current directory. File payloads live in this skill's `assets/` directory (`$ASSETS` below = `assets/` next to this SKILL.md). Execute the steps in order.

## 0. Preconditions

- The current directory is the target. create-next-app fails immediately if unrelated files exist, so verify the directory is effectively empty (`.git` is fine). If not, stop and ask the user.
- `docker` and `aqua` are required. If missing, skip the verification step (8) and report it.

## 1. Scaffold

```bash
pnpm dlx create-next-app@latest . --ts --biome --no-tailwind --app --src-dir \
  --import-alias "@/*" --use-pnpm --skip-install
```

`--skip-install` is mandatory: pnpm 10+ aborts install on unapproved build scripts (sharp), and when install fails create-next-app aborts BEFORE git init / AGENTS.md / CLAUDE.md generation. With all flags specified there are no interactive prompts.

## 2. Approve build scripts + install

```bash
cp $ASSETS/pnpm-workspace.yaml .   # allowBuilds: pre-approves sharp and prisma packages
pnpm install
```

## 3. Add dependencies

```bash
pnpm add @prisma/client @prisma/adapter-pg @mantine/core @mantine/hooks
pnpm add -D prisma dotenv postcss postcss-preset-mantine postcss-simple-vars
```

Prisma 7 requires a driver adapter at runtime (the Rust engine is gone), hence `@prisma/adapter-pg`. `dotenv` is needed because the Prisma CLI no longer auto-loads `.env`; `prisma.config.ts` imports it.

## 4. Prisma init and cleanup

```bash
pnpm prisma init --datasource-provider postgresql
cp $ASSETS/prisma.config.ts .
printf 'DATABASE_URL="postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable"\n' > .env
cp .env .env.example   # .env is excluded by create-next-app's .gitignore (.env*)
rm -rf .windsurf .agents .claude skills-lock.json   # prisma init drops agent skills; do not ship them
```

- Leave `prisma/schema.prisma` as generated (generator `prisma-client`, output `../src/generated/prisma`). Never hand-write models — they come from the DB via `db pull`.
- prisma init already added `/src/generated/prisma` to `.gitignore`.

## 5. Place files

```bash
cp $ASSETS/compose.yml $ASSETS/aqua.yaml $ASSETS/atlas.hcl $ASSETS/postcss.config.cjs .
mkdir -p db/migrations && touch db/schema.sql db/migrations/.gitkeep
rm public/*.svg src/app/favicon.ico src/app/globals.css src/app/page.module.css
touch public/.gitkeep
cp $ASSETS/layout.tsx src/app/layout.tsx
cp $ASSETS/page.tsx src/app/page.tsx
mkdir -p src/domain src/usecases src/boundaries/ports src/boundaries/adapters src/lib src/components src/queries
touch src/domain/.gitkeep src/usecases/.gitkeep src/boundaries/ports/.gitkeep \
  src/boundaries/adapters/.gitkeep src/lib/.gitkeep src/components/.gitkeep
cp $ASSETS/queries-client.ts src/queries/client.ts
```

Docs:
- `AGENTS.md` — keep the generated `nextjs-agent-rules` block at the top, then append the contents of `$ASSETS/dev-guide.md` after it
- `CLAUDE.md` — overwrite with the single line `@AGENTS.md`

## 6. package.json scripts

Add the following to the existing scripts (dev/build/start/lint/format):

```json
"typecheck": "tsc --noEmit",
"db:up": "docker compose up -d",
"db:down": "docker compose down",
"db:diff": "aqua exec -- atlas migrate diff --env local",
"db:apply": "aqua exec -- atlas migrate apply --env local",
"db:pull": "prisma db pull && prisma generate",
"generate": "prisma generate"
```

atlas runs via `aqua exec --` so the version pinned in aqua.yaml is used, not whatever is on PATH. `pnpm db:diff <name>` works because pnpm appends the argument, which atlas accepts as a positional after flags.

## 7. aqua

```bash
aqua i -l
```

## 8. Verify

```bash
docker info >/dev/null 2>&1 || { open -a Docker; until docker info >/dev/null 2>&1; do sleep 2; done; }  # macOS
docker compose up -d
pnpm prisma generate   # generate even with zero models (import target of src/queries/client.ts)
pnpm build && pnpm lint && pnpm typecheck
pnpm db:diff noop_check   # expect: "no changes to be made" (atlas dev DB runs in docker, daemon required)
```

## 9. Commit

Once verification passes, commit everything (create-next-app already made the initial commit):

```bash
git add -A && git commit -m "Set up template stack (Mantine, Prisma, Atlas, compose)"
```

## Known pitfalls

- If pnpm writes `allowBuilds: <pkg>: set this to true or false` into `pnpm-workspace.yaml`, install aborted on an unapproved build script. Set the package to `true` and re-run `pnpm install`.
- Mantine components cannot be server components (`'use client'` required). In server components, use flat aliases (`PopoverTarget`) instead of compound syntax (`Popover.Target`).
- Schema change flow: edit `db/schema.sql` → `pnpm db:diff <name>` → `pnpm db:apply` → `pnpm db:pull`. Prisma migrate is never used.
