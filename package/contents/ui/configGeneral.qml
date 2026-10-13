import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_layoutStyle: layoutStyle.currentIndex
    property alias cfg_alignment: alignment.currentIndex
    property alias cfg_showDay: showDay.checked
    property alias cfg_showDate: showDate.checked
    property alias cfg_showSeconds: showSeconds.checked
    property alias cfg_showSecondsBar: showSecondsBar.checked
    property alias cfg_clockFormat: clockFormat.currentIndex
    property alias cfg_dayFormat: dayFormat.text
    property alias cfg_dateFormat: dateFormat.text
    property alias cfg_dayUppercase: dayUppercase.checked
    property alias cfg_dateUppercase: dateUppercase.checked
    property alias cfg_localeName: localeName.text

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: layoutStyle
            Kirigami.FormData.label: "Layout:"
            model: ["Wide (date beside the time)", "Stacked (everything in a column)"]
        }
        QQC2.ComboBox {
            id: alignment
            Kirigami.FormData.label: "Alignment:"
            model: ["Left", "Center", "Right"]
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Show" }

        QQC2.CheckBox { id: showDay; text: "Weekday" }
        QQC2.CheckBox { id: showDate; text: "Date" }
        QQC2.CheckBox { id: showSeconds; text: "Seconds in the time" }
        QQC2.CheckBox { id: showSecondsBar; text: "Seconds progress bar" }

        Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Format" }

        QQC2.ComboBox {
            id: clockFormat
            Kirigami.FormData.label: "Clock:"
            model: ["Follow system", "12-hour (AM/PM)", "24-hour"]
        }
        RowLayout {
            Kirigami.FormData.label: "Weekday format:"
            QQC2.TextField { id: dayFormat; placeholderText: "dddd" }
            QQC2.CheckBox { id: dayUppercase; text: "UPPERCASE" }
        }
        RowLayout {
            Kirigami.FormData.label: "Date format:"
            QQC2.TextField { id: dateFormat; placeholderText: "d MMMM yyyy" }
            QQC2.CheckBox { id: dateUppercase; text: "UPPERCASE" }
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 24
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: "dddd = Monday · ddd = Mon · d = 4 · dd = 04 · MMMM = October · MMM = Oct · MM = 10 · yyyy = 2026. "
                + "Example: \"d MMMM yyyy\" → 4 October 2026, \"dd.MM.yyyy\" → 04.10.2026"
        }
        QQC2.TextField {
            id: localeName
            Kirigami.FormData.label: "Language of names:"
            placeholderText: "empty = system (e.g. tr_TR, es_ES, de_DE)"
        }
    }
}
