self: super:
let
  sourceInfo = import ./sources/clawdbot-source.nix;
  clawdbotGateway = super.callPackage ./packages/clawdbot-gateway.nix {
    inherit sourceInfo;
  };
  clawdbotApp = super.callPackage ./packages/clawdbot-app.nix { };
  toolSets = import ./tools/extended.nix { pkgs = super; };
  clawdbotBundle = super.callPackage ./packages/clawdbot-batteries.nix {
    clawdbot-gateway = clawdbotGateway;
    clawdbot-app = clawdbotApp;
    extendedTools = toolSets.base;
  };
in {
  clawdbot-gateway = clawdbotGateway;
  clawdbot-app = clawdbotApp;
  clawdbot = clawdbotBundle;
  clawdbot-tools-base = toolSets.base;
  clawdbot-tools-extended = toolSets.extended;
}
