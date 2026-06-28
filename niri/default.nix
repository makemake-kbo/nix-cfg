# niri — scrollable-tiling Wayland compositor, set up to feel close to GNOME.
#
# Self-contained: this whole directory + the single `./niri` import line in
# configuration.nix is everything. To remove niri entirely, delete that import
# line and `rm -rf niri/`, then `nixos-rebuild switch`. GNOME is untouched.
#
# Config files live in /etc (pure Nix, no dotfiles in $HOME). niri reads
# ~/.config/niri/config.kdl first, then /etc/niri/config.kdl, so these act as
# system defaults you can still override per-user later if you want.

{ pkgs, ... }:

let
  # Rotates wallpapers from ~/Pictures/wallpaper using swww (smooth fade
  # transitions, no flicker). Picks a random image every 15 minutes. Installed
  # on PATH so config.kdl can spawn it by name.
  niri-wallpaper = pkgs.writeShellScriptBin "niri-wallpaper" ''
    set -eu
    dir="$HOME/Pictures/wallpaper"
    ${pkgs.swww}/bin/awww-daemon &
    sleep 1
    while :; do
      img=$(${pkgs.findutils}/bin/find "$dir" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        2>/dev/null | ${pkgs.coreutils}/bin/shuf -n1 || true)
      if [ -n "''${img:-}" ]; then
        ${pkgs.swww}/bin/awww img "$img" \
          --transition-type fade --transition-duration 2
      fi
      sleep 900
    done
  '';
in
{
  # Installs niri, registers the "Niri" session for GDM (selectable via the
  # login gear menu — GNOME stays the default), and wires the xdg portal.
  programs.niri.enable = true;

  # polkit_gnome ships its agent under $out/libexec; make sure that dir is
  # linked into /run/current-system/sw so config.kdl can spawn it by path.
  environment.pathsToLink = [ "/libexec" ];

  environment.systemPackages = with pkgs; [
    waybar                  # top bar (replaces GNOME panel)
    fuzzel                  # app launcher
    swaynotificationcenter  # notifications + center (replaces GNOME notifications)
    swww                    # wallpaper daemon (rotation, transitions)
    niri-wallpaper          # wallpaper rotation script (defined above)
    gammastep               # night light (replaces GNOME night light)
    cliphist                # clipboard history (replaces clipboard-indicator ext)
    wl-clipboard            # wl-copy / wl-paste
    swaylock                # screen locker
    swayidle                # idle -> lock / suspend
    xwayland-satellite      # run X11 apps under niri
    brightnessctl           # brightness keys
    playerctl               # media play/pause/next keys
    libnotify               # notify-send
    pavucontrol             # audio control (waybar audio click target)
    networkmanagerapplet    # nm-connection-editor (waybar network click target)
    polkit_gnome            # graphical polkit auth agent
  ];

  # config.kdl spawns these via PATH (waybar, fuzzel, swaync, …) — all on PATH
  # through systemPackages above. The portal/theme/fonts/keyd from the rest of
  # the system config carry over unchanged.

  environment.etc = {
    "niri/config.kdl".source = ./config.kdl;

    "xdg/waybar/config.jsonc".source = ./waybar/config.jsonc;
    "xdg/waybar/style.css".source = ./waybar/style.css;

    "xdg/fuzzel/fuzzel.ini".source = ./fuzzel.ini;

    "xdg/swaync/config.json".source = ./swaync/config.json;
    "xdg/swaync/style.css".source = ./swaync/style.css;
  };
}
