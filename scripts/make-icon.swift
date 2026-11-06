// Draws the Coffee app icon and writes a complete .iconset folder.
// Usage: swift scripts/make-icon.swift <output.iconset>
import AppKit

// All coordinates are on a 1024 × 1024 canvas, origin at the bottom left.
// The background follows Apple's macOS icon grid: an 824 × 824 rounded square
// centered on the canvas, leaving room for the system's drop shadow.
func drawIcon() {
    let cream = NSColor(red: 1.00, green: 0.97, blue: 0.92, alpha: 1)
    let creamShade = NSColor(red: 0.93, green: 0.87, blue: 0.79, alpha: 1)
    let coffee = NSColor(red: 0.36, green: 0.19, blue: 0.10, alpha: 1)

    // Background
    let background = NSBezierPath(roundedRect: NSRect(x: 100, y: 100, width: 824, height: 824), xRadius: 185, yRadius: 185)
    NSGradient(
        starting: NSColor(red: 0.93, green: 0.64, blue: 0.40, alpha: 1),
        ending: NSColor(red: 0.47, green: 0.25, blue: 0.13, alpha: 1)
    )!.draw(in: background, angle: -90)

    // Saucer, with a soft shadow beneath it
    NSGraphicsContext.saveGraphicsState()
    let saucerShadow = NSShadow()
    saucerShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    saucerShadow.shadowOffset = NSSize(width: 0, height: -10)
    saucerShadow.shadowBlurRadius = 24
    saucerShadow.set()
    creamShade.setFill()
    NSBezierPath(ovalIn: NSRect(x: 252, y: 250, width: 520, height: 100)).fill()
    NSGraphicsContext.restoreGraphicsState()

    // Handle: a ring on the right whose left half is hidden behind the cup
    let handle = NSBezierPath(ovalIn: NSRect(x: 632, y: 400, width: 160, height: 160))
    handle.lineWidth = 38
    cream.setStroke()
    handle.stroke()

    // Cup body: wide at the rim, tapering to a rounded base
    let body = NSBezierPath()
    body.move(to: NSPoint(x: 300, y: 610))
    body.line(to: NSPoint(x: 724, y: 610))
    body.curve(to: NSPoint(x: 640, y: 315), controlPoint1: NSPoint(x: 724, y: 440), controlPoint2: NSPoint(x: 700, y: 330))
    body.curve(to: NSPoint(x: 384, y: 315), controlPoint1: NSPoint(x: 570, y: 298), controlPoint2: NSPoint(x: 454, y: 298))
    body.curve(to: NSPoint(x: 300, y: 610), controlPoint1: NSPoint(x: 324, y: 330), controlPoint2: NSPoint(x: 300, y: 440))
    body.close()
    NSGradient(starting: cream, ending: creamShade)!.draw(in: body, angle: 0)

    // Rim and coffee surface
    cream.setFill()
    NSBezierPath(ovalIn: NSRect(x: 300, y: 570, width: 424, height: 80)).fill()
    coffee.setFill()
    NSBezierPath(ovalIn: NSRect(x: 324, y: 582, width: 376, height: 56)).fill()

    // Steam: three gentle S-curves rising from the cup
    cream.withAlphaComponent(0.75).setStroke()
    for x in [432.0, 512.0, 592.0] {
        let steam = NSBezierPath()
        steam.move(to: NSPoint(x: x, y: 680))
        steam.curve(to: NSPoint(x: x, y: 830), controlPoint1: NSPoint(x: x - 45, y: 730), controlPoint2: NSPoint(x: x + 45, y: 780))
        steam.lineWidth = 26
        steam.lineCapStyle = .round
        steam.stroke()
    }
}

func renderPNG(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let transform = NSAffineTransform()
    transform.scale(by: CGFloat(pixels) / 1024)
    transform.concat()
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("Usage: swift make-icon.swift <output.iconset>\n".data(using: .utf8)!)
    exit(1)
}
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        try renderPNG(pixels: points * scale).write(to: outputURL.appendingPathComponent(name))
    }
}
