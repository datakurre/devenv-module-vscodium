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
    features = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };
  config.packages = mkIf cfg.enable [
    (unstable.vscode-with-extensions.override {
      vscode = if lib.elem "unfree" cfg.features then unstable.vscode else unstable.vscodium;
      vscodeExtensions =
        [
          unstable.vscode-extensions.ms-vscode.makefile-tools
          vscode-marketplace.bbenoist.nix
          vscode-marketplace.tamasfe.even-better-toml
        ]
        ++ optionals (lib.elem "unfree" cfg.features) [
          (vscode-marketplace.ms-vscode-remote.remote-ssh.override { meta.licenses = [ ]; })
          (unstable.vscode-extensions.ms-python.vscode-pylance)
        ]
        ++ optionals (!lib.elem "unfree" cfg.features) [
          vscode-marketplace.ms-pyright.pyright
        ]
        ++ optionals (lib.elem "java" cfg.features) [
          vscode-marketplace.redhat.java
          vscode-marketplace.vscjava.vscode-java-debug
          vscode-marketplace.vscjava.vscode-java-test
          vscode-marketplace.vscjava.vscode-maven
          vscode-marketplace.vscjava.vscode-java-dependency
          vscode-marketplace.visualstudioexptteam.vscodeintellicode
        ]
        ++ optionals (lib.elem "python" cfg.features || lib.elem "robot" cfg.features) [
          pkgs.vscode-extensions.ms-python.python
          pkgs.vscode-extensions.ms-python.debugpy
          (vscode-marketplace.charliermarsh.ruff.overrideAttrs (old: {
            postInstall = ''
              rm -f $out/share/vscode/extensions/charliermarsh.ruff/bundled/libs/bin/ruff
              ln -s ${pkgs.ruff}/bin/ruff $out/share/vscode/extensions/charliermarsh.ruff/bundled/libs/bin/ruff
            '';
          }))
        ]
        ++ optionals (!lib.elem "go" cfg.features) [
          vscode-marketplace.golang.go
        ]
        ++ optionals (lib.elem "jupyter" cfg.features) [
          vscode-marketplace.ms-toolsai.jupyter
          vscode-marketplace.ms-toolsai.jupyter-keymap
          vscode-marketplace.ms-toolsai.jupyter-renderers
          vscode-marketplace.ms-toolsai.vscode-jupyter-cell-tags
          vscode-marketplace.ms-toolsai.vscode-jupyter-slideshow
          vscode-marketplace.ms-toolsai.vscode-jupyter-powertoys
        ]
        ++ optionals (lib.elem "robot" cfg.features) [
          vscode-marketplace.d-biehl.robotcode
        ]
        ++ optionals (lib.elem "bpmn" cfg.features) [
          vscode-marketplace.miragon-gmbh.vs-code-bpmn-modeler
        ]
        ++ optionals (lib.elem "vim" cfg.features) [
          vscode-marketplace.vscodevim.vim
        ]
        ++ optionals (lib.elem "copilot" cfg.features) [
          (vscode-marketplace-release.github.copilot.override { meta.licenses = [ ]; })
          (vscode-marketplace-release.github.copilot-chat.override { meta.licenses = [ ]; })
        ]
        ++ optionals (lib.elem "continue" cfg.features) [
          vscode-marketplace.continue.continue
        ];
    })
  ];
}
