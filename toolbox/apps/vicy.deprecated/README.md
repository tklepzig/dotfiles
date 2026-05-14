# Run as CLI

## Install necessary dependency (only once)

    npm i

## Run CLI

    ./vicy.sh

# Run in browser

## Transpile to js

    npm run build

## Serve via http

    npm start

## Serve via https (allows to install it as PWA)

Use the makefile of certificates/ to create a valid ssl certificate and rootCA
(which should only be temporarily imported into Chrome since after installing vicy
it is available offline and the rootCA is not necessary anymore)
and run the following (also from certificates/)

    ./serve.sh <certName> ../apps/vicy
