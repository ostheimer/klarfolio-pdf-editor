# Klarfolio PDF Editor

Klarfolio PDF Editor ist eine kostenlose, native macOS-App zum Erstellen, Anzeigen und Bearbeiten von PDF-Dateien.

## Ziel

Klarfolio PDF Editor soll ein schneller, kostenloser PDF-Reader und PDF-Editor für macOS werden. Der aktuelle Stand ist ein funktionales MVP mit Anzeige, Suche, Seitenverwaltung, PDF-Zusammenführung und grundlegenden Anmerkungswerkzeugen.

## Funktionen

- Ablenkungsarmer Lesemodus bei jedem App-Start und beim Öffnen jeder vorhandenen PDF
- Schreibgeschützter Lesemodus und Sicherheitsabfrage vor dem Verwerfen ungespeicherter Änderungen
- Passwortgeschützte PDFs verdeckt entsperren; zentrale PDF-Rechte und konservativer Schreibschutz für verschlüsselte und digital signierte Originale
- Kompaktes PDF-Inhaltsverzeichnis mit verschachtelten Kapiteln und direktem Seitenansprung
- Persönliche lokale Seiten-Lesezeichen und dokumentbezogen gemerkte Leseposition
- PDF-Dateien und Bildseiten per sicherem Drag-and-drop öffnen beziehungsweise importieren
- Vorhandene PDF-Textfelder und Checkboxen im Bearbeitungsmodus sicher ausfüllen und speichern
- PDF öffnen, neu erstellen, speichern und unter neuem Namen sichern
- Seitenvorschau mit direkter Seitennavigation
- Leere Seiten einfügen, Seiten drehen, verschieben und löschen
- Aktuelle Seite visuell zuschneiden und auf die volle Seitengröße zurücksetzen; Zuschneiden blendet Inhalte nur aus und ist keine sichere Schwärzung
- Bilder als PDF-Seiten importieren
- Mehrere PDFs zusammenführen
- Suche mit Treffer-Hervorhebung
- Textfelder, Notizen, Marker, Unterstreichungen, Durchstreichungen, Stempel und Signaturfelder
- Nicht-interaktive Anmerkungen auswählen, verschieben, bearbeiten und gezielt löschen
- Web- und interne Seitenlinks als PDF-Anmerkungen anlegen
- Seitenbereiche in neue PDFs extrahieren und Dokumente nach der aktuellen Seite teilen
- Zoom, Fensteranpassung und verschiedene Seitenlayouts

Eine ausführliche Featurebeschreibung liegt in [docs/external/features.md](docs/external/features.md).

## Ausführen

```bash
./script/build_and_run.sh
```

Die Codex-App kann dieselbe Aktion über den lokalen `Run`-Button starten.
Das Paket setzt Swift 6 beziehungsweise Xcode 16 oder neuer voraus; der App-Deployment-Target bleibt macOS 14.

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
- [Lokale Entwicklung und Installation](docs/internal/local-development.md)
- [Datenschutzhinweis (Entwurf vor Veröffentlichung)](docs/external/privacy.md)
- [Interne Architektur](docs/internal/architecture.md)
- [Einordnung gegenüber PDF Expert](docs/internal/pdf-expert-positioning.md)
- [Windows-Roadmap für eine spätere Plattformentscheidung](docs/internal/windows-roadmap.md)
- [Domainentscheidung](docs/internal/domain-decision.md)
- [Manueller QA-Katalog](docs/internal/manual-qa.md)
- [Versionierte PDF-Testdateien und ihre Herkunft](TestFixtures/README.md)
- [App-Store-Metadaten](docs/internal/app-store-metadata.md)
- [HTML-Website](website/index.html)

## Status

Der lokale Schutz-Slice (#22) erweitert die Crop-Basis auf 151 Tests in elf Suites, 14 synthetische Fixtures und QA-01 bis QA-106. Der echte macOS-Accessibility-Smoke umfasst 105 erfolgreiche Prüfungen. Passwortöffnung und durchgängige PDF-Rechte sind umgesetzt; verschlüsselte und digital signierte PDFs bleiben begründet schreibgeschützt. Nachweise und Grenzen stehen im [Schutz-QA-Protokoll](docs/internal/protected-pdf-qa.md), die vorherige Crop-Basis im [Crop-QA-Protokoll](docs/internal/crop-qa.md). Ein CI-Skip zählt nicht als echter UI-Pass.

Die dokumentierte P1-Phase ist funktional abgeschlossen; sicherer Drag-and-drop, vorhandene PDF-Formulare und eine komfortable Reader-Navigation erweitern den lokalen P2-Funktionsumfang. Aktuell liegt der Schwerpunkt auf der sicheren praktischen Nutzung auf dem Mac: Jeder App-Start und jede erfolgreich geöffnete vorhandene PDF beginnen im schreibgeschützten Lesemodus, auch wenn zuvor bearbeitet wurde. Eine kompakte Navigationsschaltfläche öffnet bei Bedarf das PDF-Inhaltsverzeichnis und persönliche Seiten-Lesezeichen; die zuletzt gelesene Seite wird pro Dokument ausschließlich lokal wiederhergestellt. Lesezeichen verändern weder die PDF-Datei noch ihren Speicherstatus. Die Bearbeitungsoberfläche erscheint erst nach einer ausdrücklichen Auswahl; ein bewusst neu erstelltes PDF darf direkt zur Bearbeitung wechseln. Abgebrochene oder fehlgeschlagene Öffnungen verändern weder das bisherige Dokument noch seinen Modus. Auch ungespeicherte Formularänderungen bleiben vor unbeabsichtigtem Verwerfen geschützt. Versionierte synthetische PDF-Fixtures, Regressionstests und ein lokaler UI-Smoke begleiten diesen Entwicklungsstand. Eine öffentliche Veröffentlichung ist derzeit nicht vorgesehen; Apple-Signierung/App-Store-Einrichtung, vollständiger Release-QA-Nachweis sowie finale Betreiber-, Support-, Datenschutz- und HTTPS-Downloadangaben bleiben Voraussetzungen für einen späteren öffentlichen Start.

Die App bleibt bewusst lokal, nativ und einfach gehalten. Nicht enthalten sind derzeit OCR, echte Bearbeitung vorhandener PDF-Texte, das Erstellen neuer Formularfelder, digitale Zertifikatssignaturen, sichere Schwärzung, Komprimierung, Export nach Office-Formaten und KI-Funktionen.
