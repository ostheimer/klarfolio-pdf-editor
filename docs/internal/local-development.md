# Lokale Entwicklung und Installation

Klarfolio kann auf demselben Mac als Entwicklungs-App genutzt und weiterentwickelt werden, ohne eine spätere App-Store-Installation zu überschreiben.

## Entwicklungs-App installieren

```bash
./script/install_local_dev.sh
```

Das Skript erstellt und startet standardmäßig:

- App: `~/Applications/Klarfolio PDF Editor Dev.app`
- Bundle-ID: `at.ostheimer.klarfoliopdf.debug`
- Konfiguration: `debug`
- Signatur: lokal/ad hoc

Die App wird beim erneuten Aufruf gezielt aktualisiert. Eine vorhandene App mit der Produktions-Bundle-ID `at.ostheimer.klarfoliopdf` bleibt unberührt.

Der Installationsordner kann bei Bedarf explizit überschrieben werden:

```bash
KLARFOLIO_LOCAL_APPLICATIONS_DIR="/vollständiger/pfad" ./script/install_local_dev.sh
```

## Direkt aus dem Repository arbeiten

Für den üblichen Entwicklungszyklus:

```bash
./script/build_and_run.sh --verify
```

Weitere Modi:

```bash
./script/build_and_run.sh --debug
./script/build_and_run.sh --logs
./script/build_and_run.sh --telemetry
```

Der lokale Repository-Build liegt unter `dist/Klarfolio PDF Editor.app` und verwendet ebenfalls die Debug-Bundle-ID.

## Tests

Unter vollständigem Xcode 16 oder neuer:

```bash
swift test --parallel
```

Wenn nur die Command Line Tools aktiv sind und Swift das Modul `Testing` nicht findet, kann der bereits validierte lokale Fallback verwendet werden:

```bash
swift test --disable-sandbox \
  -Xswiftc -F/Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath \
  -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath \
  -Xlinker /Library/Developer/CommandLineTools/Library/Developer/usr/lib
```

## Trennung der Builds

| Build | Bundle-ID | Zweck |
| --- | --- | --- |
| Lokale Entwicklungs-App | `at.ostheimer.klarfoliopdf.debug` | tägliche Nutzung und Entwicklung |
| Release/App Store | `at.ostheimer.klarfoliopdf` | signierte Veröffentlichung |

Eine lokale ad-hoc-Signatur ist nur für Entwicklung und persönliche Nutzung gedacht. Sie ersetzt keine Apple-Distribution-Signatur, Notarisierung oder App-Store-Prüfung.
