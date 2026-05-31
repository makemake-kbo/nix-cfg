{ config, pkgs, lib, ... }:

{
  # Enable fonts to use on your system.  You should make sure to add at least
  # one English font (like dejavu_fonts), as well as Japanese fonts like
  # "ipafont" and "kochi-substitute".

  fonts = {
    enableDefaultPackages = false;
    fontDir.enable = true;

    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      twemoji-color-font
      font-awesome
      hanazono
      carlito
      ipafont
      kochi-substitute
      source-code-pro
      vista-fonts
      ttf_bitstream_vera
      # Use bin to save build time (~11min).
      iosevka-bin

      # Roman for PDF.
      liberation_ttf
    ];

    fontconfig = {
      enable = true;

      defaultFonts = {
        monospace = [ "Source Code Pro" "Noto Sans CJK SC" "Font Awesome 6 Free" "Twemoji" ];
        sansSerif = [ "Cantarell" "Noto Sans CJK SC" "Twemoji" ];
        serif = [ "Noto Serif" "Noto Serif CJK SC" "Twemoji" ];
        emoji = [ "Twemoji" ];
      };

      localConf = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Use language-specific font variants. -->
          ${lib.concatMapStringsSep "\n" ({ lang, variant }:
            let
              replace = from: to: ''
                <match target="pattern">
                  <test name="lang" compare="contains">
                    <string>${lang}</string>
                  </test>
                  <test name="family">
                    <string>${from}</string>
                  </test>
                  <edit name="family" binding="strong" mode="prepend_first">
                    <string>${to}</string>
                  </edit>
                </match>
              '';
            in
            replace "sans-serif" "Noto Sans CJK ${variant}" +
            replace "serif" "Noto Serif CJK ${variant}"
          ) [
            { lang = "zh";    variant = "SC"; }
            { lang = "zh-TW"; variant = "TC"; }
            { lang = "zh-HK"; variant = "HK"; }
            { lang = "ja";    variant = "JP"; }
            { lang = "ko";    variant = "KR";  }
          ]}
        </fontconfig>
      '';
    };
  };

  # Flatpak font fix
  system.fsPackages = [ pkgs.bindfs ];
  fileSystems = let
    mkRoSymBind = path: {
      device = path;
      fsType = "fuse.bindfs";
      options = [ "ro" "resolve-symlinks" "x-gvfs-hide" ];
    };
    aggregatedFonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = config.fonts.packages;
      pathsToLink = [ "/share/fonts" ];
      # 26.05 pulls X11 bitmap fonts (font-misc-misc, font-cursor-misc) into
      # fonts.packages; they ship colliding share/fonts/X11/misc/fonts.dir
      # files, which buildEnv now errors on. Ignore the collision (legacy
      # index files, irrelevant to the Flatpak font mount).
      ignoreCollisions = true;
    };
  in {
    # Create an FHS mount to support flatpak host icons/fonts
    "/usr/share/icons" = mkRoSymBind (config.system.path + "/share/icons");
    "/usr/share/fonts" = mkRoSymBind (aggregatedFonts + "/share/fonts");
  };
}