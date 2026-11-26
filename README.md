# Homebrew tap

```sh
brew install amyjainberkeley/apps/switchboard
```

## Switchboard

Switchboard shows the limits of every Claude account you use, and moves Claude
Code to another one with one keystroke. For macOS, with Claude Code. After
`brew install`, type `switchboard setup` to add your accounts.

`brew upgrade switchboard` (or `switchboard update`) updates it, with the
choices you made. `brew uninstall switchboard` removes it and keeps your
accounts and settings in `~/.switchboard`; `brew uninstall --zap switchboard`
removes those too, with your accounts' logins in your Keychain.

The cask runs Switchboard's own installer (`install.sh --homebrew`), so it
installs exactly what the one-line install does. Homebrew runs a cask's
uninstall step before every upgrade too, so the cask's step removes Switchboard
only for `brew uninstall`. The program, its source and its releases are at
[amyjainberkeley/switchboard](https://github.com/amyjainberkeley/switchboard).

To release a version, tag it `v<version>` on GitHub, then:

```sh
./update-switchboard.sh 0.2.0
git commit -am "switchboard 0.2.0"
```

`update-switchboard.sh` sets the cask's version and the tag download's SHA-256,
then runs `brew style`. It refuses a download that is not that version of
Switchboard, with the installer and `packaging/homebrew` in it.
`tests/test-update-switchboard.sh` checks that.
