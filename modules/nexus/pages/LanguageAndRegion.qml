import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Temperature units (there must be one for each value of the TemperatureUnit enum)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: Tr.tr("°C")
            value: TemperatureUnit.Celsius
        },
        MenuItem {
            text: Tr.tr("°F")
            value: TemperatureUnit.Fahrenheit
        },
        MenuItem {
            text: Tr.tr("K")
            value: TemperatureUnit.Kelvin
        }
    ]

    // Clock format (index 0 = 24-hour, 1 = 12-hour — matches Time.useTwelveHourClock)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: Tr.tr("24-hour")
        },
        MenuItem {
            text: Tr.tr("12-hour")
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



    title: Tr.tr("Language & region")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Language
        SectionHeader {
            first: true
            text: Tr.tr("Language")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("UI language")
            subtext: Tr.tr("The language used in the shell UI")
            active: menuItems.find(i => i.modelData === Tr.language) ?? autoLang
            onSelected: item => {
                Tr.language = item.modelData ?? ""; // qmllint disable missing-property
            }

            menuItems: [autoLang, ...langItems.instances]

            MenuItem {
                id: autoLang

                text: Tr.tr("Auto")
            }

            Variants {
                id: langItems

                model: Tr.supportedLanguages

                MenuItem {
                    required property string modelData

                    text: {
                        const locale = Qt.locale(modelData);
                        return locale.name === "C" ? modelData : locale.nativeLanguageName || locale.name;
                    }
                }
            }
        }

        // Weather
        SectionHeader {
            text: Tr.tr("Weather")
        }

        // Placeholder until the map-based location picker lands
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: comingSoon.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: comingSoon

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.padding.extraSmall

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "map"
                    color: Colours.pick(Colours.palette.m3base02, Colours.palette.m3outlineVariant)
                    fontStyle: Tokens.font.icon.extraLarge
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Tr.tr("Location picker coming soon")
                    color: Colours.pick(Colours.palette.m3base02, Colours.palette.m3outlineVariant)
                    font: Tokens.font.title.small
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: Tr.tr("Choose your weather location on a map in a future update")
                    color: Colours.pick(Colours.palette.m3base02, Colours.palette.m3outlineVariant)
                    font: Tokens.font.body.small
                }
            }
        }

        // Prayer times
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

        // Units
        SectionHeader {
            text: Tr.tr("Units")
        }

        SelectRow {
            first: true
            label: Tr.tr("Temperature")
            subtext: Tr.tr("Units for weather temperatures")
            menuItems: root.tempItems
            active: root.tempItems.find(i => i.value === GlobalConfig.services.weatherUnits)
            onSelected: item => GlobalConfig.services.weatherUnits = item.value
        }

        SelectRow {
            last: true
            label: Tr.tr("System temperatures")
            subtext: Tr.tr("Units for CPU and GPU temperatures")
            menuItems: root.tempItems
            active: root.tempItems.find(i => i.value === GlobalConfig.services.sensorUnits)
            onSelected: item => GlobalConfig.services.sensorUnits = item.value
        }

        // Time & date
        SectionHeader {
            text: Tr.tr("Time & date")
        }

        SelectRow {
            first: true
            last: true
            label: Tr.tr("Clock format")
            subtext: Tr.tr("How times are shown across the shell")
            menuItems: root.clockItems
            active: root.clockItems[GlobalConfig.services.useTwelveHourClock ? 1 : 0]
            onSelected: item => GlobalConfig.services.useTwelveHourClock = root.clockItems.indexOf(item) === 1
        }
    }
}
