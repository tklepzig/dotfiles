move file to /etc/cron.d/
chmod 755 file
chown root:root file

sample entry:

0 4 * * * root /sbin/shutdown -r +5