# Theme Changes:

## Left Sidebar:
- left workspace background colors: base08 base09 base0A base0B base0C. Unfocused opacity: %50, focused %100. (if no opacity functionality, blend it with the background color - dependant on the variant being dark or light, but thats an overkill, make sure that there is no transparency before you do that!)
- Tab Name Displayer: base0D
- Date & Clock: Day name (for example "Thu") at top should be base0A, numbers (in clock, the date of today) should be in base0B, the seperating line and ":" in clock should be base0C
- The widgets down there (for example keyboard layout, battery etc.) should be like so (these are dynamic, the user can add multiple widgets): the 1st widget in that column: base0E, second: base0D, third: base0C, forth, base0B and so on (counting back till base 08). Note: if the number of widgets are less than these declerations, it should not overwrite anything (we don't want any bugs). The background of these widgets should be base01. No background coloring like the workspaces here.
  - the widgets that include list-like structure in this area (like the keyboard layout list, battery modes etc.) should also be colored using this list respective to their index: base0B, 0C, 0D, 0E
- Shutdown button: background %50 base08, the icon %100 base08 (if no trancparency implement the algorithm obove if needed)

## Right Menu:
- right sound and brightness scrollers, respectively base0A and base0B
- The shutdown menu should use: base0C, 0B, 0A and 09 from top to bottom. The backgrounds should also be colored like workspaces.
- Every "Quick toggles" instance should have a index-based coloring from base08-base0D. Background-coloring enabled here also (depending on focusing, transparency changes)
- icons in the bottom right menu (Keep Awake and Screen Recorder) should be in base0A
- the list in Screen Recorder options should be color-indexed and focus-based like the workspace-implementation

## Top Menus:

All the menu buttons should use base08-base0B index and focus-based coloring but unlike the workspaces and the other widgets, the focused widget should have its color IN FOREGROUND (background is plain here) with %100 opacity, other unfocused ones should have their color also in FOREGROUND, but with %67 opacity.

### Dashboard:
- Weather Widget: Indicator icon should be in base0A, degree in base09 if its 25+, base0B if 15-25, base0C if 0-15, base 0D if under 0.
- Clock Widget should use base0B for numbers (hours and minutes), base0C for the three dots in-between.
- Calendar: Weekdays = base08-0C, Weekends: base0E. Current day indicator: base0F, the ones that are dimmed (the ones cross over this month) should be also dimmed using base03
- Three circular graphs showing CPU-usage, Ram usage and disk usage: The icons should be in base07, the circular graphs should use: base0A, base0C, base0E
- The Music player should use: base0B for the top loading circular indicator (music line, how much is played how much left), base0A for the music name, base0B for album, base0C for the producer. base0D for play button and base0E for next/previous with %30 opacity.

# Media:

- The sound-dj element should use all base08-base0F together!
- other options should be like the music player in dashboard menu and all-over the program decided.


...

Continue other layers of this program using such view of design.

But don't change the app-menu (opens after clicking super)

Be smart, you are a profesional digital artist and frontend developer. Implement these changes smartly!
