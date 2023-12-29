# Serve as PWA

## Install necessary dependency (only once)

    npm i

## Create certificates

Use the makefile of certificates/ to create a valid ssl certificate and rootCA
(which should only be temporarily imported into Chrome since after installing
the toolbox it is available offline and the rootCA is not necessary anymore).
See `make help` for guidance.
