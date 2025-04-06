# SSH

### Copy public key to server

    ssh-copy-id -i $HOME/.ssh/id_rsa.pub user@server.local

### Edit ssh config on server to disallow password authentication

    sudo vi /etc/ssh/sshd_config

    ChallengeResponseAuthentication no
    PasswordAuthentication no
    UsePAM no --> problem with systemctl over ssh!! Set it to yes instead and make sure both ChallengeResponseAuthentication and PasswordAuthentication is set to no
    PermitRootLogin no

Save and close the file. Reload or restart the ssh server on Linux:

    sudo systemctl reload ssh

### Verification

Try to login as root:

    ssh root@server.local

> Permission denied (publickey).

Try to login with password only:

    ssh user@server.local -o PubkeyAuthentication=no

> Permission denied (publickey).

### Documentation

    man sshd_config
    man ssh

### Port Knocking

Connect to your server via SSH and change the SSH port to something else
(e.g., 63123)

    sudo vi /etc/ssh/sshd_config
    # Search for line `Port 22` and change it to 63123
    systemctl restart sshd.service

> If you have any firewall rules, make sure to allow SSH on the new port and
> block the old one 22.

Reconnect to your server now with the new SSH port

    ssh user@server.local -p 63123

Implement port knocking with knockd

    sudo apt install knockd

TODO Complete from https://goteleport.com/blog/ssh-port-knocking/ when wq2 is
available.

### TODO

UsePAM no or yes???  
AuthenticationMethods publickey
