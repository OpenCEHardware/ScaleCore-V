{ pkgs }:
with pkgs; let
  shell =
    { withLibs
    , withToolchains
    , withQuartus
    }: mkShell {
      buildInputs = [
        zlib
      ] ++ lib.optionals withLibs [
        ncurses
        openssl
        SDL2
      ];

      nativeBuildInputs = [
        gnumake
        gtkwave
        lcov
        openocd
        pkg-config
        (python3.withPackages (py: with py; [
          cocotb
          cocotb-bus
          find-libpython # Para cocotb
          pdoc3
          pytest # Para cocotb
          pyyaml # autococo
          (py.callPackage ./cocotb-coverage.nix { })
          (py.callPackage ./peakrdl/peakrdl.nix { })
          (py.callPackage ./peakrdl/peakrdl-cheader.nix { })
          (py.callPackage ./peakrdl/peakrdl-html.nix { })
          (py.callPackage ./peakrdl/peakrdl-ipxact.nix { })
          (py.callPackage ./peakrdl/peakrdl-regblock.nix { })
          (py.callPackage ./peakrdl/peakrdl-systemrdl.nix { })
          (py.callPackage ./peakrdl/peakrdl-uvm.nix { })
          (py.callPackage ./pyuvm.nix { })
        ] ++ lib.optionals withLibs [
          matplotlib
          numpy
          pillow
        ]))
        verible
        verilator
      ] ++ lib.optionals withQuartus [
        kermit
        (quartus-prime-lite.override { supportedDevices = [ "Cyclone V" ]; })
      ] ++ lib.optionals withToolchains [
        binutils
        gcc
        gdb
        meson
        ninja
        rv32Pkgs.stdenv.cc.cc
        rv32Pkgs.stdenv.cc.bintools
      ];

      shellHook = ''
        export MAKEFLAGS="AR=gcc-ar"

        # <https://discourse.nixos.org/t/fonts-in-nix-installed-packages-on-a-non-nixos-system/5871/7>
        export LOCALE_ARCHIVE="${glibcLocales}/lib/locale/locale-archive"
        export FONTCONFIG_FILE="${fontconfig.out}/etc/fonts/fonts.conf"
      '';
    };
in
rec {
  default = full;

  empty = mkShell { };

  minimal = shell {
    withLibs = false;
    withQuartus = false;
    withToolchains = false;
  };

  full = shell {
    withLibs = true;
    withQuartus = true;
    withToolchains = true;
  };

  full-no-quartus = shell {
    withLibs = true;
    withQuartus = false;
    withToolchains = true;
  };
}
