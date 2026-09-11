# Theme Changes:

## Left Sidebar:
- left workspace background colors: base08 base09 base0A base0B base0C. Unfocused workspace-icons (all of them) should be in their index-color with %70 opacity.
- Tab Name Displayer: base0A
- Date & Clock: Day name (for example "Thu") at top should be base0A, date numbers should be in base0B, the seperating line should be base0F and the clock should be base09
- The widgets down there (for example keyboard layout, battery etc.) should be like so (these are dynamic, the user can add multiple widgets): the 1st widget in that column: base0E, second: base0D, third: base0C, forth, base0B and so on (counting back till base 08). Note: if the number of widgets are less than these declerations, it should not overwrite anything (we don't want any bugs). The background of these widgets should be base01. No background coloring like the workspaces here.
  - the widgets that include list-like structure in this area (like the keyboard layout list, battery modes etc.) should also be colored using this list respective to their index: base0B, 0C, 0D, 0E. The focused ones should use this color in background, unfocused ones should use that in foreground (e.g icon colors/text color), for hovering, the background color should be used with %10 opacity
- Shutdown button: background %10 base08, the icon %100 base08

## Right Menu:
- right sound and brightness scrollers should be calculated smoothly depending on the colors of the theme. lowest is base0F, highest is base08. The algorithms pseudocode:
  ```
  BASE16_SPECTRUM = (15 /*lowest*/, 8 /*highest*/)
  BASE16_SPECTRUM_LEN = 8
  ONE_SPEC_LEN = 100/(BASE16_SPECTRUM_LEN - 1)
  fn calc_between_which_colors(base16table, value_in_percentage) -> (idx_color1, idx_color2, value_in_percentage % 100/(BASE16_SPECTRUM_LEN - 1):
    # maps 100-0 to base08-base0F (e.g the highest index should be (9, 8) (base09, base08), lowest indexes = (15, 14) => base0F, base0E) and returns the percentage value that fits between these colors e.g modulo of the unit space value between the colors with 100. For example: spectrum length is 8. That means 8 different colors and 8 different points in the slider that the color matches exactly to schemes colors. These points are calculated like so: first point: 0 percent = base0F, every next point should be calculated using 100/7 because we have 7 more colors to place through 0-100. at 0+100/7 we have base0E and at 200/7 base0D. these should not be written magically, instead should get calculated! The point is that the program should now, how far is the value in percentage between these corresponding colors, becaues then it will calculate: if you are at 10%, the color of that slider should be between base0F and 0E, but closer to base0E, because 10 is closer to 100/7 as it is to %0. got that? it should then return also: value_in_percentage % 100/(BASE16_SPECTRUM_LEN - 1)
  fn calc_absolute_color_point_in_scheme(idx_color1, idx_color2, absolute_point_between_colors) -> absolute_color:
    mix_colors(idx_color1*absolute_point_between_colors*(ONE_SPEC_LEN - absolute_point_between_colors), idx_color2*absolute_point_between_colors) # power of the colors depending on the distance.
  ```
- The shutdown menu is now good. But only the icon of shutdown is black when hovered.
- Every "Quick toggles" instance should have a index-based coloring from base08-base0D. Background-coloring enabled here also (depending on focusing, transparency changes) not-enabled values should have the base opacity as %10
- icons in the bottom right menu (Keep Awake and Screen Recorder) should be in base0A, the record button and the slider there should be base0B
- the list in Screen Recorder options should be color-indexed and focus-based like the workspace-implementation. The recorded-videos preview should use the entire spectrum (first one base08 until base0F) for directory icons. But play buttons should be kept base07.

## Top Menus:

All the menu buttons should use base08-base0B index and focus-based coloring but unlike the workspaces and the other widgets, the focused widget should have its color IN FOREGROUND (background is plain here) with %100 opacity, other unfocused ones should have their color also in FOREGROUND, but with %67 opacity.

### Dashboard:
- Weather Widget: Indicator icon should be in base0A, degree in base09 if its 25+, base0B if 15-25, base0C if 0-15, base 0D if under 0.
- Clock Widget should use base0A for numbers (hours and minutes), base0F for the three dots in-between.
- Calendar: Weekdays = base08-0C, Weekends: base0E. Current day indicator: base0F (to foreground should be changed accordingly. Currently this works fine, but results to an unreadable date number), the ones that are dimmed (the ones cross over this month) should be also dimmed using base00
- Three circular graphs showing CPU-usage, Ram usage and disk usage: The icons should be in base07, the circular graphs should use: base0A, base0C, base0E
- The Music player should use: base0B for the top loading circular indicator (music line, how much is played how much left), base0A for the music name, base0B for album, base0C for the producer. base0D for play button and base0E for next/previous with %30 opacity. If no media is being played, the opacity of these elements should be %33.

# Media:

- The sound-dj element should use all base08-base0E together! !!!FIXME, all the sound-disks should have their own color, each disk should follow the following structure: first = base08, second = base09, third = base0A... seventh = base0E eight = base0D (!!! RETURNED BACK, it should use an occilation-algorithm, not 123456712345671234567, instead 1234567654321234567654321), nineth = base0C, tenth = base0B... until the last one gets colored
- other options should be like the music player in dashboard menu and all-over the program decided.


...

Continue other layers of this program using such view of design.

But don't change the app-menu (opens after clicking super): Only change the >scheme menu. The icons there should have an index-based color. other than that do not touch this menu.

Be smart, you are a profesional digital artist and frontend developer. Implement these changes smartly!
