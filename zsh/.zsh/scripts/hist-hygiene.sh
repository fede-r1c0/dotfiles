#!/bin/bash
# hist-hygiene.sh - Detect and redact secrets from shell history files
#
# Scans ~/.zsh_history, ~/.bash_history, ~/.local/share/fish/fish_history
# for embedded secrets (API keys, tokens, passwords, credentials in URLs)
# and redacts them in-place atomically. Preserves the command — only the
# secret value is replaced with ***REDACTED:label***.
#
# No persistent backups are created: backup files of unredacted history
# multiply the exposure surface this tool exists to eliminate.
# POSIX same-FS `mv` provides atomicity; tmpfile is cleaned by trap EXIT.
#
# Logs contain only metadata (counters and labels) — never values, never
# line context.
#
# Usage: hist-hygiene.sh [OPTIONS]
#   -f, --find        Scan and report findings (no mutation, default)
#   -c, --clear       Redact secrets in-place (atomic, no backup)
#   -n, --dry-run     With --clear: preview without mutation
#   -y, --yes         Skip confirmation prompt for --clear
#   -p, --paranoid    Enable high-entropy patterns (high false-positive)
#       --cron        Non-interactive: redact + write metadata log + exit 0
#   -h, --help        Show this help
#
# Exit codes:
#   0  success
#   1  error (validation, IO, unsupported flag combination)
#   2  user cancelled

set -euo pipefail

readonly VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"; readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; readonly SCRIPT_DIR

# ==============================================================================
# Load Libraries
# ==============================================================================

# shellcheck source=lib/colors.sh
source "${SCRIPT_DIR}/lib/colors.sh"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"
# shellcheck source=lib/validation.sh
source "${SCRIPT_DIR}/lib/validation.sh"
# shellcheck source=lib/hist-patterns.sh
source "${SCRIPT_DIR}/lib/hist-patterns.sh"

# ==============================================================================
# Globals
# ==============================================================================

MODE="find"        # find | clear | cron
DRY_RUN=0
PARANOID=0
ASSUME_YES=0
QUIET=0
HIST_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hist-hygiene"
HIST_LOG_FILE="${HIST_LOG_DIR}/run.log"

# Disable lib/logging.sh file output — we manage our own metadata log
LOG_TO_FILE=false

HIST_FILES=()      # populated by detect_history_files
TOTAL_REDACTED=0   # accumulator for cron metadata

# ==============================================================================
# Help
# ==============================================================================

usage() {
    cat <<EOF
${SCRIPT_NAME} v${VERSION} - shell history secret scrubber

USAGE:
    ${SCRIPT_NAME} [OPTIONS]

OPTIONS:
    -f, --find        Scan and report findings (default, no mutation)
    -c, --clear       Redact secrets in-place atomically
    -n, --dry-run     With --clear: preview without mutation
    -y, --yes         Skip confirmation prompt for --clear
    -p, --paranoid    Enable high-entropy patterns (high false-positive)
        --cron        Non-interactive cron mode (redact + metadata log)
    -h, --help        Show this help

EXAMPLES:
    ${SCRIPT_NAME}                 # scan all detected history files
    ${SCRIPT_NAME} --clear         # redact (with confirmation)
    ${SCRIPT_NAME} --clear --yes   # redact without confirmation
    ${SCRIPT_NAME} --clear -n      # preview redaction
    ${SCRIPT_NAME} --cron          # daily cron entry

CRON ENTRY (suggested, daily at 18:00 local time):
    0 18 * * * ${SCRIPT_DIR}/${SCRIPT_NAME} --cron

DETECTED HISTORY FILES:
    ~/.zsh_history (zsh, supports redaction)
    ~/.bash_history (bash, supports redaction)
    ~/.local/share/fish/fish_history (fish, scan-only — YAML format)
EOF
}

# ==============================================================================
# Argument parsing
# ==============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--find)     MODE="find" ;;
            -c|--clear)    MODE="clear" ;;
            -n|--dry-run)  DRY_RUN=1 ;;
            -y|--yes)      ASSUME_YES=1 ;;
            -p|--paranoid) PARANOID=1 ;;
            --cron)        MODE="cron"; ASSUME_YES=1; QUIET=1 ;;
            -h|--help)     usage; exit 0 ;;
            -v|--version)  echo "${SCRIPT_NAME} v${VERSION}"; exit 0 ;;
            --) shift; break ;;
            -*)
                log_error "Unknown option: $1"
                echo "Run '${SCRIPT_NAME} --help' for usage." >&2
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                exit 1
                ;;
        esac
        shift
    done
}

# ==============================================================================
# History file detection
# ==============================================================================

detect_history_files() {
    HIST_FILES=()

    # zsh history (HISTFILE env or default)
    local zsh_hist="${HISTFILE:-$HOME/.zsh_history}"
    if [[ -f "$zsh_hist" && -s "$zsh_hist" ]]; then
        HIST_FILES+=("$zsh_hist")
    fi

    # bash history
    local bash_hist="$HOME/.bash_history"
    if [[ -f "$bash_hist" && -s "$bash_hist" ]]; then
        HIST_FILES+=("$bash_hist")
    fi

    # fish history (XDG)
    local fish_hist="${XDG_DATA_HOME:-$HOME/.local/share}/fish/fish_history"
    if [[ -f "$fish_hist" && -s "$fish_hist" ]]; then
        HIST_FILES+=("$fish_hist")
    fi

    return 0
}

# Returns "zsh" | "bash" | "fish" based on filename
hist_format() {
    local file="$1"
    case "$(basename "$file")" in
        .zsh_history|zsh_history)   echo "zsh" ;;
        .bash_history|bash_history) echo "bash" ;;
        fish_history)               echo "fish" ;;
        *)                          echo "unknown" ;;
    esac
}

# ==============================================================================
# Redaction — produces ***REDACTED:label*** for each pattern category
# ==============================================================================

# Per-label sed expression that redacts only the secret value, preserving
# the surrounding context (boundary chars, var names, scheme prefixes).
#
# Different patterns require different redaction strategies because their
# regexes embed structural context (URL schemes, env-var names, CLI flags)
# that we want to keep visible in the redacted line.
sed_expr_for_label() {
    local label="$1"
    case "$label" in
        github_token)
            echo 's#(gh[poursu]_)[A-Za-z0-9]{36}#\1***REDACTED***#g'
            ;;
        npm_token)
            echo 's#(npm_)[A-Za-z0-9]{36}#\1***REDACTED***#g'
            ;;
        openai_key)
            echo 's#sk-(proj-)?[A-Za-z0-9_-]{20,}#sk-***REDACTED***#g'
            ;;
        anthropic_key)
            echo 's#sk-ant-[A-Za-z0-9_-]{20,}#sk-ant-***REDACTED***#g'
            ;;
        slack_token)
            echo 's#(xox[bp]-)[0-9]+-[0-9]+-[A-Za-z0-9-]+#\1***REDACTED***#g'
            ;;
        stripe_key)
            echo 's#sk_(live|test)_[A-Za-z0-9]{24,}#sk_\1_***REDACTED***#g'
            ;;
        aws_access_key_id)
            echo 's#(AKIA|ASIA)[0-9A-Z]{16}#\1***REDACTED***#g'
            ;;
        jwt)
            echo 's#eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+#***REDACTED:jwt***#g'
            ;;
        url_creds)
            echo 's#((https?|postgres(ql)?|mysql|mongodb|redis|amqp|ftp)://)[^:/@[:space:]]+:[^@[:space:]]+@#\1***REDACTED***@#g'
            ;;
        env_assignment)
            echo 's#((API[_-]?KEY|ACCESS[_-]?TOKEN|AUTH[_-]?TOKEN|BEARER|SECRET[_-]?KEY|PRIVATE[_-]?KEY|PASSWORD|PASSWD|SECRET|TOKEN|CREDENTIAL[S]?|CLIENT[_-]?SECRET|DB[_-]?PASS)[[:space:]]*=[[:space:]]*)["'"'"']?[^"'"'"'[:space:]]{6,}#\1***REDACTED***#g'
            ;;
        curl_user_flag)
            echo 's#((-u|--user)[[:space:]]+)[^[:space:]]+:[^[:space:]]+#\1***REDACTED***#g'
            ;;
        curl_bearer)
            echo 's#([Aa]uthorization:[[:space:]]*[Bb]earer[[:space:]]+)[A-Za-z0-9._-]+#\1***REDACTED***#g'
            ;;
        mysql_password_flag)
            echo 's#([[:space:]]-p)[^[:space:]-][^[:space:]]*#\1***REDACTED***#g'
            ;;
        wget_password_flag)
            echo 's#(--password[= ])[^[:space:]]+#\1***REDACTED***#g'
            ;;
        pem_private_key)
            echo 's#-----BEGIN [A-Z ]*PRIVATE KEY-----#-----BEGIN ***REDACTED*** PRIVATE KEY-----#g'
            ;;
        high_entropy_b64)
            echo 's#[A-Za-z0-9+/=]{40,}#***REDACTED:high_entropy***#g'
            ;;
    esac
}

# Build a sed script that redacts each loaded pattern.
build_sed_script() {
    local i
    for i in "${!HIST_PATTERN_LABELS[@]}"; do
        sed_expr_for_label "${HIST_PATTERN_LABELS[$i]}"
    done
}

# Count matches in a file using the combined regex
count_matches() {
    local file="$1"
    local combined
    combined="$(hist_patterns_combined_regex)"
    local count
    count=$(grep -cE "$combined" "$file" 2>/dev/null || true)
    echo "${count:-0}"
}

# Per-label match counts: outputs "label:N" lines
match_counts_by_label() {
    local file="$1"
    local i count
    for i in "${!HIST_PATTERN_REGEXES[@]}"; do
        count=$(grep -cE "${HIST_PATTERN_REGEXES[$i]}" "$file" 2>/dev/null || true)
        if (( ${count:-0} > 0 )); then
            printf '%s:%d\n' "${HIST_PATTERN_LABELS[$i]}" "$count"
        fi
    done
}

# ==============================================================================
# Find mode — report only, no mutation
# ==============================================================================

cmd_find() {
    local file fmt count any=0

    for file in "${HIST_FILES[@]}"; do
        fmt="$(hist_format "$file")"
        count="$(count_matches "$file")"

        if (( count > 0 )); then
            any=1
            (( QUIET )) || printf '%b%s%b (%s): %d match(es)\n' \
                "$YELLOW" "$file" "$NC" "$fmt" "$count"
            if ! (( QUIET )); then
                while IFS= read -r line; do
                    printf '  %b%s%b\n' "$DIM" "  $line" "$NC"
                done < <(match_counts_by_label "$file" | sort)
            fi
        else
            (( QUIET )) || printf '%b%s%b (%s): clean\n' \
                "$GREEN" "$file" "$NC" "$fmt"
        fi
    done

    if (( any == 0 )); then
        (( QUIET )) || log_success "No secrets detected in history files"
        return 0
    fi

    (( QUIET )) || cat <<EOF

To redact: ${SCRIPT_NAME} --clear
To preview: ${SCRIPT_NAME} --clear --dry-run
EOF
    return 0
}

# ==============================================================================
# Clear mode — atomic in-place redaction without backup
# ==============================================================================

# Returns 0 on success, non-zero on failure (original is preserved by trap).
redact_file() {
    local file="$1"
    local fmt
    fmt="$(hist_format "$file")"

    if [[ "$fmt" == "fish" ]]; then
        log_warn "Skipping $file: fish YAML format not supported for redaction"
        return 0
    fi

    local before_count
    before_count="$(count_matches "$file")"
    if (( before_count == 0 )); then
        (( QUIET )) || log_info "$file: clean (skipped)"
        return 0
    fi

    if (( DRY_RUN )); then
        (( QUIET )) || log_info "[DRY-RUN] Would redact $before_count match(es) in $file"
        return 0
    fi

    # Atomic redaction: tmpfile in same FS, mv on success, trap cleans on failure
    local tmpfile
    tmpfile="$(mktemp "${file}.XXXXXX")"
    # shellcheck disable=SC2064
    trap "rm -f '$tmpfile'" RETURN

    # Build sed script to a temp file (handles many patterns cleanly)
    local sed_script
    sed_script="$(mktemp)"
    # shellcheck disable=SC2064
    trap "rm -f '$tmpfile' '$sed_script'" RETURN

    build_sed_script > "$sed_script"

    if ! sed -E -f "$sed_script" "$file" > "$tmpfile"; then
        log_error "sed failed redacting $file (original intact)"
        return 1
    fi

    # Validate tmpfile is not catastrophically truncated
    local orig_lines tmp_lines
    orig_lines=$(wc -l < "$file")
    tmp_lines=$(wc -l < "$tmpfile")
    if (( tmp_lines < orig_lines - before_count )); then
        log_error "Truncation detected ($orig_lines -> $tmp_lines lines), aborting (original intact)"
        return 1
    fi

    # Preserve permissions
    if is_macos; then
        local mode
        mode=$(stat -f '%Mp%Lp' "$file")
        chmod "$mode" "$tmpfile"
    else
        chmod --reference="$file" "$tmpfile"
    fi

    # Atomic POSIX rename
    if ! mv "$tmpfile" "$file"; then
        log_error "Rename failed for $file (original intact)"
        return 1
    fi

    TOTAL_REDACTED=$(( TOTAL_REDACTED + before_count ))
    (( QUIET )) || log_success "Redacted $before_count secret(s) in $file"
    return 0
}

cmd_clear() {
    local file
    local total_to_redact=0

    for file in "${HIST_FILES[@]}"; do
        local count
        count="$(count_matches "$file")"
        total_to_redact=$(( total_to_redact + count ))
    done

    if (( total_to_redact == 0 )); then
        (( QUIET )) || log_success "No secrets detected, nothing to redact"
        return 0
    fi

    if (( DRY_RUN == 0 && ASSUME_YES == 0 )); then
        log_warn "About to redact $total_to_redact secret(s) in-place (no backup)"
        if ! confirm "Continue?" "n"; then
            log_info "Cancelled by user"
            return 2
        fi
    fi

    for file in "${HIST_FILES[@]}"; do
        redact_file "$file" || {
            log_error "Redaction failed for $file"
            return 1
        }
    done
}

# ==============================================================================
# Cron mode — non-interactive, metadata-only logging
# ==============================================================================

# Append a single metadata line per history file. Never values.
log_metadata() {
    local file="$1"
    local before_count="$2"
    local labels="$3"
    local status="$4"
    local timestamp
    timestamp="$(date '+%Y-%m-%dT%H:%M:%S%z')"
    printf '%s file=%s scanned_lines=%d redacted=%d types=%s status=%s\n' \
        "$timestamp" "$(basename "$file")" \
        "$(wc -l < "$file" 2>/dev/null || echo 0)" \
        "$before_count" "${labels:-none}" "$status" >> "$HIST_LOG_FILE"
}

# Rotate logs older than 90 days
rotate_logs() {
    [[ -d "$HIST_LOG_DIR" ]] || return 0
    find "$HIST_LOG_DIR" -name '*.log' -type f -mtime +90 -delete 2>/dev/null || true
}

cmd_cron() {
    mkdir -p "$HIST_LOG_DIR"
    rotate_logs

    local file fmt before_count labels status
    for file in "${HIST_FILES[@]}"; do
        fmt="$(hist_format "$file")"
        before_count="$(count_matches "$file")"

        if [[ "$fmt" == "fish" ]]; then
            log_metadata "$file" "$before_count" "skipped_fish" "skipped"
            continue
        fi

        if (( before_count == 0 )); then
            log_metadata "$file" 0 "none" "clean"
            continue
        fi

        # Capture labels before redaction (file changes after)
        labels="$(match_counts_by_label "$file" | tr '\n' ',' | sed 's/,$//')"

        if redact_file "$file"; then
            status="redacted"
        else
            status="error"
        fi
        log_metadata "$file" "$before_count" "$labels" "$status"
    done

    return 0
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    parse_args "$@"

    local pattern_mode="default"
    (( PARANOID )) && pattern_mode="paranoid"
    load_patterns "$pattern_mode"

    detect_history_files

    if (( ${#HIST_FILES[@]} == 0 )); then
        (( QUIET )) || log_info "No history files detected"
        return 0
    fi

    case "$MODE" in
        find)  cmd_find ;;
        clear) cmd_clear ;;
        cron)  cmd_cron ;;
        *)     log_error "Unknown mode: $MODE"; return 1 ;;
    esac
}

main "$@"
