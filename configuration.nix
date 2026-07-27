# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # mdmonitor PROGRAM handler. mdadm invokes it as: <event> <md-device>
  # [<component-device>]. Everything lands in the journal under tag "mdadm";
  # only the events that mean "your redundancy is gone or going" additionally
  # raise a desktop notification.
  mdadmNotify = pkgs.writeShellScript "mdadm-notify" ''
    event="$1"; array="$2"; dev="''${3:-}"

    if [ -n "$dev" ]; then
      msg="$event on $array ($dev)"
    else
      msg="$event on $array"
    fi

    echo "$msg" | ${pkgs.systemd}/bin/systemd-cat -t mdadm -p warning

    # mdadm --scan derives a by-name path (/dev/md/md0) from the array metadata,
    # but udev never creates /dev/md/ on this box, so it reports that path as
    # DeviceDisappeared once per boot. The real array is /dev/md0 — anything
    # under /dev/md/ here is that phantom. Still journalled above, just not
    # escalated to the desktop, so genuine popups stay worth reading.
    case "$array" in
      /dev/md/*) exit 0 ;;
    esac

    case "$event" in
      Fail|FailSpare|DegradedArray|DeviceDisappeared|SparesMissing|TestMessage)
        ${pkgs.dbus}/bin/dbus-send --system \
          / net.nuetzlich.SystemNotifications.Notify \
          "string:RAID problem on $array" \
          "string:$msg — run 'cat /proc/mdstat'"
        ;;
    esac
  '';
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # ledger
      ./ledger-udev-rules.nix
      # networking rules
      ./networking.nix
      # font config
      ./fonts.nix
      # patching non nix software
      ./nix_ld.nix
      # dconf / GNOME settings
      ./dconf.nix
      # Sublime Text user settings
      ./sublime.nix
      # niri WM (self-contained; delete this line + ./niri to remove)
      # ./niri
    ];

  # Bootloader.
  # Both NVMe drives are md0 members (MBR, legacy BIOS) carrying identical
  # copies of /boot inside the LUKS root. GRUB goes into both MBRs so either
  # disk can boot the machine on its own.
  # by-id paths only: kernel nvme enumeration is unstable — it has swapped these
  # between nvme0n1/nvme1n1, and pointing grub at the bare /dev/nvme0n1 made
  # grub-install land on the GPT Intel Optane scratch disk (no BIOS Boot
  # Partition -> "embedding is not possible" failure). by-id is enumeration-proof.
  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [
    "/dev/disk/by-id/nvme-WD_BLACK_SN7100_2TB_25516P801106"
    "/dev/disk/by-id/nvme-WD_BLACK_SN770_2TB_232165800652"
  ];
  # Nothing to probe: NixOS is the only install on this box. Flip to true if a
  # second OS ever lands, otherwise it just mounts every visible partition on
  # each rebuild and finds nothing.
  boot.loader.grub.useOSProber = false;

  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    ARRAY /dev/md0 metadata=1.2 UUID=c54679b3:7e790cba:d9811404:12a22794
    MAILADDR root
    PROGRAM ${mdadmNotify}
  '';

  # mdadm delivers MAILADDR via sendmail, and there is no MTA on this machine,
  # so mail alone is a silent black hole. PROGRAM is the escape hatch: it fires
  # for every mdmonitor event, logs to the journal, and pushes the serious ones
  # to the desktop over the same system-bus channel smartd uses.

  # SMART monitoring for both mirror members. mdmonitor already shouts when the
  # array drops a disk; smartd is what warns *before* that happens.
  services.smartd = {
    enable = true;
    notifications.wall.enable = true;
    notifications.systembus-notify.enable = true;
    devices = [
      { device = "/dev/disk/by-id/nvme-WD_BLACK_SN7100_2TB_25516P801106"; }
      { device = "/dev/disk/by-id/nvme-WD_BLACK_SN770_2TB_232165800652"; }
    ];
  };

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  boot.loader.grub.enableCryptodisk=true;

  boot.initrd.luks.devices."luks-ae26ff11-642a-4fd1-ae52-50c9b954baee".keyFile =
    "/crypto_keyfile.bin";

  # Without this, dm-crypt swallows discards and fstrim.timer only ever trims
  # /mnt/QVO — the NVMe mirror never sees a TRIM at all. md RAID1 passes
  # discards through to both members, so this is the only missing link.
  # Trade-off: an attacker with a disk image can see which blocks are in use
  # (roughly how full the disk is and where data sits), though not their
  # contents. Accepted here: the drives are internal and don't travel.
  boot.initrd.luks.devices."luks-ae26ff11-642a-4fd1-ae52-50c9b954baee".allowDiscards = true;

  # RAID1 can detect a mismatch between mirror halves but has no way to know
  # which half is right, so the value of a scrub is catching divergence while
  # both disks are still healthy. mdadm ships the timer (first Sunday of the
  # month, 01:00); NixOS links the unit but leaves it disabled.
  systemd.timers.mdcheck_start.wantedBy = [ "timers.target" ];
  systemd.timers.mdcheck_continue.wantedBy = [ "timers.target" ];

  # No swap at all meant memory pressure went straight to the OOM killer. zram
  # is a compressed in-RAM cushion: idle at normal usage, and far cheaper than
  # losing a process. ~8G of 46G.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 17;
  };
  networking.hostName = "melchior"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Belgrade";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Lofree Flow84 connects over Bluetooth as an Apple device (05ac:2041),
  # so its top row sends F1-F12 instead of the printed media keys. keyd
  # remaps the function row to the media actions GNOME expects. Hold the
  # right Alt key to access the real F1-F12 (the "fnkeys" layer).
  services.keyd = {
    enable = true;
    keyboards.lofree = {
      ids = [ "05ac:2041" ];
      settings = {
        main = {
          f1 = "brightnessdown";
          f2 = "brightnessup";
          f7 = "previoussong";
          f8 = "playpause";
          f9 = "nextsong";
          f10 = "mute";
          f11 = "volumedown";
          f12 = "volumeup";
          rightalt = "layer(fnkeys)";
        };
        fnkeys = {
          f1 = "f1";
          f2 = "f2";
          f7 = "f7";
          f8 = "f8";
          f9 = "f9";
          f10 = "f10";
          f11 = "f11";
          f12 = "f12";
        };
      };
    };
  };

  # Disable cups
  services.printing.enable = false;

  # Bluetooth. powerOnBoot ensures the controller comes up powered.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # The BCM20702A1 dongle (ASUS USB-BT400) ships a buggy ROM and needs the
  # brcm/BCM20702A1-0b05-17cb.hcd patch at probe time; without it the link
  # corrupts ACL packets and BLE HID devices (mouse/keyboard) can't stay up.
  hardware.firmware = [ pkgs.broadcom-bt-firmware ];

  # systemd-rfkill persists rfkill soft-block state to /var/lib/systemd/rfkill
  # and restores it on every boot. A single stray Bluetooth/airplane toggle
  # therefore kept the radio dead across reboots. Clear any persisted block at
  # boot so the controller is always available.
  systemd.services.rfkill-unblock-bt = {
    description = "Clear persisted Bluetooth rfkill soft-block at boot";
    wantedBy = [ "multi-user.target" ];
    before = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
    };
  };

  # Enable sound with pipewire.
  # sound.enable = true;
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  services.gnome.at-spi2-core.enable = true;

  # AMD GPU - VAAPI for hardware video acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva
      libva-utils
      libva-vdpau-driver
      libvdpau-va-gl
      rocmPackages.clr.icd
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      libva
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # RX 6800 XT power management.
  #
  # The stock ppfeaturemask (0xfff7bfff) leaves the OverDrive bit (1<<14) clear,
  # so pp_od_clk_voltage reads back empty and no undervolt is possible at all.
  # Enabling it is the prerequisite for any voltage offset.
  #
  # The mask is set explicitly rather than taking the module default. Bits are
  # from enum PP_FEATURE_MASK in drivers/gpu/drm/amd/include/amd_shared.h:
  #
  #   0xfff7bfff  kernel default   — clears OVERDRIVE (0x4000), GFX_DCS (0x80000)
  #   0xfffd7fff  module default   — clears GFXOFF (0x8000), STUTTER_MODE (0x20000)
  #   0xfff7ffff  used here        — kernel default, plus OVERDRIVE, nothing else
  #
  # The module default is wrong for this machine: it disables GFXOFF and stutter
  # mode, which are exactly the two idle power-saving features that matter here.
  # GFXOFF is what lets the graphics engine power-gate to 0MHz at idle (23% of
  # idle residency, measured). Turning it off to chase OverDrive would raise idle
  # draw to buy an undervolt. Setting only the OverDrive bit keeps both.
  hardware.amdgpu.overdrive.enable = true;
  hardware.amdgpu.overdrive.ppfeaturemask = "0xfff7ffff";
  #
  # LACT applies the offset at boot via lactd. Left unconfigured on purpose:
  # populating services.lact.settings makes /etc/lact/config.yaml a read-only
  # symlink into the store, which locks the GUI out of editing it. Tune in the
  # GUI first, then paste the resulting /etc/lact/config.yaml into settings here
  # to make it declarative.
  services.lact.enable = true;

  # Override DP EDID for Samsung Odyssey G85SD — DP-side EDID hides 175Hz +
  # FreeSync modes behind a DisplayID 2.0 block the kernel mis-parses. The
  # binary here is the HDMI-side EDID dumped from macOS, which encodes the
  # same modes in CTA-861 blocks the kernel handles correctly.
  hardware.display = {
    edid.packages = [
      (pkgs.runCommand "samsung-g85sd-edid" {} ''
        mkdir -p $out/lib/firmware/edid
        cp ${./samsung-g85sd.bin} $out/lib/firmware/edid/samsung-g85sd.bin
      '')
    ];
    outputs."DP-3".edid = "samsung-g85sd.bin";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # udev group
  users.groups.peripherals = {};

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.makemake = {
    isNormalUser = true;
    description = "makemake";
    # No lingering: the per-user systemd manager is torn down on logout so a
    # full logout/login picks up rebuild changes to user units (e.g. PipeWire).
    # With lingering on, the old manager survives logout holding stale units.
    linger = false;
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "peripherals" "docker"];
    packages = with pkgs; [
      # should be a flatpak innit
      # firefox
      evolution
      evince
      gnome-tweaks
      sublime-merge
      sublime4
      framesh
      vlc
      ffmpeg
      yt-dlp
      gnupg
      smartmontools
      systemd
      whois
      file
      virt-viewer
      spice 
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
      mdadm
      (wineWow64Packages.stable.override { waylandSupport = true; })

      # Migrated off Flatpak -> native nixpkgs. (Firefox, Bitwig, Mumble and
      # Ungoogled Chromium intentionally stay Flatpak; PollyMC and yuzu stay
      # Flatpak because they aren't packaged / were removed from nixpkgs.)
      obsidian
      telegram-desktop
      krita
      nicotine-plus
      fractal
      polari
      gnome-music
      eyedropper
      kdePackages.kleopatra
    ];
  };

 # Do not install useless gnome garbage
  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    xterm
  ]) ++ (with pkgs; [
    cheese # webcam tool
    epiphany # web browser
    gnome-characters
  ]);

  # enable running appimages
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Add steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  # hyprland
  # programs.hyprland.enable = true;

  # zram is configured up by the storage settings, next to the LUKS/RAID block.

  # System profiling
  services.sysprof.enable = true;

  # This is only for sublime4 i hate it here
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1w"
  ];

  # Desktop icons n sheeit
  environment.sessionVariables = rec {
    XDG_CACHE_HOME  = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME   = "$HOME/.local/share";
    XDG_STATE_HOME  = "$HOME/.local/state";

    # Dark mode everywhere
    # GTK_THEME=Adwaita:dark;

    # Not officially in the specification
    XDG_BIN_HOME    = "$HOME/.local/bin";
    PATH = [ 
      "${XDG_BIN_HOME}"
    ];
  }; 

 # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     git
     curl
     htop
  ];

  # Flatpak
  services.flatpak.enable = true;

  # Virtualization
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "br0" ];
  boot.extraModprobeConfig = "options kvm_amd nested=1";

  virtualisation.libvirtd.qemu = {
    package = pkgs.qemu_kvm;
    runAsRoot = true;
    swtpm.enable = true;
  };
  # The BT dongle (0b05:17cb) wedges on resume from suspend ("invalid context
  # state" + xhci reset); the RESET_RESUME quirk (:b) power-cycles it cleanly
  # on every resume instead of trying to restore its corrupted USB state.
  boot.kernelParams = [ "amd_iommu=on" "amdgpu.freesync_video=1" "usbcore.quirks=0b05:17cb:b" ];
  boot.kernelModules = [ "kvm-amd" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];

  programs.virt-manager.enable = true;

  # Docker masturbation
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  virtualisation.docker.daemon.settings = {
    data-root = "/home/makemake/docker";
  };

  virtualisation = {
    podman = {
      enable = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  fileSystems."/mnt/QVO" = {
    device = "/dev/disk/by-uuid/c2127c5f-c14c-4f53-9500-4205230268fc";
    fsType = "ext4";
    options = [ "defaults" "nofail" "x-systemd.device-timeout=5s" ];
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Flakes
  nix = {
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
