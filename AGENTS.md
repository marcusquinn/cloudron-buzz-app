# Buzz for Cloudron

<!-- AI-CONTEXT-START -->

## Quick Reference

- **Build**: `docker build --tag cloudron-buzz-app:test .`
- **Test**: `./test/package-test.sh`
- **Deploy**: `cloudron install --location buzz`
- **Update**: `cloudron update --app buzz`
- **Health**: `cloudron exec --app buzz -- /app/code/buzz-ctl status`

## Project Overview

Cloudron package for the Buzz human-agent collaboration workspace. It runs a
single secure Buzz relay with Cloudron PostgreSQL and Redis addons plus a
loopback-only MinIO service for media and Git object storage.

## Architecture

- `/app/code` is read-only package code and pinned upstream binaries.
- `/app/data/config` stores stable relay identity and generated secrets.
- `/app/data/minio` stores authoritative media and Git objects.
- `/run/buzz` contains disposable Git hydration and pack-cache data.
- `supervisord` manages MinIO and the Buzz relay as the `cloudron` user.

## Conventions

- Commits use Conventional Commits.
- Branches use `feature/`, `bugfix/`, `hotfix/`, `refactor/`, or `chore/`.
- Every container stage is pinned by tag and digest.
- Runtime scripts pass ShellCheck with zero findings.
- Never print persisted private keys, passwords, or service credentials.

## Key Files

- `CloudronManifest.json`: app metadata, addons, memory, and health contract.
- `Dockerfile`: pinned multi-stage runtime assembly.
- `start.sh`: secure first-run initialization and process launch.
- `run-relay.sh`: production Buzz configuration and object-store bootstrap.
- `run-minio.sh`: private loopback MinIO process.
- `buzz-ctl`: owner, member, and health administration.
- `test/package-test.sh`: static package and security-contract tests.

<!-- AI-CONTEXT-END -->

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` for
the full workflow context and command reference.

### Beads quick reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for all task tracking. Do not use TodoWrite, TaskCreate, or
  Markdown TODO lists.
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, complete every step below. Work is not
complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:

   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```

5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**

- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
