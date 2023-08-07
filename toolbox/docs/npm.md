_engine-strict_

If set to true, then npm will stubbornly refuse to install (or even consider installing) any package that claims to not be compatible with the current Node.js version.
This can be overridden by setting the --force flag.

    echo 'engine-strict=true' >> ~/.npmrc
