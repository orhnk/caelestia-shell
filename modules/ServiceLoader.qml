import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

Scope {
    Component.onCompleted: {
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        Quran;
        // Prayer times drive reminders (and a 60s tick), so they must run even
        // when the dashboard is never opened. The service fetches from its own
        // FileView handler, which also means the saved method/school are
        // restored before the timings are requested.
        Salat;
        Weather.reload();

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
