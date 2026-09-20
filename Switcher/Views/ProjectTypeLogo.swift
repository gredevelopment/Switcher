import SwiftUI

struct ProjectTypeLogo: View {
    let type: DetectedProjectType
    var size: CGFloat = 14

    var body: some View {
        if let assetName = type.assetName {
            Image(assetName)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .accessibilityLabel(type.label)
        }
    }
}
