#!/bin/bash

isProgramInstalled()
{
    command -v $1 >/dev/null 2>&1 || { return 1 >&2; }
    return 0
}

codeBin=$(isProgramInstalled code && echo "code" || echo "code-insiders")

$codeBin --install-extension WallabyJs.quokka-vscode --force
$codeBin --install-extension formulahendry.auto-rename-tag --force
$codeBin --install-extension akamud.vscode-javascript-snippet-pack --force
$codeBin --install-extension christian-kohler.path-intellisense --force
#$codeBin --install-extension donjayamanne.githistory --force
#$codeBin --install-extension huizhou.githd --force
$codeBin --install-extension eamodio.gitlens --force
$codeBin --install-extension kisstkondoros.typelens --force
# $codeBin --install-extension michelemelluso.code-beautifier --force
$codeBin --install-extension minhthai.vscode-todo-parser --force
$codeBin --install-extension mrmlnc.vscode-scss --force
$codeBin --install-extension pflannery.vscode-versionlens --force
$codeBin --install-extension qinjia.seti-icons --force
$codeBin --install-extension maptz.camelcasenavigation --force
$codeBin --install-extension CoenraadS.bracket-pair-colorizer --force

# Testing
#$codeBin --install-extension nwhatt.chai-snippets --force
#$codeBin --install-extension spoonscen.es6-mocha-snippets --force
$codeBin --install-extension Orta.vscode-jest --force
$codeBin --install-extension andys8.jest-snippets --force
$codeBin --install-extension thekarel.open-spec-file --force
$codeBin --install-extension legfrey.javascript-test-runner --force
$codeBin --install-extension rtbenfield.vscode-jest-test-adapter --force

# ES 2015, Babel
# $codeBin --install-extension dzannotti.vscode-babel-coloring --force
$codeBin --install-extension dbaeumer.vscode-eslint --force
# $codeBin --install-extension cmstead.jsrefactor --force
# $codeBin --install-extension jeremyrajan.react-component --force
# $codeBin --install-extension wangtao0101.vscode-js-import --force

# Prettier
$codeBin --install-extension esbenp.prettier-vscode --force

# Flow
# $codeBin --install-extension flowtype.flow-for-vscode --force
# $codeBin --install-extension lsadam0.ReactFlowSnippets --force

# Styled Components
$codeBin --install-extension jpoissonnier.vscode-styled-components --force

# Typescript
#$codeBin --install-extension rbbit.typescript-hero --force # Ein Typescript Import Assistant, der alle Imports einer Datei auf einmal auflösen kann
#$codeBin --install-extension pmneo.tsimporter --force # Ebenfalls ein Typescript Import Assistant, aber der unterstützt die tsconfig.json
$codeBin --install-extension eg2.tslint --force
$codeBin --install-extension christianoetterli.refactorix --force
$codeBin --install-extension infeng.vscode-react-typescript --force

# Angular
#$codeBin --install-extension johnpapa.Angular2 --force
#$codeBin --install-extension Angular.ng-template --force

# C#
#$codeBin --install-extension ms-vscode.csharp --force
#$codeBin --install-extension cake-build.cake-vscode --force

# Docker
$codeBin --install-extension PeterJausovec.vscode-docker --force

# Debugging
$codeBin --install-extension msjsdiag.debugger-for-chrome --force

# npm
$codeBin --install-extension eg2.vscode-npm-script --force
$codeBin --install-extension jasonnutter.search-node-modules --force

# systemd unit files
$codeBin --install-extension coolbear.systemd-unit-file --force

# .vim files
$codeBin --install-extension dunstontc.viml --force

# Open in GitHub
$codeBin --install-extension fabiospampinato.vscode-open-in-github

# Python
$codeBin --install-extension brainfit.vscode-importmagic
$codeBin --install-extension ms-python.python