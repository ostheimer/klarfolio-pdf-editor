import Foundation

/// PDF coordinates are unrotated, bottom-left based. Preview coordinates are
/// rotated, top-left based, in points (not pixels).
struct PDFCropGeometry {
    let mediaBox: CGRect
    let rotation: Int
    static let minimumDimension: CGFloat = 36
    static let pointsPerMillimeter: CGFloat = 72 / 25.4

    init?(mediaBox: CGRect, rotation: Int) {
        guard Self.isFinitePositive(mediaBox), rotation % 90 == 0 else { return nil }
        self.mediaBox = mediaBox
        self.rotation = (rotation % 360 + 360) % 360
    }

    static func isFinitePositive(_ rect: CGRect) -> Bool {
        [rect.origin.x, rect.origin.y, rect.width, rect.height, rect.maxX, rect.maxY].allSatisfy(\.isFinite)
            && rect.size.width > 0 && rect.size.height > 0
    }

    var displaySize: CGSize {
        rotation == 90 || rotation == 270
            ? CGSize(width: mediaBox.height, height: mediaBox.width) : mediaBox.size
    }

    func isValid(_ crop: CGRect) -> Bool {
        Self.isFinitePositive(crop)
            && crop.width >= min(Self.minimumDimension, mediaBox.width)
            && crop.height >= min(Self.minimumDimension, mediaBox.height)
            && crop.minX >= mediaBox.minX && crop.maxX <= mediaBox.maxX
            && crop.minY >= mediaBox.minY && crop.maxY <= mediaBox.maxY
    }

    func displayRect(for crop: CGRect) -> CGRect {
        transform(crop) { point in
            let x = point.x - mediaBox.minX
            let y = point.y - mediaBox.minY
            switch rotation {
            case 90: return CGPoint(x: y, y: x)
            case 180: return CGPoint(x: mediaBox.width - x, y: y)
            case 270: return CGPoint(x: mediaBox.height - y, y: mediaBox.width - x)
            default: return CGPoint(x: x, y: mediaBox.height - y)
            }
        }
    }

    func cropRect(for display: CGRect) -> CGRect {
        let mapped = transform(display) { point in
            let local: CGPoint
            switch rotation {
            case 90: local = CGPoint(x: point.y, y: point.x)
            case 180: local = CGPoint(x: mediaBox.width - point.x, y: point.y)
            case 270: local = CGPoint(x: mediaBox.width - point.y, y: mediaBox.height - point.x)
            default: local = CGPoint(x: point.x, y: mediaBox.height - point.y)
            }
            return CGPoint(x: local.x + mediaBox.minX, y: local.y + mediaBox.minY)
        }
        // Repeated mm steps can put an otherwise exact page edge a fraction of
        // a point outside the MediaBox. Snap only conversion roundoff here;
        // isValid and the Store still strictly reject out-of-bounds API input.
        func snapped(_ value: CGFloat, to edge: CGFloat) -> CGFloat {
            abs(value - edge) < 1e-9 ? edge : value
        }
        let minX = snapped(mapped.minX, to: mediaBox.minX)
        let minY = snapped(mapped.minY, to: mediaBox.minY)
        let maxX = snapped(mapped.maxX, to: mediaBox.maxX)
        let maxY = snapped(mapped.maxY, to: mediaBox.maxY)
        var result = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        if maxX == mediaBox.maxX, result.maxX > maxX { result.size.width = result.size.width.nextDown }
        if maxY == mediaBox.maxY, result.maxY > maxY { result.size.height = result.size.height.nextDown }
        return result
    }

    /// Clamp gestures only. Store/API input is rejected, never silently repaired.
    func selection(from start: CGPoint, to end: CGPoint, draggingCorner: Int? = nil) -> CGRect {
        let size = displaySize
        let a = CGPoint(x: min(max(start.x, 0), size.width), y: min(max(start.y, 0), size.height))
        var b = CGPoint(x: min(max(end.x, 0), size.width), y: min(max(end.y, 0), size.height))
        if let corner = draggingCorner {
            // Existing corner handles keep their opposite corner fixed, even
            // if the pointer crosses it. The minimum applies on the same side.
            let minimumWidth = min(Self.minimumDimension, size.width)
            let minimumHeight = min(Self.minimumDimension, size.height)
            b.x = corner % 2 == 0 ? min(b.x, a.x - minimumWidth) : max(b.x, a.x + minimumWidth)
            b.y = corner < 2 ? min(b.y, a.y - minimumHeight) : max(b.y, a.y + minimumHeight)
        }
        let width = max(abs(b.x - a.x), min(Self.minimumDimension, size.width))
        let height = max(abs(b.y - a.y), min(Self.minimumDimension, size.height))
        func origin(anchor: CGFloat, end: CGFloat, length: CGFloat, limit: CGFloat) -> CGFloat {
            let minimum = min(Self.minimumDimension, limit)
            let value: CGFloat
            if end < anchor, anchor >= minimum {
                value = anchor - length
            } else if end >= anchor, limit - anchor >= minimum {
                value = anchor
            } else if anchor >= minimum {
                value = anchor - length
            } else {
                value = anchor
            }
            // A new background selection may start too close to both edges;
            // an existing valid corner always has enough room on one side.
            return min(max(value, 0), limit - length)
        }
        return CGRect(x: origin(anchor: a.x, end: b.x, length: width, limit: size.width),
                      y: origin(anchor: a.y, end: b.y, length: height, limit: size.height),
                      width: width, height: height)
    }

    private func transform(_ rect: CGRect, point: (CGPoint) -> CGPoint) -> CGRect {
        let corners = [CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
                       CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.maxX, y: rect.maxY)].map(point)
        let xs = corners.map(\.x), ys = corners.map(\.y)
        return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!)
    }
}
