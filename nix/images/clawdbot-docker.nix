{ pkgs }:
let
  entrypoint = pkgs.stdenvNoCC.mkDerivation {
    pname = "clawdbot-docker-entrypoint";
    version = "1";
    src = ../docker/entrypoint.sh;
    dontUnpack = true;
    installPhase = "${../scripts/docker-entrypoint-install.sh}";
  };
  toolsBase = pkgs.clawdbot-tools;
  baseContents = [
    pkgs.bash
    pkgs.coreutils
    pkgs.cacert
    pkgs.python3
    entrypoint
    toolsBase
  ];
  gatewayContents = [ pkgs.clawdbot-gateway ];
  config = {
    Entrypoint = [ "/bin/clawdbot-entrypoint" ];
    WorkingDir = "/data";
    Volumes = { "/data" = {}; };
    ExposedPorts = { "18789/tcp" = {}; };
    Env = [
      "CLAWDBOT_DATA_DIR=/data"
      "CLAWDBOT_GATEWAY_PORT=18789"
      "CLAWDBOT_TELEGRAM_REQUIRE_MENTION=true"
      "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt"
    ];
  };
  image = pkgs.dockerTools.buildLayeredImage {
    name = "clawdbot";
    tag = "latest";
    contents = baseContents ++ gatewayContents;
    inherit config;
  };
  stream = pkgs.dockerTools.streamLayeredImage {
    name = "clawdbot";
    tag = "latest";
    contents = baseContents ++ gatewayContents;
    inherit config;
  };
in {
  inherit image stream;
}
