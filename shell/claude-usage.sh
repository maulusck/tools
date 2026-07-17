#!/bin/sh
# claude-usage — Claude Code subscription usage, same data as the TUI /usage. POSIX sh.
#   watch:  watch -n 300 claude-usage    # keep >=180s or the endpoint 429s you for the whole session
#   raw:    RAW=1 claude-usage           # full unparsed JSON even when jq is installed

CREDS="$HOME/.claude/.credentials.json"

# POSIX token extractor (no jq needed): pull accessToken out of a creds JSON on stdin
extract() { sed -n 's/.*"accessToken"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'; }

tok="${CLAUDE_CODE_OAUTH_TOKEN:-}"
[ -z "$tok" ] && [ -f "$CREDS" ] && tok=$(extract < "$CREDS")
[ -z "$tok" ] && tok=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null | extract)
[ -z "$tok" ] && { echo "no OAuth token — run 'claude' then /login" >&2; exit 1; }

# ponytail: User-Agent must look like the CLI or the endpoint hands out permanent 429s
ver=$(claude --version 2>/dev/null | sed -n 's/.*\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\).*/\1/p')

resp=$(curl -sS -w '\n%{http_code}' \
  -H "Authorization: Bearer $tok" \
  -H "anthropic-beta: oauth-2025-04-20" \
  -H "User-Agent: claude-cli/${ver:-2.0.0} (external, cli)" \
  https://api.anthropic.com/api/oauth/usage)

code=$(printf '%s\n' "$resp" | tail -n1)
body=$(printf '%s\n' "$resp" | sed '$d')

if [ "$code" != 200 ]; then
  echo "HTTP $code — $body" >&2
  [ "$code" = 401 ] && echo "token expired — run 'claude' once to refresh" >&2
  [ "$code" = 429 ] && echo "rate-limited: poll no faster than every 180s" >&2
  exit 1
fi

# jq optional: clean per-window view if present, raw JSON if not
if [ -z "${RAW:-}" ] && command -v jq >/dev/null 2>&1; then
  out=$(printf '%s' "$body" | jq -r '
    def bar($u): ([($u/100*20|floor),20]|min) as $f
      | "[" + (if $f>0 then "#"*$f else "" end) + (if 20-$f>0 then "-"*(20-$f) else "" end) + "]";
    to_entries[]
    | select((.value|type) == "object" and (.value.utilization|type) == "number")
    | "\(.key|gsub("_";" ")): \(bar(.value.utilization)) \(.value.utilization)%"
      + (if .value.resets_at then "  (resets \(.value.resets_at[0:16]|sub("T";" ")) UTC)" else "" end)')
  [ -n "$out" ] && printf '%s\n' "$out" || printf '%s' "$body" | jq .
else
  command -v jq >/dev/null 2>&1 || echo "jq not found (install it for a cleaner view)" >&2
  printf '%s\n' "$body"
fi
