#!/bin/bash
# lib/hist-patterns.sh - Sensitive value detection patterns for shell history
#
# Provides parallel arrays of labels and regex patterns for detecting
# secrets in shell history files. Patterns favor low false-positive rate
# over exhaustive coverage.
#
# Source this file:
#   source "${SCRIPT_DIR}/lib/hist-patterns.sh"
#   load_patterns          # populates HIST_PATTERN_LABELS and HIST_PATTERN_REGEXES
#   load_patterns paranoid # adds high-FP entropy patterns
#
# Boundary surrogates `(^|[^A-Za-z0-9_])` and `([^A-Za-z0-9_]|$)` are used
# instead of `\b` because BSD grep on macOS does not support `\b` by default.

[[ -n "${_LIB_HIST_PATTERNS_LOADED:-}" ]] && return 0
readonly _LIB_HIST_PATTERNS_LOADED=1

# Bash 3.2 compatible parallel arrays — index N in LABELS maps to index N in REGEXES.
HIST_PATTERN_LABELS=()
HIST_PATTERN_REGEXES=()

_hist_pattern_add() {
    HIST_PATTERN_LABELS+=("$1")
    HIST_PATTERN_REGEXES+=("$2")
}

# Boundary helpers — POSIX ERE alternative to \b
readonly _HBL='(^|[^A-Za-z0-9_])'
readonly _HBR='([^A-Za-z0-9_]|$)'

load_patterns() {
    local mode="${1:-default}"

    HIST_PATTERN_LABELS=()
    HIST_PATTERN_REGEXES=()

    # GitHub tokens (consolidated): ghp_, gho_, ghu_, ghs_, ghr_
    _hist_pattern_add "github_token" \
        "${_HBL}(gh[poursu]_[A-Za-z0-9]{36})${_HBR}"

    # npm token
    _hist_pattern_add "npm_token" \
        "${_HBL}(npm_[A-Za-z0-9]{36})${_HBR}"

    # OpenAI keys (sk-... and sk-proj-...)
    _hist_pattern_add "openai_key" \
        "${_HBL}(sk-(proj-)?[A-Za-z0-9_-]{20,})${_HBR}"

    # Anthropic keys
    _hist_pattern_add "anthropic_key" \
        "${_HBL}(sk-ant-[A-Za-z0-9_-]{20,})${_HBR}"

    # Slack bot/user tokens
    _hist_pattern_add "slack_token" \
        "${_HBL}(xox[bp]-[0-9]+-[0-9]+-[A-Za-z0-9-]+)${_HBR}"

    # Stripe live/test keys
    _hist_pattern_add "stripe_key" \
        "${_HBL}(sk_(live|test)_[A-Za-z0-9]{24,})${_HBR}"

    # AWS access key IDs (long-lived AKIA, STS temp ASIA)
    _hist_pattern_add "aws_access_key_id" \
        "${_HBL}((AKIA|ASIA)[0-9A-Z]{16})${_HBR}"

    # JWT — three base64url segments separated by dots
    _hist_pattern_add "jwt" \
        "${_HBL}(eyJ[A-Za-z0-9_-]+\\.eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+)${_HBR}"

    # Credentials embedded in URLs: scheme://user:pass@host
    _hist_pattern_add "url_creds" \
        "(https?|postgres(ql)?|mysql|mongodb|redis|amqp|ftp)://[^:/@[:space:]]+:[^@[:space:]]+@"

    # Sensitive env-var assignments — minimum 6 chars after = filters PASS=1
    # Allows compound prefixes like DATABASE_PASSWORD, MY_API_KEY, APP_SECRET
    _hist_pattern_add "env_assignment" \
        "(^|[^A-Za-z0-9])([A-Z][A-Z0-9]*_)?(API[_-]?KEY|ACCESS[_-]?TOKEN|AUTH[_-]?TOKEN|BEARER|SECRET[_-]?KEY|PRIVATE[_-]?KEY|PASSWORD|PASSWD|SECRET|TOKEN|CREDENTIAL[S]?|CLIENT[_-]?SECRET|DB[_-]?PASS)[[:space:]]*=[[:space:]]*[\"']?[^\"'[:space:]]{6,}"

    # curl -u user:pass or --user user:pass
    _hist_pattern_add "curl_user_flag" \
        "${_HBL}curl[^|;&]*[[:space:]](-u|--user)[[:space:]]+[^[:space:]]+:[^[:space:]]+"

    # curl Authorization: Bearer
    _hist_pattern_add "curl_bearer" \
        "${_HBL}curl[^|;&]*[Aa]uthorization:[[:space:]]*[Bb]earer[[:space:]]+[A-Za-z0-9._-]+"

    # mysql -p<pass> (no space) — avoid matching -p alone
    _hist_pattern_add "mysql_password_flag" \
        "${_HBL}mysql[^|;&]*[[:space:]]-p[^[:space:]-][^[:space:]]*"

    # wget --password=... or --password ...
    _hist_pattern_add "wget_password_flag" \
        "${_HBL}wget[^|;&]*--password[= ][^[:space:]]+"

    # PEM private key block header (single line — multi-line blocks not pasted in shell)
    _hist_pattern_add "pem_private_key" \
        "-----BEGIN [A-Z ]*PRIVATE KEY-----"

    if [[ "$mode" == "paranoid" ]]; then
        # High false-positive: 40+ char base64-ish strings without context
        _hist_pattern_add "high_entropy_b64" \
            "${_HBL}([A-Za-z0-9+/=]{40,})${_HBR}"
    fi
}

# Build a single combined ERE for one-pass grep/sed
# Outputs to stdout: alternation of all loaded patterns
hist_patterns_combined_regex() {
    local i first=1
    for i in "${!HIST_PATTERN_REGEXES[@]}"; do
        if (( first )); then
            printf '%s' "${HIST_PATTERN_REGEXES[$i]}"
            first=0
        else
            printf '|%s' "${HIST_PATTERN_REGEXES[$i]}"
        fi
    done
}
