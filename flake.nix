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
      devShells = forSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              gnupg
              pinentry-curses
              pcsclite
              ccid
              curl
              openssh
              git
            ];
            shellHook = builtins.readFile ./bootstrap.sh;
          };
        }
      );
    };
}
