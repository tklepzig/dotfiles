# Linux in General

## Useful and up-to-date Commands

- grep (replaces egrep/fgrep)
- dig (replaces nslookup)
- ss (replaces netstat)
- ip (replaces ifconfig)
- iw (replaces iwconfig)
- rsync & sftp (replaces scp)
- nftables (replaces iptables)

## Redirection Shorthand

Redirect directly stdout and stderr to whatever, e.g. `/dev/null`

    &>/dev/null

> instead of
>
>     >/dev/null 2>&1

## Retrieve who is taking up so much space

This will tell you which directory is taking up the most space, then just change
`/` to point to that dir, and repeat.

    du -h --max=1 -x / 2>/dev/null | sort -h

> Alternatively install ncdu.

## Too big `/var/log/journal` file

You can diminish the size of the journal by means of these commands:

Retain the most recent 100M of data:

    sudo journalctl --vacuum-size=100M

Delete everything but the last 10 days.

    sudo journalctl --vacuum-time=10d

See also `man journalctl`.
