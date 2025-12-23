# Ubuntu Touch Twitch Viewer - Projekt Status

## Aktueller Stand ✅

### Entwicklungsumgebung (macOS)
- **Clickable** installiert und funktionsfähig
- **VS-Code** Verwendet als IDE
- **Docker** als Build-Backend eingerichtet
- **Android Studio's ADB** konfiguriert (wichtig: nicht Homebrew ADB!)
- Tablet über USB verbunden mit `developer_mode` (nicht `mtp_adb`!)

### Tablet (Volla mit Ubuntu Touch)
- Developer Mode aktiviert
- ADB funktioniert (USB-Debugging authorized)
- Template App erfolgreich deployed und läuft
- `clickable logs` zeigt Live-Logs der App

### Projekt
- Template-Projekt "TwitchViewer" erstellt (QML app with C++ plugin)
- Erfolgreich gebaut und auf Tablet installiert
- App erscheint im App Drawer und startet

---

## Übergeordneter Plan 🎯

**Ziel:** Native Ubuntu Touch App für Twitch mit optimaler Performance

### Tech Stack:
- **C++ (Qt/QtNetwork)** → Twitch API, OAuth, JSON
- **QML** → UI (Stream-Liste, Navigation, Controls)  
- **libmpv** → Video Playback (ressourcenschonend, Hardware-Dekodierung)

### Features:
1. Twitch Login (OAuth)
2. Liste gefolgter Kanäle mit Live-Status
3. Stream-Qualitätsauswahl
4. Embedded Video Player
5. (Optional) Chat-Integration

---

## Nächster Schritt 🚀

**Projektstruktur aufsetzen:**
1. C++ Backend-Klasse für Twitch API erstellen
2. QML UI-Grundgerüst designen
3. libmpv in QML Item integrieren
4. OAuth Flow implementieren

**Fragen für den Start:**
- Hast du bereits einen Twitch Developer Account / Client ID? Ja
- Welche Features sind dir am wichtigsten (Reihenfolge)? Am wichtigsten ist mir, dass das Anschauen erstmal funktioniert. die komplexen Features mit Twitch login etc können dann später folgen. 
- Soll die App im Portrait oder Landscape Mode laufen? Die App soll maximale Kompabilität haben. Also Landscape, portrait, und auch egal ob das device ein Tablet, oder ein Handy ist

# TwitchViewer

A small App to view Twitch Streams

## License

Copyright (C) 2025  Dominic Bussemas

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3, as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranties of MERCHANTABILITY, SATISFACTORY
QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.
