    git clone --no-checkout <repo-url>
    git config filter.encrypt.required true
    git config filter.encrypt.clean "path/to/clean gpg-key-id '%f'"
    git config filter.encrypt.smudge "path/to/smudge gpg-key-id
    git checkout

Add .gitattributes file with correct config, e.g.

    *.md filter=encrypt
