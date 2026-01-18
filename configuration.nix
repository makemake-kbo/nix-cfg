# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

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
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  boot.loader.grub.enableCryptodisk=true;

  boot.initrd.luks.devices."luks-b8654007-4232-4f9b-bb97-5ddc37ecac20".keyFile = "/crypto_keyfile.bin";
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
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Disable cups 
  services.printing.enable = false;

  # Enable sound with pipewire.
  # sound.enable = true;
  hardware.pulseaudio.enable = false;
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
      vaapiVdpau
      libvdpau-va-gl
      rocmPackages.clr.icd
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      libva
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # udev group
  users.groups.peripherals = {};

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.makemake = {
    isNormalUser = true;
    description = "makemake";
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
      win-virtio
      win-spice
    ];
  };

 # Do not install useless gnome garbage
  environment.gnome.excludePackages = (with pkgs; [
    gnome-tour
    xterm
  ]) ++ (with pkgs; [
    cheese # webcam tool
    gnome-music
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

  # zram
  zramSwap.enable = false;

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
    ovmf = {
      enable = true;
      packages = [ pkgs.OVMFFull.fd ];
    };
  };
  boot.kernelParams = [ "amd_iommu=on" ];  # or "amd_iommu=on" for AMD
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

  # fileSystems."/mnt/QVO" = {
  #   device = "/dev/disk/by-uuid/c2127c5f-c14c-4f53-9500-4205230268fc";
  #   fsType = "ext4";
  #   options = [ "defaults" "user" "rw" ];
  # };

  # fileSystems."/mnt/pciessd" = {
  #   device = "/dev/disk/by-uuid/e7ac3523-c3d0-4aad-9227-0e3799f4ad18";
  #   fsType = "ext4";
  #   options = [ "defaults" "user" "rw" ];
  # };

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
