# OpenPDF

OpenPDF ist eine native macOS-App zum Erstellen, Anzeigen und Bearbeiten von PDF-Dateien.

## Ziel

OpenPDF soll ein schneller, nativer PDF-Reader und PDF-Editor für macOS werden. Der aktuelle Stand ist ein funktionales MVP mit Anzeige, Suche, Seitenverwaltung, PDF-Zusammenführung und grundlegenden Anmerkungswerkzeugen.

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

## Dokumentation

- [Nutzerhandbuch](docs/external/user-guide.md)
- [Featureübersicht](docs/external/features.md)
- [Interne Architektur](docs/internal/architecture.md)
- [Einordnung gegenüber PDF Expert](docs/internal/pdf-expert-positioning.md)
- [Domainentscheidung](docs/internal/domain-decision.md)
- [HTML-Website](website/index.html)

## Status

Die App ist aktuell bewusst lokal, nativ und einfach gehalten. Nicht enthalten sind derzeit OCR, echte Bearbeitung vorhandener PDF-Texte, Formularfeld-Authoring, digitale Zertifikatssignaturen, Schwärzung, Komprimierung, Export nach Office-Formaten und KI-Funktionen.
