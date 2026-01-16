# TwitchViewer - Projekt-Richtlinien für Claude Code

## Branch-Strategie

### Hauptregel
- **Main Branch ist immer stabil und produktionsreif**
- Alle neuen Features und Änderungen werden in separaten Feature-Branches entwickelt
- Keine direkte Entwicklung auf dem Main Branch

### Branch-Naming
- Feature-Branches: `feature/feature-name`
- Bugfixes: `fix/bug-description`
- Beispiele:
  - `feature/chat-integration`
  - `fix/player-crash`

### Workflow
1. Neue Features immer in Feature-Branch entwickeln
2. Nach Fertigstellung PR gegen Main erstellen
3. Main Branch nur nach vollständiger Implementierung und Tests mergen

## Projekt-Kontext

### Technologie-Stack
- **Plattform:** Ubuntu Touch (Clickable Framework)
- **UI:** QML (Qt Quick)
- **Backend:** C++ (Qt)
- **API:** Twitch GraphQL API
- **Build-System:** CMake

### Sensible Dateien
- `config.cpp` enthält API-Schlüssel und sensible Daten
- Diese Datei ist in `.gitignore` und `.claudeignore` aufgeführt
- **Niemals** auf diese Datei zugreifen oder Änderungen vorschlagen

## Code-Stil & Best Practices

### QML
- Konsistente Einrückung (4 Spaces)
- Property-Bindings bevorzugen
- Signal-Handler klar benennen

### C++
- Qt-Konventionen folgen
- RAII-Prinzip beachten
- Smart Pointers verwenden wo möglich

## Testing & Qualität
- Bei neuen Features: Manuelle Tests auf Ubuntu Touch empfehlen
- Breaking Changes vermeiden
- Backward-Kompatibilität beachten

## Weitere Hinweise
- Bei Unsicherheiten nachfragen
- Dokumentation aktuell halten
- Commit-Messages auf Deutsch oder Englisch (konsistent bleiben)
