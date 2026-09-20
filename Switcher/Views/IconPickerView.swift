import AppKit
import SwiftUI

struct IconPickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    let projectID: UUID

    @Binding var selectedIcon: String
    @Binding var selectedColorHex: String
    @Binding var iconStyle: ProjectIconStyle

    @State private var searchText = ""
    @State private var imageImportError: String?
    @State private var imageRefreshToken = UUID()
    @FocusState private var focusedField: FocusField?

    private enum FocusField: Hashable {
        case search
    }

    private var filteredIcons: [String] {
        IconCatalog.icons(matching: searchText)
    }

    private var selectedColor: Color {
        Color(hex: selectedColorHex) ?? Color(hex: IconCatalog.defaultColorHex)!
    }

    private var hasCustomImage: Bool {
        ProjectIconStore.hasImage(for: projectID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Appearance", selection: $iconStyle) {
                        ForEach(ProjectIconStyle.allCases, id: \.self) { style in
                            Text(style.label).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)

                    preview

                    switch iconStyle {
                    case .symbol:
                        colorSection
                        iconSection
                    case .image:
                        imageSection
                    }
                }
                .padding(20)
            }
            .navigationTitle("Project Icon")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(iconStyle == .image && !hasCustomImage)
                }
            }
            .nativeScrollEdgeChrome()
            .frame(minWidth: 480, minHeight: 520)
            .defaultFocus($focusedField, nil)
            .clearInitialFocusOnAppear()
            .onChange(of: iconStyle) { _, newStyle in
                if newStyle == .symbol {
                    ProjectIconStore.deleteImage(for: projectID)
                    imageRefreshToken = UUID()
                }
            }
        }
    }

    private var preview: some View {
        HStack(spacing: 12) {
            ProjectIconTile(
                iconStyle: iconStyle,
                projectID: projectID,
                iconName: selectedIcon,
                iconColorHex: selectedColorHex,
                isActive: true,
                imageRefreshToken: imageRefreshToken
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Preview")
                    .font(.subheadline.weight(.medium))

                if iconStyle == .symbol {
                    Text(selectedIcon)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if hasCustomImage {
                    Text("Custom image")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Choose an image")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 8), count: 6), spacing: 8) {
                ForEach(IconCatalog.presetColors, id: \.hex) { preset in
                    Button {
                        selectedColorHex = preset.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: preset.hex) ?? .accentColor)
                            .frame(width: 28, height: 28)
                            .overlay {
                                if selectedColorHex == preset.hex {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: 2)
                                }
                            }
                            .overlay {
                                if selectedColorHex == preset.hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help(preset.name)
                }
            }

            ColorPicker("Custom color", selection: Binding(
                get: { selectedColor },
                set: { selectedColorHex = $0.hexString }
            ))
        }
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Icon")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(filteredIcons.count) icons")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            TextField("Search icons", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .search)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(44), spacing: 8), count: 8),
                spacing: 8
            ) {
                ForEach(filteredIcons, id: \.self) { icon in
                    Button {
                        selectedIcon = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(
                                selectedIcon == icon
                                    ? selectedColor.iconGlyph(colorScheme: colorScheme)
                                    : .secondary
                            )
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        selectedIcon == icon
                                            ? selectedColor.opacity(0.18)
                                            : Color.secondary.opacity(0.08)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help(icon)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("The image fills the entire icon box.")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack(spacing: 10) {
                Button("Choose Image…") {
                    chooseImage()
                }

                if hasCustomImage {
                    Button("Remove Image", role: .destructive) {
                        removeImage()
                    }
                }
            }

            if let imageImportError {
                Text(imageImportError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func chooseImage() {
        imageImportError = nil

        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = ProjectIconStore.allowedContentTypes
        panel.prompt = "Choose"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try ProjectIconStore.importImage(from: url, for: projectID)
            iconStyle = .image
            imageRefreshToken = UUID()
        } catch {
            imageImportError = error.localizedDescription
        }
    }

    private func removeImage() {
        ProjectIconStore.deleteImage(for: projectID)
        imageRefreshToken = UUID()
    }
}

struct ProjectIconTile: View {
    @Environment(\.colorScheme) private var colorScheme

    var iconStyle: ProjectIconStyle = .symbol
    var projectID: UUID?
    let iconName: String
    let iconColorHex: String
    var isActive: Bool = true
    var size: CGFloat = 44
    var imageRefreshToken: UUID = UUID()

    init(project: Project, isActive: Bool = true, size: CGFloat = 44, imageRefreshToken: UUID = UUID()) {
        self.iconStyle = project.iconStyle
        self.projectID = project.id
        self.iconName = project.iconName
        self.iconColorHex = project.iconColorHex
        self.isActive = isActive
        self.size = size
        self.imageRefreshToken = imageRefreshToken
    }

    init(
        iconStyle: ProjectIconStyle = .symbol,
        projectID: UUID? = nil,
        iconName: String,
        iconColorHex: String,
        isActive: Bool = true,
        size: CGFloat = 44,
        imageRefreshToken: UUID = UUID()
    ) {
        self.iconStyle = iconStyle
        self.projectID = projectID
        self.iconName = iconName
        self.iconColorHex = iconColorHex
        self.isActive = isActive
        self.size = size
        self.imageRefreshToken = imageRefreshToken
    }

    private var iconColor: Color {
        Color(hex: iconColorHex) ?? Color(hex: IconCatalog.defaultColorHex)!
    }

    private var glyphColor: Color {
        iconColor.iconGlyph(colorScheme: colorScheme, muted: !isActive)
    }

    var body: some View {
        Group {
            if iconStyle == .image, let projectID, let image = ProjectIconStore.image(for: projectID) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            iconColor
                                .opacity(isActive ? 0.2 : 0.12)
                        )
                        .frame(width: size, height: size)

                    Image(systemName: iconName)
                        .font(.system(size: size * 0.45, weight: .medium))
                        .foregroundStyle(glyphColor)
                }
            }
        }
        .id(imageRefreshToken)
    }
}
