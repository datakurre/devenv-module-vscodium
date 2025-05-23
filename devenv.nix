{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.package.vscodium;
  unstable = import inputs.unstable {
    system = pkgs.system;
    config = {
      allowUnfree = true;
    };
  };
  vscode-marketplace =
    (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion unstable.vscodium.version)
    .vscode-marketplace;
  vscode-marketplace-release =
    (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion unstable.vscodium.version)
    .vscode-marketplace-release;
  inherit (lib)
    types
    mkOption
    mkIf
    optionals
    ;
in
{
  options.package.vscodium = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    java = mkOption {
      type = types.bool;
      default = false;
    };
    bpmn = mkOption {
      type = types.bool;
      default = false;
    };
    python = mkOption {
      type = types.bool;
      default = false;
    };
    robot = mkOption {
      type = types.bool;
      default = false;
    };
    unfree = mkOption {
      type = types.bool;
      default = false;
    };
    vim = mkOption {
      type = types.bool;
      default = false;
    };
    copilot = mkOption {
      type = types.bool;
      default = false;
    };
    continue = mkOption {
      type = types.bool;
      default = false;
    };
  };
  config.packages = mkIf cfg.enable [
    (unstable.vscode-with-extensions.override {
      vscode = if cfg.unfree then unstable.vscode else unstable.vscodium;
      vscodeExtensions =
        [
          unstable.vscode-extensions.ms-vscode.makefile-tools
          vscode-marketplace.bbenoist.nix
          vscode-marketplace.tamasfe.even-better-toml
        ]
        ++ optionals cfg.unfree [
          (vscode-marketplace.ms-vscode-remote.remote-ssh.override { meta.licenses = [ ]; })
          (unstable.vscode-extensions.ms-python.vscode-pylance) # .override { meta.licenses = [ ]; })
        ]
        ++ optionals (!cfg.unfree) [
          vscode-marketplace.ms-pyright.pyright # cannot be used with pylance
        ]
        ++ optionals (cfg.java) [
          vscode-marketplace.redhat.java
          vscode-marketplace.vscjava.vscode-java-debug
          vscode-marketplace.vscjava.vscode-java-test
          vscode-marketplace.vscjava.vscode-maven
          vscode-marketplace.vscjava.vscode-java-dependency
          vscode-marketplace.visualstudioexptteam.vscodeintellicode
        ]
        ++ optionals cfg.python or cfg.robot [
          pkgs.vscode-extensions.ms-python.python
          pkgs.vscode-extensions.ms-python.debugpy
          (vscode-marketplace.charliermarsh.ruff.overrideAttrs (old: {
            postInstall = ''
              rm -f $out/share/vscode/extensions/charliermarsh.ruff/bundled/libs/bin/ruff
              ln -s ${pkgs.ruff}/bin/ruff $out/share/vscode/extensions/charliermarsh.ruff/bundled/libs/bin/ruff
            '';
          }))
        ]
        ++ optionals cfg.robot [
          vscode-marketplace.d-biehl.robotcode
        ]
        ++ optionals cfg.bpmn [
          vscode-marketplace.miragon-gmbh.vs-code-bpmn-modeler
        ]
        ++ optionals cfg.vim [
          vscode-marketplace.vscodevim.vim
        ]
        ++ optionals cfg.copilot [
          (vscode-marketplace-release.github.copilot.override { meta.licenses = [ ]; })
          (vscode-marketplace-release.github.copilot-chat.override { meta.licenses = [ ]; })
        ]
        ++ optionals cfg.continue [
          vscode-marketplace.continue.continue
        ];
    })
  ];
}
