import SwiftUI

struct ReadingNavigationView: View {
    @ObservedObject var store: PDFDocumentStore

    private var displayedPageNumber: Int {
        min(store.currentPageIndex + 1, max(store.pageCount, 1))
    }

    private var bookmarkActionLabel: String {
        guard store.fileURL != nil else {
            return "PDF zuerst speichern, um ein Lesezeichen hinzuzufügen"
        }

        return store.isCurrentPageBookmarked
            ? "Lesezeichen für Seite \(displayedPageNumber) entfernen"
            : "Lesezeichen für Seite \(displayedPageNumber) hinzufügen"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    outlineSection
                    bookmarksSection
                }
                .padding(16)
            }
            .frame(minHeight: 220, idealHeight: 310, maxHeight: 390)
        }
        .frame(width: 350)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("readerNavigationPanel")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Inhalt & Lesezeichen")
                    .font(.headline)

                Text("Seite \(displayedPageNumber) von \(max(store.pageCount, 1))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .accessibilityIdentifier("readerCurrentPageLabel")
            }

            Spacer(minLength: 8)

            Button {
                store.toggleBookmarkForCurrentPage()
            } label: {
                Image(systemName: store.isCurrentPageBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(store.isCurrentPageBookmarked ? Color.accentColor : .secondary)
            }
            .buttonStyle(.borderless)
            .disabled(store.fileURL == nil)
            .accessibilityLabel(bookmarkActionLabel)
            .accessibilityIdentifier("readerAddBookmark")
            .help(bookmarkActionLabel)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var outlineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Inhaltsverzeichnis", systemImage: "list.bullet.indent")

            if store.documentOutline.isEmpty {
                emptyState(
                    title: "Kein Inhaltsverzeichnis vorhanden",
                    message: "Dieses PDF enthält keine eingebetteten Kapitel.",
                    systemImage: "text.badge.xmark"
                )
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(store.documentOutline) { item in
                        ReadingOutlineItemView(store: store, item: item, depth: 0)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("readerOutlineSection")
    }

    private var bookmarksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Meine Lesezeichen", systemImage: "bookmark")

            if store.fileURL == nil {
                emptyState(
                    title: "PDF zuerst speichern",
                    message: "Persönliche Lesezeichen sind erst nach dem Speichern verfügbar.",
                    systemImage: "square.and.arrow.down"
                )
            } else if store.pageBookmarks.isEmpty {
                emptyState(
                    title: "Noch keine Lesezeichen",
                    message: "Markiere die aktuelle Seite, um sie später schnell wiederzufinden.",
                    systemImage: "bookmark.slash"
                )
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(store.pageBookmarks) { bookmark in
                        bookmarkRow(bookmark)
                    }
                }
            }

            Text("Lesezeichen werden nur auf diesem Mac gespeichert.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("readerBookmarksSection")
    }

    private func sectionTitle(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
    }

    private func emptyState(title: String, message: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: systemImage)
                .foregroundStyle(.tertiary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 5)
    }

    private func bookmarkRow(_ bookmark: PDFPageBookmark) -> some View {
        HStack(spacing: 8) {
            Button {
                store.goToBookmark(bookmark.id)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(Color.accentColor)

                    Text(bookmark.title)
                        .lineLimit(1)

                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Zu \(bookmark.title) springen")
            .accessibilityIdentifier("readerBookmark.page.\(bookmark.pageIndex)")

            Button {
                store.removeBookmark(bookmark.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Lesezeichen für Seite \(bookmark.pageIndex + 1) entfernen")
            .accessibilityIdentifier("readerRemoveBookmark.page.\(bookmark.pageIndex)")
            .help("Lesezeichen entfernen")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            bookmark.pageIndex == store.currentPageIndex
                ? Color.accentColor.opacity(0.08)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 7)
        )
    }
}

private struct ReadingOutlineItemView: View {
    @ObservedObject var store: PDFDocumentStore
    let item: PDFOutlineItem
    let depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            outlineRow

            ForEach(item.children) { child in
                ReadingOutlineItemView(store: store, item: child, depth: depth + 1)
            }
        }
    }

    @ViewBuilder
    private var outlineRow: some View {
        if let pageIndex = item.pageIndex {
            Button {
                store.goToOutline(item)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 6)

                    Text("\(pageIndex + 1)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(item.title), Seite \(pageIndex + 1)")
            .accessibilityIdentifier("readerOutline.page.\(pageIndex)")
            .padding(.leading, CGFloat(depth) * 14 + 8)
            .padding(.trailing, 8)
            .padding(.vertical, 6)
            .background(
                pageIndex == store.currentPageIndex
                    ? Color.accentColor.opacity(0.08)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 7)
            )
        } else {
            Text(item.title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.leading, CGFloat(depth) * 14 + 8)
                .padding(.vertical, 6)
        }
    }
}
