    git clone --no-checkout <repo-url>
    ./init <gpg-key-id>
    git checkout

Add .gitattributes file with correct config, e.g.

    *.md filter=encrypt
