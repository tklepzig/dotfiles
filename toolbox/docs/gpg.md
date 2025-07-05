# GPG

TODO: Improve overall docs for gpg multipurpose  
See

- https://www.linuxbabe.com/security/a-practical-guide-to-gpg-part-1-generate-your-keypair
- https://tutonics.com/articles/gpg-encryption-guide-part-1/
- https://medium.com/code-oil/comprehensive-yet-simple-guide-for-gpg-key-subkey-encryption-signing-verification-other-common-c28fd868cbe7
- https://gock.net/blog/2020/gpg-cheat-sheet
- https://incenp.org/notes/2015/using-an-offline-gnupg-master-key.html
- https://alexcabal.com/creating-the-perfect-gpg-keypair

TODO

- Sensible order
- howto trust
- renew expiration for subkeys (--edit-key, select via "key n", "expire",
  "save")
- howto set key flags (S, E, A, C, etc.) to primary key and subkeys --
- --faked-system-time

## Create key pair

    gpg --full-gen-key

## List public keys

    gpg --list-keys --with-subkey-fingerprints --keyid-format=short

> --list-keys can be replaced with -k.

## List secret keys

    gpg --list-secret-keys --with-subkey-fingerprints --keyid-format=short

> --list-secret-keys can be replaced with -K.

## Export

### Get key ID

    gpg --list-secret-keys user@example.com

Example output:

    pub   4096R/ABC12345 2020-01-01 [expires: 2025-12-31]
    uid                  Your Name <user@example.com>
    sub   4096R/DEF67890 2020-01-01 [expires: 2025-12-31]

The ID is the one after the slash of the first line, so `ABC12345`

### Export the public key

    gpg --armor --export YOUR_ID_HERE > public.key

> The flag `--armor` ensures the key is pretty printed.

### Export the private key

    gpg --armor --export-secret-keys YOUR_ID_HERE > private.key

## Import

    gpg --import private.key

## Add Subkey

    gpg --edit-key YOUR_ID_HERE
    gpg> addkey
    gpg> save

## Revoke Subkey

Using the gpg cli, you have to select one or more keys by entering
`key <number>`:

    gpg --edit-key YOUR_ID_HERE
    gpg> key 1
    gpg> revkey
    gpg> save

## Remove master key

You can remove the master key and keep only the subkeys. This is useful if you
want to keep the master key on a read-only device and use subkeys for daily
usage.

Make sure to export your master key before removing it

    gpg --export-secret-keys YOUR_ID_HERE > master.key
    gpg --export YOUR_ID_HERE > master.pub

Store the exported keys and the revocation certificate in a secure place (not on
your computer). You may also print a hardcopy with a tool like Paperkey

    gpg --export-secret-keys YOUR_ID_HERE | paperkey | lpr

Now remove it by using its keygrip

    gpg --list-secret-keys --with-keygrip
    gpg-connect-agent "DELETE_KEY YOUR_KEYGRIP_HERE" /bye

If you need it for any operation, you can always import it again:

    gpg --import master.pub master.key

Instead of importing it in your default keyring, you can also use temporary
GnuPG home directory

    mkdir ~/gpgtmp
    chmod 0700 ~/gpgtmp
    gpg --homedir ~/gpgtmp --import /path/of/secure/master/place/like/an/usb/stick/master.key
    # If you have a gpg.conf which you need for the operation below, make sure to symlink it to the temporary GnuPG home directory first
    # Doing some operations which need the master key (Using the temporary directory as GnuPG home,
    # but add the public keyring from your default GnuPG home directory)
    gpg --homedir ~/gpgtmp --keyring ~/.gnupg/pubring.kbx --edit-key YOUR_ID_HERE
    gpg> ...
    gpg> save
    # When done, remove the temporary keyring
    gpg-connect-agent --homedir ~/gpgtmp KILLAGENT /bye
    rm -rf ~/gpgtmp

> See also https://incenp.org/notes/2015/using-an-offline-gnupg-master-key.html

## Delete

### Revoke the key

    gpg --import /path/to/revocation_certificate.rev

> The revocation certificate was created when you generated the key.

### Revoke the key on the keyserver

    gpg --keyserver SERVER --send-key YOUR_ID_HERE

> Popular keyservers are `pgp.mit.edu`, `keys.openpgp.org` and
> `keyserver.ubuntu.com`.

### Delete public key

    gpg --delete-key user@example.com

### Deletes private key

    gpg --delete-secret-key user@example.com

### Delete the revocation certificate

    rm /path/to/revocation_certificate.rev

## Sign commits in Git

### Add public key

Import your public key to your git provider (e.g.
https://github.com/settings/keys)

### Add GPG key

    git config user.signingkey YOUR_ID_HERE

### Always sign Git commits

    git config commit.gpgsign true

## Sign via SSH key

    ssh-keygen -t ed25519 -C 'my signing key'

    cat ~/.ssh/id_ed25519.pub
    # add to your git server as a signing key...

    git config --global gpg.format ssh
    git config --global user.signingkey ~/.ssh/id_ed25519.pub

## Cache password for private key

The gpg-agent daemon is used for caching. Add the following line to
`~/.gnupg/gpg-agent.conf`

    default-cache-ttl 43200

Now the password is cached for 12 hours.

### Pinentry issues?

- Add `no-tty` to `.gnupg/gpg.conf`
- Run `brew install pinentry-mac`
- Add `pinentry-program /opt/homebrew/bin/pinentry-mac` to
  `.gnupg/gpg-agent.conf`
- Run `gpgconf --kill gpg-agent` after change the conf file
