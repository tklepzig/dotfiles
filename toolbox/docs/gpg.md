TODO: Improve overall docs for gpg multipurpose  
See also
https://www.linuxbabe.com/security/a-practical-guide-to-gpg-part-1-generate-your-keypair

# Create key pair

```
gpg --full-gen-key
```

# Export

## Get key ID

```
gpg --list-secret-keys user@example.com
```

Example output:

```
pub   4096R/ABC12345 2020-01-01 [expires: 2025-12-31]
uid                  Your Name <user@example.com>
sub   4096R/DEF67890 2020-01-01 [expires: 2025-12-31]
```

The ID is the one after the slash of the first line, so `ABC12345`

## Export the public key

```
gpg --armor --export YOUR_ID_HERE > public.key
```

> The flag `--armor` ensures the key is pretty printed.

## Export the private key

```
gpg --armor --export-secret-keys YOUR_ID_HERE > private.key
```

# Import

```
gpg --import private.key
```

# Delete

## Delete public key

```
gpg --delete-key user@example.com
```

## Deletes private key

```
gpg --delete-secret-key user@example.com
```

# Git

## Add public key

Import your public key to your git provider (e.g.
https://github.com/settings/keys)

## Add GPG key

```
git config user.signingkey YOUR_ID_HERE
```

## Always sign Git commits

```
git config commit.gpgsign true
```

# Cache password for private key

The gpg-agent daemon is used for caching. Add the following line to
`~/.gnupg/gpg-agent.conf`

```
default-cache-ttl 43200
```

Now the password is cached for 12 hours.

## Pinentry issues?

- Add `no-tty` to `.gnupg/gpg.conf`
- Run `brew install pinentry-mac`
- Add `pinentry-program /opt/homebrew/bin/pinentry-mac` to
  `.gnupg/gpg-agent.conf`
- Run `gpgconf --kill gpg-agent` after change the conf file
