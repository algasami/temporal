{
  description = "Temporal OS flake easy configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
  let

    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
    version = builtins.substring 0 0 lastModifiedDate;

  in flake-utils.lib.eachDefaultSystem (system:
    let
      name = "temporal_os";
      src = ./.;
      pkgs = import nixpkgs { inherit system; };
      pkg_buildInputs = with pkgs; [
        qemu
      ];
      pkg_nativeBuildInputs = with pkgs; [
        gnumake
        mtools # mformat
        shc # compile script to executable
        nasm
        coreutils
      ];
    in
    {
      packages.default = with pkgs; stdenv.mkDerivation {
        inherit system name src version;
        buildPhase = ''
        make build
        '';
        installPhase = ''
        make install PREFIX=$out
        '';

        # runtime dependencies
        buildInputs = pkg_buildInputs;

        # build-time dependencies
        nativeBuildInputs = pkg_nativeBuildInputs;
      };
      devShells.default = with pkgs; pkgs.mkShell {
        buildInputs = pkg_buildInputs ++ pkg_nativeBuildInputs;
        # include all of them so that it can be easier to debug
      };
    }
  );
}
