{
  description = "Desktop shell for Caelestia dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE for consumers: point nixpkgs at your system flake's nixpkgs
    # (inputs.caelestia-shell.inputs.nixpkgs.follows = "nixpkgs") so updates
    # don't duplicate nixpkgs and rebuild the world. The follows below keep
    # every other input on that same nixpkgs instance.
    caelestia-cli = {
      url = "github:caelestia-dots/cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.caelestia-shell.follows = "";
    };

    m3shapes = {
      url = "github:soramanew/m3shapes/32ad9ce328bb77ed349b40a3be10ee9ea610b8ab";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs.lib) genAttrs platforms modules lists systems;

    pkgsOf = nixpkgs.legacyPackages;
    systems' = lists.intersectLists platforms.linux systems.flakeExposed;
    eachSystem = genAttrs systems';

    # Merge a scheme tree (as produced by `packages.*.schemes`, i.e.
    # `$out/share/caelestia/schemes`) into a Caelestia CLI package's data
    # dir, so `caelestia scheme list/set` sees the extra schemes.
    # Users can point this at their own palette set, e.g.:
    #   withSchemes cli (schemes.override { extraSchemes = [ ./my-palettes ]; })
    withSchemes = cli: schemeTree:
      cli.overrideAttrs (old: {
        postFixup =
          (old.postFixup or "")
          + ''
            for schemeDir in "$out"/lib/python*/site-packages/caelestia/data/schemes; do
              cp -r ${schemeTree}/share/caelestia/schemes/. "$schemeDir"/
            done
          '';
      });
  in {
    formatter = eachSystem (system: pkgsOf.${system}.alejandra);

    lib = {
      inherit withSchemes;
    };

    packages = eachSystem (system: let
      pkgs = pkgsOf.${system};

      # Unicode Uthmani (Hafs) script used by the background ayah. Fetched here
      # instead of committed so the repo carries no font binary. The glyph-based
      # QPC fonts on QUL cannot be used for this: they map a whole word per
      # glyph and need the matching per-page script.
      quran-font = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "kfgqpc-uthmanic-script-hafs";
        version = "1.0.0";

        src = pkgs.fetchurl {
          url = "https://cdn.jsdelivr.net/npm/kfgqpc-uthmanic-script-hafs-regular@${finalAttrs.version}/arabic.otf";
          hash = "sha256-WeILJANoemeFT9GZhhq+01KAaMA10miYmEZdX685uzE=";
        };

        dontUnpack = true;

        installPhase = ''
          install -Dm644 $src $out/share/fonts/opentype/KFGQPC-Uthmanic-Script-HAFS.otf
        '';

        meta = {
          description = "KFGQPC Uthmanic Script HAFS (Unicode) Quran font";
          homepage = "https://qul.tarteel.ai/resources/font/249";
          license = pkgs.lib.licenses.isc;
          platforms = pkgs.lib.platforms.all;
        };
      });

      # Arabic calligraphy pool for the background ayah widget. Vendored
      # (unlike quran-font) because most of these faces are not in nixpkgs.
      # All are OFL-licensed, see data/fonts/OFL.txt.
      arabic-fonts = pkgs.stdenvNoCC.mkDerivation {
        pname = "caelestia-arabic-fonts";
        version = "1.0.0";

        src = ./data/fonts;

        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          install -Dm644 $src/*.ttf $out/share/fonts/truetype/
        '';
      };

      # Base16 colour schemes ported from ifraaH (see schemes/ and
      # scripts/port-ifraah-schemes.py) in CLI layout. Add your own
      # palettes via `schemes.override { extraSchemes = [ ./my-palettes ]; }`.
      schemes = pkgs.callPackage ./nix/schemes.nix {};

      # Caelestia CLI with the ported (+ user) schemes merged into its data
      # dir, so `caelestia scheme list/set` sees them out of the box.
      cli-with-schemes = withSchemes inputs.caelestia-cli.packages.${system}.default schemes;
    in rec {
      inherit quran-font arabic-fonts schemes cli-with-schemes;

      caelestia-shell = pkgs.callPackage ./nix {
        rev = self.rev or self.dirtyRev;
        stdenv = pkgs.clangStdenv;
        inherit quran-font arabic-fonts;
        # Bundle the CLI with the ported schemes so `caelestia scheme`
        # (used by the shell launcher) sees them out of the box.
        caelestia-cli = cli-with-schemes;
        quickshell = inputs.quickshell.packages.${system}.default.override {
          withX11 = false;
          withI3 = false;
        };
        m3shapes = inputs.m3shapes.packages.${system}.default;
      };
      with-cli = caelestia-shell.override {withCli = true;};
      debug = caelestia-shell.override {debug = true;};
      default = caelestia-shell;
    });

    devShells = eachSystem (system: {
      default = let
        pkgs = pkgsOf.${system};
        shell = self.packages.${system}.caelestia-shell;
        mkShell = pkgs.mkShell.override {stdenv = shell.stdenv;};
      in
        mkShell {
          inputsFrom = [shell shell.plugin shell.extras];
          packages = with pkgs; [clazy material-symbols rubik nerd-fonts.caskaydia-cove];
          CAELESTIA_XKB_RULES_PATH = "${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst";
        };
    });

    homeManagerModules.default = modules.importApply ./nix/hm-module.nix self;
  };
}
