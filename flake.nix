{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";

    nixos-template = {
      url = "github:RemiErr/nixos-template";
      # 對齊版本，避免重複 fetch 多份 nixpkgs
      inputs.nixpkgs.follows        = "nixpkgs";
      inputs.home-manager.follows   = "home-manager";
      inputs.noctalia-shell.follows = "noctalia-shell";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-template, ... }@inputs:
    let
      system = "x86_64-linux";
      vars   = import ./variables.nix;
    in
    {
      nixosConfigurations.${vars.hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs vars; };
        modules = [
          # ── Template 提供的系統模組 ─────────────────────────────
          nixos-template.nixosModules.default

          # ── 本機專屬設定 ────────────────────────────────────────
          ./hardware-configuration.nix  # nixos-generate-config 產生
          {
            networking.hostName      = vars.hostname;
            nixpkgs.config.allowUnfree = true;
            system.stateVersion      = "25.11";
          }

          # ── Home Manager ────────────────────────────────────────
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs      = true;
            home-manager.useUserPackages    = true;
            home-manager.extraSpecialArgs   = { inherit inputs vars; };
            home-manager.users.${vars.username} = nixos-template.homeModules.default;
            home-manager.backupFileExtension = "bak";
          }
        ];
      };
    };
}
