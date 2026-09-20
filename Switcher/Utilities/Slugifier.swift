import Foundation

enum Slugifier {
    static func slug(from name: String) -> String {
        var result = ""
        var previousWasSeparator = false

        for character in name.lowercased() {
            if character.isLetter || character.isNumber {
                result.append(character)
                previousWasSeparator = false
            } else if character == " " || character == "_" || character == "-" {
                if !previousWasSeparator && !result.isEmpty {
                    result.append("-")
                    previousWasSeparator = true
                }
            }
        }

        let trimmed = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? "project" : trimmed
    }
}
