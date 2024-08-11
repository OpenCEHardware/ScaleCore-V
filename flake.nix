{
  # Cambiar esto en el futuro para obtener versiones más recientes de paquetes.
  # Se requiere `nix flake update` luego de cambiar esta línea, para actualizar flake.lock
  inputs.nixpkgs.url = "github:nixos/nixpkgs/24.05";

  outputs = { self, nixpkgs }:
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
            arch = "rv32imafc";
            abi = "ilp32f";
          };
        };
      };
    in
    {
      devShells.${system} = import ./nix/shells.nix { inherit pkgs; };
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
