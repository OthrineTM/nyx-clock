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
    readonly property color themeText: Kirigami.Theme.textColor
    readonly property color themeAccent: Kirigami.Theme.highlightColor
    readonly property color themeBackground: Kirigami.Theme.backgroundColor
    property NyxStyle style: NyxStyle {
        cfg: root.cfg
        themeText: root.themeText
        themeAccent: root.themeAccent
        themeBackground: root.themeBackground
    }
    readonly property var faceNames: ["Classic", "Stacked", "Weekday card", "Compact card", "Analog", "Minimal"]

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Next Face: " + root.faceNames[(root.cfg.face + 1) % root.faceNames.length]
            icon.name: "view-preview"
            onTriggered: root.cfg.face = (root.cfg.face + 1) % root.faceNames.length
        },
        PlasmaCore.Action {
            text: "Next Style: " + root.style.nextPreset().name
            icon.name: "preferences-desktop-theme"
            onTriggered: root.style.apply(root.style.nextPreset())
        }
    ]

    // part colors: the clock's own (Colors & Glow page) or the shared style's
    readonly property bool styled: cfg.useStyleColors
    readonly property color cDay: styled ? style.dim : cfg.dayColor
    readonly property color cTime: styled ? style.text : cfg.timeColor
    readonly property color cAmpm: styled ? style.accent : cfg.ampmColor
    readonly property color cDate: styled ? style.dim : cfg.dateColor
    readonly property color cDetail: styled ? style.dim : cfg.detailColor
    readonly property color cAccent: styled ? style.accent : cfg.accentColor
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
    // Qt's "h"/"hh" only switch to 1-12 when the pattern itself has AP,
    // so the 12-hour value is worked out here
    function hourText(padded) {
        if (!use12h) return fmt(padded ? "HH" : "H")
        var h = now.getHours() % 12 || 12
        return padded && h < 10 ? "0" + h : String(h)
    }
    function ampmText() {
        return now.getHours() < 12 ? loc.amText : loc.pmText
    }
    function timeText() {
        return hourText(!use12h) + fmt(cfg.showSeconds ? ":mm:ss" : ":mm")
    }
    function upper(t, on) { return on ? t.toUpperCase() : t }
    // ISO 8601 week number and day of the year
    readonly property int weekNumber: {
        var d = new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()))
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7))
        return Math.ceil(((d - Date.UTC(d.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7)
    }
    readonly property int dayOfYear: Math.round((new Date(now.getFullYear(), now.getMonth(), now.getDate())
                                                 - new Date(now.getFullYear(), 0, 1)) / 86400000) + 1
    readonly property int daysInYear: new Date(now.getFullYear(), 1, 29).getMonth() === 1 ? 366 : 365

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
        Layout.minimumWidth: 160
        Layout.minimumHeight: 100
        Layout.preferredWidth: [760, 420, 420, 260, 300, 420][root.cfg.face] ?? 760
        Layout.preferredHeight: [380, 420, 220, 240, 300, 200][root.cfg.face] ?? 380

        // on a styled surface the content keeps a margin from the edges
        readonly property real pad: root.style.hasSurface ? Math.min(width, height) * 0.08 : 0
        readonly property real cw: width - pad * 2
        readonly property real ch: height - pad * 2

        // every size is derived from the widget size
        readonly property real u: Math.min(cw / 2.0, ch)
        readonly property bool wide: root.cfg.layoutStyle === 0
        readonly property int hAlign: [Qt.AlignLeft, Qt.AlignHCenter, Qt.AlignRight][root.cfg.alignment]
        readonly property real dayPx: u * 0.17 * root.cfg.daySize / 100
        readonly property real timePx: u * 0.40 * root.cfg.timeSize / 100
        readonly property real datePx: u * 0.12 * root.cfg.dateSize / 100
        readonly property real detailPx: u * 0.055 * root.cfg.detailSize / 100

        NyxSurface {
            anchors.fill: parent
            visible: root.style.hasSurface
            style: root.style
        }

        component DetailText: Text {
            color: root.cDetail
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
                color: root.cAccent
                Layout.preferredWidth: face.detailPx * 1.9
                Layout.preferredHeight: face.detailPx * 1.9
            }
            Text {
                text: Math.round(root.temp) + root.unitSymbol
                color: root.cDetail
                font.family: root.cfg.detailFont
                font.weight: root.cfg.detailWeight
                font.pixelSize: face.detailPx * 1.8
            }
            Rectangle {
                Layout.preferredWidth: Math.max(1, face.u * 0.004)
                Layout.fillHeight: true
                color: root.cAccent
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
                        color: root.cAccent
                        Layout.preferredWidth: face.detailPx * 1.2
                        Layout.preferredHeight: face.detailPx * 1.2
                    }
                }
                DetailText { text: "Feels like: " + Math.round(root.feels) + root.unitSymbol }
                DetailText { text: "Humidity: " + root.humidity + "%" }
            }
        }

        // the chosen face, scaled down when it would not fit (long dates, big fonts)
        Item {
            id: stage
            x: face.pad
            y: face.pad
            width: face.cw
            height: face.ch

            layer.enabled: root.cfg.glowEnabled || root.style.textShadow > 0
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: root.cfg.glowEnabled ? root.cfg.glowColor : "black"
                shadowOpacity: root.cfg.glowEnabled ? root.cfg.glowStrength / 100 : root.style.textShadow
                shadowBlur: root.cfg.glowEnabled ? 1.0 : 0.5
                shadowHorizontalOffset: 0
                shadowVerticalOffset: root.cfg.glowEnabled ? 0 : 1
                blurMax: root.cfg.glowEnabled ? 48 : 16
            }

            Loader {
                id: faceLoader
                readonly property real fit: !item ? 1
                    : Math.min(1, stage.width / Math.max(1, item.implicitWidth), stage.height / Math.max(1, item.implicitHeight))
                anchors.verticalCenter: parent.verticalCenter
                // classic follows the alignment setting, the other faces are centered
                x: root.cfg.face !== 0 || root.cfg.alignment === 1 ? (stage.width - width) / 2
                 : root.cfg.alignment === 0 ? 0 : stage.width - width
                width: item ? item.implicitWidth : 0
                height: item ? item.implicitHeight : 0
                scale: root.cfg.fitToWidget ? fit : 1
                transformOrigin: root.cfg.face !== 0 || root.cfg.alignment === 1 ? Item.Center
                               : root.cfg.alignment === 0 ? Item.Left : Item.Right
                sourceComponent: [classicFace, stackedFace, weekdayFace, compactFace, analogFace, minimalFace][root.cfg.face] ?? classicFace
            }
        }

        // ---- 0: classic: weekday, time, date and weather -------------------
        Component {
            id: classicFace
            ColumnLayout {
                id: block
                spacing: 0

                // weekday
                Text {
                    visible: root.cfg.showDay
                    Layout.alignment: face.hAlign
                    text: root.upper(root.fmt(root.cfg.dayFormat), root.cfg.dayUppercase)
                    color: root.cDay
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
                            text: root.timeText()
                            color: root.cTime
                            font.family: root.cfg.timeFont
                            font.weight: root.cfg.timeWeight
                            font.pixelSize: face.timePx
                            font.features: { "tnum": 1 }
                        }
                        Text {
                            visible: root.use12h
                            Layout.alignment: Qt.AlignBaseline
                            text: root.ampmText()
                            color: root.cAmpm
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
                        text: root.upper(root.fmt(root.cfg.dateFormat), root.cfg.dateUppercase)
                        color: root.cDate
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

                SecondsBar {
                    visible: root.cfg.showSecondsBar
                    Layout.alignment: face.hAlign
                    Layout.topMargin: face.u * 0.05
                    Layout.preferredWidth: face.u * 1.4
                }
            }
        }

        // optional seconds bar
        component SecondsBar: Rectangle {
            Layout.preferredHeight: Math.max(2, face.u * 0.008)
            radius: height / 2
            color: Qt.darker(root.cAccent, 3.5)

            Rectangle {
                width: parent.width * (root.now.getSeconds() + 1) / 60
                height: parent.height
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.cAccent }
                    GradientStop { position: 1.0; color: root.cAmpm }
                }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }

        // the faces below size from the smaller side, so they work in any widget shape
        readonly property real s: Math.min(cw, ch)

        // ---- 1: stacked: hours over minutes, date on the side --------------
        Component {
            id: stackedFace
            RowLayout {
                spacing: face.s * 0.06
                ColumnLayout {
                    spacing: -face.s * 0.12
                    Repeater {
                        model: [root.hourText(true), root.fmt("mm")]
                        Text {
                            required property string modelData
                            required property int index
                            text: modelData
                            color: index === 0 ? root.cTime : Qt.alpha(root.cTime, 0.55)
                            font.family: root.cfg.timeFont
                            font.weight: index === 0 ? root.cfg.timeWeight : Math.max(100, root.cfg.timeWeight - 400)
                            font.pixelSize: face.s * 0.46 * root.cfg.timeSize / 100
                            font.features: { "tnum": 1 }
                        }
                    }
                }
                ColumnLayout {
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: face.s * 0.08
                    spacing: face.s * 0.01
                    Text {
                        visible: root.use12h
                        text: root.ampmText()
                        color: root.cAmpm
                        font.family: root.cfg.timeFont
                        font.weight: root.cfg.timeWeight
                        font.pixelSize: face.s * 0.07
                    }
                    Text {
                        visible: root.cfg.showDay
                        text: root.fmt("ddd").toUpperCase()
                        color: root.cDay
                        font.family: root.cfg.dayFont
                        font.weight: root.cfg.dayWeight
                        font.pixelSize: face.s * 0.065
                        font.letterSpacing: face.s * 0.01
                    }
                    Text {
                        visible: root.cfg.showDate
                        text: root.fmt("d")
                        color: root.cTime
                        font.family: root.cfg.dateFont
                        font.weight: root.cfg.dateWeight
                        font.pixelSize: face.s * 0.13
                    }
                    Text {
                        visible: root.cfg.showDate
                        text: root.fmt("MMM").toUpperCase()
                        color: root.cDate
                        font.family: root.cfg.dateFont
                        font.weight: root.cfg.dateWeight
                        font.pixelSize: face.s * 0.065
                    }
                    Text {
                        visible: root.cfg.showWeather && root.weatherOk
                        Layout.topMargin: face.s * 0.03
                        text: Math.round(root.temp) + "°"
                        color: root.cAccent
                        font.family: root.cfg.detailFont
                        font.weight: root.cfg.detailWeight
                        font.pixelSize: face.s * 0.08
                    }
                }
            }
        }

        // ---- 2: weekday card: date and week on top, big weekday, day count -----
        Component {
            id: weekdayFace
            ColumnLayout {
                readonly property real h: Math.min(face.ch, face.cw * 0.52)
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.fmt("dd.MM.yyyy")
                        color: root.cDetail
                        font.family: root.cfg.detailFont
                        font.weight: root.cfg.detailWeight
                        font.pixelSize: parent.parent.h * 0.075
                        font.letterSpacing: parent.parent.h * 0.012
                    }
                    Text {
                        text: "WEEK " + root.weekNumber
                        color: root.cDetail
                        font.family: root.cfg.detailFont
                        font.weight: root.cfg.detailWeight
                        font.pixelSize: parent.parent.h * 0.075
                        font.letterSpacing: parent.parent.h * 0.012
                    }
                }
                Text {
                    text: root.upper(root.fmt(root.cfg.dayFormat), false)
                    color: root.cTime
                    font.family: root.cfg.dayFont
                    font.weight: Math.max(root.cfg.dayWeight, 700)
                    font.pixelSize: parent.h * 0.42 * root.cfg.daySize / 100
                    font.letterSpacing: -parent.h * 0.01
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.fmt("d MMMM")
                        color: root.cAccent
                        font.family: root.cfg.dateFont
                        font.weight: root.cfg.dateWeight
                        font.italic: true
                        font.pixelSize: parent.parent.h * 0.11 * root.cfg.dateSize / 100
                    }
                    Text {
                        Layout.alignment: Qt.AlignBottom
                        text: root.dayOfYear + "/" + root.daysInYear
                        color: root.cDetail
                        font.family: root.cfg.detailFont
                        font.weight: root.cfg.detailWeight
                        font.pixelSize: parent.parent.h * 0.07
                        font.features: { "tnum": 1 }
                    }
                }
                SecondsBar {
                    visible: root.cfg.showSecondsBar
                    Layout.fillWidth: true
                    Layout.topMargin: parent.h * 0.04
                }
            }
        }

        // ---- 3: compact card: place, time, month / day, weather ----------------
        Component {
            id: compactFace
            ColumnLayout {
                readonly property real h: Math.min(face.ch, face.cw * 0.95)
                spacing: h * 0.01
                RowLayout {
                    visible: root.cfg.showWeather
                    spacing: parent.h * 0.025
                    Kirigami.Icon {
                        source: "mark-location"
                        fallback: "folder-location"
                        isMask: true
                        color: root.cDetail
                        Layout.preferredWidth: parent.parent.h * 0.075
                        Layout.preferredHeight: parent.parent.h * 0.075
                    }
                    Text {
                        text: root.cfg.cityName
                        color: root.cDetail
                        font.family: root.cfg.detailFont
                        font.weight: root.cfg.detailWeight
                        font.pixelSize: parent.parent.h * 0.07
                    }
                }
                RowLayout {
                    spacing: parent.h * 0.02
                    Text {
                        text: root.timeText()
                        color: root.cTime
                        font.family: root.cfg.timeFont
                        font.weight: root.cfg.timeWeight
                        font.pixelSize: parent.parent.h * 0.26 * root.cfg.timeSize / 100
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        visible: root.use12h
                        Layout.alignment: Qt.AlignBaseline
                        text: root.ampmText()
                        color: root.cAmpm
                        font.family: root.cfg.timeFont
                        font.weight: root.cfg.timeWeight
                        font.pixelSize: parent.parent.h * 0.08
                    }
                }
                RowLayout {
                    visible: root.cfg.showDate
                    spacing: parent.h * 0.02
                    Text {
                        text: root.fmt("MMM").toUpperCase() + " / " + root.fmt("d")
                        color: root.cTime
                        font.family: root.cfg.dateFont
                        font.weight: root.cfg.dateWeight
                        font.pixelSize: parent.parent.h * 0.2 * root.cfg.dateSize / 100
                    }
                    Text {
                        visible: root.cfg.showDay
                        Layout.alignment: Qt.AlignBaseline
                        text: root.fmt("ddd").toUpperCase()
                        color: root.cDay
                        font.family: root.cfg.dayFont
                        font.weight: root.cfg.dayWeight
                        font.pixelSize: parent.parent.h * 0.08
                    }
                }
                RowLayout {
                    visible: root.cfg.showWeather && root.weatherOk
                    spacing: parent.h * 0.03
                    Text {
                        text: Math.round(root.temp) + "°"
                        color: root.cTime
                        font.family: root.cfg.detailFont
                        font.weight: Math.max(root.cfg.detailWeight, 600)
                        font.pixelSize: parent.parent.h * 0.17
                    }
                    Kirigami.Icon {
                        source: root.describe(root.code, root.isDay)[1]
                        Layout.preferredWidth: parent.parent.h * 0.15
                        Layout.preferredHeight: parent.parent.h * 0.15
                    }
                }
            }
        }

        // ---- 4: analog -------------------------------------------------------
        Component {
            id: analogFace
            Item {
                id: dial
                readonly property real d: Math.min(face.cw, face.ch)
                implicitWidth: d
                implicitHeight: d
                readonly property real hourAngle: (root.now.getHours() % 12 + root.now.getMinutes() / 60) * 30
                readonly property real minuteAngle: (root.now.getMinutes() + root.now.getSeconds() / 60) * 6
                readonly property real secondAngle: root.now.getSeconds() * 6

                // minute ticks, longer every five minutes
                Repeater {
                    model: 60
                    Item {
                        required property int index
                        anchors.fill: parent
                        rotation: index * 6
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: dial.d * 0.02
                            width: index % 5 === 0 ? Math.max(2, dial.d * 0.012) : Math.max(1, dial.d * 0.005)
                            height: index % 5 === 0 ? dial.d * 0.05 : dial.d * 0.025
                            radius: width / 2
                            color: index % 5 === 0 ? root.cTime : Qt.alpha(root.cTime, 0.45)
                        }
                    }
                }
                // numerals
                Repeater {
                    model: 12
                    Text {
                        required property int index
                        readonly property real a: (index + 1) * 30 * Math.PI / 180
                        x: dial.d / 2 + Math.sin(a) * dial.d * 0.36 - width / 2
                        y: dial.d / 2 - Math.cos(a) * dial.d * 0.36 - height / 2
                        text: index + 1
                        color: root.cTime
                        font.family: root.cfg.timeFont
                        font.weight: root.cfg.timeWeight
                        font.pixelSize: dial.d * 0.1
                    }
                }
                // weekday and date in the lower half
                Text {
                    visible: root.cfg.showDate
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: dial.d * 0.64
                    text: root.fmt("ddd").toUpperCase() + " " + root.fmt("d")
                    color: root.cAmpm
                    font.family: root.cfg.dateFont
                    font.weight: root.cfg.dateWeight
                    font.pixelSize: dial.d * 0.06
                }
                component Hand: Rectangle {
                    property real handAngle
                    property real length
                    x: dial.d / 2 - width / 2
                    y: dial.d / 2 - length
                    height: length + dial.d * 0.04
                    radius: width / 2
                    antialiasing: true
                    transform: Rotation { origin.x: width / 2; origin.y: length; angle: handAngle }
                }
                Hand { handAngle: dial.hourAngle; length: dial.d * 0.24; width: dial.d * 0.035; color: root.cTime }
                Hand { handAngle: dial.minuteAngle; length: dial.d * 0.36; width: dial.d * 0.022; color: root.cTime }
                Hand {
                    visible: root.cfg.showSeconds
                    handAngle: dial.secondAngle
                    length: dial.d * 0.4
                    width: Math.max(1, dial.d * 0.008)
                    color: root.cAccent
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: dial.d * 0.05
                    height: width
                    radius: width / 2
                    color: root.cAccent
                }
            }
        }

        // ---- 5: minimal: time and one quiet line -----------------------------
        Component {
            id: minimalFace
            ColumnLayout {
                readonly property real h: Math.min(face.ch, face.cw * 0.45)
                spacing: 0
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: parent.h * 0.03
                    Text {
                        text: root.timeText()
                        color: root.cTime
                        font.family: root.cfg.timeFont
                        font.weight: Math.max(100, root.cfg.timeWeight - 400)
                        font.pixelSize: parent.parent.h * 0.62 * root.cfg.timeSize / 100
                        font.features: { "tnum": 1 }
                    }
                    Text {
                        visible: root.use12h
                        Layout.alignment: Qt.AlignBaseline
                        text: root.ampmText()
                        color: root.cAmpm
                        font.family: root.cfg.timeFont
                        font.weight: Math.max(100, root.cfg.timeWeight - 400)
                        font.pixelSize: parent.parent.h * 0.14
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: (root.cfg.showDay ? root.fmt("dddd") : "")
                        + (root.cfg.showDay && root.cfg.showDate ? "  ·  " : "")
                        + (root.cfg.showDate ? root.fmt("d MMMM") : "")
                        + (root.cfg.showWeather && root.weatherOk ? "  ·  " + Math.round(root.temp) + root.unitSymbol : "")
                    color: root.cDate
                    font.family: root.cfg.detailFont
                    font.weight: root.cfg.detailWeight
                    font.pixelSize: parent.h * 0.12
                    font.letterSpacing: parent.h * 0.01
                }
            }
        }
    }
}
