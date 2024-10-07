Usage:

    ./clone <repo-url> <gpg-key-id>

Ensure the necessary filetypes are correctly configured in `.gitattributes`:

    # encrypt markdown files
    *.md filter=encrypt
