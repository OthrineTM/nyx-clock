import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "Layout & Format"
        icon: "preferences-desktop-display"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: "Fonts & Sizes"
        icon: "preferences-desktop-font"
        source: "configFonts.qml"
    }
    ConfigCategory {
        name: "Colors & Glow"
        icon: "preferences-desktop-color"
        source: "configColors.qml"
    }
    ConfigCategory {
        name: "Style"
        icon: "preferences-desktop-theme"
        source: "configStyle.qml"
    }
    ConfigCategory {
        name: "Weather"
        icon: "weather-few-clouds"
        source: "configWeather.qml"
    }
}
