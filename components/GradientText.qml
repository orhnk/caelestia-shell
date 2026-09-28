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
    // Flat stroke/aura override. Transparent (default) keeps the gradient.
    property color strokeColor: "transparent"
    property real outlineWidth: 1.5
    property real auraWidth: 10
    property real auraStrength: 0.55
    property int maximumLineCount: 2147483647
    property int elide: Text.ElideRight
    property real lineH: 1.0

    // The shader paints the stroke and aura outwards from the glyph edges, and
    // several faces in Quran.fontPool draw marks that reach well past the text
    // box (stacked diacritics, Nastaliq swashes, deep descenders). Everything
    // is therefore rendered on a surface that overflows the item by the effect
    // reach plus a slice of the font's line height, so no glyph part and no
    // glow is ever clipped by the shader texture. The overflow is invisible.
    readonly property real overscan: Math.ceil(root.outlineWidth + root.auraWidth + Math.max(0, fm.height) * 0.4)
    // Shader/capture area: always the item plus the overscan on every side.
    readonly property size surfaceSize: Qt.size(Math.max(1, root.width + 2 * root.overscan), Math.max(1, root.height + 2 * root.overscan))

    implicitWidth: mask.implicitWidth
    implicitHeight: mask.implicitHeight

    FontMetrics {
        id: fm

        font: root.font
    }

    // Painted first (behind the fill text below). Overflows the item bounds;
    // nothing between here and the window clips, so the glow renders freely.
    ShaderEffect {
        anchors.fill: parent
        anchors.margins: -root.overscan

        property var maskTex: maskSrc
        property var gradTex: gradSrc
        property color fillColor: "transparent"
        property color strokeColor: root.strokeColor
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
    // The mask is captured supersampled for smooth dilation edges. Both are
    // captured over the full shader surface (sourceRect may exceed the item),
    // so the mask's stroke/aura neighbourhood is present at every glyph edge.
    ShaderEffectSource {
        id: maskSrc

        sourceItem: mask
        sourceRect: Qt.rect(-root.overscan, -root.overscan, root.surfaceSize.width, root.surfaceSize.height)
        hideSource: false
        live: true
        textureSize: Qt.size(root.surfaceSize.width * 2, root.surfaceSize.height * 2)
    }

    ShaderEffectSource {
        id: gradSrc

        sourceItem: gradRect
        sourceRect: Qt.rect(-root.overscan, -root.overscan, root.surfaceSize.width, root.surfaceSize.height)
        hideSource: true
        live: true
        textureSize: root.surfaceSize
    }
}
