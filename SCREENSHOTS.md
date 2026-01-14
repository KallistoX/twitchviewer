# Screenshot Workflow

Dieses Dokument beschreibt, wie du Screenshots von deinem Ubuntu Touch Gerät in dieses Repository übertragen kannst.

## Voraussetzungen

- Ubuntu Touch Gerät mit USB-Debugging aktiviert
- ADB (Android Debug Bridge) installiert
- Gerät per USB verbunden
- Clickable installiert (`pip3 install --user clickable-ut`)

## Screenshots vom Gerät holen

### 1. Gerät verbinden und prüfen

```bash
# Prüfe ob das Gerät verbunden ist
adb devices

# Sollte ausgeben:
# List of devices attached
# (no serial number)    device
```

### 2. Screenshots auf dem Gerät erstellen

Auf Ubuntu Touch werden Screenshots standardmäßig hier gespeichert:
```
/home/phablet/Pictures/Screenshots/
```

Screenshot erstellen: Gleichzeitiges Drücken von **Volume Down + Power Button**

### 3. Screenshots auf den Computer übertragen

```bash
# Alle Screenshots übertragen
adb pull /home/phablet/Pictures/Screenshots/ screenshots/

# Oder nur einen spezifischen Screenshot
adb pull /home/phablet/Pictures/Screenshots/screenshot20260114_190118833.png screenshots/
```

### 4. Screenshots umbenennen

Benenne die Screenshots sinnvoll um, damit sie in der README gut aussehen:

```bash
cd screenshots/

# Beispiele:
mv screenshot20260114_190118833.png 01_browse_streams.png
mv screenshot20260114_190210740.png 02_categories.png
mv screenshot20260114_190232528.png 03_player_quality.png
```

### 5. Screenshots in README einbinden

Die Screenshots sind bereits in der [README.md](README.md) unter der Sektion "Screenshots" eingebunden.

Wenn du neue Screenshots hinzufügst, erweitere die Tabelle entsprechend.

## Alternative: Mit Clickable Shell

```bash
# Shell auf dem Gerät öffnen
clickable shell

# Screenshots auflisten
ls -la /home/phablet/Pictures/Screenshots/

# In einem anderen Terminal die Dateien ziehen
adb pull /home/phablet/Pictures/Screenshots/ screenshots/
```

## Screenshots löschen (optional)

Wenn du die Screenshots vom Gerät entfernen möchtest:

```bash
# Alle Screenshots löschen
adb shell "rm /home/phablet/Pictures/Screenshots/*"

# Oder nur einen spezifischen
adb shell "rm /home/phablet/Pictures/Screenshots/screenshot20260114_190118833.png"
```

## Für OpenStore

Für den OpenStore werden Screenshots separat im OpenStore-Dashboard hochgeladen:

1. Gehe zu https://open-store.io/
2. Melde dich an
3. Öffne deine App
4. Lade Screenshots im Bereich "Screenshots" hoch

**OpenStore Anforderungen:**
- Format: PNG oder JPG
- Empfohlene Größe: 1200x900 oder größer
- Maximal 5 Screenshots
- Screenshots sollten die Hauptfeatures der App zeigen

## Tipps

- Stelle sicher, dass die Screenshots keine persönlichen Daten zeigen
- Verwende Dark Mode oder Light Mode konsistent
- Zeige die wichtigsten Features der App
- Landscape und Portrait Orientierung beide zeigen
- Screenshots sollten aktuell sein und die neueste Version zeigen

## Troubleshooting

### "device not found"
```bash
# Prüfe USB-Verbindung und aktiviere USB-Debugging auf dem Gerät
adb devices
```

### "Permission denied"
```bash
# Starte ADB-Server neu
adb kill-server
adb start-server
```

### Screenshots sind zu groß für Git
```bash
# Komprimiere PNG-Dateien (optional)
pngquant --quality=80-90 screenshots/*.png
```
