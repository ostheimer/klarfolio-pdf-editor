# Windows-Roadmap

## Entscheidung

Die Windows-App soll im selben Repository entstehen. Die vorhandene macOS-Struktur bleibt dabei unangetastet; Windows wird als eigenständige Plattformanwendung mit gemeinsam genutzten Produktspezifikationen und Test-Fixtures ergänzt.

Vorgesehene Struktur:

```text
Klarfolio repository
├── Sources/                         macOS-App (SwiftUI/AppKit/PDFKit)
├── Tests/                           macOS-Tests
├── Windows/
│   ├── src/Klarfolio.Windows/       Windows-App
│   ├── tests/Klarfolio.Windows.Tests/
│   └── README.md
├── TestFixtures/                    plattformübergreifende PDF-Fixtures
└── docs/
```

Ein späterer Umbau des macOS-Quellbaums ist dafür nicht erforderlich.

## Technische Leitplanken

- Die Windows-App ist kein direkter Port: SwiftUI, AppKit und PDFKit stehen dort nicht als gleichwertiger Stack zur Verfügung.
- Vorläufige Zielrichtung ist eine native C#-Desktop-App mit Windows App SDK und WinUI 3.
- Die PDF-Engine wird erst nach einem isolierten technischen Spike ausgewählt.
- Engine-Kandidaten müssen Rendering, Textsuche, Seitenoperationen, Annotationen, verlustfreies Speichern, x64/ARM64, Lizenzverträglichkeit und Wartbarkeit nachweisen.
- GPL-/AGPL-, kommerzielle und proprietäre Lizenzfolgen werden vor jeder Einbindung dokumentiert.
- Windows-Code wird auf einem Windows-GitHub-Actions-Runner und später auf realer Windows-Hardware gebaut und getestet; ein Mac kann WinUI nicht vollständig verifizieren.
- Produktverhalten und PDF-Fixtures sollen plattformübergreifend vergleichbar sein, die Benutzeroberflächen bleiben nativ.

## Phasen

### W0 – Fundament und Machbarkeit

1. Windows-Projektstruktur und Build-Pipeline anlegen.
2. PDF-Engine-Kandidaten mit einer festen Fixture-Suite vergleichen.
3. Spike für Öffnen, Rendern, Textsuche, eine Annotation und verlustfreies Speichern erstellen.
4. Lizenz-, Sicherheits-, Performance- und Paketierungsentscheidung dokumentieren.
5. Windows 11 x64 als erste unterstützte Zielplattform festlegen; ARM64 separat entscheiden.

### W1 – Kleines Windows-MVP

- PDF öffnen, anzeigen, durchsuchen und speichern
- Seiten drehen, verschieben, löschen, extrahieren, teilen und zusammenführen
- Grundlegende Annotationen und Web-/Seitenlinks
- lokale Verarbeitung ohne Konto
- Installer beziehungsweise MSIX, App-Icon und Dateizuordnung
- automatisierte Kern- und Fixture-Tests

### W2 – Parität und Differenzierung

- Formular-Workflow
- Zuschneiden
- sichere Schwärzung
- OCR und Konvertierung nach gesonderter Engine-/Lizenzentscheidung
- plattformspezifische Explorer-Integration und Batch-Workflows

## Go-/No-Go für die Vollentwicklung

Der Spike darf beginnen. Ein vollständiges Windows-Produkt wird erst priorisiert, wenn:

- wiederholt derselbe relevante Windows-Workflow genannt wird,
- konkrete Zahlungs- oder Pilotbereitschaft vorliegt,
- die Engine-Fixtures ohne Datenverlust bestehen,
- Lizenz und laufende Wartung wirtschaftlich tragbar sind,
- die zusätzliche Support- und Release-Pipeline realistisch betreut werden kann.

Die offenen Umsetzungsarbeiten werden im zentralen GitHub-Roadmap-Issue gepflegt.
