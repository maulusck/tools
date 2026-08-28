# container management client
ct=$(command -v podman >/dev/null 2>&1 && echo podman || echo docker)
# containers data directory
LOCAL="${HOME}/local"
# backup directory
BACKUP="/srv/bak/containers"
# max backups to keep
KEEP=${1:-9}
DELETE=$((KEEP + 1))