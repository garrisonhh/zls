{
  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

      zig-overlay.url = "github:mitchellh/zig-overlay";
      zig-overlay.inputs.nixpkgs.follows = "nixpkgs";

      flake-utils.url = "github:numtide/flake-utils";

      langref.url = "https://raw.githubusercontent.com/ziglang/zig/f1992a39a59b941f397b8501a525b38e5863a527/doc/langref.html.in";
      langref.flake = false;

      zig-packager.url = "github:garrisonhh/nix-zig-packager";
    };

  outputs = { self, nixpkgs, zig-overlay, zig-packager, flake-utils, langref, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          inherit system;
          overlays = [
            zig-overlay.overlays.default
            zig-packager.overlays.default
          ];
        };
      in
      rec {
        formatter = pkgs.nixpkgs-fmt;
        packages.default = packages.zls;
        packages.zls = pkgs.buildZig11Package {
          inherit system;
          src = self;
          extraAttrs = {
            inherit langref;
          };
          buildFlags = [ "-Dlangref=$langref" ];
        };
      }
    );
}
