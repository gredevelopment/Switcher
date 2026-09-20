import AppKit
import SwiftUI

struct IconPickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedIcon: String
    @Binding var selectedColorHex: String

    @State private var searchText = ""
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    preview

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
                .padding(20)
            }
            .navigationTitle("Icon & Color")
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
                }
            }
            .nativeScrollEdgeChrome()
            .frame(minWidth: 480, minHeight: 520)
            .defaultFocus($focusedField, nil)
            .clearInitialFocusOnAppear()
        }
    }

    private var preview: some View {
        HStack(spacing: 12) {
            ProjectIconTile(
                iconName: selectedIcon,
                iconColorHex: selectedColorHex,
                isActive: true
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("Preview")
                    .font(.subheadline.weight(.medium))
                Text(selectedIcon)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
    }
}

struct ProjectIconTile: View {
    @Environment(\.colorScheme) private var colorScheme

    let iconName: String
    let iconColorHex: String
    var isActive: Bool = true
    var size: CGFloat = 44

    private var iconColor: Color {
        Color(hex: iconColorHex) ?? Color(hex: IconCatalog.defaultColorHex)!
    }

    private var glyphColor: Color {
        iconColor.iconGlyph(colorScheme: colorScheme, muted: !isActive)
    }

    var body: some View {
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
