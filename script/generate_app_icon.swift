#!/usr/bin/env swift

import AppKit
import Foundation

private let fileManager = FileManager.default
private let repoRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
private let resourcesURL = repoRoot
    .appendingPathComponent("Sources/KlarfolioPDFEditor/Resources", isDirectory: true)
private let iconsetURL = resourcesURL
    .appendingPathComponent("AppIcon.iconset", isDirectory: true)
private let previewURL = resourcesURL
    .appendingPathComponent("AppIcon.png")
private let icnsURL = resourcesURL
    .appendingPathComponent("AppIcon.icns")

private struct IconColor {
    static let inkTop = NSColor(hex: 0x12333D)
    static let inkBottom = NSColor(hex: 0x0E1B24)
    static let aqua = NSColor(hex: 0x28B7C8)
    static let aquaDark = NSColor(hex: 0x11768B)
    static let paper = NSColor(hex: 0xFAFBFF)
    static let paperBlue = NSColor(hex: 0xDDEEF5)
    static let line = NSColor(hex: 0xCBD6DE)
    static let pdfRed = NSColor(hex: 0xE34A4A)
    static let pdfRedDark = NSColor(hex: 0xB82734)
    static let highlight = NSColor(hex: 0xFFD84D)
    static let penBlue = NSColor(hex: 0x1873D1)
    static let penBlueDark = NSColor(hex: 0x0A4F9B)
}

private extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            deviceRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

private extension CGRect {
    func scaled(_ scale: CGFloat) -> CGRect {
        CGRect(
            x: origin.x * scale,
            y: origin.y * scale,
            width: width * scale,
            height: height * scale
        )
    }
}

private func drawRoundedRect(_ rect: CGRect, radius: CGFloat, fill: NSColor, stroke: NSColor? = nil, lineWidth: CGFloat = 1) {
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    fill.setFill()
    path.fill()
    if let stroke {
        stroke.setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

private func drawText(_ text: String, in rect: CGRect, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let textSize = string.size()
    let textRect = CGRect(
        x: rect.midX - textSize.width / 2,
        y: rect.midY - textSize.height / 2 - size * 0.03,
        width: textSize.width,
        height: textSize.height
    )
    string.draw(in: textRect)
}

private func drawIcon(at scale: CGFloat) {
    let canvas = CGRect(x: 0, y: 0, width: 1024, height: 1024).scaled(scale)
    let background = CGRect(x: 64, y: 64, width: 896, height: 896).scaled(scale)
    let cornerRadius = 210 * scale

    NSGraphicsContext.current?.cgContext.clear(canvas)

    NSGraphicsContext.saveGraphicsState()
    let backgroundShadow = NSShadow()
    backgroundShadow.shadowColor = NSColor.black.withAlphaComponent(0.42)
    backgroundShadow.shadowBlurRadius = 36 * scale
    backgroundShadow.shadowOffset = NSSize(width: 0, height: -22 * scale)
    backgroundShadow.set()
    let backgroundPath = NSBezierPath(roundedRect: background, xRadius: cornerRadius, yRadius: cornerRadius)
    NSGradient(colors: [IconColor.inkTop, IconColor.inkBottom])?.draw(in: backgroundPath, angle: -90)
    NSGraphicsContext.restoreGraphicsState()

    drawRoundedRect(
        CGRect(x: 104, y: 560, width: 380, height: 310).scaled(scale),
        radius: 88 * scale,
        fill: IconColor.aqua.withAlphaComponent(0.18)
    )
    drawRoundedRect(
        CGRect(x: 600, y: 132, width: 260, height: 210).scaled(scale),
        radius: 70 * scale,
        fill: IconColor.pdfRed.withAlphaComponent(0.12)
    )

    NSGraphicsContext.saveGraphicsState()
    let pageShadow = NSShadow()
    pageShadow.shadowColor = NSColor.black.withAlphaComponent(0.23)
    pageShadow.shadowBlurRadius = 30 * scale
    pageShadow.shadowOffset = NSSize(width: 0, height: -18 * scale)
    pageShadow.set()

    let backPage = CGRect(x: 244, y: 262, width: 416, height: 566).scaled(scale)
    drawRoundedRect(
        backPage,
        radius: 34 * scale,
        fill: IconColor.paperBlue,
        stroke: NSColor.white.withAlphaComponent(0.55),
        lineWidth: 3 * scale
    )
    NSGraphicsContext.restoreGraphicsState()

    let frontPage = CGRect(x: 324, y: 198, width: 440, height: 610).scaled(scale)
    NSGraphicsContext.saveGraphicsState()
    let frontShadow = NSShadow()
    frontShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    frontShadow.shadowBlurRadius = 34 * scale
    frontShadow.shadowOffset = NSSize(width: 0, height: -20 * scale)
    frontShadow.set()
    drawRoundedRect(
        frontPage,
        radius: 38 * scale,
        fill: IconColor.paper,
        stroke: NSColor.white.withAlphaComponent(0.7),
        lineWidth: 3 * scale
    )
    NSGraphicsContext.restoreGraphicsState()

    let fold = NSBezierPath()
    fold.move(to: CGPoint(x: frontPage.maxX - 128 * scale, y: frontPage.maxY))
    fold.line(to: CGPoint(x: frontPage.maxX, y: frontPage.maxY - 128 * scale))
    fold.line(to: CGPoint(x: frontPage.maxX - 128 * scale, y: frontPage.maxY - 128 * scale))
    fold.close()
    NSGradient(colors: [NSColor(hex: 0xEEF3F8), NSColor(hex: 0xDCE7EF)])?.draw(in: fold, angle: -45)
    IconColor.line.withAlphaComponent(0.7).setStroke()
    fold.lineWidth = 3 * scale
    fold.stroke()

    IconColor.line.withAlphaComponent(0.75).setStroke()
    for y in [616, 558, 500, 442].map({ CGFloat($0) * scale }) {
        let line = NSBezierPath()
        line.move(to: CGPoint(x: frontPage.minX + 78 * scale, y: y))
        line.line(to: CGPoint(x: frontPage.maxX - 88 * scale, y: y))
        line.lineCapStyle = .round
        line.lineWidth = 13 * scale
        line.stroke()
    }

    let highlightLine = NSBezierPath()
    highlightLine.move(to: CGPoint(x: 430 * scale, y: 358 * scale))
    highlightLine.line(to: CGPoint(x: 706 * scale, y: 490 * scale))
    IconColor.highlight.withAlphaComponent(0.68).setStroke()
    highlightLine.lineCapStyle = .round
    highlightLine.lineWidth = 42 * scale
    highlightLine.stroke()

    let badge = CGRect(x: 260, y: 258, width: 268, height: 128).scaled(scale)
    NSGraphicsContext.saveGraphicsState()
    let badgeShadow = NSShadow()
    badgeShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    badgeShadow.shadowBlurRadius = 16 * scale
    badgeShadow.shadowOffset = NSSize(width: 0, height: -7 * scale)
    badgeShadow.set()
    let badgePath = NSBezierPath(roundedRect: badge, xRadius: 32 * scale, yRadius: 32 * scale)
    NSGradient(colors: [IconColor.pdfRed, IconColor.pdfRedDark])?.draw(in: badgePath, angle: -90)
    NSGraphicsContext.restoreGraphicsState()
    drawText("PDF", in: badge, size: 70 * scale, weight: .black, color: .white)

    NSGraphicsContext.saveGraphicsState()
    let penShadow = NSShadow()
    penShadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
    penShadow.shadowBlurRadius = 16 * scale
    penShadow.shadowOffset = NSSize(width: 0, height: -8 * scale)
    penShadow.set()

    let transform = NSAffineTransform()
    transform.translateX(by: 650 * scale, yBy: 406 * scale)
    transform.rotate(byDegrees: -28)
    transform.concat()

    let penBody = CGRect(x: -180 * scale, y: -34 * scale, width: 330 * scale, height: 68 * scale)
    let bodyPath = NSBezierPath(roundedRect: penBody, xRadius: 25 * scale, yRadius: 25 * scale)
    NSGradient(colors: [IconColor.penBlue, IconColor.penBlueDark])?.draw(in: bodyPath, angle: -90)

    let penStripe = CGRect(x: -118 * scale, y: -34 * scale, width: 52 * scale, height: 68 * scale)
    IconColor.aqua.withAlphaComponent(0.95).setFill()
    NSBezierPath(rect: penStripe).fill()

    let tip = NSBezierPath()
    tip.move(to: CGPoint(x: 150 * scale, y: -34 * scale))
    tip.line(to: CGPoint(x: 222 * scale, y: 0))
    tip.line(to: CGPoint(x: 150 * scale, y: 34 * scale))
    tip.close()
    NSColor(hex: 0xEEF3F8).setFill()
    tip.fill()

    let nib = NSBezierPath()
    nib.move(to: CGPoint(x: 205 * scale, y: -11 * scale))
    nib.line(to: CGPoint(x: 238 * scale, y: 0))
    nib.line(to: CGPoint(x: 205 * scale, y: 11 * scale))
    nib.close()
    NSColor(hex: 0x27313A).setFill()
    nib.fill()

    NSGraphicsContext.restoreGraphicsState()
}

private func pngData(size pixels: Int) throws -> Data {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "KlarfolioPDFEditorIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create bitmap representation."])
    }

    rep.size = CGSize(width: pixels, height: pixels)
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        throw NSError(domain: "KlarfolioPDFEditorIcon", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create graphics context."])
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.shouldAntialias = true
    context.imageInterpolation = .high
    drawIcon(at: CGFloat(pixels) / 1024)
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "KlarfolioPDFEditorIcon", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not encode PNG data."])
    }
    return data
}

private func runIconutil() throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", "-o", icnsURL.path, iconsetURL.path]

    let pipe = Pipe()
    process.standardError = pipe
    try process.run()
    process.waitUntilExit()

    if process.terminationStatus != 0 {
        let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorMessage = String(data: errorData, encoding: .utf8) ?? "iconutil failed."
        throw NSError(domain: "KlarfolioPDFEditorIcon", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorMessage])
    }
}

try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)
if fileManager.fileExists(atPath: iconsetURL.path) {
    try fileManager.removeItem(at: iconsetURL)
}
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconFiles: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for iconFile in iconFiles {
    let data = try pngData(size: iconFile.pixels)
    try data.write(to: iconsetURL.appendingPathComponent(iconFile.name), options: .atomic)
    if iconFile.pixels == 1024 {
        try data.write(to: previewURL, options: .atomic)
    }
}

try runIconutil()

print("Generated \(previewURL.path)")
print("Generated \(icnsURL.path)")
