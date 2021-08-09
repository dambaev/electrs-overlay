{config, pkgs, options, lib, ...}:
let
  cfg = config.services.electrs;
in
{
  options.services.electrs = {
    enable = lib.mkEnableOption "Rust implementation of Electrum service";
    rpc_listen = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:50001";
      example = "127.0.0.1:50001";
    };
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
          electrs --electrum-rpc-addr="${cfg.rpc_listen}"
        '';
      };
    };    
  };
}
