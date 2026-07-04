#!/bin/sh
# Mirror Gitea repos to their existing GitHub repos. Idempotent.
set -eu

usage() {
  cat <<EOF
Usage: $0 [-h]

Mirrors every Gitea repo to a GitHub repo of the same name, when that
GitHub repo exists. Skips ones already mirrored. Set all vars to run
unattended (cron); leave any unset to be prompted.

  GITEA           Gitea base URL, e.g. https://gitea.example.com
  GITEA_TOKEN     Gitea API token
  GH_USER         GitHub account owning the target repos
  GH_TOKEN        GitHub PAT with repo scope
  INTERVAL        Sync interval          [24h0m0s]
  SYNC_ON_COMMIT  Sync on every commit   [y/N]
EOF
}
[ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] && { usage; exit 0; }

for c in curl jq; do command -v "$c" >/dev/null || { echo "$c: not found" >&2; exit 1; }; done
die() { echo "$0: $*" >&2; exit 1; }

# track whether anything was prompted (=> interactive => confirm before run)
prompted=0

# ask VAR "text" [secret|default]   default shown as [default]
ask() {
  eval "v=\${$1:-}"; [ -n "$v" ] && return
  prompted=1
  case ${3:-} in
    secret) printf '%s: ' "$2"; stty -echo; read -r v; stty echo; echo ;;
    ?*)     printf '%s [%s]: ' "$2" "$3"; read -r v
            [ -z "$v" ] && case $3 in */*) v=$(printf %s "$3" | tr -dc 'A-Z');; *) v=$3;; esac ;;
    *)      printf '%s: ' "$2"; read -r v ;;
  esac
  [ -n "$v" ] || die "$1 required"; eval "$1=\$v"
}

ask GITEA          "Gitea base URL"
ask GITEA_TOKEN    "Gitea API token"         secret
ask GH_USER        "GitHub account"
ask GH_TOKEN       "GitHub PAT (repo scope)" secret
ask INTERVAL       "Sync interval"           24h0m0s
ask SYNC_ON_COMMIT "Sync on every commit?"   y/N

GITEA=${GITEA%/}
case $SYNC_ON_COMMIT in [yY]*) soc=true ;; *) soc=false ;; esac
GA="Authorization: token $GITEA_TOKEN"
GH="Authorization: token $GH_TOKEN"

# gitea METHOD PATH [json] -> body on stdout, sets $code
gitea() {
  if [ -n "${3:-}" ]; then
    r=$(curl -s -w '\n%{http_code}' -X "$1" -H "$GA" \
        -H 'Content-Type: application/json' -d "$3" "$GITEA$2")
  else
    r=$(curl -s -w '\n%{http_code}' -X "$1" -H "$GA" "$GITEA$2")
  fi
  code=${r##*
}; printf '%s' "${r%
*}"
}
gh_has() { [ "$(curl -s -o /dev/null -w '%{http_code}' -H "$GH" \
           "https://api.github.com/repos/$GH_USER/$1")" = 200 ]; }

# preflight
curl -sf -H "$GH" https://api.github.com/user >/dev/null || die "GitHub token rejected"
gitea GET /api/v1/user/repos?limit=1 >/dev/null
[ "$code" = 200 ] || die "Gitea request failed (HTTP $code)"

printf '\n  Gitea   %s\n  GitHub  %s\n  Every   %s\n  OnPush  %s\n\n' \
  "$GITEA" "$GH_USER" "$INTERVAL" "$soc"
[ "$prompted" = 1 ] && { printf '  Enter to start, Ctrl-C to abort: '; read -r _; echo; }

added=0 kept=0 absent=0 failed=0 page=1
while :; do
  repos=$(gitea GET "/api/v1/user/repos?limit=50&page=$page")
  n=$(printf '%s' "$repos" | jq 'length'); [ "$n" -eq 0 ] && break
  i=0
  while [ "$i" -lt "$n" ]; do
    owner=$(printf '%s' "$repos" | jq -r ".[$i].owner.login")
    name=$( printf '%s' "$repos" | jq -r ".[$i].name"); i=$((i+1))
    url="https://github.com/$GH_USER/$name.git"
    slug="$owner/$name"

    gh_has "$name" || { printf '  \342\200\224 %-40s no github repo\n' "$slug"; absent=$((absent+1)); continue; }

    m=$(gitea GET "/api/v1/repos/$owner/$name/push_mirrors")
    printf '%s' "$m" | jq -e --arg u "$url" 'any(.[];.remote_address==$u)' >/dev/null 2>&1 \
      && { printf '  = %-40s already mirrored\n' "$slug"; kept=$((kept+1)); continue; }

    json=$(jq -n --arg a "$url" --arg u "$GH_USER" --arg p "$GH_TOKEN" \
                 --arg iv "$INTERVAL" --argjson s "$soc" \
      '{remote_address:$a,remote_username:$u,remote_password:$p,interval:$iv,sync_on_commit:$s}')
    gitea POST "/api/v1/repos/$owner/$name/push_mirrors" "$json" >/dev/null
    case $code in
      20*) printf '  + %-40s mirror added\n' "$slug"; added=$((added+1)) ;;
      *)   printf '  ! %-40s failed (HTTP %s)\n' "$slug" "$code"; failed=$((failed+1)) ;;
    esac
  done
  page=$((page+1))
done

printf '\n  added %d   kept %d   absent %d   failed %d\n' "$added" "$kept" "$absent" "$failed"
