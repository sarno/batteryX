import AppKit
import CoreGraphics
import Foundation

func createBatteryXIcon() -> NSImage {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)

    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    // 1. Shadow for squircle
    ctx.saveGState()
    let shadowColor = NSColor.black.withAlphaComponent(0.45).cgColor
    ctx.setShadow(offset: CGSize(width: 0, height: -22), blur: 32, color: shadowColor)

    // 2. Base Squircle (macOS App Icon Shape)
    let squircleRect = CGRect(x: 104, y: 104, width: 816, height: 816)
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: 185, cornerHeight: 185, transform: nil)

    ctx.addPath(squirclePath)
    ctx.clip()
    ctx.restoreGState()

    // Re-clip squircle for background drawing
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // Background Gradient: Deep Midnight Space Slate
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.12, green: 0.14, blue: 0.19, alpha: 1.0).cgColor,
        NSColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512, y: 920), end: CGPoint(x: 512, y: 104), options: [])
    }

    // Subtle Radial Glow behind battery
    let radialColors = [
        NSColor(red: 0.0, green: 0.8, blue: 0.6, alpha: 0.22).cgColor,
        NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor
    ] as CFArray
    if let radialGradient = CGGradient(colorsSpace: colorSpace, colors: radialColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(radialGradient, startCenter: CGPoint(x: 512, y: 512), startRadius: 50, endCenter: CGPoint(x: 512, y: 512), endRadius: 380, options: [])
    }

    // Top Specular Highlight arc
    ctx.saveGState()
    let highlightRect = CGRect(x: 104, y: 520, width: 816, height: 400)
    ctx.clip(to: highlightRect)
    let highlightColors = [
        NSColor.white.withAlphaComponent(0.12).cgColor,
        NSColor.white.withAlphaComponent(0.0).cgColor
    ] as CFArray
    if let highlightGrad = CGGradient(colorsSpace: colorSpace, colors: highlightColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(highlightGrad, start: CGPoint(x: 512, y: 920), end: CGPoint(x: 512, y: 650), options: [])
    }
    ctx.restoreGState()

    // Squircle Rim Light Border
    ctx.addPath(squirclePath)
    ctx.setLineWidth(4.0)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    ctx.strokePath()

    // 3. Draw Battery Shell
    // Battery Body: centered at (512, 512)
    let bWidth: CGFloat = 460
    let bHeight: CGFloat = 250
    let bX: CGFloat = 260
    let bY: CGFloat = 386
    let bRadius: CGFloat = 52

    let batteryRect = CGRect(x: bX, y: bY, width: bWidth, height: bHeight)
    let batteryPath = CGPath(roundedRect: batteryRect, cornerWidth: bRadius, cornerHeight: bRadius, transform: nil)

    // Battery Shell Background (Dark translucent glass)
    ctx.saveGState()
    ctx.addPath(batteryPath)
    ctx.setFillColor(NSColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 0.85).cgColor)
    ctx.fillPath()

    // Battery Terminal Pin (+ pole on right)
    let pinRect = CGRect(x: bX + bWidth + 6, y: bY + (bHeight - 96) / 2, width: 26, height: 96)
    let pinPath = CGPath(roundedRect: pinRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
    ctx.addPath(pinPath)
    ctx.setFillColor(NSColor(red: 0.45, green: 0.50, blue: 0.60, alpha: 0.9).cgColor)
    ctx.fillPath()
    ctx.restoreGState()

    // 4. Battery Charge Level (80% signature limit in Glowing Emerald/Cyan)
    ctx.saveGState()
    let innerPadding: CGFloat = 16
    let fillWidth: CGFloat = (bWidth - innerPadding * 2) * 0.78 // 78%-80% level
    let fillHeight: CGFloat = bHeight - innerPadding * 2
    let fillRect = CGRect(x: bX + innerPadding, y: bY + innerPadding, width: fillWidth, height: fillHeight)
    let fillPath = CGPath(roundedRect: fillRect, cornerWidth: 38, cornerHeight: 38, transform: nil)

    // Glow
    ctx.setShadow(offset: .zero, blur: 24, color: NSColor(red: 0.0, green: 0.9, blue: 0.7, alpha: 0.7).cgColor)
    ctx.addPath(fillPath)
    ctx.clip()

    let chargeColors = [
        NSColor(red: 0.0, green: 0.95, blue: 0.65, alpha: 1.0).cgColor,  // Neon Green
        NSColor(red: 0.0, green: 0.72, blue: 1.0, alpha: 1.0).cgColor    // Electric Cyan
    ] as CFArray
    if let chargeGrad = CGGradient(colorsSpace: colorSpace, colors: chargeColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(chargeGrad, start: CGPoint(x: fillRect.minX, y: fillRect.midY), end: CGPoint(x: fillRect.maxX, y: fillRect.midY), options: [])
    }
    ctx.restoreGState()

    // Battery Outline Stroke
    ctx.saveGState()
    ctx.addPath(batteryPath)
    ctx.setLineWidth(14.0)
    ctx.setStrokeColor(NSColor(red: 0.45, green: 0.52, blue: 0.65, alpha: 0.95).cgColor)
    ctx.strokePath()

    // Inner highlight stroke for battery shell
    ctx.addPath(batteryPath)
    ctx.setLineWidth(3.0)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.35).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    // 5. Dynamic 3D Electric Lightning Bolt Symbol
    ctx.saveGState()
    // Bolt Path centered over battery
    let bolt = CGMutablePath()
    bolt.move(to: CGPoint(x: 520, y: 690))        // Top peak
    bolt.addLine(to: CGPoint(x: 430, y: 520))     // Left inner notch
    bolt.addLine(to: CGPoint(x: 505, y: 520))     // Center mid step
    bolt.addLine(to: CGPoint(x: 460, y: 330))     // Bottom peak
    bolt.addLine(to: CGPoint(x: 605, y: 495))     // Right inner notch
    bolt.addLine(to: CGPoint(x: 530, y: 495))     // Center mid step
    bolt.closeSubpath()

    // Bolt Drop Shadow & Glow
    ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 22, color: NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.85).cgColor)

    ctx.addPath(bolt)
    ctx.clip()

    // Vivid Golden Yellow to Bright Orange Gradient
    let boltColors = [
        NSColor(red: 1.0, green: 0.98, blue: 0.55, alpha: 1.0).cgColor,  // Bright golden highlight
        NSColor(red: 1.0, green: 0.72, blue: 0.0, alpha: 1.0).cgColor,   // Pure amber yellow
        NSColor(red: 1.0, green: 0.45, blue: 0.0, alpha: 1.0).cgColor    // Warm energetic orange
    ] as CFArray
    if let boltGrad = CGGradient(colorsSpace: colorSpace, colors: boltColors, locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(boltGrad, start: CGPoint(x: 512, y: 690), end: CGPoint(x: 512, y: 330), options: [])
    }
    ctx.restoreGState()

    // Crisp White Rim on Lightning Bolt
    ctx.saveGState()
    ctx.addPath(bolt)
    ctx.setLineWidth(4.0)
    ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    // 6. Subtle Modern "X" emblem at top right corner of squircle
    ctx.saveGState()
    let xCenter = CGPoint(x: 810, y: 810)
    let xSize: CGFloat = 36
    let xPath = CGMutablePath()
    xPath.move(to: CGPoint(x: xCenter.x - xSize, y: xCenter.y - xSize))
    xPath.addLine(to: CGPoint(x: xCenter.x + xSize, y: xCenter.y + xSize))
    xPath.move(to: CGPoint(x: xCenter.x - xSize, y: xCenter.y + xSize))
    xPath.addLine(to: CGPoint(x: xCenter.x + xSize, y: xCenter.y - xSize))

    ctx.addPath(xPath)
    ctx.setLineWidth(10.0)
    ctx.setLineCap(.round)
    ctx.setStrokeColor(NSColor(red: 0.0, green: 0.9, blue: 0.7, alpha: 0.8).cgColor)
    ctx.setShadow(offset: .zero, blur: 12, color: NSColor(red: 0.0, green: 0.9, blue: 0.7, alpha: 0.6).cgColor)
    ctx.strokePath()
    ctx.restoreGState()

    ctx.restoreGState() // Squircle clip restore

    image.unlockFocus()
    return image
}

let iconImage = createBatteryXIcon()
guard let tiffData = iconImage.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiffData),
      let pngData = rep.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render PNG")
}

let fm = FileManager.default
let iconsetDir = "Resources/AppIcon.iconset"
try? fm.removeItem(atPath: iconsetDir)
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Save 1024x1024 master
let masterURL = URL(fileURLWithPath: "\(iconsetDir)/icon_512x512@2x.png")
try pngData.write(to: masterURL)

// Generate all macOS icon sizes
let sizes: [(String, Int)] = [
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

for (filename, targetDim) in sizes {
    let targetSize = NSSize(width: targetDim, height: targetDim)
    let resizedImage = NSImage(size: targetSize)
    resizedImage.lockFocus()
    iconImage.draw(in: NSRect(origin: .zero, size: targetSize), from: NSRect(origin: .zero, size: iconImage.size), operation: .copy, fraction: 1.0)
    resizedImage.unlockFocus()

    if let resizedTiff = resizedImage.tiffRepresentation,
       let resizedRep = NSBitmapImageRep(data: resizedTiff),
       let resizedPng = resizedRep.representation(using: .png, properties: [:]) {
        let fileURL = URL(fileURLWithPath: "\(iconsetDir)/\(filename)")
        try resizedPng.write(to: fileURL)
    }
}

print("✅ Generated all icon sizes in \(iconsetDir)")
