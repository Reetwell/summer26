import SwiftUI

struct ShoppingView: View {
    private let store = ShoppingStore.shared
    @State private var showAdd = false
    @State private var newName = ""
    @State private var newAmount = ""
    @State private var newCategory = "Other"
    @State private var showCopyConfirm = false
    @State private var showRemindersConfirm = false
    @State private var toastMessage: String?

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    // MARK: - iOS

    private var iosLayout: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    // Header
                    HStack(alignment: .firstTextBaseline) {
                        Text("Shopping")
                            .font(.serifDisplay(34))
                        Spacer()
                        Menu {
                            Button(action: copyList) {
                                Label("Copy list", systemImage: "doc.on.doc")
                            }
                            #if os(iOS)
                            Button(action: { Task { await sendToReminders() } }) {
                                Label("Send to Reminders", systemImage: "checklist")
                            }
                            #endif
                            if store.doneCount > 0 {
                                Button(role: .destructive) { store.clearDone() } label: {
                                    Label("Clear checked", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.green500)
                        }
                    }
                    .slideIn()

                    // Progress bar
                    progressBar
                        .slideIn(delay: 0.05)

                    // Sections
                    ForEach(Array(store.sections.enumerated()), id: \.element.title) { sIdx, section in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(section.title.uppercased())
                                .font(.sans(11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .kerning(1.2)
                            BBCard(padding: Spacing.xs) {
                                VStack(spacing: 0) {
                                    ForEach(section.items) { item in
                                        itemRow(item)
                                        if item.id != section.items.last?.id {
                                            Divider().padding(.leading, 46)
                                        }
                                    }
                                }
                            }
                        }
                        .slideIn(delay: 0.08 + Double(sIdx) * 0.06)
                    }

                    // Add item button
                    Button {
                        showAdd = true
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.green500)
                            Text("Add item")
                                .font(.sans(15, weight: .semibold))
                                .foregroundStyle(Color.green500)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .strokeBorder(Color.green500.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .slideIn(delay: 0.28)

                    // Action buttons
                    HStack(spacing: Spacing.sm) {
                        actionButton("Copy list", icon: "doc.on.doc", action: copyList)
                        #if os(iOS)
                        actionButton("Reminders", icon: "checklist") { Task { await sendToReminders() } }
                        #endif
                    }
                    .slideIn(delay: 0.32)
                }
                .padding(Spacing.md)
                .padding(.bottom, Spacing.xl)
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
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - macOS

    private var macLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text("Shopping")
                        .font(.serifDisplay(34))
                    Spacer()
                    HStack(spacing: Spacing.sm) {
                        macActionButton("Copy", icon: "doc.on.doc", action: copyList)
                        macActionButton("Add item", icon: "plus") { showAdd = true }
                        if store.doneCount > 0 {
                            macActionButton("Clear checked", icon: "trash") { store.clearDone() }
                        }
                    }
                }
                .slideIn()

                progressBar.slideIn(delay: 0.04)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(Array(store.sections.enumerated()), id: \.element.title) { sIdx, section in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text(section.title.uppercased())
                                .font(.sans(11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .kerning(1.2)
                            BBCard(padding: Spacing.xs) {
                                VStack(spacing: 0) {
                                    ForEach(section.items) { item in
                                        itemRow(item)
                                        if item.id != section.items.last?.id {
                                            Divider().padding(.leading, 46)
                                        }
                                    }
                                }
                            }
                        }
                        .slideIn(delay: Double(sIdx) * 0.05)
                    }
                }
            }
            .padding(48)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Color.bbBackground)
        .sheet(isPresented: $showAdd) { addItemSheet }
    }

    // MARK: - Shared subviews

    private var progressBar: some View {
        BBCard(padding: Spacing.sm) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("This week's list")
                        .font(.sans(14, weight: .semibold))
                    Spacer()
                    Text("\(store.doneCount) of \(store.totalCount)")
                        .font(.sans(13))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.green500.opacity(0.14))
                        Capsule().fill(Color.green500)
                            .frame(width: store.totalCount > 0 ? geo.size.width * CGFloat(store.doneCount) / CGFloat(store.totalCount) : 0)
                    }
                }
                .frame(height: 7)
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
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(item.done ? Color.green500 : Color.secondary.opacity(0.35), lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(item.done ? Color.green500 : .clear))
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
                if !item.amount.isEmpty {
                    Text(item.amount)
                        .font(.sans(13))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { store.remove(id: item.id) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name (e.g. Chicken breast)", text: $newName)
                    TextField("Amount (e.g. 500g)", text: $newAmount)
                }
                Section("Category") {
                    Picker("Category", selection: $newCategory) {
                        ForEach(["Protein", "Carbs", "Produce", "Supplements", "Other"], id: \.self) {
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

    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13))
                Text(title).font(.sans(14, weight: .semibold))
            }
            .foregroundStyle(Color.green700)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.green500.opacity(0.1), in: RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func macActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.sans(13, weight: .semibold))
                .foregroundStyle(Color.green500)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.green500.opacity(0.1), in: Capsule())
        }
        .buttonStyle(.plain)
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

    #if os(iOS)
    private func sendToReminders() async {
        let ok = await store.sendToReminders()
        showToast(ok ? "Added to Reminders ✓" : "Reminders access needed")
    }
    #endif

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { toastMessage = nil }
        }
    }
}
