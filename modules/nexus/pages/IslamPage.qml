pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Faces offered for the translation text. All ship with the shell or are
    // common system fonts; Qt falls back gracefully if one is missing.
    readonly property list<string> translationFonts: [
        "Amiri",
        "Rubik",
        "IBM Plex Sans Arabic Bold",
        "Noto Naskh Arabic",
        "Noto Sans Arabic",
        "Scheherazade New",
    ]

    // Translation currently picked for download (id) or null.
    property var pendingFetch: null

    // Tanzil translations not downloaded yet.
    readonly property var downloadOptions: Quran.fetchableTranslations.filter(t => !Quran.fetchedTranslations.some(f => f.id === t.id))

    readonly property bool activeIsFetched: !Quran.isBuiltinTranslation(Quran.translationId) && Quran.fetchedTranslations.some(t => t.id === Quran.translationId)

    readonly property list<MenuItem> modeItems: [
        MenuItem {
            text: Tr.tr("Random")
            value: "random"
        },
        MenuItem {
            text: Tr.tr("Daily")
            value: "daily"
        },
        MenuItem {
            text: Tr.tr("Sequential")
            value: "sequential"
        }
    ]

    readonly property list<MenuItem> madhabItems: [
        MenuItem {
            text: Tr.tr("Shafi")
            value: 0
        },
        MenuItem {
            text: Tr.tr("Hanafi")
            value: 1
        }
    ]

    title: Tr.tr("Islam")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ---- Quran --------------------------------------------------------
        SectionHeader {
            first: true
            text: Tr.tr("Quran")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Show translation")
            subtext: Tr.tr("Display a translation under the ayah")
            checked: Quran.translationEnabled
            onToggled: Quran.setTranslationEnabled(checked)
        }

        SelectRow {
            label: Tr.tr("Translation")
            subtext: Quran.translationNameFor(Quran.translationId)
            menuItems: translationVariants.instances
            active: translationVariants.instances.find(i => i.value === Quran.translationId) ?? null
            fallbackText: Quran.translationNameFor(Quran.translationId)
            onSelected: item => Quran.setTranslationId(item.value)

            Variants {
                id: translationVariants

                model: Quran.translationOptions

                MenuItem {
                    required property var modelData

                    text: `${modelData.language} — ${modelData.name}`
                    value: modelData.id
                }
            }
        }

        SelectRow {
            label: Tr.tr("Translation font")
            subtext: Quran.translationFont || Tr.tr("Shell default")
            menuItems: translationFontVariants.instances
            active: translationFontVariants.instances.find(i => i.text === Quran.translationFont) ?? null
            fallbackText: Quran.translationFont || Tr.tr("Shell default")
            onSelected: item => Quran.translationFont = item.text

            Variants {
                id: translationFontVariants

                model: root.translationFonts

                MenuItem {
                    required property string modelData

                    text: modelData
                }
            }
        }

        SliderRow {
            label: Tr.tr("Translation size")
            subtext: Tr.tr("Relative to the ayah size, which it follows")
            valueLabel: `${Math.round(Quran.translationScale * 100)}%`
            value: Quran.translationScale
            onMoved: v => Quran.translationScale = Math.max(0.1, v)
        }

        SelectRow {
            label: Tr.tr("Download a language")
            subtext: Tr.tr("Translations are fetched from Tanzil and cached locally")
            menuItems: fetchVariants.instances
            active: fetchVariants.instances.find(i => i.value === root.pendingFetch) ?? null
            fallbackText: Tr.tr("Choose a language")
            onSelected: item => root.pendingFetch = item.value

            Variants {
                id: fetchVariants

                model: root.downloadOptions

                MenuItem {
                    required property var modelData

                    text: `${modelData.language} — ${modelData.name}`
                    value: modelData.id
                }
            }
        }

        RowButton {
            icon: Quran.translationFetching ? "downloading" : "download"
            text: root.pendingFetch ? Tr.tr("Download %1").arg(Quran.translationNameFor(root.pendingFetch)) : Tr.tr("Download translation")
            subtext: {
                if (Quran.translationFetching)
                    return Tr.tr("Downloading…");
                if (Quran.translationFetchError)
                    return Quran.translationFetchError;
                if (root.downloadOptions.length === 0)
                    return Tr.tr("All available languages are downloaded");
                return Tr.tr("Fetches the selected language and makes it active");
            }
            disabled: !root.pendingFetch || Quran.translationFetching
            onClicked: {
                const t = Quran.fetchableTranslations.find(x => x.id === root.pendingFetch);
                if (t) {
                    Quran.fetchTranslation(t.id, t.language, t.name);
                    root.pendingFetch = null;
                }
            }
        }

        RowButton {
            last: true
            visible: root.activeIsFetched
            icon: "delete"
            text: Tr.tr("Remove downloaded translation")
            subtext: Quran.translationNameFor(Quran.translationId)
            onClicked: Quran.removeFetchedTranslation(Quran.translationId)
        }

        // ---- Verse appearance ---------------------------------------------
        SectionHeader {
            text: Tr.tr("Ayah appearance")
        }

        SelectRow {
            first: true
            label: Tr.tr("Typeface")
            subtext: Quran.fontRandom ? Tr.tr("A new face is rolled for each ayah") : Quran.fontFamily
            menuItems: [randomFontItem, ...fontVariants.instances]
            active: Quran.fontRandom ? randomFontItem : (fontVariants.instances.find(i => i.value === Quran.fontFamily) ?? randomFontItem)
            onSelected: item => Quran.setFontFamily(item.value)

            MenuItem {
                id: randomFontItem

                text: Tr.tr("Random")
                value: "random"
            }

            Variants {
                id: fontVariants

                model: Quran.fontPool

                MenuItem {
                    required property string modelData

                    text: modelData
                    value: modelData
                }
            }
        }

        StepperRow {
            label: Tr.tr("Ayah size")
            subtext: Tr.tr("Base size before the fit-to-card adjustment")
            value: Quran.fontScale
            from: 0.25
            to: 4
            stepSize: 0.25
            onMoved: v => Quran.setFontScale(v)
        }

        StepperRow {
            label: Tr.tr("Glow")
            subtext: Tr.tr("Aura strength around the ayah")
            value: Quran.auraScale
            from: 0
            to: 3
            stepSize: 0.1
            onMoved: v => Quran.setAuraScale(v)
        }

        SelectRow {
            last: true
            label: Tr.tr("Verse rotation")
            subtext: Tr.tr("How a new verse is picked")
            menuItems: root.modeItems
            active: root.modeItems.find(i => i.value === Quran.mode) ?? root.modeItems[0]
            onSelected: item => Quran.setMode(item.value)
        }

        // ---- Prayer times -------------------------------------------------
        SectionHeader {
            text: Tr.tr("Prayer times")
        }

        RowButton {
            first: true
            icon: "location_on"
            text: Weather.city || Weather.loc || Tr.tr("Unknown location")
            subtext: Tr.tr("Prayer location (follows weather location)")
            trailingIcon: "refresh"
            onClicked: {
                Weather.reload();
                Salat.refresh();
            }
        }

        SelectRow {
            label: Tr.tr("Madhab")
            subtext: Tr.tr("Asr calculation (Hanafi uses a longer shadow)")
            menuItems: root.madhabItems
            active: root.madhabItems.find(i => i.value === Salat.school) ?? root.madhabItems[0]
            onSelected: item => Salat.school = item.value
        }

        SelectRow {
            label: Tr.tr("Calculation method")
            subtext: Salat.methodAuto ? Tr.tr("Auto: %1, from Aladhan").arg(Salat.methodName(Salat.method)) : Tr.tr("Fajr and Isha angles, from Aladhan")
            menuItems: [autoMethod, ...methodVariants.instances]
            active: Salat.methodAuto ? autoMethod : [...methodVariants.instances].find(i => i.value === Salat.method)
            onSelected: item => {
                if (item === autoMethod || item.value === -1) {
                    Salat.methodAuto = true;
                } else if (Number.isFinite(item.value)) {
                    Salat.methodAuto = false;
                    Salat.method = item.value;
                }
            }

            MenuItem {
                id: autoMethod

                text: Salat.methodAuto ? Tr.tr("Auto (%1)").arg(Salat.methodName(Salat.method)) : Tr.tr("Auto")
                value: -1
            }

            Variants {
                id: methodVariants

                model: Salat.methodList

                MenuItem {
                    required property var modelData

                    text: modelData.name
                    value: modelData.id
                }
            }
        }

        StepperRow {
            label: Tr.tr("Remind before")
            subtext: Tr.tr("Minutes before prayer time to show a reminder")
            value: Salat.reminderMins
            from: 0
            to: 60
            stepSize: 1
            onMoved: v => Salat.reminderMins = Math.round(v)
        }

        ToggleRow {
            text: Tr.tr("Prayer reminders")
            subtext: Tr.tr("Show a toast before each prayer")
            checked: Salat.reminderMins > 0
            onToggled: Salat.reminderMins = checked ? 5 : 0
        }

        RowButton {
            icon: "sync"
            text: Tr.tr("Re-fetch times")
            subtext: Tr.tr("Reload this month from Aladhan")
            onClicked: Salat.refresh()
        }

        RowButton {
            last: true
            icon: "delete_sweep"
            text: Tr.tr("Clear cache")
            subtext: Tr.tr("Drop all saved timetables and fetch again")
            onClicked: Salat.clearCache()
        }
    }
}
