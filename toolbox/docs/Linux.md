# Linux in General

## Too big `/var/log/journal` file

You can diminish the size of the journal by means of these commands:

Retain the most recent 100M of data:

    sudo journalctl --vacuum-size=100M

Delete everything but the last 10 days.

    sudo journalctl --vacuum-time=10d

See also `man journalctl`.
