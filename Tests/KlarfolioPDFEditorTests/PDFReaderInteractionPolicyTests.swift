import PDFKit
import Testing
@testable import KlarfolioPDFEditor

@Suite("Sicherer Umgang mit interaktiven PDF-Formularen")
struct PDFReaderInteractionPolicyTests {
    @Test("Der Lesemodus blockiert sichtbare Formularfelder")
    func readingModeBlocksVisibleWidgetInteractions() throws {
        let page = try #require(PDFUtilities.blankPage())
        let widget = PDFAnnotation(
            bounds: CGRect(x: 20, y: 30, width: 120, height: 32),
            forType: .widget,
            withProperties: nil
        )
        page.addAnnotation(widget)

        #expect(
            PDFReaderInteractionPolicy.blocksFormInteraction(
                at: CGPoint(x: 40, y: 45),
                on: page,
                workspaceMode: .reading
            )
        )
    }

    @Test("Noch nicht unterstützte Formularfelder bleiben auch im Bearbeitungsmodus geschützt")
    func editingModeBlocksUnsupportedWidgetInteractions() throws {
        let page = try #require(PDFUtilities.blankPage())
        let widget = PDFAnnotation(
            bounds: CGRect(x: 20, y: 30, width: 120, height: 32),
            forType: .widget,
            withProperties: nil
        )
        page.addAnnotation(widget)

        #expect(
            PDFReaderInteractionPolicy.blocksFormInteraction(
                at: CGPoint(x: 40, y: 45),
                on: page,
                workspaceMode: .editing
            )
        )
    }

    @Test("Normale Dokumentbereiche bleiben in beiden Arbeitsmodi bedienbar")
    func ordinaryDocumentAreasRemainInteractiveInBothModes() throws {
        let page = try #require(PDFUtilities.blankPage())
        let widget = PDFAnnotation(
            bounds: CGRect(x: 20, y: 30, width: 120, height: 32),
            forType: .widget,
            withProperties: nil
        )
        page.addAnnotation(widget)

        #expect(
            !PDFReaderInteractionPolicy.blocksFormInteraction(
                at: CGPoint(x: 220, y: 245),
                on: page,
                workspaceMode: .reading
            )
        )
        #expect(
            !PDFReaderInteractionPolicy.blocksFormInteraction(
                at: CGPoint(x: 220, y: 245),
                on: page,
                workspaceMode: .editing
            )
        )
    }

    @Test("Links werden im Lesemodus nicht als Formularbearbeitung blockiert")
    func readingModePreservesLinkInteractions() throws {
        let page = try #require(PDFUtilities.blankPage())
        let link = PDFAnnotation(
            bounds: CGRect(x: 20, y: 30, width: 120, height: 32),
            forType: .link,
            withProperties: nil
        )
        link.action = PDFActionURL(url: try #require(URL(string: "https://example.invalid")))
        page.addAnnotation(link)

        #expect(
            !PDFReaderInteractionPolicy.blocksFormInteraction(
                at: CGPoint(x: 40, y: 45),
                on: page,
                workspaceMode: .reading
            )
        )
    }

    @Test("Formular-Reset-Aktionen auf scheinbaren Links werden in beiden Modi blockiert")
    func resetFormActionsOnLinksCannotMutateTheDocument() throws {
        let page = try #require(PDFUtilities.blankPage())
        let destructiveLink = PDFAnnotation(
            bounds: CGRect(x: 20, y: 30, width: 120, height: 32),
            forType: .link,
            withProperties: nil
        )
        let resetAction = PDFActionResetForm()
        resetAction.fields = ["KlarfolioName"]
        destructiveLink.action = resetAction
        page.addAnnotation(destructiveLink)

        #expect(
            PDFReaderInteractionPolicy.blocksFormInteraction(
                at: CGPoint(x: 40, y: 45),
                on: page,
                workspaceMode: .reading
            )
        )
        #expect(
            PDFReaderInteractionPolicy.blocksFormInteraction(
                at: CGPoint(x: 40, y: 45),
                on: page,
                workspaceMode: .editing
            )
        )
    }
}
