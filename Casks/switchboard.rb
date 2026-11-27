cask "switchboard" do
  # update-switchboard.sh sets version and sha256 from the release's own download on GitHub.
  version "0.3.0"
  sha256 "6bb6c199c87732a035fe5d455d1e537b33fe09b5274b2fc09fc39f33af4270e9"

  url "https://github.com/amyjainberkeley/switchboard/releases/download/v#{version}/switchboard-#{version}.tar.gz"
  name "Switchboard"
  desc "Shows the limits of every Claude account and switches Claude Code between them"
  homepage "https://github.com/amyjainberkeley/switchboard"

  # The installer itself, as the one-line install runs it: Switchboard lives in
  # ~/.switchboard, and Homebrew links its command.
  installer script: {
    executable: "switchboard-#{version}/install.sh",
    args:       ["--homebrew"],
  }
  binary "switchboard-#{version}/packaging/homebrew/launcher", target: "switchboard"

  # Removes Switchboard only for `brew uninstall` (and everything for --zap);
  # before an upgrade or a reinstall it leaves Switchboard as it is.
  uninstall script: {
    executable: "switchboard-#{version}/packaging/homebrew/uninstall.sh",
  }

  # The notes of chats carried on in another assistant are kept beside ~/.switchboard, never in it.
  zap trash: [
    "~/.switchboard",
    "~/.switchboard-notes",
  ]

  caveats <<~EOS
    Type `switchboard setup` to add your accounts, then `switchboard` to see them.

    `brew uninstall switchboard` removes the program and keeps your accounts
    and settings in ~/.switchboard. `brew uninstall --zap switchboard` removes
    those too, and takes your accounts' logins out of your Keychain.
  EOS
end
