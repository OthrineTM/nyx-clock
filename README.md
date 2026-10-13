# Nyx Clock

A customizable desktop clock for KDE Plasma 6, with weekday, date and weather.

![Nyx Clock on a purple wallpaper with weekday, time, date and weather](screenshots/clock.png)

## Features

- **Layout & Format:**
  - choose the layout and alignment
  - 12 or 24 hour time, optional seconds, optional seconds progress bar
  - custom weekday and date formats, UPPERCASE switches, and a language (locale) option
- **Fonts & Sizes:** font family, weight (100–900) and size for each part (weekday, time, date, details). Resize the widget to scale everything at once.
- **Colors & Glow:** a color for each part, an accent color, an adjustable glow, and ready-made color presets. The default is a violet theme.
- **Weather:** current conditions, "feels like" and humidity from [Open-Meteo](https://open-meteo.com). It's free, with no account or API key. Search for your city in the settings. The default city is London.

## Fonts

The default fonts are [Orbitron](https://fonts.google.com/specimen/Orbitron), [Quicksand](https://fonts.google.com/specimen/Quicksand) and [Audiowide](https://fonts.google.com/specimen/Audiowide), all free under the OFL. Install them for the default look, or pick any installed font in **Fonts & Sizes**.

## Install

```bash
git clone https://github.com/OthrineTM/nyx-clock.git
kpackagetool6 --type Plasma/Applet --install nyx-clock/package
```

Then right-click your desktop → **Add or Manage Widgets…**, search for **Nyx Clock**, and drag it onto the desktop. Right-click the clock → **Configure Nyx Clock…** to set your city.

**Update:** `git pull`, then `kpackagetool6 --type Plasma/Applet --upgrade nyx-clock/package`, then `systemctl --user restart plasma-plasmashell`.

**Remove:** `kpackagetool6 --type Plasma/Applet --remove io.github.othrinetm.nyxclock`

## License

GPL-3.0-or-later. See [LICENSE](LICENSE). Weather data by [Open-Meteo.com](https://open-meteo.com) (CC BY 4.0).
