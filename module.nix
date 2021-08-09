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
    db_dir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/electrs";
      example = "/var/lib/electrs";
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
          mkdir -p "${cfg.db_dir}" # ensure DB dir exists
          electrs \
            -vv \
            --electrum-rpc-addr="${cfg.rpc_listen}" \
            --db-dir "${cfg.db_dir}"
        '';
      };
    };    
  };
}
