import SwiftCrossUI

// MARK: - Avatar

struct AvatarView: View {
    let letter: String
    let size: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Double(size) / 4.0)
                .foregroundColor(.gray)
            Text(letter)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Entry row

struct EntryRow: View {
    let name: String
    let subtitle: String

    var initial: String { String(name.prefix(1)).uppercased() }

    var body: some View {
        HStack {
            AvatarView(letter: initial, size: 36)
            VStack(alignment: .leading) {
                Text(name)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
