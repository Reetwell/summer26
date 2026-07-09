import SwiftUI

struct ShoppingView: View {
    private let store = ShoppingStore.shared
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newAmount = ""
    @State private var newCategory = "Other"
    @State private var toastMessage: String?

    private var percent: Int {
        store.totalCount > 0 ? Int((Double(store.doneCount) / Double(store.totalCount) * 100).rounded()) : 0
    }

    var body: some View {
        ScrollView {
            content
                .padding(contentPadding)
                .frame(maxWidth: 960, alignment: .leading)
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: store.doneCount)
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
        .sheet(isPresented: $showAdd) { addItemSheet }
        .overlay(alignment: .top) {
            if let msg = toastMessage {
                Text(msg)
                    .font(.sans(14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color.green500, in: Capsule())
                    .padding(.top, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    #if os(macOS)
    private var contentPadding: CGFloat { 40 }
    private let columns = [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]
    #else
    private var contentPadding: CGFloat { Spacing.md }
    private let columns = [GridItem(.flexible(), spacing: Spacing.md)]
    #endif

    private var content: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            hero.slideIn()

            // action buttons
            HStack {
                Spacer()
                pillButton("Copy list", icon: "doc.on.doc", tint: Color.green700, action: copyList)
                if store.doneCount > 0 {
                    pillButton("Clear checked", icon: "line.3.horizontal.decrease", tint: Color(hex: "#E8564A")) {
                        withAnimation { store.clearDone() }
                    }
                }
            }
            .slideIn(delay: 0.04)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(Array(store.sections.enumerated()), id: \.element.title) { i, section in
                    sectionCard(section).slideIn(delay: 0.08 + Double(i) * 0.05)
                }
            }

            addItemRow.slideIn(delay: 0.3)
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("SHOPPING LIST")
                .font(.sans(11, weight: .bold))
                .kerning(1.6)
                .foregroundStyle(.white.opacity(0.7))
            (Text("\(store.doneCount) of \(store.totalCount) ").foregroundStyle(.white)
             + Text("got").foregroundStyle(.white.opacity(0.72)))
                .font(.serifDisplay(46))
                .contentTransition(.numericText())
            Text("This week's list, built from your meals.")
                .font(.sans(14))
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 6) {
                HStack {
                    Text("Progress").font(.sans(12, weight: .semibold)).foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    Text("\(percent)%").font(.sans(12, weight: .bold)).foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.2))
                        Capsule().fill(Color(hex: "#86F8C9"))
                            .frame(width: store.totalCount > 0 ? geo.size.width * CGFloat(store.doneCount) / CGFloat(store.totalCount) : 0)
                    }
                }
                .frame(height: 6)
            }
            .padding(.top, 4)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.green700, Color.green900],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28)
        )
    }

    // MARK: - Section card

    private func sectionCard(_ section: (title: String, items: [ShopItem])) -> some View {
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: sectionIcon(section.title))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(section.title.uppercased())
                        .font(.sans(11, weight: .bold))
                        .kerning(1.3)
                        .foregroundStyle(.secondary)
                }
                VStack(spacing: 0) {
                    ForEach(section.items) { item in
                        itemRow(item)
                        if item.id != section.items.last?.id {
                            Divider().padding(.leading, 34)
                        }
                    }
                }
            }
        }
    }

    private func itemRow(_ item: ShopItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                store.toggle(id: item.id)
            }
        } label: {
            HStack(spacing: Spacing.md) {
                ZStack {
                    Circle()
                        .stroke(item.done ? Color.green500 : Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if item.done {
                        Circle().fill(Color.green500).frame(width: 22, height: 22)
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
                if !item.amount.isEmpty {
                    Text(item.amount)
                        .font(.sans(13))
                        .strikethrough(item.done, color: .secondary)
                        .foregroundStyle(item.done ? Color.secondary.opacity(0.55) : Color.secondary.opacity(0.75))
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addItemRow: some View {
        Button {
            showAdd = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "plus").font(.system(size: 13, weight: .semibold))
                Text("Add item").font(.sans(14, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func pillButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(title).font(.sans(13, weight: .semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(Color.bbSurface, in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func sectionIcon(_ title: String) -> String {
        switch title.lowercased() {
        case "protein": return "fish.fill"
        case "carbs": return "circle.grid.2x2.fill"
        case "produce": return "leaf.fill"
        case "dairy": return "drop.fill"
        case "supplements": return "pills.fill"
        default: return "bag.fill"
        }
    }

    // MARK: - Add item sheet

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name (e.g. Chicken breast)", text: $newName)
                    TextField("Amount (e.g. 500g)", text: $newAmount)
                }
                Section("Category") {
                    Picker("Category", selection: $newCategory) {
                        ForEach(["Protein", "Carbs", "Produce", "Dairy", "Supplements", "Other"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Add item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAdd = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        store.add(ShopItem(name: newName, amount: newAmount, category: newCategory))
                        newName = ""; newAmount = ""; newCategory = "Other"
                        showAdd = false
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .font(.sans(15, weight: .semibold))
                    .foregroundStyle(Color.green500)
                }
            }
        }
    }

    // MARK: - Actions

    private func copyList() {
        let text = store.copyText()
        #if os(iOS)
        UIPasteboard.general.string = text
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        showToast("List copied!")
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}
