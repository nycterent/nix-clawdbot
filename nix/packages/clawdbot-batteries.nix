{ lib
, buildEnv
, clawdbot-gateway
, clawdbot-app
, extendedTools
}:

buildEnv {
  name = "clawdbot-2.0.0-beta4";
  paths = [ clawdbot-gateway clawdbot-app ] ++ extendedTools;
  pathsToLink = [ "/bin" "/Applications" ];

  meta = with lib; {
    description = "Clawdbot batteries-included bundle (gateway + app + tools)";
    homepage = "https://github.com/clawdbot/clawdbot";
    license = licenses.mit;
    platforms = platforms.darwin;
  };
}
