import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property var cfg: Plasmoid.configuration
    readonly property var loc: cfg.localeName.length > 0 ? Qt.locale(cfg.localeName) : Qt.locale()
    // clockFormat: 0 = follow system, 1 = 12h, 2 = 24h
    readonly property bool use12h: cfg.clockFormat === 1
        || (cfg.clockFormat === 0 && /[aA]/.test(Qt.locale().timeFormat(Locale.ShortFormat)))
    readonly property string unitSymbol: cfg.tempUnit === 1 ? "°F" : "°C"
    property date now: new Date()

    // weather state; the last good reading is kept if a refresh fails
    property bool weatherOk: false
    property real temp: 0
    property real feels: 0
    property int humidity: 0
    property int code: 0
    property bool isDay: true

    function fmt(pattern) {
        return root.now.toLocaleString(root.loc, pattern)
    }

    // WMO weather code -> [description, icon]
    function describe(c, day) {
        var n = day ? "" : "-night"
        if (c === 0) return ["Clear", "weather-clear" + n]
        if (c === 1) return ["Mainly clear", "weather-few-clouds" + n]
        if (c === 2) return ["Partly cloudy", "weather-clouds" + n]
        if (c === 3) return ["Overcast", "weather-overcast"]
        if (c === 45 || c === 48) return ["Fog", "weather-fog"]
        if (c >= 51 && c <= 55) return ["Drizzle", "weather-showers-scattered"]
        if (c === 56 || c === 57) return ["Freezing drizzle", "weather-freezing-rain"]
        if (c >= 61 && c <= 65) return ["Rain", "weather-showers"]
        if (c === 66 || c === 67) return ["Freezing rain", "weather-freezing-rain"]
        if (c >= 71 && c <= 77) return ["Snow", "weather-snow"]
        if (c >= 80 && c <= 82) return ["Rain showers", "weather-showers"]
        if (c === 85 || c === 86) return ["Snow showers", "weather-snow-scattered"]
        if (c === 95) return ["Thunderstorm", "weather-storm"]
        if (c === 96 || c === 99) return ["Thunderstorm, hail", "weather-storm"]
        return ["Unknown", "weather-none-available"]
    }

    function fetchWeather() {
        if (!cfg.showWeather) return
        var url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + cfg.latitude + "&longitude=" + cfg.longitude
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day"
            + "&timezone=auto"
            + (cfg.tempUnit === 1 ? "&temperature_unit=fahrenheit" : "")
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return
            try {
                var c = JSON.parse(xhr.responseText).current
                root.temp = c.temperature_2m
                root.feels = c.apparent_temperature
                root.humidity = c.relative_humidity_2m
                root.code = c.weather_code
                root.isDay = c.is_day === 1
                root.weatherOk = true
            } catch (e) {
                console.warn("Nyx Clock: bad weather response", e)
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Timer {
        interval: Math.max(5, root.cfg.weatherInterval) * 60000
        running: root.cfg.showWeather
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchWeather()
    }

    Connections {
        target: Plasmoid.configuration
        function onLatitudeChanged() { root.fetchWeather() }
        function onLongitudeChanged() { root.fetchWeather() }
        function onTempUnitChanged() { root.fetchWeather() }
    }

    fullRepresentation: Item {
        id: face
        Layout.minimumWidth: 240
        Layout.minimumHeight: 120
        Layout.preferredWidth: 760
        Layout.preferredHeight: 380

        // every size is derived from the widget size
        readonly property real u: Math.min(width / 2.0, height)
        readonly property bool wide: root.cfg.layoutStyle === 0
        readonly property int hAlign: [Qt.AlignLeft, Qt.AlignHCenter, Qt.AlignRight][root.cfg.alignment]
        readonly property real dayPx: u * 0.17 * root.cfg.daySize / 100
        readonly property real timePx: u * 0.40 * root.cfg.timeSize / 100
        readonly property real datePx: u * 0.12 * root.cfg.dateSize / 100
        readonly property real detailPx: u * 0.055 * root.cfg.detailSize / 100

        component DetailText: Text {
            color: root.cfg.detailColor
            font.family: root.cfg.detailFont
            font.weight: root.cfg.detailWeight
            font.pixelSize: face.detailPx
        }

        readonly property bool weatherUnderDate: wide && root.cfg.weatherPosition === 0

        component WeatherBlock: RowLayout {
            spacing: face.u * 0.025

            Kirigami.Icon {
                source: "temperature-normal"
                fallback: "weather-clear"
                isMask: true
                color: root.cfg.accentColor
                Layout.preferredWidth: face.detailPx * 1.9
                Layout.preferredHeight: face.detailPx * 1.9
            }
            Text {
                text: Math.round(root.temp) + root.unitSymbol
                color: root.cfg.detailColor
                font.family: root.cfg.detailFont
                font.weight: root.cfg.detailWeight
                font.pixelSize: face.detailPx * 1.8
            }
            Rectangle {
                Layout.preferredWidth: Math.max(1, face.u * 0.004)
                Layout.fillHeight: true
                color: root.cfg.accentColor
                opacity: 0.7
            }
            ColumnLayout {
                spacing: face.detailPx * 0.15

                DetailText {
                    text: root.cfg.cityName
                    font.weight: Math.min(900, root.cfg.detailWeight + 100)
                }
                RowLayout {
                    spacing: face.detailPx * 0.4
                    DetailText { text: root.describe(root.code, root.isDay)[0] }
                    Kirigami.Icon {
                        source: root.describe(root.code, root.isDay)[1]
                        isMask: true
                        color: root.cfg.accentColor
                        Layout.preferredWidth: face.detailPx * 1.2
                        Layout.preferredHeight: face.detailPx * 1.2
                    }
                }
                DetailText { text: "Feels like: " + Math.round(root.feels) + root.unitSymbol }
                DetailText { text: "Humidity: " + root.humidity + "%" }
            }
        }

        ColumnLayout {
            id: block
            anchors.verticalCenter: parent.verticalCenter
            x: root.cfg.alignment === 0 ? 0
             : root.cfg.alignment === 2 ? face.width - width
             : (face.width - width) / 2
            spacing: 0

            layer.enabled: root.cfg.glowEnabled
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: root.cfg.glowColor
                shadowOpacity: root.cfg.glowStrength / 100
                shadowBlur: 1.0
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
                blurMax: 48
            }

            // weekday
            Text {
                visible: root.cfg.showDay
                Layout.alignment: face.hAlign
                text: {
                    var t = root.fmt(root.cfg.dayFormat)
                    return root.cfg.dayUppercase ? t.toUpperCase() : t
                }
                color: root.cfg.dayColor
                font.family: root.cfg.dayFont
                font.weight: root.cfg.dayWeight
                font.pixelSize: face.dayPx
                font.letterSpacing: face.dayPx * root.cfg.dayLetterSpacing / 100
            }

            // time (+ AM/PM) and date: side by side, or stacked.
            // In the wide layout the weather can sit in the date's column, under the date.
            GridLayout {
                Layout.alignment: face.hAlign
                columns: face.wide ? 2 : 1
                columnSpacing: face.u * 0.06
                rowSpacing: 0

                RowLayout {
                    Layout.row: 0
                    Layout.column: 0
                    Layout.alignment: face.wide ? Qt.AlignBottom : face.hAlign
                    spacing: face.u * 0.02

                    Text {
                        text: root.fmt(root.use12h ? (root.cfg.showSeconds ? "h:mm:ss" : "h:mm")
                                                   : (root.cfg.showSeconds ? "HH:mm:ss" : "HH:mm"))
                        color: root.cfg.timeColor
                        font.family: root.cfg.timeFont
                        font.weight: root.cfg.timeWeight
                        font.pixelSize: face.timePx
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        visible: root.use12h
                        Layout.alignment: Qt.AlignBaseline
                        text: root.fmt("AP")
                        color: root.cfg.ampmColor
                        font.family: root.cfg.timeFont
                        font.weight: root.cfg.timeWeight
                        font.pixelSize: face.timePx * 0.28
                    }
                }

                Text {
                    visible: root.cfg.showDate
                    Layout.row: face.wide ? 0 : 1
                    Layout.column: face.wide ? 1 : 0
                    Layout.alignment: face.wide ? (Qt.AlignTop | Qt.AlignLeft) : face.hAlign
                    Layout.topMargin: face.wide ? face.timePx * 0.18 : 0
                    text: {
                        var t = root.fmt(root.cfg.dateFormat)
                        return root.cfg.dateUppercase ? t.toUpperCase() : t
                    }
                    color: root.cfg.dateColor
                    font.family: root.cfg.dateFont
                    font.weight: root.cfg.dateWeight
                    font.pixelSize: face.datePx
                }

                WeatherBlock {
                    visible: face.weatherUnderDate && root.cfg.showWeather && root.weatherOk
                    Layout.row: 1
                    Layout.column: 1
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.topMargin: face.u * 0.02
                }
            }

            // weather below everything (right side / centered, or stacked layout)
            WeatherBlock {
                visible: !face.weatherUnderDate && root.cfg.showWeather && root.weatherOk
                Layout.alignment: !face.wide ? face.hAlign
                                : root.cfg.weatherPosition === 1 ? Qt.AlignRight : Qt.AlignHCenter
                Layout.topMargin: face.u * 0.03
            }

            // optional seconds bar
            Rectangle {
                visible: root.cfg.showSecondsBar
                Layout.alignment: face.hAlign
                Layout.topMargin: face.u * 0.05
                Layout.preferredWidth: face.u * 1.4
                Layout.preferredHeight: Math.max(2, face.u * 0.008)
                radius: height / 2
                color: Qt.darker(root.cfg.accentColor, 3.5)

                Rectangle {
                    width: parent.width * (root.now.getSeconds() + 1) / 60
                    height: parent.height
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.cfg.accentColor }
                        GradientStop { position: 1.0; color: root.cfg.ampmColor }
                    }
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
