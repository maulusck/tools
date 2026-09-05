## Local container management scripts

Tools built around a `~/local` directory holding one subdirectory per container's
data. Useful for small, manually managed containerized environments.

`env.sh` is the single config point. Everything is overridable via environment:

    CT_BIN     container runtime      (default: podman, else docker)
    CT_LOCAL   data directory         (default: ~/local)
    CT_BACKUP  backup directory       (default: /srv/bak/containers)
    CT_KEEP    backups to retain      (default: 9)

e.g. `CT_BACKUP=/tmp/test ./backup-local.sh`. Pure POSIX sh. The rest is up to you.
