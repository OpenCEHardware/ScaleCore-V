{
  inputs = {
    # Cambiar esto en el futuro para obtener versiones más recientes de paquetes.
    # Se requiere `nix flake update` luego de cambiar esta línea, para actualizar flake.lock
    nixpkgs.url = "github:nixos/nixpkgs/24.05";

    nix-appimage = {
      url = "github:ralismark/nix-appimage";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-appimage }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;

        overlays = [
          (self: super: {
            inherit rv32Pkgs;
          })
        ];
      };

      rv32Pkgs = import nixpkgs {
        inherit system;
        config.allowUnsupportedSystem = true;

        crossSystem = {
          config = "riscv32-none-elf";
          gcc = {
            arch = "rv32i_zicsr";
            abi = "ilp32";
          };
        };
      };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;

      inherit (nix-appimage) bundlers;
      devShells.${system} = import ./nix/shells.nix { inherit pkgs; };

      packages.${system} = pkgs.lib.mapAttrs
        (name: shell: pkgs.callPackage ./nix/bundle.nix {
          inherit name shell;
        })
        self.devShells.${system};
    };
}
