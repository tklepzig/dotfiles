npm cache clean --force
yarn cache clean
find . -name "node_modules" -type d  -exec rm -rf "{}" \;