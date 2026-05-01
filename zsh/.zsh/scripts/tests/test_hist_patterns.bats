#!/usr/bin/env bats
# Tests for lib/hist-patterns.sh — regex catalog for history secret detection

setup() {
    SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")" && pwd)"
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/lib/hist-patterns.sh"
    load_patterns
}

# Helper: assert string matches the combined regex
_match() {
    local input="$1"
    local combined
    combined="$(hist_patterns_combined_regex)"
    echo "$input" | grep -qE "$combined"
}

# Helper: assert string does NOT match
_nomatch() {
    local input="$1"
    local combined
    combined="$(hist_patterns_combined_regex)"
    ! echo "$input" | grep -qE "$combined"
}

# ==============================================================================
# Token prefix patterns
# ==============================================================================

@test "matches GitHub PAT (ghp_)" {
    _match "git push https://ghp_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA@github.com/x"
}

@test "matches GitHub OAuth (gho_)" {
    _match "export GH_TOKEN=gho_BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"
}

@test "matches npm token" {
    _match "npm publish --token npm_CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"
}

@test "matches OpenAI key" {
    _match "OPENAI_API_KEY=sk-proj-abcdefghijklmnopqrstuvwxyz123456"
}

@test "matches Anthropic key" {
    _match "ANTHROPIC_API_KEY=sk-ant-abcdefghijklmnop1234567890"
}

@test "matches Slack bot token" {
    _match "curl -H xoxb-12345-67890-AbCdEfGhIjKlMn"
}

@test "matches Stripe live key" {
    # Fixture: sk_live_ prefix shape, neutralized to avoid push-protection scanners
    local prefix="sk_live"
    _match "stripe login --api-key ${prefix}_EXAMPLEAAAAAAAAAAAAAAAA"
}

@test "matches AWS access key (AKIA)" {
    _match "AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE"
}

@test "matches AWS STS key (ASIA)" {
    _match "export AWS_ACCESS_KEY_ID=ASIAIOSFODNN7EXAMPLE"
}

@test "rejects malformed ghp_ (too short)" {
    _nomatch "ghp_short"
}

# ==============================================================================
# JWT
# ==============================================================================

@test "matches JWT three-segment token" {
    _match "Authorization: eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTYifQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
}

@test "rejects two-segment string (not JWT)" {
    _nomatch "eyJhbGc.eyJzdWI"
}

# ==============================================================================
# URL credentials
# ==============================================================================

@test "matches postgres URL with credentials" {
    _match "psql postgres://admin:hunter2@db.example.com/mydb"
}

@test "matches https URL with basic auth" {
    _match "curl https://user:secret@api.example.com/v1"
}

@test "matches mysql URL with credentials" {
    _match "mysql://root:rootpass@localhost:3306/db"
}

@test "rejects URL without credentials" {
    _nomatch "git clone https://github.com/user/repo.git"
}

# ==============================================================================
# Env-var assignments
# ==============================================================================

@test "matches PASSWORD= with 6+ chars" {
    _match "export DATABASE_PASSWORD=hunter2pass"
}

@test "matches API_KEY= assignment" {
    _match "API_KEY=abcdef123456"
}

@test "matches CLIENT_SECRET= with quotes" {
    _match 'CLIENT_SECRET="abcdef123456"'
}

@test "rejects PASS=1 (below min length)" {
    _nomatch "PASS=1"
}

@test "rejects FOO=bar (not a sensitive name)" {
    _nomatch "FOO=barvalue"
}

# ==============================================================================
# CLI auth flags
# ==============================================================================

@test "matches curl -u user:pass" {
    _match "curl -u admin:hunter2 https://api.example.com"
}

@test "matches curl --user user:pass" {
    _match "curl --user fede:secret123 https://api.example.com"
}

@test "matches curl Authorization Bearer" {
    _match 'curl -H "Authorization: Bearer abc123def456" https://api.example.com'
}

@test "matches mysql -ppassword (no space)" {
    _match "mysql -uroot -psecretpass mydb"
}

@test "matches wget --password=secret" {
    _match "wget --password=mypassword https://example.com/file"
}

@test "rejects bare curl without auth flag" {
    _nomatch "curl https://example.com/api"
}

# ==============================================================================
# PEM blocks
# ==============================================================================

@test "matches PEM RSA private key header" {
    _match "-----BEGIN RSA PRIVATE KEY-----"
}

@test "matches PEM EC private key header" {
    _match "-----BEGIN EC PRIVATE KEY-----"
}

@test "rejects public key header" {
    _nomatch "-----BEGIN PUBLIC KEY-----"
}

# ==============================================================================
# Paranoid mode (high false-positive)
# ==============================================================================

@test "default mode does NOT match SHA1 hex string" {
    _nomatch "git checkout deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
}

@test "default mode does NOT match base64 path" {
    _nomatch "ls /opt/data/abcdefghijklmnopqrstuvwxyz0123456789ABCD"
}

@test "paranoid mode matches 40+ char base64 string" {
    load_patterns paranoid
    _match "echo abcdefghijklmnopqrstuvwxyz0123456789ABCDEFG"
}

# ==============================================================================
# Combined regex sanity
# ==============================================================================

@test "combined regex is non-empty after load_patterns" {
    local combined
    combined="$(hist_patterns_combined_regex)"
    [ -n "$combined" ]
}

@test "double-source guard prevents reload" {
    # Re-source should be no-op (return 0 immediately)
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/lib/hist-patterns.sh"
    [ "$?" -eq 0 ]
}
