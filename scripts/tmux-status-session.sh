#!/bin/sh
tmux new-session -s SysStat -n MAIN \; \
        send-keys 'bmon' C-m \; \
        split-window -h \; \
        send-keys 'htop' C-m \; \
        split-window -v \; \
        send-keys 'while true; do (clear && sensors && sleep 10) done' C-m
