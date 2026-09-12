pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.services

Item {
    id: root

    property string text
    property color color: Colours.pick(Colours.palette.m3base05, Colours.palette.m3onSurface)
    property color maskTop: Colours.pick(Colours.palette.m3base0D, Colours.palette.m3primary)
    property color maskBottom: Colours.pick(Colours.palette.m3base0E, Colours.palette.m3tertiary)
    property real maskWidth: 2
    property font font: Tokens.font.body.small
    property int horizontalAlignment: Text.AlignLeft
    property int wrapMode: Text.NoWrap
    property int elide: Text.ElideNone
    property int maximumLineCount: 2147483647
    property real lineHeight: 1.0

    // The outline is drawn outside the glyphs, so the text is inset by its width
    // or the border gets clipped along the first/last line and both end edges.
    readonly property real pad: Math.max(0, maskWidth)
    readonly property real textWidth: Math.max(0, width - 2 * pad)

    implicitWidth: main.contentWidth + 2 * pad
    implicitHeight: main.contentHeight + 2 * pad

    ShaderEffectSource {
        id: tex

        anchors.fill: parent

        sourceItem: src
        hideSource: true
    }

    StyledText {
        id: src

        x: root.pad
        y: root.pad
        width: root.textWidth
        height: main.height
        text: root.text
        font: root.font
        horizontalAlignment: root.horizontalAlignment
        wrapMode: root.wrapMode
        elide: root.elide
        maximumLineCount: root.maximumLineCount
        lineHeight: root.lineHeight
    }

    ShaderEffect {
        property var srcTex: tex
        property vector2d texel: Qt.vector2d(tex.width > 0 ? 1.0 / tex.width : 0, tex.height > 0 ? 1.0 / tex.height : 0)
        property real radius: root.maskWidth
        property color topColor: root.maskTop
        property color bottomColor: root.maskBottom

        anchors.fill: parent
        vertexShader: "shaders/mask.vert.qsb"
        fragmentShader: "shaders/mask.frag.qsb"
    }

    StyledText {
        id: main

        x: root.pad
        y: root.pad
        width: root.textWidth
        text: root.text
        color: root.color
        font: root.font
        horizontalAlignment: root.horizontalAlignment
        wrapMode: root.wrapMode
        elide: root.elide
        maximumLineCount: root.maximumLineCount
        lineHeight: root.lineHeight
    }
}
