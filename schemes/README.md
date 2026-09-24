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

## Regenerate

```sh
scripts/port-ifraah-schemes.py --src ~/src/ifraaH/themes --out schemes
```

## Install (overlay onto the CLI scheme dir)

The CLI reads schemes from its package data dir (`caelestia/data/schemes`),
so the robust way to use these is a nix overlay on `caelestia-cli` that
copies `schemes/*` over its `data/schemes` (this keeps `dynamic` and the
hand-tuned built-ins, only adding new schemes).

For a quick imperative test, copy them next to the installed CLI data
(resolve the dir from the `caelestia` binary, e.g.
`<cli>/lib/python3.13/site-packages/caelestia/data/schemes`) without
clobbering existing files:

```sh
cp -rn schemes/* <cli-data-schemes>/
```

Then pick one with `caelestia scheme set -n <scheme>` (flavour is `default`,
mode follows the file). Note `onedark/default/dark.txt` overlaps the CLI's
built-in `onedark`: the port is the canonical base16 onedark, the built-in
is a hand-tuned Material palette (use `-n` copy without clobber to keep it).
