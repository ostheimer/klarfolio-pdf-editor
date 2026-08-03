# Einordnung gegenüber PDF Expert

Stand der Recherche: 2026-06-14.

Quellen:

- PDF Expert Produktseite deutsch: https://pdfexpert.com/de
- PDF Expert Featureseite: https://pdfexpert.com/features
- PDF Expert OCR-Seite deutsch: https://pdfexpert.com/de/features/ocr-pdf-mac
- PDF Expert Mac-Anleitungen deutsch: https://pdfexpert.com/de/how-to
- PDF Expert App-Store-Seite: https://apps.apple.com/de/app/pdf-expert-editor-converter/id743974925

## Kurzfazit

PDF Expert ist ein reifes, kommerzielles PDF-Produkt für Apple-Plattformen. Die öffentliche Produktkommunikation stellt Lesen, Anmerken, direkte PDF-Bearbeitung, Seitenorganisation, Konvertierung, OCR, Formulare, Signaturen, Schutzfunktionen, Komprimierung und KI-gestützte Dokumentarbeit heraus.

Klarfolio PDF Editor ist aktuell ein lokales macOS-MVP. Es deckt die Grundfläche `Lesen + Anmerken + Seitenorganisation` ab, hat aber noch keine tiefe Inhaltsbearbeitung, keine OCR, keine Konvertierung, keine Formular-Spezialfunktionen, keine sichere Schwärzung und keine KI-Funktionen.

## Featurematrix

| Bereich | PDF Expert laut öffentlicher Produktseiten | Klarfolio PDF Editor aktuell | Einordnung |
| --- | --- | --- | --- |
| PDF lesen | Mehrere Lese- und Ansichtsmodi, Tag/Nacht/Sepia, vertikales und horizontales Scrollen. | Native PDFKit-Anzeige, fortlaufend, Einzelseite, Doppelseite, Zoom. | Teilweise vergleichbar, aber ohne Lesethemen und Komfortmodi. |
| Suche | Suche in PDFs, laut Featureseite auch über mehrere PDFs und Notizen. | Suche im geöffneten PDF mit Treffer-Hervorhebung. | Basis vorhanden, Multi-Dokument- und Notizsuche fehlen. |
| Anmerkungen | Hervorheben, Kommentare, Stempel, Text, Sticker, teils Audio und Formen. | Textfeld, Notiz, Marker, Unterstreichen, Durchstreichen, Stempel, Signaturfeld-Platzhalter. | Kern vorhanden, Zeichenwerkzeuge, Formen, Audio und Bearbeitung vorhandener Annotationen fehlen. |
| Direkte Textbearbeitung | Vorhandenen PDF-Text ändern, Absätze ergänzen, Schriften bearbeiten. | Nicht umgesetzt. Textfelder sind Annotationen. | Große Lücke gegenüber PDF Expert. |
| Bilder bearbeiten | Bilder einfügen, ersetzen und skalieren. | Bilder können als neue Seiten importiert werden. | Nur Import als Seiten, keine Objektbearbeitung im PDF. |
| Links | Links zu Seiten oder Websites hinzufügen. | Nicht umgesetzt. | Technisch als Link-Annotation erreichbar, UI fehlt. |
| Seitenverwaltung | Zusammenführen, Seiten hinzufügen, löschen, drehen, neu anordnen, extrahieren, teilen. | Zusammenführen, leere Seiten, Bildseiten, löschen, drehen, verschieben. | Starke MVP-Abdeckung, Extrahieren und Teilen fehlen. |
| Konvertierung | PDF zu Word, Excel, PowerPoint, Bildern, TXT und umgekehrt. | Bilder zu PDF-Seiten, ansonsten keine Konvertierung. | Große Lücke. |
| OCR | Texterkennung für Scans, Text kopieren, markieren und durchsuchen. | Nicht umgesetzt. | Große Lücke, besonders für gescannte Dokumente. |
| Scan-Verbesserung | Scans verbessern, Schatten entfernen, Kontrast verbessern, Doppelseiten aufteilen. | Nicht umgesetzt. | Nicht im MVP. |
| Formulare | PDF-Formulare ausfüllen, inklusive gängiger Formularformate laut App Store. | Keine eigene Formular-UI. | Potenzial über PDFKit, aber noch nicht produktisiert. |
| Signaturen | Elektronische Signaturen und mehrere Signaturen. | Signaturfeld als Annotation-Platzhalter. | Nur visueller Platzhalter, keine echte Signaturfunktion. |
| Schutz | Passwortschutz, Schwärzen/Zensieren, vertrauliche Daten entfernen. | Nicht umgesetzt. | Wichtig, aber sicherheitskritisch und später sorgfältig umzusetzen. |
| Komprimierung | PDFs komprimieren. | Nicht umgesetzt. | Fehlt. |
| KI-Funktionen | PDF Copilot mit Zusammenfassung, Fragen, Erklärungen und Quellenbezug laut App Store/Anleitungen. | Nicht umgesetzt. | Kein aktuelles Ziel des MVP. |
| Plattformen | Mac, iPhone, iPad, Vision Pro, geräteübergreifendes Konto. | macOS lokal. | Klarfolio PDF Editor ist enger, aber dafür einfacher und lokal. |

## Produktpositionierung für Klarfolio PDF Editor

Klarfolio PDF Editor sollte kurzfristig nicht als vollständiger PDF-Expert-Ersatz auftreten. Eine realistische Positionierung ist:

- native, lokale macOS-App für einfache PDF-Arbeiten
- schnelle Seitenorganisation ohne Cloud-Konto
- grundlegende Annotationen und Suche
- gut verständliche, deutsch lokalisierte Oberfläche
- ausbaufähige Open-Source- oder interne Grundlage für spezialisierte PDF-Workflows

## Priorisierte Roadmap nach PDF-Expert-Vergleich

| Priorität | Feature | Warum |
| --- | --- | --- |
| P1 | Annotationen auswählen, verschieben und bearbeiten | Macht vorhandene MVP-Funktionen wirklich nutzbar. |
| P1 | Seiten extrahieren und Dokument teilen | Nahe an bestehender Seitenlogik, hoher Alltagsnutzen. |
| P1 | Link-Annotationen | Schließt eine sichtbare Lücke mit überschaubarem PDFKit-Aufwand. |
| P2 | Formularfelder ausfüllen | Wichtig für Verträge, Bewerbungen und Behörden-PDFs. |
| P2 | Sichere Schwärzung | Hoher Nutzen, aber nur mit echter Inhaltsentfernung veröffentlichen. |
| P2 | Crop/Zuschneiden | Häufige Scan- und Dokumentpflegefunktion. |
| P3 | OCR | Strategisch wichtig, aber größere technische Entscheidung. |
| P3 | Export/Konvertierung | Hoher Aufwand, potenziell externe Abhängigkeiten. |
| P3 | Direkte Inhaltsbearbeitung | Größte Funktionslücke, aber technisch komplex. |
| P4 | KI-Zusammenfassung und Fragen | Optional, abhängig von Produktziel und Datenschutzmodell. |

## Abgrenzung bei Kommunikation

In Nutzertexten sollte Klarfolio PDF Editor nicht behaupten, bestehende PDF-Texte oder Bilder direkt wie ein Office-Dokument zu bearbeiten. Korrekte Formulierungen sind:

- `Textfelder hinzufügen`
- `PDFs kommentieren`
- `Seiten organisieren`
- `PDFs zusammenführen`
- `Bilder als Seiten importieren`

Zu vermeiden sind aktuell:

- `PDF-Text direkt bearbeiten`
- `Bilder im PDF ändern`
- `PDFs sicher schwärzen`
- `PDFs in Word/Excel/PowerPoint konvertieren`
- `PDFs unterschreiben` ohne Zusatz, dass es nur ein Platzhalter ist
