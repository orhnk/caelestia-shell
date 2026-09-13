pragma ComponentBehavior: Bound

import QtQuick

// Glyph fill renders as a real vector Text (always crisp); the shader behind
// it paints only the gradient outline (stroke) and gradient aura (glow).
// The mask is one whole Text item, so complex-script shaping (e.g. Arabic
// joining) stays intact. No visible rectangles.
Item {
    id: root

    required property string text
    property font font
    property color fill: "white"
    property Gradient gradient
    property real outlineWidth: 1.5
    property real auraWidth: 10
    property real auraStrength: 0.55
    property int maximumLineCount: 2147483647
    property int elide: Text.ElideRight
    property real lineH: 1.0

    implicitWidth: mask.implicitWidth
    implicitHeight: mask.implicitHeight

    // Painted first (behind the fill text below).
    ShaderEffect {
        anchors.fill: parent

        property var maskTex: maskSrc
        property var gradTex: gradSrc
        property color fillColor: "transparent"
        property vector4d radii: Qt.vector4d(root.outlineWidth / Math.max(1, width), root.outlineWidth / Math.max(1, height), root.auraWidth / Math.max(1, width), root.auraWidth / Math.max(1, height))
        property vector4d misc: Qt.vector4d(root.auraStrength, 0, 0, 0)

        fragmentShader: "gradienttext.frag.qsb"
    }

    Text {
        id: mask

        anchors.fill: parent
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        maximumLineCount: root.maximumLineCount
        elide: root.elide
        text: root.text
        color: root.fill
        font: root.font
        lineHeight: root.lineH
        renderType: Text.NativeRendering
    }

    Rectangle {
        id: gradRect

        anchors.fill: parent
        gradient: root.gradient
    }

    // NOTE: never put layer.enabled on mask/gradRect: a layer plate breaks
    // hideSource capture and the raw sources leak through as rectangles.
    // The mask is captured supersampled for smooth dilation edges.
    ShaderEffectSource {
        id: maskSrc

        sourceItem: mask
        hideSource: false
        live: true
        textureSize: Qt.size(Math.max(1, mask.width * 2), Math.max(1, mask.height * 2))
    }

    ShaderEffectSource {
        id: gradSrc

        sourceItem: gradRect
        hideSource: true
        live: true
    }
}
