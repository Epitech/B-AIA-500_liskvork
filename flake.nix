{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
  }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      "aarch64-linux"
    ]
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      zig = pkgs.zig_0_13;
    in rec {
      formatter = pkgs.alejandra;

      checks = let
        hooks = {
          alejandra.enable = true;
          check-merge-conflicts.enable = true;
          check-shebang-scripts-are-executable.enable = true;
          check-added-large-files.enable = true;
          zig-fmt = {
            enable = true;
            entry = "${zig}/bin/zig fmt --check .";
            files = "\\.z(ig|on)$";
          };
        };
      in {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          inherit hooks;
          src = ./.;
        };
      };

      devShells.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;

        name = "liskvork";
        inputsFrom = pkgs.lib.attrsets.attrValues packages;
        packages = with pkgs; [
          zls
        ];
      };

      packages = rec {
        liskvork = default;
        default = pkgs.stdenv.mkDerivation {
          name = "liskvork";

          XDG_CACHE_HOME = "${placeholder "out"}";

          src = pkgs.lib.cleanSource ./.;
          buildInputs = [
            zig
          ];

          buildPhase = ''
            zig build -Doptimize=ReleaseSafe
          '';

          doCheck = true;
          checkPhase = ''
            zig build test -Doptimize=ReleaseSafe
          '';

          installPhase = ''
            zig build install --prefix $out -Doptimize=ReleaseSafe
            rm -rf $out/zig # remove cache
          '';
        };
      };
    });
}
