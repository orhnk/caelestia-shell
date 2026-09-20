import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.utils


Item {
    id: root

    clip: true

    // Minimum breathing room of a row, per side. Rows stretch past this to fill
    // the card, so this is the floor rather than the actual gap. Deliberately
    // below the smallest Tokens value - the next-prayer highlight already
    // separates the rows visually.
    readonly property int rowVPadding: 2
    readonly property int outerVPadding: Tokens.padding.extraSmall

    // Horizontal split around the next-prayer pill: the pill starts
    // `outerHPadding` in from the widget edge, and the text sits `rowHPadding`
    // inside the pill. Only their sum sets the widget's width, so the two trade
    // against each other - widening the pill keeps the widget the same size.
    readonly property int outerHPadding: Tokens.padding.extraSmall
    readonly property int rowHPadding: Tokens.padding.medium

    implicitWidth: layout.implicitWidth + outerHPadding * 2
    implicitHeight: layout.implicitHeight + outerVPadding * 2

    // Display only - Salat loads and refreshes itself. Size the name column up
    // front so the first frame is not collapsed; later changes come through the
    // prayersChanged connection below.
    Component.onCompleted: updateNameCol()

    property real nameColWidth: 0

    function updateNameCol(): void {
        let w = 0;
        for (const n of Salat.names) {
            nameMetrics.text = Salat.label(n);
            w = Math.max(w, nameMetrics.advanceWidth);
        }
        // Salat.label() swaps Dhuhr for "Jumu'ah" on Fridays and that string is
        // not in Salat.names, so without measuring it here the widest label of
        // the week is the one column that is never sized for it - and since the
        // name elides, the row would truncate every Friday. Measured through
        // Salat.label isn't possible (it is not a key of the labels table), so
        // ask the translation directly, same as the service does.
        nameMetrics.text = Tr.tr("Jumu'ah");
        nameColWidth = Math.max(w, nameMetrics.advanceWidth);
    }

    Connections {
        target: Salat

        function onPrayersChanged(): void {
            root.updateNameCol();
        }
    }

    ColumnLayout {
        id: layout

        // Fill instead of centre: the card hands us the height the countdown
        // left over, and the rows stretch to use all of it.
        anchors.fill: parent
        anchors.leftMargin: root.outerHPadding
        anchors.rightMargin: root.outerHPadding
        anchors.topMargin: root.outerVPadding
        anchors.bottomMargin: root.outerVPadding
        spacing: 0

        TextMetrics {
            id: timeMetrics

            font: Tokens.font.mono.builders.medium.weight(Font.DemiBold).build()
            text: GlobalConfig.services.useTwelveHourClock ? "00:00 AM" : "00:00"
        }

        TextMetrics {
            id: nameMetrics

            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: Salat.nextIndex < 0
            text: Tr.tr("Prayer times")
            color: Accents.base0D
            font: Tokens.font.headline.builders.small.weight(Font.DemiBold).build()
            elide: Text.ElideRight
        }

        // Shown while times are an offline approximation (booted with no
        // network); the service keeps retrying and swaps to online data.
        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: Salat.nextIndex >= 0 && !Salat.onlineOk
            text: Tr.tr("offline")
            color: Colours.pick(Colours.palette.m3base04, Colours.palette.m3outline)
            font: Tokens.font.label.small
            elide: Text.ElideRight
        }

        Repeater {
            model: Salat.prayers

            Item {
                id: row

                required property var modelData
                required property int index

                readonly property bool isNext: index === Salat.nextIndex
                readonly property color prayerColor: Accents.prayerColor(index)

                // Tightest a row is ever allowed to get.
                readonly property int naturalHeight: rowLayout.implicitHeight + root.rowVPadding * 2

                Layout.fillWidth: true
                // rowLayout.implicitWidth excludes its own anchored margins;
                // add them back so the highlight covers name and time fully.
                implicitWidth: rowLayout.implicitWidth + root.rowHPadding * 2
                implicitHeight: naturalHeight
                // The layout spacing is 0, so a row's own padding is the entire
                // gap between prayers. Stretching splits the height the card has
                // left after the countdown evenly over the rows, so the margin
                // grows with the card instead of being a fixed 2px, and the list
                // ends flush with the clock.
                Layout.fillHeight: true
                Layout.minimumHeight: naturalHeight

                StyledRect {
                    anchors.fill: parent
                    radius: Tokens.rounding.medium
                    color: row.isNext ? row.prayerColor : "transparent"

                    Behavior on color {
                        CAnim {}
                    }
                }

                RowLayout {
                    id: rowLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: root.rowHPadding
                    anchors.rightMargin: root.rowHPadding
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.preferredWidth: root.nameColWidth
                        text: Salat.label(row.modelData.name)
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                        elide: Text.ElideRight
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        // advanceWidth, not width: the name column above is sized
                        // by an advance too, and mixing the two metrics makes the
                        // right edge of the row land differently from the left.
                        Layout.preferredWidth: timeMetrics.advanceWidth
                        horizontalAlignment: Text.AlignRight
                        text: row.modelData.display
                        color: row.isNext ? Colours.on(row.prayerColor) : row.prayerColor
                        font: Tokens.font.mono.builders.medium.weight(Font.DemiBold).build()
                    }
                }
            }
        }
    }
}
