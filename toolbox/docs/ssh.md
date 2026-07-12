# SSH

<!-- vim-markdown-toc GFM -->

* [Copy public key to server](#copy-public-key-to-server)
* [Edit ssh config on server to disallow password authentication](#edit-ssh-config-on-server-to-disallow-password-authentication)
* [Verification](#verification)
* [Port forwarding — local (`-L`)](#port-forwarding--local--l)
* [Port forwarding — remote (`-R`) and dynamic (`-D`)](#port-forwarding--remote--r-and-dynamic--d)
* [Jump host (`-J` / ProxyJump)](#jump-host--j--proxyjump)
* [Documentation](#documentation)
* [Port Knocking](#port-knocking)
* [TODO](#todo)

<!-- vim-markdown-toc -->

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

### Port forwarding — local (`-L`)

Tunnel a port on **your** machine through the SSH server to some destination.

    ssh -L [bind_addr:]local_port:dest_host:dest_port user@gateway

Mental model: "listen on `local_port` here, forward everything through `gateway`
to `dest_host:dest_port`." Crucially, `dest_host` is resolved from the
**gateway's** point of view, not yours.

> So `localhost` means the gateway's _own_ loopback (a service running on the
> server itself), and `10.0.0.5` is whatever the gateway can reach on its
> network. Your machine never needs to route to the destination at all — you're
> borrowing the gateway's network vantage point. That's the whole point of `-L`.

Reach a database that only listens on the server's localhost:

    ssh -L 5432:localhost:5432 user@server.local
    # now `psql -h localhost -p 5432` on your machine hits the server's Postgres

Reach a box the gateway can see but you can't (gateway as a jump host):

    ssh -L 8080:10.0.0.5:80 user@gateway
    # http://localhost:8080 → 10.0.0.5:80 on the gateway's network

By default the local port binds to `127.0.0.1` only. Prefix a bind address to
expose it wider (e.g. `-L 0.0.0.0:8080:...` to let other machines use your
tunnel). Repeat `-L` for multiple tunnels in one connection.

> **Same idea, any server:** `127.0.0.1` (loopback) = reachable only from the
> machine itself; `0.0.0.0` (all interfaces) = reachable from the network via
> your hostname/IP. To keep a dev server private, bind it to loopback:
> `server.listen(3000, "127.0.0.1")` in Node, `--bind 127.0.0.1` for
> `python -m http.server`, `-p 127.0.0.1:8080:80` for Docker. Vite/Next dev bind
> to localhost by default — you opt into exposure with `--host`. Check what a
> port is actually bound to with `ss -tlnp`.

Just the tunnel, no shell:

    ssh -N -L 5432:localhost:5432 user@server.local   # -N: no remote command
    ssh -fN -L 5432:localhost:5432 user@server.local  # -f: also background it

### Port forwarding — remote (`-R`) and dynamic (`-D`)

Reverse direction — open a port **on the server** that forwards back to you.
`-R` is `-L` flipped: instead of a port on your machine, it's a port on the
gateway.

    ssh -R 8080:localhost:3000 user@server.local
    # server's localhost:8080 → your machine's localhost:3000

Why it matters: NAT and firewalls block inbound connections but allow outbound
ones. `-R` rides an outbound SSH connection _backwards_, so the public side gets
a door into a machine it could never dial directly. Two common shapes:

**Share your dev server.** Laptop has no public address (behind NAT), but you
want a colleague or a Stripe/GitHub webhook to hit your local app:

    ssh -R 8080:localhost:3000 user@public-server
    # http://public-server:8080 → your laptop's :3000  (poor man's ngrok)

**Phone home from a box behind NAT** (Raspberry Pi, office machine). It can't
accept inbound SSH, so _it_ dials out to a public relay you control:

    # run ON the pi:
    ssh -R 2222:localhost:22 user@public-relay
    # then from anywhere:
    ssh -p 2222 pi@public-relay        # → lands on the pi at home

> To bind `-R` on the server's public interface (not just its localhost), set
> `GatewayPorts yes` in the server's `sshd_config`. Needed for the
> share-with-others case; not for phoning home to your own account.

> For a persistent tunnel, pair with `autossh` (auto-reconnect on drop) and a
> systemd service so it survives reboots.

Dynamic SOCKS proxy — one tunnel, any destination the server can reach:

    ssh -D 1080 user@server.local
    # point a browser/curl at SOCKS5 127.0.0.1:1080 to route through the server

### Jump host (`-J` / ProxyJump)

A bastion is a gateway that fronts hosts you can't reach directly — internal
servers with no public SSH port, where the bastion is the only box exposed. `-J`
hops through it to the real destination in one command:

    ssh -J user@bastion user@internal.host   # replaces two manual hops
    ssh -J user@bastion1,user@bastion2 user@target   # chain multiple hops

Two things make this better than SSHing to the bastion and onward by hand:

- **End-to-end encrypted.** `-J` uses the bastion only as a TCP relay — it
  negotiates the SSH session directly with `internal.host`, so the bastion never
  sees your session traffic. (Under the hood: `ProxyJump`/`ProxyCommand`.)
- **No keys on the bastion.** Your _local_ key authenticates you to the final
  host, so credentials never pile up on the gateway. The bastion stays a
  lockable, auditable chokepoint.

Persist it in `~/.ssh/config` — then plain `ssh internal` hops automatically:

    Host internal
        HostName internal.host
        ProxyJump user@bastion

> Contrast with `-L`: `-J` lands a whole **shell** on the host behind the
> gateway; `-L` brings a single **port** through it while you stay put.

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
