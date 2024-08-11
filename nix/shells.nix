{ pkgs }: with pkgs; {
  default = mkShell {
    buildInputs = [
      ncurses
      openssl
      SDL2
      zlib
    ];

    nativeBuildInputs = [
      binutils
      gcc
      gdb
      gnumake
      gtkwave
      kermit
      lcov
      meson
      ninja
      openocd
      pkg-config
      (python3.withPackages (py: with py; [
        cocotb
        cocotb-bus
        find-libpython # Para cocotb
        matplotlib
        numpy
        pdoc3
        pillow
        pytest # Para cocotb
        (py.callPackage ./cocotb-coverage.nix { })
        (py.callPackage ./peakrdl/peakrdl.nix { })
        (py.callPackage ./peakrdl/peakrdl-cheader.nix { })
        (py.callPackage ./peakrdl/peakrdl-html.nix { })
        (py.callPackage ./peakrdl/peakrdl-ipxact.nix { })
        (py.callPackage ./peakrdl/peakrdl-regblock.nix { })
        (py.callPackage ./peakrdl/peakrdl-systemrdl.nix { })
        (py.callPackage ./peakrdl/peakrdl-uvm.nix { })
        (py.callPackage ./pyuvm.nix { })
      ]))
      rv32Pkgs.stdenv.cc.cc
      rv32Pkgs.stdenv.cc.bintools
      (quartus-prime-lite.override { supportedDevices = [ "Cyclone V" ]; })
      verilator
    ];

    shellHook = ''
      export MAKEFLAGS="AR=gcc-ar"

      # <https://discourse.nixos.org/t/fonts-in-nix-installed-packages-on-a-non-nixos-system/5871/7>
      export LOCALE_ARCHIVE="${glibcLocales}/lib/locale/locale-archive"
      export FONTCONFIG_FILE="${fontconfig.out}/etc/fonts/fonts.conf"
    '';
  };
}
