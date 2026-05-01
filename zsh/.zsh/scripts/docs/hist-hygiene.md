# hist-hygiene.sh

Detect and redact secrets (API keys, tokens, passwords, credentials in URLs) embedded in shell history files.

## Features

- **Redact, not delete**: preserves command line, replaces only the sensitive value with `***REDACTED***` so history stays usable for `Ctrl+R` / `!!`
- **Atomic in-place rewrite**: POSIX `mv` same-FS via `mktemp` + `trap EXIT`; no `.bak` files left behind (backups would multiply secret exposure)
- **Multi-shell**: scans `~/.zsh_history`, `~/.bash_history`, and fish history (XDG path); fish redaction skipped (multi-line YAML format)
- **Metadata-only logs**: cron output records counts and label types, never values or line context
- **Idempotent**: re-running on already-redacted file is a no-op
- **High-confidence patterns by default**: GitHub/npm/OpenAI/Anthropic/Slack/Stripe/AWS tokens, JWTs, URL credentials, sensitive env-var assignments, `curl -u` / `Authorization: Bearer`, PEM headers
- **`--paranoid` opt-in**: matches 40+ char base64-ish strings (high false-positive)

## Quick Usage

```bash
# Scan only (read-only, safe)
histfind

# Preview redaction without writing
hist-hygiene.sh --clear --dry-run

# Redact in-place (prompts for confirmation)
histclear

# Non-interactive (cron / scripted)
hist-hygiene.sh --clear --yes

# Pause / resume recording in current session
histstop
histstart
```

## Options

| Long | Description |
|------|-------------|
| `--find` | Scan and report findings (default; no mutation) |
| `--clear` | Redact secrets in-place atomically |
| `--cron` | Non-interactive run; metadata-only log, no stdout |
| `--dry-run` | With `--clear`, preview without writing |
| `--yes` | Skip confirmation prompt for `--clear` |
| `--paranoid` | Add high-FP entropy patterns (40+ char base64) |
| `--quiet` | Suppress progress output |
| `--help` | Show help |
| `--version` | Show version |

## Cron Configuration

```bash
# Edit crontab
crontab -e

# Daily redaction at 18:00 local time
0 18 * * * ~/.zsh/scripts/hist-hygiene.sh --cron
```

Logs land at `~/.local/state/hist-hygiene/run.log` and rotate after 90 days. Format:

```
2026-05-01T18:00:01-03:00 file=zsh_history scanned_lines=42351 redacted=3 types=github_token:2,aws_access_key_id:1 status=ok
```

**macOS note**: cron requires Full Disk Access for `/usr/sbin/cron` to read `~/.zsh_history`. Grant via System Settings → Privacy & Security → Full Disk Access → `+` → `/usr/sbin/cron`.

## launchd (recommended on macOS)

`launchd` runs missed jobs after wake (cron skips them) and avoids the Full Disk Access caveat for the cron daemon.

`~/Library/LaunchAgents/com.fede.hist-hygiene.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.fede.hist-hygiene</string>
    <key>ProgramArguments</key>
    <array>
      <string>/Users/fede/dotfiles/zsh/.zsh/scripts/hist-hygiene.sh</string>
      <string>--cron</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
      <key>Hour</key><integer>18</integer>
      <key>Minute</key><integer>0</integer>
    </dict>
</dict>
</plist>
```

```bash
launchctl load ~/Library/LaunchAgents/com.fede.hist-hygiene.plist
launchctl list | grep hist-hygiene
```

## Adoption Path

Three phases. Skipping ahead defeats the safety property of validating before automating.

**Phase 1 — manual trust (~1 week)**

```bash
histfind                              # read-only scan; see what's there
hist-hygiene.sh --clear --dry-run     # preview redactions, no mutation
histclear                             # supervised first redaction
```

After `histclear`, inspect `~/.zsh_history` directly. Confirm commands preserved, secrets replaced with `***REDACTED***`. Verify `Ctrl+R` still surfaces commands.

**Phase 2 — automation**

Install launchd plist (or cron). Tail the log weekly:

```bash
tail -20 ~/.local/state/hist-hygiene/run.log
```

Investigate any unexpected label in `types=`. False positive → adjust regex in `lib/hist-patterns.sh`.

**Phase 3 — active session hygiene**

Use `histstop` before pasting a command with a secret; `histstart` after. Cron is safety net for what slipped through.

```bash
histstop
deploy --token=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
histstart
```

## Risks (first month)

| Risk | Mitigation |
|------|------------|
| False positive redacts legitimate value | Log `types=label:N` exposes which patterns fire; unexpected label → review regex |
| `***REDACTED***` placeholder reused via `Ctrl+R` | By design — forces re-typing the secret value, never silently re-uses it |
| Indexers (atuin, mcfly, fzf-history) cached the secret pre-redaction | After `histclear`, trigger reindex of the indexer (e.g. `atuin import auto`) |
| Concurrent shell writing to `$HISTFILE` during redaction | Run cron at low-contention hour (18:00 default); `flock` used when available |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (clean, redacted, or no history files) |
| 1 | Error (invalid flags, write failure, validation failure) |
| 2 | User cancelled `--clear` confirmation |

## Related

- Pattern catalog: [`lib/hist-patterns.sh`](../lib/hist-patterns.sh) — 15 high-confidence regexes
- Tests: [`tests/test_hist_hygiene.bats`](../tests/test_hist_hygiene.bats), [`tests/test_hist_patterns.bats`](../tests/test_hist_patterns.bats)
