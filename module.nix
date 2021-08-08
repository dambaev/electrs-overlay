{config, pkgs, options, lib, ...}:
let
  cfg = config.services.electrs;
in
{
  options.services.electrs = {
    enable = lib.mkEnableOption "Rust implementation of Electrum service";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      electrs
    ];
    systemd.services = {
      # define systemd service for electrs
      electrs = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-setup.service" ];
        requires = [ "network-setup.service" ];
        serviceConfig = {
          Type = "simple";
        };
        path = with pkgs; [ electrs ];
        script = ''
          electrs
        '';
      };
    };
    
  };
}
