import SwiftUI

struct ShopItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: String
    var done: Bool = false
}

struct ShopSection: Identifiable {
    let id = UUID()
    let title: String
    var items: [ShopItem]
}

struct ShoppingView: View {
    @State private var sections = [
        ShopSection(title: "Protein", items: [
            ShopItem(name: "Chicken breast", amount: "1.2 kg"),
            ShopItem(name: "Salmon fillets", amount: "4"),
            ShopItem(name: "Greek yogurt", amount: "1 kg"),
            ShopItem(name: "Eggs", amount: "12")
        ]),
        ShopSection(title: "Carbs", items: [
            ShopItem(name: "Basmati rice", amount: "1 kg"),
            ShopItem(name: "Wholemeal wraps", amount: "8"),
            ShopItem(name: "Oats", amount: "500 g"),
            ShopItem(name: "Bananas", amount: "6")
        ]),
        ShopSection(title: "Produce", items: [
            ShopItem(name: "Broccoli", amount: "2 heads"),
            ShopItem(name: "Spinach", amount: "400 g"),
            ShopItem(name: "Peppers", amount: "3"),
            ShopItem(name: "Avocados", amount: "2")
        ])
    ]

    private var totalCount: Int { sections.flatMap(\.items).count }
    private var doneCount: Int { sections.flatMap(\.items).filter(\.done).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Shopping")
                    .font(.serifDisplay(34))
                    .slideIn()

                // Progress
                BBCard(padding: Spacing.sm) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("This week's list")
                                .font(.sans(14, weight: .semibold))
                            Spacer()
                            Text("\(doneCount) of \(totalCount)")
                                .font(.sans(13))
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.green500.opacity(0.14))
                                Capsule().fill(Color.green500)
                                    .frame(width: totalCount > 0 ? geo.size.width * CGFloat(doneCount) / CGFloat(totalCount) : 0)
                            }
                        }
                        .frame(height: 7)
                    }
                }
                .slideIn(delay: 0.05)

                ForEach(Array(sections.enumerated()), id: \.element.id) { sIndex, section in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(section.title.uppercased())
                            .font(.sans(11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .kerning(1.2)

                        BBCard(padding: Spacing.xs) {
                            VStack(spacing: 0) {
                                ForEach(section.items) { item in
                                    itemRow(item, sectionIndex: sIndex)
                                    if item.id != section.items.last?.id {
                                        Divider().padding(.leading, 46)
                                    }
                                }
                            }
                        }
                    }
                    .slideIn(delay: 0.1 + Double(sIndex) * 0.07)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.bbBackground)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func itemRow(_ item: ShopItem, sectionIndex: Int) -> some View {
        Button {
            toggle(item, in: sectionIndex)
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(item.done ? Color.green500 : Color.secondary.opacity(0.35), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.done ? Color.green500 : .clear)
                        )
                        .frame(width: 21, height: 21)

                    if item.done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                }

                Text(item.name)
                    .font(.sans(15))
                    .strikethrough(item.done, color: .secondary)
                    .foregroundStyle(item.done ? .secondary : .primary)

                Spacer()

                Text(item.amount)
                    .font(.sans(13))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func toggle(_ item: ShopItem, in sectionIndex: Int) {
        guard let itemIndex = sections[sectionIndex].items.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            sections[sectionIndex].items[itemIndex].done.toggle()
        }
    }
}
