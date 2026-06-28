{ lib, ... }:

let
  inherit (lib) gvariant;
in
{
  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {
        # Desktop appearance
        "org/gnome/desktop/interface" = {
          clock-show-date = true;
          color-scheme = "prefer-dark";
          enable-animations = true;
          font-antialiasing = "grayscale";
          font-hinting = "slight";
          gtk-theme = "Adwaita-dark";
        };

        # Input
        "org/gnome/desktop/input-sources" = {
          sources = [ (gvariant.mkTuple [ "xkb" "us" ]) ];
          xkb-options = [ "terminate:ctrl_alt_bksp" "caps:ctrl_modifier" ];
        };

        # Peripherals
        "org/gnome/desktop/peripherals/mouse" = {
          speed = -0.120623;
        };

        "org/gnome/desktop/peripherals/touchpad" = {
          two-finger-scrolling-enabled = true;
        };

        "org/gnome/desktop/peripherals/tablets/056a:0377" = {
          keep-aspect = false;
          output = [ "HPN" "OMEN by HP 25" "3CQ83122PM" "DP-1" ];
        };

        # Date/time
        "org/gnome/desktop/datetime" = {
          automatic-timezone = true;
        };

        "org/gnome/desktop/calendar" = {
          show-weekdate = false;
        };

        # Session & privacy
        "org/gnome/desktop/session" = {
          idle-delay = gvariant.mkUint32 300;
        };

        "org/gnome/desktop/privacy" = {
          old-files-age = gvariant.mkUint32 30;
          recent-files-max-age = gvariant.mkInt32 30;
        };

        "org/gnome/desktop/sound" = {
          event-sounds = true;
          theme-name = "__custom";
        };

        # Mutter / window manager
        "org/gnome/mutter" = {
          dynamic-workspaces = true;
          edge-tiling = true;
          experimental-features = [ "variable-refresh-rate" ];
          workspaces-only-on-primary = true;
        };

        # Nautilus
        "org/gnome/nautilus/compression" = {
          default-compression-format = "tar.xz";
        };

        "org/gnome/nautilus/preferences" = {
          default-folder-viewer = "icon-view";
          fts-enabled = false;
          search-filter-time-type = "last_modified";
        };

        # Night light
        "org/gnome/settings-daemon/plugins/color" = {
          night-light-enabled = true;
          night-light-schedule-automatic = false;
          night-light-temperature = gvariant.mkUint32 3700;
        };

        # Power
        "org/gnome/settings-daemon/plugins/power" = {
          power-button-action = "interactive";
          sleep-inactive-ac-timeout = gvariant.mkInt32 3600;
          sleep-inactive-ac-type = "suspend";
        };

        # Weather
        "org/gnome/GWeather4" = {
          temperature-unit = "centigrade";
        };

        "org/gnome/shell/weather" = {
          automatic-location = true;
        };

        # Shell
        "org/gnome/shell" = {
          enabled-extensions = [
            "blur-my-shell@aunetx"
            "appindicatorsupport@rgcjonas.gmail.com"
            "just-perfection-desktop@just-perfection"
            "clipboard-indicator@tudmotu.com"
          ];
          disabled-extensions = [
            "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
            "places-menu@gnome-shell-extensions.gcampax.github.com"
            "light-style@gnome-shell-extensions.gcampax.github.com"
            "apps-menu@gnome-shell-extensions.gcampax.github.com"
            "trayIconsReloaded@selfmade.pl"
            "native-window-placement@gnome-shell-extensions.gcampax.github.com"
          ];
          favorite-apps = [
            "org.mozilla.firefox.desktop"
            "org.gnome.Lollypop.desktop"
            "org.gnome.Nautilus.desktop"
            "org.gnome.Evolution.desktop"
            "obsidian.desktop"
            "org.gnome.Console.desktop"
            "sublime_text.desktop"
            "sublime_merge.desktop"
          ];
        };

        # Screenshot keybinding (PrintScreen -> GNOME screenshot UI)
        "org/gnome/shell/keybindings" = {
          show-screenshot-ui = [ "<Shift><Super>4" ];
        };

        # Extension: AppIndicator
        "org/gnome/shell/extensions/appindicator" = {
          icon-opacity = gvariant.mkInt32 240;
          legacy-tray-enabled = true;
        };

        # Extension: Blur My Shell
        "org/gnome/shell/extensions/blur-my-shell" = {
          settings-version = gvariant.mkInt32 2;
        };

        "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
          brightness = 0.6;
          sigma = gvariant.mkInt32 30;
        };

        "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
          blur = true;
          brightness = 0.6;
          sigma = gvariant.mkInt32 30;
          static-blur = true;
          style-dash-to-dock = gvariant.mkInt32 0;
        };

        "org/gnome/shell/extensions/blur-my-shell/panel" = {
          brightness = 0.6;
          sigma = gvariant.mkInt32 30;
        };

        "org/gnome/shell/extensions/blur-my-shell/window-list" = {
          brightness = 0.6;
          sigma = gvariant.mkInt32 30;
        };

        # Extension: Just Perfection
        "org/gnome/shell/extensions/just-perfection" = {
          accessibility-menu = true;
          dash-icon-size = gvariant.mkInt32 0;
          panel = true;
          panel-in-overview = true;
          ripple-box = true;
          search = true;
          show-apps-button = true;
          startup-status = gvariant.mkInt32 1;
          theme = false;
          window-demands-attention-focus = false;
          window-picker-icon = true;
          workspace = true;
          workspaces-in-app-grid = true;
        };

        # Evolution defaults
        "org/gnome/evolution/calendar" = {
          week-start-day-name = "monday";
        };

        "org/gnome/evolution/mail" = {
          forward-style-name = "attached";
          image-loading-policy = "never";
        };
      };
    }];
  };
}
