{ pkgs, config, ... }: {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 2234 9943 9944 ];
    allowedUDPPortRanges = [
      { from = 2234; to = 2234; }
      { from = 9943; to = 9944; }
    ];
  };

  networking.extraHosts =
    ''
      192.168.1.150 samus
      104.27.206.92 nhentai.net
      104.27.206.92 static.nhentai.net
      104.27.206.92 t1.nhentai.net
      104.27.206.92 t2.nhentat.net
      104.27.206.92 t3.nhentai.net
    '';
}