{ pkgs, config, ... }: {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 2234 ];
    allowedUDPPortRanges = [
      { from = 2234; to = 2234; }
    ];
  };

  networking.extraHosts =
    ''
      192.168.0.150 samus
    '';
}