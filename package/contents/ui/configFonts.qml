import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property string cfg_dayFont
    property int cfg_dayWeight
    property int cfg_daySize
    property alias cfg_dayLetterSpacing: letterSpacing.value
    property string cfg_timeFont
    property int cfg_timeWeight
    property int cfg_timeSize
    property string cfg_dateFont
    property int cfg_dateWeight
    property int cfg_dateSize
    property string cfg_detailFont
    property int cfg_detailWeight
    property int cfg_detailSize

    readonly property var families: Qt.fontFamilies()

    // font family + weight + size for one part of the clock
    component FontRow: RowLayout {
        id: row
        property string family
        property int weight
        property int size

        QQC2.ComboBox {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 13
            model: page.families
            editable: true
            currentIndex: find(row.family)
            onActivated: row.family = currentText
            onAccepted: row.family = editText
        }
        QQC2.SpinBox {
            from: 100; to: 900; stepSize: 100
            value: row.weight
            onValueModified: row.weight = value
            QQC2.ToolTip.text: "Weight: 100 = thin, 400 = regular, 700 = bold, 900 = black"
            QQC2.ToolTip.visible: hovered
        }
        QQC2.SpinBox {
            from: 20; to: 400; stepSize: 5
            value: row.size
            onValueModified: row.size = value
            textFromValue: function (v) { return v + " %" }
            valueFromText: function (t) { return parseInt(t) }
            QQC2.ToolTip.text: "Size relative to the default"
            QQC2.ToolTip.visible: hovered
        }
    }

    Kirigami.FormLayout {
        QQC2.Label {
            Kirigami.FormData.label: " "
            opacity: 0.7
            text: "Font  ·  weight (100–900)  ·  size"
        }
        FontRow {
            Kirigami.FormData.label: "Weekday:"
            family: page.cfg_dayFont; weight: page.cfg_dayWeight; size: page.cfg_daySize
            onFamilyChanged: page.cfg_dayFont = family
            onWeightChanged: page.cfg_dayWeight = weight
            onSizeChanged: page.cfg_daySize = size
        }
        QQC2.SpinBox {
            id: letterSpacing
            Kirigami.FormData.label: "Weekday letter spacing:"
            from: -10; to: 150; stepSize: 5
            textFromValue: function (v) { return v + " %" }
            valueFromText: function (t) { return parseInt(t) }
        }
        FontRow {
            Kirigami.FormData.label: "Time:"
            family: page.cfg_timeFont; weight: page.cfg_timeWeight; size: page.cfg_timeSize
            onFamilyChanged: page.cfg_timeFont = family
            onWeightChanged: page.cfg_timeWeight = weight
            onSizeChanged: page.cfg_timeSize = size
        }
        FontRow {
            Kirigami.FormData.label: "Date:"
            family: page.cfg_dateFont; weight: page.cfg_dateWeight; size: page.cfg_dateSize
            onFamilyChanged: page.cfg_dateFont = family
            onWeightChanged: page.cfg_dateWeight = weight
            onSizeChanged: page.cfg_dateSize = size
        }
        FontRow {
            Kirigami.FormData.label: "Weather details:"
            family: page.cfg_detailFont; weight: page.cfg_detailWeight; size: page.cfg_detailSize
            onFamilyChanged: page.cfg_detailFont = family
            onWeightChanged: page.cfg_detailWeight = weight
            onSizeChanged: page.cfg_detailSize = size
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "Tip: resize the widget itself to scale everything at once. "
                + "Suggested free fonts (Google Fonts): Orbitron, Quicksand, Audiowide, Michroma. See the README to install them."
        }
    }
}
