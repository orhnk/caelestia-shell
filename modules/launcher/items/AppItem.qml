import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property ScreenState screenState
    required property string searchText

    readonly property string highlightedName: {
        const name = root.modelData?.name ?? "";
        const q = root.searchText.trim().toLowerCase();
        if (!q)
            return Strings.escapeHtml(name);

        const hex = Accents.css(Accents.base0D);
        const lower = name.toLowerCase();
        let out = "";
        let pos = 0;
        for (const word of q.split(/\s+/)) {
            if (!word)
                continue;
            const i = lower.indexOf(word, pos);
            if (i < 0)
                continue;
            out += `${Strings.escapeHtml(name.slice(pos, i))}<font color="${hex}"><b>${Strings.escapeHtml(name.slice(i, i + word.length))}</b></font>`;
            pos = i + word.length;
        }
        return out + Strings.escapeHtml(name.slice(pos));
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            Apps.launch(root.modelData);
            root.screenState.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        IconImage {
            id: icon

            asynchronous: true
            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: parent.height * 0.8

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteIcon.width
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: root.highlightedName
                textFormat: Text.RichText
                font: Tokens.font.body.medium
            }

            StyledText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font: Tokens.font.body.small
                color: Colours.pick(Colours.palette.m3base04, Colours.palette.m3outline)

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteIcon.width - Tokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }

        Loader {
            id: favouriteIcon

            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            active: root.modelData && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData.id)

            sourceComponent: MaterialIcon {
                text: "favorite"
                fill: 1
                color: Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary)
            }
        }
    }
}
