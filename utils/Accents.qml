pragma Singleton

import QtQuick
import Quickshell
import qs.services

Singleton {
    id: root

    readonly property color base00: Colours.palette.m3base00
    readonly property color base01: Colours.palette.m3base01
    readonly property color base02: Colours.palette.m3base02
    readonly property color base03: Colours.palette.m3base03
    readonly property color base04: Colours.palette.m3base04
    readonly property color base05: Colours.palette.m3base05
    readonly property color base06: Colours.palette.m3base06
    readonly property color base07: Colours.palette.m3base07
    readonly property color base08: Colours.palette.m3base08
    readonly property color base09: Colours.palette.m3base09
    readonly property color base0A: Colours.palette.m3base0A
    readonly property color base0B: Colours.palette.m3base0B
    readonly property color base0C: Colours.palette.m3base0C
    readonly property color base0D: Colours.palette.m3base0D
    readonly property color base0E: Colours.palette.m3base0E
    readonly property color base0F: Colours.palette.m3base0F

    readonly property list<color> wsColors: [base08, base09, base0A, base0B, base0C]
    readonly property list<color> statusColors: [base0E, base0D, base0C, base0B, base0A, base09, base08]
    readonly property list<color> popListColors: [base0B, base0C, base0D, base0E]
    readonly property list<color> toggleColors: [base08, base09, base0A, base0B, base0C, base0D, base0E]
    readonly property list<color> topMenuColors: [base08, base09, base0A, base0B]
    readonly property list<color> sessionColors: [base0C, base0B, base0A, base09]
    readonly property list<color> weekColors: [base08, base09, base0A, base0B, base0C]
    readonly property list<color> djColors: [base08, base09, base0A, base0B, base0C, base0D, base0E]
    readonly property list<color> spectrumColors: [base0F, base0E, base0D, base0C, base0B, base0A, base09, base08]
    readonly property list<color> charSpectrum: [base07, base08, base09, base0A, base0B, base0C, base0D, base0E, base0F]
    readonly property list<color> prayerColors: [base08, base09, base0A, base0B, base0C]

    function mix(a: color, b: color, t: real): color {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
    }

    function opaque(c: color, opacity: real): color {
        if (Colours.transparency.enabled)
            return Qt.alpha(c, opacity);
        if (opacity >= 1)
            return Qt.rgba(c.r, c.g, c.b, 1);
        return mix(c, Colours.pick(Colours.palette.m3base00, Colours.palette.m3surface), 1 - opacity);
    }

    function at(colors: var, index: int): color {
        if (!colors || colors.length === 0)
            return Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary);
        const i = ((index % colors.length) + colors.length) % colors.length;
        return colors[i];
    }

    function ws(index: int): color {
        return at(wsColors, index);
    }

    function wsBg(index: int, focused: bool): color {
        return opaque(at(wsColors, index), focused ? 1 : 0.5);
    }

    function status(index: int): color {
        const i = Math.max(0, Math.min(statusColors.length - 1, index));
        return statusColors[i];
    }

    function popList(index: int): color {
        return at(popListColors, index);
    }

    function toggle(index: int): color {
        return at(toggleColors, index);
    }

    function toggleBg(index: int, active: bool): color {
        return opaque(at(toggleColors, index), active ? 1 : 0.1);
    }

    function topMenu(index: int, focused: bool): color {
        return opaque(at(topMenuColors, index), focused ? 1 : 0.67);
    }

    function session(index: int, focused: bool): color {
        return opaque(at(sessionColors, index), focused ? 1 : 0.5);
    }

    function sessionFg(index: int): color {
        return at(sessionColors, index);
    }

    function dj(index: int): color {
        const n = djColors.length;
        const period = 2 * n - 2;
        const m = ((index % period) + period) % period;
        return djColors[m < n ? m : period - m];
    }

    function css(c: color): string {
        const r = Math.round(c.r * 255).toString(16).padStart(2, "0");
        const g = Math.round(c.g * 255).toString(16).padStart(2, "0");
        const b = Math.round(c.b * 255).toString(16).padStart(2, "0");
        return `#${r}${g}${b}`;
    }

    function prayerColor(index: int): color {
        return at(prayerColors, index);
    }

    function randomCharColor(): color {
        return charSpectrum[Math.floor(Math.random() * charSpectrum.length)];
    }

    function spectrum(t: real): color {
        const cl = isNaN(t) ? 0 : Math.max(0, Math.min(1, t));
        const segs = spectrumColors.length - 1;
        const pos = cl * segs;
        const i = Math.min(Math.floor(pos), segs - 1);
        return mix(spectrumColors[i], spectrumColors[i + 1], pos - i);
    }

    function tempColor(tempC: real): color {
        if (isNaN(tempC))
            return base0B;
        if (tempC >= 25)
            return base09;
        if (tempC >= 15)
            return base0B;
        if (tempC >= 0)
            return base0C;
        return base0D;
    }
}
