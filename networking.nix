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
      104.27.206.92 nhentai.net
      104.27.206.92 static.nhentai.net
      104.27.206.92 t1.nhentai.net
      104.27.206.92 t2.nhentat.net
      104.27.206.92 t3.nhentai.net
    '';
}