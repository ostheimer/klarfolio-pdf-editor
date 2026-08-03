# Klarfolio PDF Editor

Klarfolio PDF Editor ist eine kostenlose, native macOS-App zum Erstellen, Anzeigen und Bearbeiten von PDF-Dateien.

## Ziel

Klarfolio PDF Editor soll ein schneller, kostenloser PDF-Reader und PDF-Editor für macOS werden. Der aktuelle Stand ist ein funktionales MVP mit Anzeige, Suche, Seitenverwaltung, PDF-Zusammenführung und grundlegenden Anmerkungswerkzeugen.

## Funktionen

- PDF öffnen, neu erstellen, speichern und unter neuem Namen sichern
- Seitenvorschau mit direkter Seitennavigation
- Leere Seiten einfügen, Seiten drehen, verschieben und löschen
- Bilder als PDF-Seiten importieren
- Mehrere PDFs zusammenführen
- Suche mit Treffer-Hervorhebung
- Textfelder, Notizen, Marker, Unterstreichungen, Durchstreichungen, Stempel und Signaturfelder
- Zoom, Fensteranpassung und verschiedene Seitenlayouts

Eine ausführliche Featurebeschreibung liegt in [docs/external/features.md](docs/external/features.md).

## Ausführen

```bash
./script/build_and_run.sh
```

Die Codex-App kann dieselbe Aktion über den lokalen `Run`-Button starten.

## App-Icon

Das App-Icon liegt unter `Sources/KlarfolioPDFEditor/Resources/AppIcon.icns`. Die PNG-Vorschau
und die `.icns`-Datei können bei Bedarf neu erzeugt werden:

```bash
swift script/generate_app_icon.swift
```

## App-Store-Paket

Die App kann als sandboxed macOS-Bundle gebaut werden. Für ein Mac-App-Store-Paket
werden Apple Distribution-Zertifikate benötigt:

```bash
APP_STORE_APP_IDENTITY="3rd Party Mac Developer Application: Example Team" \
APP_STORE_INSTALLER_IDENTITY="3rd Party Mac Developer Installer: Example Team" \
./script/package_app_store.sh
```

Weitere Release-Notizen liegen in
[docs/internal/app-store-release.md](docs/internal/app-store-release.md).

## Dokumentation

- [Nutzerhandbuch](docs/external/user-guide.md)
- [Featureübersicht](docs/external/features.md)
- [Interne Architektur](docs/internal/architecture.md)
- [Einordnung gegenüber PDF Expert](docs/internal/pdf-expert-positioning.md)
- [Domainentscheidung](docs/internal/domain-decision.md)
- [HTML-Website](website/index.html)

## Status

Die App ist aktuell bewusst lokal, nativ und einfach gehalten. Nicht enthalten sind derzeit OCR, echte Bearbeitung vorhandener PDF-Texte, Formularfeld-Authoring, digitale Zertifikatssignaturen, Schwärzung, Komprimierung, Export nach Office-Formaten und KI-Funktionen.
