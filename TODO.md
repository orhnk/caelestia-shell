# TODO

Status: all four items below are implemented and verified on `main`
(commit `6e88e51c`, "fix: lockscreen screencopy bg, salat own fonts, flat
wallpapers, picker bg"). No further code changes were needed.

- [x] The lock screen while caelestia is on should not use the wallpaper as
      background (use the older implementation instead).
  - `modules/lock/LockSurface.qml:157` — the background is again a plain
    `ScreencopyView` (`captureSource: root.screen`) with the same blur
    `MultiEffect`. The `Loader` that chose between wallpaper and screencopy,
    the `wallpaperBackground` `CachingImage` component and the
    `qs.components.images` import are gone.
  - `plugin/src/Caelestia/Config/lockconfig.hpp` — the `lock.useWallpaper`
    option was removed, and its README example entry with it, so no wallpaper
    path can be selected (`grep -r useWallpaper` is empty).
  - `modules/lock/Lock.qml:32` still pre-warms a screencopy, so the first
    capture succeeds (the compositor refuses capture once locked).

- [x] The Salat widget should use its own font for salat names and times.
  - `modules/dashboard/dash/PrayerTimes.qml:17` — pinned `fontFamily` =
    "Rubik" (same approach as `DateTime.clockFamily`), which the names and the
    times share.
  - `rowFont` (`:22`) builds that one font once, and the two `TextMetrics` plus
    both row `StyledText`s read it, so the widget no longer follows the theme
    font and the names cannot drift apart from the times.

- [x] The wallpapers (random pick and the view) should not be colour-scheme
      dependent — all together from `${WPPPATH}`, never `${WPPPATH}/${THEME}`.
  - `modules/nexus/pages/wallandstyle/WallpaperSelect.qml:107` — a single flat,
    sorted list built from `Wallpapers.list` (the recursive `FileSystemModel`
    over `Paths.wallsdir`); the per-category grouping, the category label and
    the "open category subpage" branch were removed.
  - `services/Wallpapers.qml:45` — `setRandom()` picks uniformly from the
    recursive `wallpapers.entries`, so subdirectory wallpapers are included as
    well, and only images Qt could read are ever candidates (the model checks
    `QImageReader::canRead`, unlike the cli's suffix scan).
  - `utils/Paths.qml:22` — `wallsdir` is now exactly `paths.wallpaperDir` from
    the caelestia config. The `CAELESTIA_WALLPAPERS_DIR` override that used to
    take precedence is gone: a stale value (a theme dir that no longer exists)
    silently won over the config, which is what left the switcher empty.
  - Empty switcher, named: `services/Wallpapers.qml:22` checks the directory
    with `test -d` into `dirExists`, warns with the offending path, toasts
    instead of doing nothing when a random pick has no candidates, and
    `modules/launcher/ContentList.qml:135-160` shows either "No wallpapers
    found" or "Wallpaper directory not found" plus the `paths.wallpaperDir`
    hint.
  - `caelestia shell wallpaper random` (`services/Wallpapers.qml:118`) exposes
    the same model-based pick over IPC, for keybinds that should not scan the
    tree with the cli (which size-checks every candidate and aborts on an
    unreadable file).

- [x] The color picker icon background should get coloured after picking a
      color.
  - This is the icon tile of the **toast**, not the quick-toggle button: every
    toggle in the utilities panel — the colour picker included — stays on the
    theme, icon and background alike (`modules/utilities/cards/Toggles.qml`).
  - `services/ColourPicker.qml:47` passes the pick to the toast as a
    `color:#rrggbb` icon, and `modules/utilities/toasts/ToastItem.qml:16-22`
    paints the toast's icon tile with it, the glyph on top taking
    `Colours.on(...)` so it stays readable on any colour. This mirrors the
    existing `salat:<index>` icon, which colours salat toasts.

## Notes / possible follow-ups

- `modules/nexus/pages/wallandstyle/WallpaperCategory.qml`,
  `NexusState.selectedWallpaperCategory` and `Wallpapers.getCategoryFor()` are
  now unreachable (nothing opens subpage 2 any more) — safe to prune, but kept
  because the Appearance `StackPage` component indices are referenced by number
  (`WallpaperAndStyle.qml` opens subpages 1 and 3).
