import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_showWeather: showWeather.checked
    property alias cfg_weatherPosition: weatherPosition.currentIndex
    property string cfg_cityName
    property real cfg_latitude
    property real cfg_longitude
    property alias cfg_tempUnit: tempUnit.currentIndex
    property alias cfg_weatherInterval: interval.value

    property var results: []
    property string status: ""

    function search(query) {
        if (query.trim().length < 2) return
        status = "Searching…"
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) { page.status = "Search failed (no connection?)"; return }
            var r = JSON.parse(xhr.responseText).results || []
            page.results = r
            page.status = r.length ? "" : "No places found"
        }
        xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=6&language=en&name="
                 + encodeURIComponent(query.trim()))
        xhr.send()
    }

    Kirigami.FormLayout {
        QQC2.CheckBox { id: showWeather; Kirigami.FormData.label: "Weather:"; text: "Show weather" }
        QQC2.ComboBox {
            id: weatherPosition
            Kirigami.FormData.label: "Position:"
            enabled: showWeather.checked
            model: ["Under the date", "Right side", "Centered below"]
        }

        RowLayout {
            Kirigami.FormData.label: "Find a city:"
            enabled: showWeather.checked
            QQC2.TextField {
                id: query
                placeholderText: "e.g. London"
                onAccepted: page.search(text)
            }
            QQC2.Button {
                icon.name: "search"
                text: "Search"
                onClicked: page.search(query.text)
            }
        }
        ColumnLayout {
            visible: page.results.length > 0 || page.status.length > 0
            QQC2.Label { visible: page.status.length > 0; text: page.status; opacity: 0.7 }
            Repeater {
                model: page.results
                delegate: QQC2.Button {
                    flat: true
                    icon.name: "mark-location"
                    text: modelData.name
                        + (modelData.admin1 ? ", " + modelData.admin1 : "")
                        + (modelData.country ? ", " + modelData.country : "")
                    onClicked: {
                        page.cfg_cityName = modelData.name
                        page.cfg_latitude = modelData.latitude
                        page.cfg_longitude = modelData.longitude
                        page.results = []
                    }
                }
            }
        }

        QQC2.TextField {
            Kirigami.FormData.label: "Shown name:"
            enabled: showWeather.checked
            text: page.cfg_cityName
            onTextEdited: page.cfg_cityName = text
        }
        RowLayout {
            Kirigami.FormData.label: "Coordinates:"
            enabled: showWeather.checked
            QQC2.TextField {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                text: page.cfg_latitude.toFixed(4)
                validator: DoubleValidator { bottom: -90; top: 90 }
                onEditingFinished: page.cfg_latitude = parseFloat(text)
            }
            QQC2.TextField {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 7
                text: page.cfg_longitude.toFixed(4)
                validator: DoubleValidator { bottom: -180; top: 180 }
                onEditingFinished: page.cfg_longitude = parseFloat(text)
            }
        }
        QQC2.ComboBox {
            id: tempUnit
            Kirigami.FormData.label: "Units:"
            enabled: showWeather.checked
            model: ["Celsius (°C)", "Fahrenheit (°F)"]
        }
        QQC2.SpinBox {
            id: interval
            Kirigami.FormData.label: "Update every:"
            enabled: showWeather.checked
            from: 5; to: 180; stepSize: 5
            textFromValue: function (v) { return v + " min" }
            valueFromText: function (t) { return parseInt(t) }
        }
        QQC2.Label {
            opacity: 0.7
            text: "Weather data: Open-Meteo.com (free, no account or API key)"
        }
    }
}
