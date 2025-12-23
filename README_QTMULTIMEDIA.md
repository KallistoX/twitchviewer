# TwitchViewer - QtMultimedia Version

## Aktuelle Implementation

**Video Backend: QtMultimedia 5.8**
- Nutzt Qt's eingebauten Video-Player
- Basiert auf GStreamer für Video-Dekodierung
- Direkt in QML verfügbar (kein C++ Plugin nötig)

---

## Schnellstart

### 1. Dateien ersetzen
```bash
# Im Projekt-Verzeichnis
rm -rf plugins/Example

# Neue Dateien kopieren
cp qtmultimedia-version/CMakeLists.txt .
cp qtmultimedia-version/qml/Main.qml qml/
cp qtmultimedia-version/snapcraft.yaml .
```

### 2. Build & Deploy
```bash
clickable clean
clickable build
clickable install
clickable logs
```

### 3. Testen
1. App öffnen
2. Test-URL eingeben:
   ```
   http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
   ```
3. Play drücken

---

## Features

### ✅ Funktioniert
- Video-Wiedergabe (MP4, WebM, etc.)
- Play/Pause/Stop Controls
- Status-Anzeige (Playing, Paused, Loading)
- Error Handling
- URL-Eingabe mit Enter-Unterstützung

### ⏳ Noch nicht implementiert
- Twitch-URL → Stream-URL Konvertierung
- Qualitätsauswahl
- Live-Chat
- OAuth Login

---

## Performance-Erwartung

**QtMultimedia + GStreamer:**
- ✅ Gut für: Standard-Videos, 720p Streams
- ⚠️  Limitiert bei: 1080p60 High-Bitrate Streams
- Hardware-Dekodierung: Abhängig von GStreamer-Plugins

**Wenn Performance nicht ausreicht → Upgrade auf MPV** (siehe unten)

---

## Upgrade-Pfad: QtMultimedia → MPV

### Warum MPV?
- Bessere Performance (besonders bei High-Bitrate Streams)
- Native Hardware-Dekodierung
- Optimiert für Streaming

### Aufwand für Upgrade
**Stufe 1: MPV mit statischem Build** (~2-4 Stunden)
- libmpv als static library kompilieren
- Cross-compile für ARM64
- In Clickable Build einbinden
- C++ Wrapper implementieren (ähnlich wie schon vorbereitet)

**QML bleibt identisch!** Die gleichen Properties funktionieren:
```qml
VideoPlayer {
    source: "..."
    play() / pause() / stop()
}
```

### Wann upgraden?
Teste erstmal mit QtMultimedia:
- ✅ Funktioniert gut → Bleib dabei
- ❌ Ruckelt bei Streams → Upgrade auf MPV
- ❌ Hohe CPU-Last → Upgrade auf MPV

---

## Bekannte Limitierungen (QtMultimedia)

1. **HLS Streams (m3u8)**
   - Funktioniert mit GStreamer 1.0-plugins-bad
   - Bereits in snapcraft.yaml enthalten

2. **Hardware-Beschleunigung**
   - Abhängig von verfügbaren GStreamer vaapi/v4l2 Plugins
   - Auf manchen Geräten nicht optimal

3. **Twitch-URLs**
   - Direkte Twitch-URLs funktionieren NICHT
   - Brauchen streamlink/youtube-dl für URL-Extraktion
   - Kommt in Phase 2

---

## Nächste Schritte (Entwicklungs-Roadmap)

### Phase 1: Video-Wiedergabe (✅ AKTUELL)
- [x] Basic Video Player UI
- [x] Play/Pause/Stop Controls
- [ ] Testen mit direkten Video-URLs

### Phase 2: Twitch-Integration
- [ ] Streamlink Integration (URL-Extraktion)
- [ ] Qualitätsauswahl (1080p, 720p, etc.)
- [ ] Hardcoded Channel-Liste zum Testen

### Phase 3: Full Twitch Features
- [ ] OAuth Login
- [ ] Followed Channels API
- [ ] Live-Status Anzeige
- [ ] (Optional) Chat Integration

### Phase 4: Performance (Falls nötig)
- [ ] MPV Static Build
- [ ] Hardware-Dekodierung optimieren

---

## Troubleshooting

### Build-Fehler
**"Qt5Multimedia not found"**
→ Sollte nicht passieren, da qtmultimedia5-dev in build-packages ist

### Runtime-Fehler
**"Video error: Resource Error"**
→ URL nicht erreichbar oder ungültiges Format

**"Video error: Format Error"**
→ GStreamer-Codec fehlt, prüfe gstreamer-plugins

**Schwarzer Bildschirm**
→ Prüfe `clickable logs` für Fehler

### Performance-Probleme
**Video ruckelt**
→ Evtl. zu hohe Bitrate, teste niedrigere Qualität

**Hohe CPU-Last**
→ Hardware-Dekodierung nicht aktiv, erwäge MPV-Upgrade

---

## Technische Details

### Video-Backend
```
QtMultimedia.Video (QML)
    ↓
Qt5::Multimedia (C++)
    ↓
GStreamer 1.0
    ↓
Hardware (v4l2) oder Software (libav)
```

### QML API
```qml
Video {
    source: string           // URL zum Video
    autoPlay: bool          // Auto-start
    playbackState: enum     // PlayingState, PausedState, StoppedState
    status: enum            // NoMedia, Loading, Loaded, Buffering, etc.
    
    // Signals
    onError(error, errorString)
    onStatusChanged()
    
    // Methods
    play()
    pause()
    stop()
}
```

### Unterstützte Formate
- **Container**: MP4, WebM, MKV, AVI, MOV
- **Video**: H.264, VP8, VP9, MPEG-4
- **Audio**: AAC, MP3, Vorbis, Opus
- **Streaming**: HTTP, HLS (m3u8)

---

## Credits

- **Qt Multimedia**: Qt Company
- **GStreamer**: GStreamer community
- **Ubuntu Touch**: UBports Foundation