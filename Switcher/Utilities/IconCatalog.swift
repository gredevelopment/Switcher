import AppKit
import SwiftUI

enum IconCatalog {
    static let defaultIcon = "folder.fill"
    static let defaultColorHex = "#5E5CE6"

    static let allIcons: [String] = {
        var icons: [String] = []
        icons.append(contentsOf: development)
        icons.append(contentsOf: devices)
        icons.append(contentsOf: connectivity)
        icons.append(contentsOf: data)
        icons.append(contentsOf: commerce)
        icons.append(contentsOf: media)
        icons.append(contentsOf: nature)
        icons.append(contentsOf: symbols)
        icons.append(contentsOf: shapes)
        return Array(Set(icons)).sorted()
    }()

    static func icons(matching query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allIcons }
        let terms = trimmed.lowercased().split(separator: " ").map(String.init)
        return allIcons.filter { icon in
            let haystack = icon.lowercased()
            return terms.allSatisfy { haystack.contains($0) }
        }
    }

    static let presetColors: [(name: String, hex: String)] = [
        ("Indigo", "#5E5CE6"),
        ("Blue", "#0A84FF"),
        ("Teal", "#64D2FF"),
        ("Green", "#30D158"),
        ("Mint", "#63E6E2"),
        ("Yellow", "#FFD60A"),
        ("Orange", "#FF9F0A"),
        ("Red", "#FF453A"),
        ("Pink", "#FF375F"),
        ("Purple", "#BF5AF2"),
        ("Brown", "#AC8E68"),
        ("Gray", "#8E8E93"),
    ]

    private static let development = [
        "folder.fill", "folder.badge.gearshape", "doc.fill", "doc.text.fill",
        "terminal.fill", "curlybraces", "chevron.left.forwardslash.chevron.right",
        "hammer.fill", "wrench.and.screwdriver.fill", "gearshape.fill",
        "gearshape.2.fill", "cpu.fill", "memorychip.fill", "server.rack",
        "externaldrive.fill", "internaldrive.fill", "opticaldiscdrive.fill",
        "archivebox.fill", "tray.full.fill", "shippingbox.fill",
        "cube.fill", "cube.transparent.fill", "square.stack.3d.up.fill",
        "app.fill", "app.badge.fill", "app.dashed", "macwindow",
        "macwindow.on.rectangle", "sidebar.left", "sidebar.right",
        "list.bullet.rectangle.fill", "tablecells.fill", "rectangle.grid.2x2.fill",
        "square.grid.3x3.fill", "square.grid.3x3.topleft.filled",
        "puzzlepiece.fill", "function", "sum", "x.squareroot",
        "number", "textformat.123", "character.cursor.ibeam",
        "keyboard.fill", "command", "option", "control",
        "play.rectangle.fill", "play.circle.fill", "stop.circle.fill",
        "record.circle.fill", "pause.circle.fill", "forward.fill",
        "backward.fill", "repeat", "shuffle", "arrow.triangle.2.circlepath",
        "clock.fill", "timer", "hourglass", "calendar",
        "bell.fill", "bell.badge.fill", "tag.fill", "bookmark.fill",
        "flag.fill", "pin.fill", "mappin.circle.fill", "location.fill",
        "scope", "target", "crosshair", "viewfinder",
        "magnifyingglass", "magnifyingglass.circle.fill", "binoculars.fill",
        "eye.fill", "eye.slash.fill", "lock.fill", "lock.open.fill",
        "key.fill", "shield.fill", "checkmark.shield.fill", "exclamationmark.shield.fill",
        "hand.raised.fill", "hand.thumbsup.fill", "hand.thumbsdown.fill",
        "person.fill", "person.2.fill", "person.3.fill", "person.crop.circle.fill",
        "building.fill", "building.2.fill", "house.fill", "storefront.fill",
    ]

    private static let devices = [
        "laptopcomputer", "desktopcomputer", "pc", "display",
        "iphone", "ipad", "ipod", "applewatch",
        "appletv.fill", "homepod.fill", "homepodmini.fill", "hifispeaker.fill",
        "headphones", "earbuds", "airpods", "airpodsmax",
        "airpodspro", "beats.headphones", "tv.fill", "tv.and.hifispeaker.fill",
        "gamecontroller.fill", "arcade.stick", "camera.fill", "camera.metering.center.weighted",
        "video.fill", "video.circle.fill", "photo.fill", "photo.on.rectangle.angled",
        "printer.fill", "scanner.fill", "faxmachine.fill", "phone.fill",
        "phone.circle.fill", "envelope.fill", "envelope.open.fill", "paperplane.fill",
        "tray.fill", "tray.and.arrow.down.fill", "tray.and.arrow.up.fill",
        "calendar.badge.clock", "calendar.badge.plus", "calendar.badge.minus",
        "battery.100", "battery.75", "battery.50", "battery.25",
        "bolt.fill", "bolt.circle.fill", "bolt.badge.a.fill", "powerplug.fill",
        "lightbulb.fill", "lightbulb.max.fill", "flashlight.on.fill", "fanblades.fill",
    ]

    private static let connectivity = [
        "globe", "globe.americas.fill", "globe.europe.africa.fill", "globe.asia.australia.fill",
        "network", "wifi", "wifi.circle.fill", "antenna.radiowaves.left.and.right",
        "antenna.radiowaves.left.and.right.circle.fill", "cellularbars",
        "personalhotspot", "link", "link.circle.fill", "link.badge.plus",
        "arrow.left.arrow.right", "arrow.up.arrow.down", "arrow.triangle.branch",
        "arrow.triangle.merge", "arrow.triangle.swap", "arrow.2.squarepath",
        "arrow.clockwise", "arrow.counterclockwise", "arrow.uturn.left",
        "arrow.uturn.right", "arrow.uturn.up", "arrow.uturn.down",
        "square.and.arrow.up", "square.and.arrow.down", "square.and.arrow.up.on.square.fill",
        "icloud.fill", "icloud.and.arrow.up.fill", "icloud.and.arrow.down.fill",
        "cloud.fill", "cloud.rain.fill", "cloud.sun.fill", "cloud.bolt.fill",
        "bonjour", "dot.radiowaves.left.and.right", "sensor.tag.radiowaves.forward.fill",
        "shareplay", "shareplay.slash", "airplayaudio", "airplayvideo",
        "cable.connector", "cable.connector.horizontal", "platter.filled.top.iphone",
        "platter.filled.bottom.iphone", "platter.filled.top.and.arrow.up.iphone",
        "point.3.connected.trianglepath.dotted", "point.3.filled.connected.trianglepath.dotted",
    ]

    private static let data = [
        "chart.bar.fill", "chart.line.uptrend.xyaxis", "chart.pie.fill",
        "chart.xyaxis.line", "chart.dots.scatter", "waveform.path.ecg",
        "waveform", "waveform.circle.fill", "gauge.open.with.lines.needle.67percent.and.arrowtriangle",
        "speedometer", "dial.high.fill", "dial.medium.fill", "dial.low.fill",
        "slider.horizontal.3", "switch.2", "toggleswitch",
        "list.bullet", "list.number", "list.dash", "list.triangle",
        "text.alignleft", "text.aligncenter", "text.alignright", "text.justify",
        "bold", "italic", "underline", "strikethrough",
        "textformat", "textformat.size", "textformat.alt", "textformat.subscript",
        "textformat.superscript", "paragraphsign", "asterisk", "at",
        "number.circle.fill", "number.square.fill", "percent", "divide",
        "plus.forwardslash.minus", "equal.circle.fill", "xmark.circle.fill",
        "checkmark.circle.fill", "questionmark.circle.fill", "exclamationmark.circle.fill",
        "info.circle.fill", "plus.circle.fill", "minus.circle.fill",
        "multiply.circle.fill", "circle.fill", "square.fill", "triangle.fill",
        "diamond.fill", "hexagon.fill", "octagon.fill", "pentagon.fill",
        "seal.fill", "star.fill", "star.leadinghalf.filled", "heart.fill",
        "sparkles", "sparkle", "wand.and.stars", "wand.and.rays",
        "crown.fill", "trophy.fill", "medal.fill", "rosette",
    ]

    private static let commerce = [
        "cart.fill", "cart.badge.plus", "cart.badge.minus", "bag.fill",
        "bag.badge.plus", "bag.badge.minus", "basket.fill", "creditcard.fill",
        "creditcard.and.123", "banknote.fill", "dollarsign.circle.fill",
        "eurosign.circle.fill", "sterlingsign.circle.fill", "yensign.circle.fill",
        "bitcoinsign.circle.fill", "centsign.circle.fill", "gift.fill",
        "giftcard.fill", "ticket.fill", "barcode", "qrcode",
        "wallet.pass.fill", "signature", "scroll.fill", "doc.plaintext.fill",
        "doc.richtext.fill", "doc.append.fill", "doc.on.doc.fill",
        "newspaper.fill", "magazine.fill", "books.vertical.fill", "book.fill",
        "book.closed.fill", "graduationcap.fill", "studentdesk", "backpack.fill",
        "briefcase.fill", "suitcase.fill", "suitcase.cart.fill", "car.fill",
        "bus.fill", "tram.fill", "airplane", "ferry.fill",
        "bicycle", "scooter", "fuelpump.fill", "parkingsign.circle.fill",
    ]

    private static let media = [
        "music.note", "music.note.list", "music.quarternote.3", "guitars.fill",
        "pianokeys.fill", "hifispeaker.2.fill", "speaker.wave.3.fill", "speaker.slash.fill",
        "mic.fill", "mic.circle.fill", "mic.badge.plus", "video.badge.plus",
        "film.fill", "film.stack.fill", "popcorn.fill", "ticket.fill",
        "theatermasks.fill", "paintbrush.fill", "paintbrush.pointed.fill", "paintpalette.fill",
        "swatchpalette.fill", "eyedropper.halffull", "camera.filters", "camera.macro",
        "photo.artframe", "photo.stack.fill", "livephoto", "livephoto.play",
        "play.fill", "pause.fill", "stop.fill", "eject.fill",
        "forward.end.fill", "backward.end.fill", "goforward.10", "gobackward.10",
        "speaker.zzz.fill", "bell.and.waves.left.and.right.fill", "waveform.badge.mic",
        "waveform.badge.plus", "waveform.badge.minus", "waveform.badge.exclamationmark",
        "rectangle.and.pencil.and.ellipsis", "pencil", "pencil.and.outline", "pencil.tip",
        "eraser.fill", "highlighter", "lasso", "scribble.variable",
        "hand.draw.fill", "hand.point.up.left.fill", "hand.tap.fill", "hand.wave.fill",
    ]

    private static let nature = [
        "leaf.fill", "leaf.circle.fill", "tree.fill", "tree.circle.fill",
        "flame.fill", "flame.circle.fill", "drop.fill", "drop.circle.fill",
        "snowflake", "snowflake.circle.fill", "wind", "wind.snow",
        "sun.max.fill", "sun.min.fill", "sun.horizon.fill", "moon.fill",
        "moon.stars.fill", "moon.zzz.fill", "cloud.fill", "cloud.sun.fill",
        "cloud.moon.fill", "cloud.rain.fill", "cloud.snow.fill", "cloud.bolt.fill",
        "cloud.bolt.rain.fill", "cloud.fog.fill", "cloud.hail.fill", "tornado",
        "hurricane", "thermometer.sun.fill", "thermometer.snowflake", "humidity.fill",
        "mountain.2.fill", "water.waves", "beach.umbrella.fill", "tent.fill",
        "campfire.fill", "binoculars.fill", "globe.desk.fill", "map.fill",
        "safari.fill", "compass.drawing", "location.north.fill", "location.circle.fill",
        "figure.walk", "figure.run", "figure.hiking", "figure.climbing",
        "pawprint.fill", "hare.fill", "tortoise.fill", "ant.fill",
        "ladybug.fill", "fish.fill", "bird.fill", "lizard.fill",
    ]

    private static let symbols = [
        "checkmark", "checkmark.circle", "checkmark.seal.fill", "xmark",
        "xmark.circle", "xmark.seal.fill", "plus", "minus",
        "plusminus", "multiply", "divide", "equal",
        "lessthan", "greaterthan", "exclamationmark", "exclamationmark.2",
        "exclamationmark.3", "questionmark", "questionmark.diamond.fill",
        "arrow.up", "arrow.down", "arrow.left", "arrow.right",
        "arrow.up.left", "arrow.up.right", "arrow.down.left", "arrow.down.right",
        "chevron.up", "chevron.down", "chevron.left", "chevron.right",
        "chevron.up.chevron.down", "chevron.compact.up", "chevron.compact.down",
        "ellipsis", "ellipsis.circle.fill", "line.3.horizontal", "line.3.horizontal.decrease",
        "line.3.horizontal.decrease.circle.fill", "slider.horizontal.below.rectangle",
        "square.and.pencil", "square.and.arrow.up", "square.and.arrow.down",
        "rectangle.portrait.and.arrow.right", "rectangle.portrait.and.arrow.forward",
        "arrowshape.turn.up.right.fill", "arrowshape.turn.up.left.fill",
        "arrowshape.turn.up.forward.fill", "arrowshape.turn.up.backward.fill",
        "paperclip", "link", "paperclip.circle.fill", "link.badge.plus",
        "infinity", "pi", "eurosign", "dollarsign",
        "sterlingsign", "yensign", "bitcoinsign", "number.sign",
        "centsign", "florinsign", "francsign", "lirasign",
        "rublesign", "rupeesign", "shekelsign", "wonsign",
        "tugriksign", "turkishlirasign", "indianrupeesign", "brazilianrealsign",
    ]

    private static let shapes = [
        "circle", "circle.dashed", "circle.dotted", "circle.grid.2x2.fill",
        "circle.grid.3x3.fill", "circle.grid.cross.fill", "square", "square.dashed",
        "square.dotted", "rectangle.fill", "rectangle.portrait.fill", "capsule.fill",
        "oval.fill", "triangle.fill", "diamond.fill", "rhombus.fill",
        "pentagon.fill", "hexagon.fill", "octagon.fill", "seal.fill",
        "app.fill", "app.dashed", "app.badge.fill", "app.gift.fill",
        "button.horizontal.fill", "button.angledtop.vertical.left.fill",
        "capsule.portrait.fill", "oval.portrait.fill", "shield.fill",
        "shield.lefthalf.filled", "shield.righthalf.filled", "shield.checkered",
        "shield.slash.fill", "flag.fill", "flag.2.crossed.fill", "flag.and.flag.filled.crossed",
        "bookmark.fill", "bookmark.circle.fill", "bookmark.square.fill", "tag.fill",
        "tag.circle.fill", "tag.square.fill", "rosette", "laurel.leading",
        "laurel.trailing", "medal.fill", "trophy.fill", "crown.fill",
        "seal.fill", "star.fill", "star.circle.fill", "star.square.fill",
        "heart.fill", "heart.circle.fill", "heart.square.fill", "bolt.heart.fill",
        "sparkles", "sparkle", "moon.stars.fill", "sun.max.fill",
    ]
}

extension Color {
    init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    var hexString: String {
        guard let components = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components, components.count >= 3 else {
            return IconCatalog.defaultColorHex
        }
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    /// Tuned glyph color for SF Symbols. Background tints should keep using `iconColor` directly.
    func iconGlyph(colorScheme: ColorScheme, muted: Bool = false) -> Color {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else { return self }

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        switch colorScheme {
        case .dark:
            if saturation > 0.01 {
                saturation = min(saturation * 1.3 + 0.12, 1)
                let floor: CGFloat = muted ? 0.7 : 0.82
                brightness = max(min(brightness * 0.5 + 0.48, 1), floor)
            } else {
                brightness = muted ? 0.58 : 0.74
            }
        case .light:
            if saturation > 0.01 {
                saturation = min(saturation * 1.2, 1)
                brightness = min(max(brightness * 0.9, 0.38), 0.68)
            } else {
                brightness = muted ? 0.42 : 0.5
            }
        @unknown default:
            break
        }

        return Color(
            hue: Double(hue),
            saturation: Double(saturation),
            brightness: Double(brightness),
            opacity: Double(alpha)
        )
    }
}
