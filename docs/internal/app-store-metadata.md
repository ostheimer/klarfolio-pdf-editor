# App-Store-Metadaten (Arbeitsstand)

Diese Texte beschreiben ausschließlich den in diesem Repository nachweisbaren Umfang. Sie sind für die erste Mac-App-Store-Version vorbereitet, aber erst nach dem finalen QA-Lauf, der Wahl einer öffentlichen Support-/Datenschutz-URL und der Prüfung im App-Store-Connect-Formular einzutragen. Zeichenlimits für Name und Untertitel sind in Apples [App-Information-Referenz](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information) beschrieben.

## Gemeinsame Angaben

| Feld | Vorgabe | Hinweis |
| --- | --- | --- |
| Plattform | macOS | Mindestversion: macOS 14.0 |
| Produktname | Klarfolio PDF Editor | Vor Einreichung gegen die App-Store-Connect-Verfügbarkeit prüfen. |
| Bundle-ID | `at.ostheimer.klarfoliopdf` | Muss im Apple-Developer-Konto registriert sein. |
| Primärkategorie | Produktivität | Sekundärkategorie nur wählen, wenn sie in App Store Connect passt. |
| Preis | Kostenlos | Keine In-App-Käufe im aktuellen Produktumfang. |
| Support-URL | **noch offen** | Muss eine öffentliche, gepflegte URL sein. |
| Datenschutz-URL | **noch offen** | Öffentlich bereitstellen; lokaler Entwurf: [`../external/privacy.md`](../external/privacy.md). |
| Copyright | **Verantwortliche Stelle bestätigen** | Nicht aus dem Repository ableiten. |

Die Altersfreigabe wird nicht geschätzt. Das aktuelle Frageformular ist in App Store Connect für den finalen Build wahrheitsgemäß auszufüllen.

## Deutsch (de-DE)

### Name und Untertitel

- Name: `Klarfolio PDF Editor`
- Untertitel: `PDFs lesen und annotieren`

### Werbetext

PDFs lokal öffnen, organisieren und mit einfachen Anmerkungen versehen.

### Beschreibung

Klarfolio PDF Editor ist eine native macOS-App für die tägliche Arbeit mit PDF-Dateien.

Öffne vorhandene PDFs oder erstelle ein neues Dokument. Navigiere über Seitenminiaturen, suche nach eingebettetem Text und passe die Ansicht mit Zoom sowie fortlaufendem, Einzelseiten- oder Doppelseitenlayout an.

Organisiere Dokumente mit leeren Seiten, Bildseiten, Drehen, Verschieben, Löschen, dem Zusammenführen mehrerer PDFs sowie dem Extrahieren oder Teilen in neue Dateien. Ergänze einfache Anmerkungen: Textfelder, Notizen, Hervorhebungen, Unterstreichungen, Durchstreichungen, Textstempel, Links zu Webseiten oder Dokumentseiten und einen visuellen Unterschriftsplatzhalter. Dateien speicherst du in einen von dir gewählten Ordner.

Klarfolio PDF Editor arbeitet ohne Konto. Die aktuelle Version verarbeitet Dokumente lokal auf deinem Mac.

Wichtige Grenzen der aktuellen Version: Bestehende PDF-Textobjekte lassen sich nicht direkt umschreiben. OCR, echte Schwärzung, Passwortschutz, digitale Zertifikatssignaturen, Komprimierung, Office-Export, Formularfeld-Authoring und KI-Funktionen sind nicht enthalten.

### Schlüsselwörter

`pdf,reader,annotieren,notizen,seiten,zusammenführen,macos,dokument`

### Hinweise für App Review

Kein Login und kein Demo-Konto erforderlich. Die App öffnet lokale Dateien über die macOS-Dateiauswahl, den Finder oder „Öffnen mit“ und speichert an einem vom Nutzer gewählten Ort. Das „Signaturfeld“ ist ausschließlich ein visueller PDF-Platzhalter und keine digitale oder kryptografische Signatur.

## English (en-US)

### Name and subtitle

- Name: `Klarfolio PDF Editor`
- Subtitle: `Read and annotate PDFs`

### Promotional text

Open, organize, and annotate PDFs locally on your Mac.

### Description

Klarfolio PDF Editor is a native macOS app for everyday PDF work.

Open existing PDFs or create a new document. Navigate with page thumbnails, search embedded text, and adjust the view with zoom plus continuous, single-page, or two-page layouts.

Organize documents by adding blank or image pages, rotating, moving, deleting, merging, extracting, or splitting PDFs into new files. Add simple annotations: text boxes, notes, highlights, underlines, strikeouts, text stamps, links to websites or document pages, and a visual signature placeholder. Save files to a location you choose.

Klarfolio PDF Editor does not require an account. The current version processes documents locally on your Mac.

Current limitations: it does not directly rewrite existing PDF text objects and does not include OCR, true redaction, password protection, digital certificate signatures, compression, Office export, form-field authoring, or AI features.

### Keywords

`pdf,reader,annotate,notes,pages,merge,macos,documents`

### App Review notes

No login or demo account is required. The app opens local files through the macOS file picker, Finder, or Open With and saves to a user-selected location. “Signature field” is a visual PDF placeholder only; it is not a digital or cryptographic signature.

## Screenshots and final review

Capture screenshots only from the release-signed build after QA. Suggested set: empty state, page thumbnails with a multi-page document, search result, page organization, and simple annotations. Use non-confidential test content and ensure each visible feature is present in the submitted build. Before submitting, compare every locale against the final binary and the [manual QA catalogue](manual-qa.md).
