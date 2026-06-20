Install a new package (always upgrade the whole system in the same step)

    sudo pacman -Syu <package>

> Arch is rolling-release: mirrors only ever hold the _latest_ build of each
> package, and your local db is just a cached snapshot of the last sync.
> Installing against a stale db pulls dependency versions the mirrors no longer
> have (→ 404) or that mismatch your installed libraries (→ breakage).
>
> - `pacman -Syu <pkg>` — the safe default: db + system + new pkg move together
> - `pacman -S <pkg>` — fine **only** right after a full upgrade
> - `pacman -Sy <pkg>` — **never**: refreshes the db but not the system, i.e. a
>   partial upgrade (new pkg linked against old libs). This is what causes the
>   404 / "invalid signature" mess on the next install.

Upgrade the whole system

    sudo pacman -Syu

Remove packages

    sudo pacman -R

Lists all packages that were installed as a dependency and are no longer needed

    sudo pacman -Qdt

Remove all no longer needed packages

    sudo pacman -Qdtq | sudo pacman -Rcs -

List Packages

    sudo pacman -Q

Get Info about specific package

    sudo pacman -Qi <package>

Clear Cache for all non-installed packages

    sudo pacman -Sc

Clear Cache completely

    sudo pacman -Scc

List locally installed packages

    sudo pacman -Qm
