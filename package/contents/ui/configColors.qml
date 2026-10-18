import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQC

KCM.SimpleKCM {
    id: page

    property string cfg_dayColor
    property string cfg_timeColor
    property string cfg_ampmColor
    property string cfg_dateColor
    property string cfg_detailColor
    property string cfg_accentColor
    property alias cfg_glowEnabled: glowEnabled.checked
    property string cfg_glowColor
    property alias cfg_glowStrength: glowStrength.value
    property alias cfg_useStyleColors: useStyleColors.checked

    readonly property var presets: [
        { name: "Violet", day: "#e9d5ff", time: "#f5f3ff", ampm: "#e879f9", date: "#d8b4fe", detail: "#c4b5fd", accent: "#a855f7", glow: "#a855f7", strength: 80 },
        { name: "Fuchsia", day: "#f5d0fe", time: "#fdf4ff", ampm: "#f0abfc", date: "#f0abfc", detail: "#e9d5ff", accent: "#d946ef", glow: "#d946ef", strength: 80 },
        { name: "Lavender", day: "#ede9fe", time: "#ffffff", ampm: "#c4b5fd", date: "#ddd6fe", detail: "#ddd6fe", accent: "#a78bfa", glow: "#8b5cf6", strength: 60 },
        { name: "Deep purple", day: "#c084fc", time: "#e9d5ff", ampm: "#a855f7", date: "#a78bfa", detail: "#a78bfa", accent: "#7c3aed", glow: "#6d28d9", strength: 90 },
        { name: "White", day: "#ffffff", time: "#ffffff", ampm: "#ffffff", date: "#ffffff", detail: "#ffffff", accent: "#ffffff", glow: "#000000", strength: 45 }
    ]

    function applyPreset(p) {
        cfg_dayColor = p.day
        cfg_timeColor = p.time
        cfg_ampmColor = p.ampm
        cfg_dateColor = p.date
        cfg_detailColor = p.detail
        cfg_accentColor = p.accent
        cfg_glowColor = p.glow
        glowStrength.value = p.strength
    }

    // color button that stays in sync with its config key, also after presets
    component ColorPick: KQC.ColorButton {
        id: pick
        property string value
        signal picked(string c)
        color: value
        showAlphaChannel: false
        onAccepted: function (c) {
            pick.picked(c.toString())
            pick.color = Qt.binding(function () { return pick.value })
        }
    }

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: useStyleColors
            Kirigami.FormData.label: "Source:"
            text: "Use the colors of the shared Nyx style"
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "When on, the clock takes its text and accent colors from the Style page, like the other Nyx widgets."
        }

        RowLayout {
            enabled: !useStyleColors.checked
            Kirigami.FormData.label: "Presets:"
            Repeater {
                model: page.presets
                delegate: QQC2.Button {
                    text: modelData.name
                    onClicked: page.applyPreset(modelData)
                }
            }
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Colors" }

        // (the color buttons stay editable; they're used again when the option above is off)

        ColorPick { Kirigami.FormData.label: "Weekday:"; value: page.cfg_dayColor; onPicked: c => page.cfg_dayColor = c }
        ColorPick { Kirigami.FormData.label: "Time:"; value: page.cfg_timeColor; onPicked: c => page.cfg_timeColor = c }
        ColorPick { Kirigami.FormData.label: "AM / PM:"; value: page.cfg_ampmColor; onPicked: c => page.cfg_ampmColor = c }
        ColorPick { Kirigami.FormData.label: "Date:"; value: page.cfg_dateColor; onPicked: c => page.cfg_dateColor = c }
        ColorPick { Kirigami.FormData.label: "Weather text:"; value: page.cfg_detailColor; onPicked: c => page.cfg_detailColor = c }
        ColorPick { Kirigami.FormData.label: "Icons, divider, bar:"; value: page.cfg_accentColor; onPicked: c => page.cfg_accentColor = c }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Glow" }

        QQC2.CheckBox { id: glowEnabled; Kirigami.FormData.label: "Glow:"; text: "Enabled" }
        ColorPick {
            Kirigami.FormData.label: "Glow color:"
            enabled: glowEnabled.checked
            value: page.cfg_glowColor
            onPicked: c => page.cfg_glowColor = c
        }
        RowLayout {
            Kirigami.FormData.label: "Strength:"
            enabled: glowEnabled.checked
            QQC2.Slider { id: glowStrength; from: 0; to: 100; stepSize: 5 }
            QQC2.Label { text: glowStrength.value + " %" }
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "A black glow at low strength works as a drop shadow on bright wallpapers."
        }
    }
}
