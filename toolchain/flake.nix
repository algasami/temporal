{
  description = "Temporal OS Toolchain Cross-compiler";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils/4022d587cbbfd70fe950c1e2083a02621806a725";
    binutils = {
      url = "https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.gz";
      flake = false;
    };
    gcc = {
      url = "https://ftp.gnu.org/gnu/gcc/gcc-12.3.0/gcc-12.3.0.tar.gz";
      flake = false;
    };
    # tarballs are automatically unzipped
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, gcc, binutils, ... }:
  let

    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
    version = builtins.substring 0 0 lastModifiedDate;

  in flake-utils.lib.eachDefaultSystem (system:
    let
      name = "temporal_os_toolchain";
      sourceFiles = fs.difference ./. (fs.unions [
        (fs.maybeMissing ./result)
        ./flake.nix
        ./flake.lock
      ]);
      fs = pkgs.lib.fileset;
      makeLibraryPath = pkgs.lib.makeLibraryPath; # helper
      pkgs = import nixpkgs { inherit system; };
      pkg_buildInputs = with pkgs; [
        # below are for gcc
        gmp
        libmpc
        mpfr
        libelf
        isl
        flex
        bison
        gcc13
      ];
      pkg_nativeBuildInputs = with pkgs; [
        gnumake
        coreutils
        automake
        autoconf-archive
        pkg-config
        autoconf

      ];
      hardeningDisable = [ "all" ];
      # THIS IS VERY IMPORTANT AS NIX
      # ADDS -Werror=format-security automatically!!!
      # https://stackoverflow.com/questions/77249760
    in
    {
      packages.default = with pkgs; stdenv.mkDerivation {
        inherit system name version hardeningDisable;
        src = fs.toSource {
          root = ./.;
          fileset = sourceFiles;
        };

        buildPhase = ''
        # do nothing
        '';

        installPhase = ''
        export LD_LIBRARY_PATH=\"${makeLibraryPath pkg_buildInputs}:$LD_LIBRARY_PATH\"

        make -f toolchain.mk install  \
        BUILD_PREFIX=$out \
        PREFIX=$out   \
        FLAKE=true    \
        BINUTILS_SRC=${binutils} \
        GCC_SRC=${gcc} \
        BINUTILS_VERSION=2.37 \
        GCC_VERSION=12.3.0

        make -f toolchain.mk clean
        '';

        # runtime dependencies
        buildInputs = pkg_buildInputs;

        # build-time dependencies
        nativeBuildInputs = pkg_nativeBuildInputs;

        # library patch for gcc
      };
      devShells.default = with pkgs; pkgs.mkShell {
        buildInputs = pkg_buildInputs ++ pkg_nativeBuildInputs;
        inherit hardeningDisable;
        # library patch for gcc
        LD_LIBRARY_PATH = "${makeLibraryPath pkg_buildInputs}:$LD_LIBRARY_PATH";
      };
    }
  );
}
