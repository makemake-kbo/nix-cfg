{ pkgs, ... }:

# Declaratively manage the stable Sublime Text user config files by
# symlinking them out of the Nix store into ~/.config/sublime-text.
#
# Preferences.sublime-settings is deliberately NOT managed here: Sublime
# rewrites it at runtime (added dictionary words, font size, disabled
# packages), and a read-only store symlink would make those UI actions
# silently fail. Leave that one mutable.
#
# The "L+" tmpfiles type force-replaces any existing file/symlink at the
# target on each activation, so editing a file below + nixos-rebuild wins.

let
  userDir = "%h/.config/sublime-text/Packages/User";

  keymap = pkgs.writeText "Default (Linux).sublime-keymap" ''
    [
    	{ "keys": ["ctrl+s"], "command": "save_all", "args": { "async": true } },
    ]
  '';

  lspClangd = pkgs.writeText "LSP-clangd.sublime-settings" ''
    {
    	"binary": "auto",
    	"enabled": false,
    }
  '';

  lspCopilot = pkgs.writeText "LSP-copilot.sublime-settings" ''
    // Settings in here override those in "LSP-copilot/LSP-copilot.sublime-settings"

    {
    	"settings": {
    		"auto_ask_completions": true,
    	},
    }
  '';

  lspRustAnalyzer = pkgs.writeText "LSP-rust-analyzer.sublime-settings" ''
    // Settings in here override those in "LSP-rust-analyzer/LSP-rust-analyzer.sublime-settings"
    {
    	"rust-analyzer.cargo.features": [],
    }
  '';

  link = name: src: "L+ ${userDir}/${name} - - - - ${src}";
in
{
  systemd.user.tmpfiles.rules = [
    "d ${userDir} 0755 - - - -"
    (link "Default (Linux).sublime-keymap" keymap)
    (link "LSP-clangd.sublime-settings" lspClangd)
    (link "LSP-copilot.sublime-settings" lspCopilot)
    (link "LSP-rust-analyzer.sublime-settings" lspRustAnalyzer)
  ];
}
