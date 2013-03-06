#!/bin/zsh

# Edit as necessary
BACKUP="offsite"    # pool name of offsite ZFS pool
ZFS="/sbin/zfs"     # full path to zfs(8) binary
ZPOOL="/sbin/zpool" # full path to zpool(8) binary

# Do not edit beneath here. Please.
SERVER="$(hostname -s)"
DSETS=($("$ZFS" list -H -o name -t filesystem -r pool))

for D in $DSETS; do
    POOL=$(echo "$D" | awk -F '@' '{split($1,a,"/"); print a[1]}')
    DSET=$(echo "$D" | awk -F '@' '{split($1,a,"/"); print a[2]}')

    if [ -z "$DSET" ]; then FS="$POOL" else FS="$POOL/$DSET" fi

    SNAPS=($("$ZFS" list -t snapshot -Ho name -S creation -r "$FS" | grep "$FS@"))
    SNAPS=(${(@)SNAPS:#*swap*}) # no need to worry about swap

    FREQ_SNAP=(${(M)SNAPS:#*frequent*})
    HOUR_SNAP=(${(M)SNAPS:#*hourly*})
    DALY_SNAP=(${(M)SNAPS:#*daily*})
    WEEK_SNAP=(${(M)SNAPS:#*weekly*})
    MNTH_SNAP=(${(M)SNAPS:#*monthly*})

    "$ZFS" send -RI "$FREQ_SNAP[2]" "$FREQ_SNAP[1]" | ssh -c arcfour server.example.com "$ZFS recv -Fduv $BACKUP/$SERVER"
done