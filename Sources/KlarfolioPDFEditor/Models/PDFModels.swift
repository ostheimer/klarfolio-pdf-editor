import AppKit
import PDFKit
import SwiftUI

enum SidebarPanel: String, CaseIterable, Identifiable {
    case pages
    case document

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pages: "Seiten"
        case .document: "Dokument"
        }
    }

    var symbolName: String {
        switch self {
        case .pages: "square.grid.2x2"
        case .document: "doc.text.magnifyingglass"
        }
    }
}

enum PDFInteractionTool: String, CaseIterable, Identifiable {
    case select
    case text
    case note
    case highlight
    case stamp
    case sign

    var id: String { rawValue }

    var title: String {
        switch self {
        case .select: "Auswahl"
        case .text: "Text"
        case .note: "Notiz"
        case .highlight: "Marker"
        case .stamp: "Stempel"
        case .sign: "Signatur"
        }
    }

    var symbolName: String {
        switch self {
        case .select: "cursorarrow"
        case .text: "textformat"
        case .note: "note.text"
        case .highlight: "highlighter"
        case .stamp: "seal"
        case .sign: "signature"
        }
    }
}

enum AnnotationSwatch: String, CaseIterable, Identifiable {
    case yellow
    case mint
    case blue
    case pink
    case red
    case black

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yellow: "Gelb"
        case .mint: "Grün"
        case .blue: "Blau"
        case .pink: "Pink"
        case .red: "Rot"
        case .black: "Schwarz"
        }
    }

    var nsColor: NSColor {
        switch self {
        case .yellow: NSColor.systemYellow
        case .mint: NSColor.systemMint
        case .blue: NSColor.systemBlue
        case .pink: NSColor.systemPink
        case .red: NSColor.systemRed
        case .black: NSColor.labelColor
        }
    }

    var swiftUIColor: Color {
        Color(nsColor: nsColor)
    }
}

enum PageLayoutMode: String, CaseIterable, Identifiable {
    case singleContinuous
    case singlePage
    case twoUpContinuous

    var id: String { rawValue }

    var title: String {
        switch self {
        case .singleContinuous: "Fortlaufend"
        case .singlePage: "Einzelseite"
        case .twoUpContinuous: "Doppelseite"
        }
    }

    var pdfDisplayMode: PDFDisplayMode {
        switch self {
        case .singleContinuous: .singlePageContinuous
        case .singlePage: .singlePage
        case .twoUpContinuous: .twoUpContinuous
        }
    }
}

enum MarkupAnnotationKind {
    case highlight
    case underline
    case strikeOut

    var pdfSubtype: PDFAnnotationSubtype {
        switch self {
        case .highlight: .highlight
        case .underline: .underline
        case .strikeOut: .strikeOut
        }
    }

    var fallbackStatus: String {
        switch self {
        case .highlight: "Markiere zuerst Text zum Hervorheben."
        case .underline: "Markiere zuerst Text zum Unterstreichen."
        case .strikeOut: "Markiere zuerst Text zum Durchstreichen."
        }
    }
}
