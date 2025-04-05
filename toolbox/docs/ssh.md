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

https://goteleport.com/blog/ssh-port-knocking/

### TODO

UsePAM no or yes???  
AuthenticationMethods publickey
