{ pkgs, config, ... }: {
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 2234 9943 9944 7777 7778 7779 7780 ];
    allowedUDPPortRanges = [
      { from = 2234; to = 2234; }
      { from = 9943; to = 9944; }
      { from = 7777; to = 7780; }
    ];

    # Reverse-path filtering silently drops broadcast packets. Loosen it so
    # UDP broadcast on 7777-7780 can get through to the accept rules below.
    checkReversePath = "loose";

    extraCommands = ''
      ip46tables -I nixos-fw -p udp -m udp --dport 7777:7780 \
        -m pkttype --pkt-type broadcast -j nixos-fw-accept
    '';
    extraStopCommands = ''
      ip46tables -D nixos-fw -p udp -m udp --dport 7777:7780 \
        -m pkttype --pkt-type broadcast -j nixos-fw-accept || true
    '';
  };

  networking.extraHosts =
    ''
      192.168.1.150 samus
    '';
}