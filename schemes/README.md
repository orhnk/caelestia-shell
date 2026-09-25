# Schemes

Base16 colour schemes ported from [ifraaH](https://github.com/orhnk/ifraaH)
(which tracks [tinted-theming/base16-schemes](https://github.com/tinted-theming/base16-schemes)),
in Caelestia CLI layout: `schemes/<scheme>/<flavour>/<mode>.txt` with
space-separated `key hex` lines.

- 347 ifraaH themes -> 322 schemes (248 dark, 99 light files).
- Each scheme has flavour `default`. When an ifraaH `<base>-dark`/`-light`
  file pairs with an opposite-variant `<base>` file, both modes live under
  the `<base>` scheme (e.g. `atelier-cave` has `dark.txt` + `light.txt`).
- ifraaH themes are plain base16 (`base00`-`base0F` only). Every other role
  (surfaces, accents, terminal colours, app-template aliases) is derived
  from base16 with the fixed mapping in `scripts/port-ifraah-schemes.py`
  (`derive_aliases`): blue primary, cyan secondary, magenta tertiary,
  standard base16 terminal mapping. The shell applies the same fallback
  mapping at runtime for minimal base16-only schemes
  (see `services/Colours.qml` → `applyBase16`), so plain base16 stays
  coherent everywhere.
- Dynamic schemes (`dynamic` name with `default`/`hard` flavours) are
  generated from the wallpaper by the CLI and are unaffected by these files.

## Nix packaging

Like the fonts (`quran-font`, `arabic-fonts`), the schemes are a flake
dependency build: `nix/schemes.nix` packages this directory to
`$out/share/caelestia/schemes`, exposed as `packages.*.schemes`. Every
`*.txt` (ported or user-supplied) is format-checked at build time by
`nix/validate-schemes.py`, so palette mistakes fail the build instead of
breaking `caelestia scheme set` at runtime.

Because the CLI only reads schemes from its own package data dir, the flake
also provides the merge helper and a pre-merged CLI:

- `lib.withSchemes cli schemeTree` — returns `cli` with a scheme tree
  merged into its data dir (built-ins and `dynamic` kept, new files added).
- `packages.*.cli-with-schemes` — upstream CLI + the ported schemes.
- `with-cli` and the home-manager module's `cli.package` default to the
  merged CLI, so the launcher sees all schemes out of the box.

## Adding your own palettes

Drop `<scheme>/<flavour>/<mode>.txt` trees (same `key hex` format) in a
directory and merge them in:

```nix
# flake.nix of your config
let
  mySchemes = caelestia-shell.packages.${system}.schemes.override {
    extraSchemes = [ ./my-palettes ];
  };
in {
  # CLI with ported schemes + yours:
  programs.caelestia.cli.package =
    caelestia-shell.lib.withSchemes caelestia-cli mySchemes;
}
```

## Regenerate from ifraaH

```sh
scripts/port-ifraah-schemes.py --src ~/src/ifraaH/themes --out schemes
```

## Imperative install (non-Nix test)

Copy the trees next to the installed CLI data
(`<cli>/lib/python3.*/site-packages/caelestia/data/schemes`) without
clobbering existing files:

```sh
cp -rn schemes/* <cli-data-schemes>/
```

Then pick one with `caelestia scheme set -n <scheme>` (flavour is `default`,
mode follows the file). Note `onedark/default/dark.txt` overlaps the CLI's
built-in `onedark`: the port is the canonical base16 onedark, the built-in
is a hand-tuned Material palette (use `-n` copy without clobber to keep it).
