# https://discourse.nixos.org/t/creating-a-nix-flake-to-package-an-application-and-systemd-service-as-a-nixos-module/18492/2
flake: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) toJSON removeAttrs;
  inherit (lib) filterAttrs types mkEnableOption mkOption mkRenamedOptionModule;
  inherit (lib.trivial) pipe;
  inherit (flake.packages.${pkgs.stdenv.hostPlatform.system}) zapret;
  cfg = config.services.zapret;
  configFile = pkgs.writeTextFile {
    name = "config";
    text = ''
    '';
  };
in {
  options.services.zapret = {
    enable = mkEnableOption ''zapret daemon'';
    zapretconfig = mkOption {
      type = types.str;
      default = "tailscale0";
      description = ''The interface name for tunnel traffic. Use "userspace-networking" (beta) to not use TUN.'';
    };
  };


          # ${zapret.out}/src/init.d/sysv/zapret stop
  # options = {
  #   zapret.enable = mkEnableOption ''zapret daemon'';
  # };

  config = lib.mkIf cfg.enable {
    systemd.services.zapret = {
      description = "zapret daemon";

      # package = zapret.overrideAttrs (old: {
      #   config = cfg.zapretconfig;
      # });

      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "forking";
        Restart = "no";
        KillMode = "none";
        GuessMainPID = "no";
        RemainAfterExit = "no";
        IgnoreSIGPIPE = "no";
        TimeoutSec = "30sec";
        EnvironmentFile = "${configFile}";
        ExecStart = ''
          ${zapret.out}/src/init.d/sysv/zapret start
        '';
        ExecStop = ''
          ${zapret.out}/src/init.d/sysv/zapret stop
        '';
        preStart = ''
          cat ${zapret.out}/src/config
        '';
      };
    };
  };
}
