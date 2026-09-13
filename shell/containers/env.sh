# container runtime (auto-detected; override with CT_BIN=docker)
ct=${CT_BIN:-$(command -v podman || command -v docker)} || { echo "podman/docker not found" >&2; exit 1; }
# containers data directory, one subdir per container (override: CT_LOCAL)
CT_LOCAL=${CT_LOCAL:-$HOME/local}
# backup directory (override: CT_BACKUP)
CT_BACKUP=${CT_BACKUP:-/srv/bak/containers}
# max backups to keep per group (override: CT_KEEP)
CT_KEEP=${CT_KEEP:-9}
# helper image for volume backups; any image with tar works (override: CT_IMG)
CT_IMG=${CT_IMG:-docker.io/library/busybox}
