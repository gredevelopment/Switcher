import AppKit
import UniformTypeIdentifiers

enum ProjectIconStore {
    private static let maxDimension: CGFloat = 256

    enum ImportError: LocalizedError {
        case unreadable
        case conversionFailed

        var errorDescription: String? {
            switch self {
            case .unreadable:
                "The selected image could not be read."
            case .conversionFailed:
                "The selected image could not be converted."
            }
        }
    }

    static var iconsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("Switcher/ProjectIcons", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func imageURL(for projectID: UUID) -> URL {
        iconsDirectory.appendingPathComponent("\(projectID.uuidString).png")
    }

    static func hasImage(for projectID: UUID) -> Bool {
        FileManager.default.fileExists(atPath: imageURL(for: projectID).path)
    }

    static func image(for projectID: UUID) -> NSImage? {
        let url = imageURL(for: projectID)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return NSImage(contentsOf: url)
    }

    static func importImage(from sourceURL: URL, for projectID: UUID) throws {
        guard let sourceImage = NSImage(contentsOf: sourceURL) else {
            throw ImportError.unreadable
        }

        let resized = resize(sourceImage, maxDimension: maxDimension)
        guard
            let tiffData = resized.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw ImportError.conversionFailed
        }

        try pngData.write(to: imageURL(for: projectID), options: .atomic)
    }

    static func deleteImage(for projectID: UUID) {
        let url = imageURL(for: projectID)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    static let allowedContentTypes: [UTType] = [.png, .jpeg, .heic, .webP, .gif, .tiff, .bmp]

    private static func resize(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return image }

        let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1)
        guard scale < 1 else { return image }

        let targetSize = NSSize(
            width: floor(originalSize.width * scale),
            height: floor(originalSize.height * scale)
        )

        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1
        )
        resized.unlockFocus()
        return resized
    }
}
