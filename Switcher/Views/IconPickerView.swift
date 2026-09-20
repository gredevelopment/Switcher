import SwiftUI

struct IconPickerView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selectedIcon: String
    @Binding var selectedColorHex: String

    @State private var searchText = ""

    private var filteredIcons: [String] {
        IconCatalog.icons(matching: searchText)
    }

    private var selectedColor: Color {
        Color(hex: selectedColorHex) ?? Color(hex: IconCatalog.defaultColorHex)!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

                ScrollView {
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
                            .help(icon)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 220)
            }
        }
    }

    private var preview: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selectedColor.opacity(0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: selectedIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(selectedColor.iconGlyph(colorScheme: colorScheme))
            }

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
