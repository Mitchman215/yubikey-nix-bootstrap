{
  description = "Bootstrap GPG + SSH with YubiKey on a new machine";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      apps = forSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          bootstrap = pkgs.writeShellApplication {
            name = "yubikey-bootstrap";
            runtimeInputs = with pkgs; [
              gnupg
              pinentry-curses
              curl
              openssh
              git
            ];
            text = builtins.readFile ./bootstrap.sh;
          };
        in
        {
          default = {
            type = "app";
            program = "${bootstrap}/bin/yubikey-bootstrap";
          };
        }
      );
    };
}
