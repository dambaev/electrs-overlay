{config, pkgs, options, lib, ...}:
let
  eachElectrs = config.services.electrs;
  electrsOpts = {config, lib, name, ...}: {
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
    cookie_file = lib.mkOption {
      type = lib.types.str;
      default = null;
      example = "/path/to/.cookie";
    };
    blocks_dir = lib.mkOption {
      type = lib.types.str;
      default = null;
      example = "/path/to/blocks/dir";
    };
    network = lib.mkOption {
      type = lib.types.str;
      default = "bitcoin";
      example = "testnet";
      description = ''
        This option defines Bitcoin network type to work with.
        one of 'bitcoin', 'testnet', 'regtest' or 'signet'
      '';
    };
  };
  electrs_instance = electrsName: cfg: {
    environment.systemPackages = with pkgs; [
      electrs
    ];
    systemd.services = {
      # define systemd service for electrs
      nameValuePair "electrs-${electrsName}" {
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
            --db-dir "${cfg.db_dir}" \
            --cookie-file ${cfg.cookie_file} \
            --blocks-dir ${cfg.blocks_dir} \
            --network ${cfg.network}
        '';
      };
    };    
  };
in
{
  options.services.electrs = mkOption {
    type = lib.types.attrsOf (lib.types.submodule electrsOpts);
    default = {};
    description = "One or more electrs instances";
  };
  config = mkIf (eachElectrs != {}) (mapAttrs' electrs_instance eachElectrs);
}
