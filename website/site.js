// Set this once when a public primary domain is available, for example "https://klarfolio.com".
const configuredSiteUrl = "";

const translations = {
  en: {
    skip: "Skip to content",
    menu: "Menu",
    download: "Free download for macOS",
    "download.coming": "Download coming soon",
    "download.status.coming": "The first signed release is being prepared. The download will appear here once it is available.",
    "download.status.ready": "Klarfolio PDF Editor is ready to download.",
    viewFeatures: "View features",
    "nav.primary": "Primary navigation",
    "brand.home": "Klarfolio PDF Editor home",
    "language.label": "Language",
    "nav.features": "Features",
    "nav.compare": "Compare",
    "nav.languages": "Languages",
    "nav.roadmap": "Roadmap",
    "hero.title": "Klarfolio PDF Editor",
    "hero.lede": "A free, native PDF editor to read, annotate, organize, and build PDFs locally on your Mac.",
    "hero.trust.free": "Free, no subscription",
    "hero.trust.native": "Native macOS interface",
    "hero.trust.offline": "Works offline",
    "hero.trust.label": "Product highlights",
    "hero.preview.label": "Klarfolio PDF Editor app interface preview",
    "hero.preview.alt": "Klarfolio PDF Editor for macOS showing page thumbnails, highlighted PDF text, search, and annotation tools.",
    "features.title": "Everything you need in one native app.",
    "features.lede": "Fast, local, and designed around everyday PDF work.",
    "features.read.title": "Read with clarity",
    "features.read.body": "Navigate long documents with thumbnails, search, zoom, and flexible layouts.",
    "features.read.item1": "Continuous, single-page, and two-page views",
    "features.read.item2": "Search with highlighted results",
    "features.read.item3": "Page thumbnails and quick navigation",
    "features.annotate.title": "Annotate naturally",
    "features.annotate.body": "Add highlights, notes, text fields, stamps, and signature placeholders.",
    "features.annotate.item1": "Highlight, underline, and strike out selected text",
    "features.annotate.item2": "Text notes and visual stamps",
    "features.annotate.item3": "Color and font controls",
    "features.organize.title": "Organize pages",
    "features.organize.body": "Create PDFs, add image pages, merge files, rotate, reorder, and delete pages.",
    "features.organize.item1": "Merge multiple PDFs into one document",
    "features.organize.item2": "Import images as PDF pages",
    "features.organize.item3": "Move, rotate, insert, and delete pages",
    "workflow.title": "Designed for focused document work.",
    "workflow.body": "Klarfolio PDF Editor keeps PDF actions close to the document: pages on the left, reading in the center, and precise tools on the right.",
    "workflow.item1.title": "Local by default",
    "workflow.item1.body": "Open, edit, and save files on your Mac.",
    "workflow.item2.title": "No account required",
    "workflow.item2.body": "Built for offline-first document handling.",
    "workflow.item3.title": "Native foundation",
    "workflow.item3.body": "SwiftUI and PDFKit keep the app aligned with macOS.",
    "workflow.preview.alt": "Klarfolio PDF Editor detail view with highlighted contract text and signature placeholder.",
    "compare.title": "A modern alternative for Mac.",
    "compare.body": "PDF Expert is a mature commercial benchmark. Klarfolio PDF Editor starts smaller: free, local, native, and focused on core PDF workflows first.",
    "compare.col.capability": "Capability",
    "compare.col.position": "Position",
    "compare.rows.reading": "Reading and search",
    "compare.rows.annotations": "Annotations",
    "compare.rows.pages": "Page organization",
    "compare.rows.ocr": "OCR, conversion, redaction",
    "compare.status.ready": "Ready",
    "compare.status.mvp": "MVP ready",
    "compare.status.planned": "Planned",
    "compare.position.core": "Core workflow",
    "compare.position.growing": "Growing feature set",
    "compare.position.roadmap": "Roadmap area",
    "compare.label": "Klarfolio PDF Editor positioning",
    "languages.title": "Product information in your language.",
    "languages.body": "This website is available in English and German. The current app interface is German; further app localization remains future work.",
    "languages.available": "Website available",
    "languages.planned": "Planned",
    "languages.more": "More languages",
    "languages.label": "Localization roadmap",
    "roadmap.title": "Roadmap / Coming soon",
    "roadmap.body": "Klarfolio PDF Editor grows step by step, starting with the features that make daily PDF work easier.",
    "roadmap.forms.title": "Forms",
    "roadmap.forms.body": "Fill and create interactive form fields with validation.",
    "roadmap.redaction.title": "Redaction",
    "roadmap.redaction.body": "Permanently remove sensitive content, not just cover it.",
    "roadmap.ocr.title": "OCR",
    "roadmap.ocr.body": "Make scanned PDFs searchable and selectable.",
    "roadmap.batch.title": "Batch processing",
    "roadmap.batch.body": "Process multiple files for conversion, export, and optimization.",
    "final.title": "Edit PDFs for free. Keep them on your Mac.",
    "final.body": "Klarfolio PDF Editor gives you fast local tools without turning every document into a cloud workflow.",
    "footer.tagline": "A native PDF workspace for macOS. Read, annotate, organize, and build PDFs locally.",
    "footer.product": "Product",
    "footer.resources": "Resources",
    "footer.guide": "User guide",
    "footer.docs": "Documentation",
    "footer.support": "Support",
    "footer.privacy": "Privacy",
    "support.title": "Support",
    "support.intro": "Practical help for Klarfolio PDF Editor",
    "support.selfhelp.title": "Start with the guides",
    "support.selfhelp.body": "The user guide and feature overview explain the available PDF workflows, shortcuts, and current product scope.",
    "support.tracker.title": "Report a problem",
    "support.tracker.body": "For reproducible bugs or feature requests, use the public GitHub issue tracker. Please do not attach documents or share sensitive information there.",
    "support.tracker.link": "Open the public issue tracker",
    "support.privacy.title": "Privacy and sensitive documents",
    "support.privacy.body": "Klarfolio PDF Editor is designed for local document work. Read the privacy information before contacting support.",
    "support.privacy.link": "Read privacy information",
    "privacy.title": "Privacy information",
    "privacy.intro": "How Klarfolio PDF Editor handles information",
    "privacy.content.label": "Privacy information",
    "privacy.local.title": "Your documents stay on your Mac",
    "privacy.local.body": "Klarfolio PDF Editor is designed to open, edit, and save PDF files locally. The app does not require an account and does not include a cloud upload service.",
    "privacy.website.title": "This website",
    "privacy.website.body": "This static website does not use analytics, advertising pixels, contact forms, or non-essential cookies. It stores only your English/German language choice in your browser's local storage so the selection remains available across pages and later visits. Your browser may still send technical request data, such as an IP address and user-agent, to the hosting provider in order to load the site.",
    "privacy.support.title": "Support requests",
    "privacy.support.body": "Support is handled through the public GitHub issue tracker. Do not include PDFs, personal data, passwords, license keys, or other sensitive information in an issue.",
    "privacy.contact.title": "Contact and publication status",
    "privacy.contact.body": "The final website operator details, hosting provider details, and a direct privacy contact must be added before a public-domain launch. Until then, this page describes the product and website behavior only.",
    "privacy.support.link": "Open the support tracker",
    "privacy.back": "Back to product page"
  },
  de: {
    skip: "Zum Inhalt springen",
    menu: "Menü",
    download: "Kostenlos für macOS laden",
    "download.coming": "Download demnächst verfügbar",
    "download.status.coming": "Die erste signierte Version wird vorbereitet. Der Download erscheint hier, sobald sie verfügbar ist.",
    "download.status.ready": "Klarfolio PDF Editor kann jetzt heruntergeladen werden.",
    viewFeatures: "Funktionen ansehen",
    "nav.primary": "Hauptnavigation",
    "brand.home": "Startseite von Klarfolio PDF Editor",
    "language.label": "Sprache",
    "nav.features": "Funktionen",
    "nav.compare": "Vergleich",
    "nav.languages": "Sprachen",
    "nav.roadmap": "Roadmap",
    "hero.title": "Klarfolio PDF Editor",
    "hero.lede": "Ein kostenloser, nativer PDF-Editor zum Lesen, Kommentieren, Organisieren und Erstellen von PDFs auf dem Mac.",
    "hero.trust.free": "Kostenlos, ohne Abo",
    "hero.trust.native": "Native macOS-Oberfläche",
    "hero.trust.offline": "Funktioniert offline",
    "hero.trust.label": "Produktvorteile",
    "hero.preview.label": "Vorschau der Klarfolio-PDF-Editor-Oberfläche",
    "hero.preview.alt": "Klarfolio PDF Editor für macOS mit Seitenminiaturen, hervorgehobenem PDF-Text, Suche und Anmerkungswerkzeugen.",
    "features.title": "Alles Wichtige in einer nativen App.",
    "features.lede": "Schnell, lokal und auf tägliche PDF-Arbeit ausgelegt.",
    "features.read.title": "Klar lesen",
    "features.read.body": "Navigiere lange Dokumente mit Miniaturen, Suche, Zoom und flexiblen Layouts.",
    "features.read.item1": "Fortlaufende Ansicht, Einzelseite und Doppelseite",
    "features.read.item2": "Suche mit hervorgehobenen Treffern",
    "features.read.item3": "Seitenminiaturen und schnelle Navigation",
    "features.annotate.title": "Natürlich kommentieren",
    "features.annotate.body": "Füge Marker, Notizen, Textfelder, Stempel und Signaturfelder hinzu.",
    "features.annotate.item1": "Text hervorheben, unterstreichen und durchstreichen",
    "features.annotate.item2": "Textnotizen und visuelle Stempel",
    "features.annotate.item3": "Farb- und Schriftgrößensteuerung",
    "features.organize.title": "Seiten organisieren",
    "features.organize.body": "Erstelle PDFs, füge Bildseiten ein, führe Dateien zusammen, drehe, sortiere und lösche Seiten.",
    "features.organize.item1": "Mehrere PDFs zu einem Dokument zusammenführen",
    "features.organize.item2": "Bilder als PDF-Seiten importieren",
    "features.organize.item3": "Seiten verschieben, drehen, einfügen und löschen",
    "workflow.title": "Für konzentrierte Dokumentarbeit gestaltet.",
    "workflow.body": "Klarfolio PDF Editor hält PDF-Aktionen nah am Dokument: Seiten links, Lesen in der Mitte und präzise Werkzeuge rechts.",
    "workflow.item1.title": "Standardmäßig lokal",
    "workflow.item1.body": "Dateien auf dem Mac öffnen, bearbeiten und speichern.",
    "workflow.item2.title": "Kein Konto nötig",
    "workflow.item2.body": "Für Offline-Dokumentarbeit entwickelt.",
    "workflow.item3.title": "Native Grundlage",
    "workflow.item3.body": "SwiftUI und PDFKit halten die App nah an macOS.",
    "workflow.preview.alt": "Detailansicht des Klarfolio PDF Editors mit hervorgehobenem Vertragstext und Signaturfeld.",
    "compare.title": "Eine moderne Alternative für den Mac.",
    "compare.body": "PDF Expert ist ein ausgereifter kommerzieller Maßstab. Klarfolio PDF Editor startet kleiner: kostenlos, lokal, nativ und zuerst auf zentrale PDF-Workflows fokussiert.",
    "compare.col.capability": "Funktion",
    "compare.col.position": "Einordnung",
    "compare.rows.reading": "Lesen und Suche",
    "compare.rows.annotations": "Anmerkungen",
    "compare.rows.pages": "Seitenorganisation",
    "compare.rows.ocr": "OCR, Konvertierung, Schwärzung",
    "compare.status.ready": "Verfügbar",
    "compare.status.mvp": "MVP verfügbar",
    "compare.status.planned": "Geplant",
    "compare.position.core": "Kernworkflow",
    "compare.position.growing": "Wachsender Funktionsumfang",
    "compare.position.roadmap": "Roadmap-Bereich",
    "compare.label": "Einordnung des Klarfolio PDF Editors",
    "languages.title": "Produktinformationen in Deiner Sprache.",
    "languages.body": "Diese Website ist auf Deutsch und Englisch verfügbar. Die aktuelle App-Oberfläche ist deutsch; weitere App-Lokalisierungen bleiben Zukunftsarbeit.",
    "languages.available": "Website verfügbar",
    "languages.planned": "Geplant",
    "languages.more": "Weitere Sprachen",
    "languages.label": "Lokalisierungs-Roadmap",
    "roadmap.title": "Roadmap / Demnächst",
    "roadmap.body": "Klarfolio PDF Editor wächst Schritt für Schritt, beginnend mit Funktionen, die tägliche PDF-Arbeit leichter machen.",
    "roadmap.forms.title": "Formulare",
    "roadmap.forms.body": "Interaktive Formularfelder mit Validierung ausfüllen und erstellen.",
    "roadmap.redaction.title": "Schwärzung",
    "roadmap.redaction.body": "Sensible Inhalte dauerhaft entfernen, nicht nur überdecken.",
    "roadmap.ocr.title": "OCR",
    "roadmap.ocr.body": "Gescannte PDFs durchsuchbar und auswählbar machen.",
    "roadmap.batch.title": "Stapelverarbeitung",
    "roadmap.batch.body": "Mehrere Dateien für Konvertierung, Export und Optimierung verarbeiten.",
    "final.title": "PDFs kostenlos bearbeiten. Direkt auf Deinem Mac.",
    "final.body": "Klarfolio PDF Editor bietet schnelle lokale Werkzeuge, ohne jedes Dokument in einen Cloud-Workflow zu verwandeln.",
    "footer.tagline": "Ein nativer PDF-Arbeitsbereich für macOS. PDFs lesen, kommentieren, organisieren und lokal erstellen.",
    "footer.product": "Produkt",
    "footer.resources": "Ressourcen",
    "footer.guide": "Nutzerhandbuch",
    "footer.docs": "Dokumentation",
    "footer.support": "Support",
    "footer.privacy": "Datenschutz",
    "support.title": "Support",
    "support.intro": "Praktische Hilfe für Klarfolio PDF Editor",
    "support.selfhelp.title": "Zuerst in den Anleitungen nachsehen",
    "support.selfhelp.body": "Nutzerhandbuch und Funktionsübersicht erklären die verfügbaren PDF-Workflows, Kurzbefehle und den aktuellen Produktumfang.",
    "support.tracker.title": "Problem melden",
    "support.tracker.body": "Für nachvollziehbare Fehler oder Funktionswünsche steht der öffentliche GitHub-Issue-Tracker zur Verfügung. Bitte füge dort keine Dokumente an und teile keine vertraulichen Informationen.",
    "support.tracker.link": "Öffentlichen Issue-Tracker öffnen",
    "support.privacy.title": "Datenschutz und vertrauliche Dokumente",
    "support.privacy.body": "Klarfolio PDF Editor ist für lokale Dokumentarbeit konzipiert. Lies die Datenschutzinformationen, bevor Du den Support kontaktierst.",
    "support.privacy.link": "Datenschutzinformationen lesen",
    "privacy.title": "Datenschutzinformationen",
    "privacy.intro": "So geht Klarfolio PDF Editor mit Informationen um",
    "privacy.content.label": "Datenschutzinformationen",
    "privacy.local.title": "Deine Dokumente bleiben auf Deinem Mac",
    "privacy.local.body": "Klarfolio PDF Editor ist dafür ausgelegt, PDF-Dateien lokal zu öffnen, zu bearbeiten und zu speichern. Die App benötigt kein Konto und enthält keinen Cloud-Upload-Dienst.",
    "privacy.website.title": "Diese Website",
    "privacy.website.body": "Diese statische Website verwendet keine Analytik, Werbepixel, Kontaktformulare oder nicht erforderlichen Cookies. Sie speichert ausschließlich Deine Sprachwahl Deutsch/Englisch im lokalen Browserspeicher, damit die Auswahl auf weiteren Seiten und bei späteren Besuchen erhalten bleibt. Dein Browser kann dennoch technische Anfragedaten wie IP-Adresse und User-Agent an den Hosting-Anbieter übermitteln, damit die Website geladen werden kann.",
    "privacy.support.title": "Supportanfragen",
    "privacy.support.body": "Support wird über den öffentlichen GitHub-Issue-Tracker abgewickelt. Bitte veröffentliche dort keine PDFs, personenbezogenen Daten, Passwörter, Lizenzschlüssel oder andere vertrauliche Informationen.",
    "privacy.contact.title": "Kontakt und Veröffentlichungsstatus",
    "privacy.contact.body": "Vor einem Start unter einer öffentlichen Domain müssen die endgültigen Angaben zum Websitebetreiber, Hosting-Anbieter und ein direkter Datenschutzkontakt ergänzt werden. Bis dahin beschreibt diese Seite nur das Verhalten von Produkt und Website.",
    "privacy.support.link": "Support-Tracker öffnen",
    "privacy.back": "Zur Produktseite"
  }
};

const futureLocales = ["fr", "es", "it", "pt", "ja", "ko", "zh", "ar", "hi"];

const documentTitles = {
  home: {
    en: "Klarfolio PDF Editor - Free PDF Editing for Mac",
    de: "Klarfolio PDF Editor - PDFs kostenlos auf dem Mac bearbeiten"
  },
  privacy: {
    en: "Privacy information - Klarfolio PDF Editor",
    de: "Datenschutzinformationen - Klarfolio PDF Editor"
  },
  support: {
    en: "Support - Klarfolio PDF Editor",
    de: "Support - Klarfolio PDF Editor"
  }
};

function setLanguage(language) {
  const activeLanguage = translations[language] ? language : "en";
  document.documentElement.lang = activeLanguage;
  const page = document.body.dataset.page || "home";
  document.title = (documentTitles[page] || documentTitles.home)[activeLanguage];

  document.querySelectorAll("[data-i18n]").forEach((node) => {
    const key = node.getAttribute("data-i18n");
    const text = translations[activeLanguage][key];
    if (text) {
      node.textContent = text;
    }
  });

  document.querySelectorAll("[data-i18n-aria]").forEach((node) => {
    const text = translations[activeLanguage][node.getAttribute("data-i18n-aria")];
    if (text) node.setAttribute("aria-label", text);
  });

  document.querySelectorAll("[data-i18n-alt]").forEach((node) => {
    const text = translations[activeLanguage][node.getAttribute("data-i18n-alt")];
    if (text) node.setAttribute("alt", text);
  });

  document.querySelectorAll(".language-option").forEach((button) => {
    const isActive = button.dataset.lang === activeLanguage;
    button.classList.toggle("is-active", isActive);
    button.setAttribute("aria-pressed", String(isActive));
  });

  localStorage.setItem("klarfolio-language", activeLanguage);
  setDownloadState(activeLanguage);
}

function getReleaseUrl() {
  const configuredUrl = window.KLARFOLIO_DOWNLOAD_URL
    || document.querySelector('meta[name="klarfolio-download-url"]')?.content.trim();

  if (!configuredUrl) return null;

  try {
    const releaseUrl = new URL(configuredUrl, window.location.href);
    return releaseUrl.protocol === "https:" ? releaseUrl.href : null;
  } catch {
    return null;
  }
}

function setDownloadState(language) {
  const releaseUrl = getReleaseUrl();
  const isReady = Boolean(releaseUrl);

  document.querySelectorAll("[data-download]").forEach((link) => {
    link.classList.toggle("is-disabled", !isReady);
    link.setAttribute("aria-disabled", String(!isReady));

    if (isReady) {
      link.href = releaseUrl;
      link.textContent = translations[language].download;
    } else {
      link.removeAttribute("href");
      link.textContent = translations[language]["download.coming"];
    }
  });

  const status = document.getElementById("download-status");
  if (status) {
    status.textContent = translations[language][isReady ? "download.status.ready" : "download.status.coming"];
  }
}

function setCanonicalUrl() {
  const canonical = document.querySelector("[data-site-canonical]");
  if (!canonical || !configuredSiteUrl) return;

  try {
    const siteUrl = new URL(configuredSiteUrl);
    if (siteUrl.protocol !== "https:") return;
    const page = document.body.dataset.page;
    canonical.href = new URL(page ? `${page}.html` : "", siteUrl).href;
  } catch {
    // An invalid development value must not produce an invalid canonical URL.
  }
}

document.querySelectorAll(".language-option").forEach((button) => {
  button.addEventListener("click", () => setLanguage(button.dataset.lang));
});

window.KlarfolioLocales = {
  available: Object.keys(translations),
  planned: futureLocales
};

const navToggle = document.querySelector(".nav-toggle");
const navMenu = document.querySelector(".nav-menu");

if (navToggle && navMenu) {
  navToggle.addEventListener("click", () => {
    const isOpen = navMenu.classList.toggle("is-open");
    navToggle.setAttribute("aria-expanded", String(isOpen));
  });

  navMenu.querySelectorAll("a").forEach((link) => {
    link.addEventListener("click", () => {
      navMenu.classList.remove("is-open");
      navToggle.setAttribute("aria-expanded", "false");
    });
  });
}

setLanguage(localStorage.getItem("klarfolio-language") || "en");
setCanonicalUrl();
