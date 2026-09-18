#!/usr/bin/env swift
import AppKit
import SwiftUI

/// Turns a square mark into a macOS app icon: continuous squircle, gel gloss, transparent corners.
/// Usage: swift scripts/make-macos-icon.swift [artwork.png] [output.png]

let fileManager = FileManager.default
let repoRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let defaultArtwork = repoRoot.appendingPathComponent("src-tauri/icons/artwork.png")
let defaultOutput = repoRoot.appendingPathComponent("src-tauri/icons/macos-app-icon.png")

let artworkURL = URL(fileURLWithPath: CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : defaultArtwork.path)
let outputURL = URL(fileURLWithPath: CommandLine.arguments.count > 2
    ? CommandLine.arguments[2]
    : defaultOutput.path)

guard let source = NSImage(contentsOf: artworkURL) else {
    fputs("Could not read artwork at \(artworkURL.path)\n", stderr)
    exit(1)
}

let _ = NSApplication.shared

func cropOpaque(from image: NSImage) -> NSImage {
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff)
    else { return image }

    var minX = rep.pixelsWide
    var minY = rep.pixelsHigh
    var maxX = 0
    var maxY = 0

    for y in 0..<rep.pixelsHigh {
        for x in 0..<rep.pixelsWide {
            guard let color = rep.colorAt(x: x, y: y) else { continue }
            if color.alphaComponent > 0.04 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }

    guard maxX > minX, maxY > minY else { return image }

    let rect = NSRect(
        x: minX,
        y: minY,
        width: maxX - minX + 1,
        height: maxY - minY + 1
    )
    guard let cropped = rep.cgImage?.cropping(to: rect) else { return image }
    return NSImage(cgImage: cropped, size: NSSize(width: rect.width, height: rect.height))
}

struct MacAppIcon: View {
    let artwork: NSImage
    let canvas: CGFloat = 1024
    /// Apple's macOS production template: 824pt glyph on a 1024 canvas, 185pt continuous corners.
    let glyph: CGFloat = 824
    let radius: CGFloat = 185

    var body: some View {
        ZStack {
            Color.clear

            ZStack {
                Image(nsImage: artwork)
                    .resizable()
                    .scaledToFill()
                    .frame(width: glyph, height: glyph)
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.clear,
                        Color.black.opacity(0.22)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.62), location: 0),
                        .init(color: Color.white.opacity(0.22), location: 0.32),
                        .init(color: Color.white.opacity(0.0), location: 0.58)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask(
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: glyph * 1.42, height: glyph * 0.98)
                        .offset(y: -glyph * 0.30)
                )

                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.72),
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.04)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2.5
                    )
                    .padding(1)
            }
            .frame(width: glyph, height: glyph)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
        .frame(width: canvas, height: canvas)
        .preferredColorScheme(.light)
    }
}

@MainActor
func renderAndWrite() {
    let cropped = cropOpaque(from: source)
    let renderer = ImageRenderer(content: MacAppIcon(artwork: cropped))
    renderer.scale = 2
    renderer.proposedSize = ProposedViewSize(width: 1024, height: 1024)

    guard let cgImage = renderer.cgImage else {
        fputs("SwiftUI failed to render the macOS icon\n", stderr)
        exit(1)
    }

    let bitmap = NSBitmapImageRep(cgImage: cgImage)
    bitmap.size = NSSize(width: 1024, height: 1024)
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fputs("Could not encode PNG\n", stderr)
        exit(1)
    }

    do {
        try png.write(to: outputURL)
        print("Wrote \(outputURL.path)")
        exit(0)
    } catch {
        fputs("Could not write \(outputURL.path): \(error)\n", stderr)
        exit(1)
    }
}

Task { @MainActor in
    renderAndWrite()
}
RunLoop.main.run()
