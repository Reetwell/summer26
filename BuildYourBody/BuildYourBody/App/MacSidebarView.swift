import SwiftUI

#if os(macOS)
// Custom Mac layout — brand sidebar + detail, styled like the web app's desktop sidebar
struct MacRootView: View {
    @State private var selection: Int = {
        #if DEBUG
        return Int(ProcessInfo.processInfo.environment["BB_TAB"] ?? "0") ?? 0
        #else
        return 0
        #endif
    }()
    @Namespace private var pillNamespace

    private let items: [(icon: String, label: String)] = [
        ("sun.max.fill", "Today"),
        ("fork.knife", "Meals"),
        ("dumbbell.fill", "Training"),
        ("cart.fill", "Shopping"),
        ("person.fill", "Account")
    ]

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.bbBackground)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Wordmark — "Build Your" + green "Body", serif like the web
            (Text("Build Your ")
                .foregroundStyle(.primary)
             + Text("Body")
                .foregroundStyle(Color.green500))
                .font(.serifDisplay(20))
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.lg)

            ForEach(items.indices, id: \.self) { i in
                sidebarItem(index: i)
            }

            Spacer()

            // Streak footer chip
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
                Text("6 day streak")
                    .font(.sans(12, weight: .semibold))
            }
            .foregroundStyle(Color.green500)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.green500.opacity(0.1), in: Capsule())
            .padding(Spacing.md)
        }
        .padding(.horizontal, Spacing.sm)
        .frame(width: 220)
        .background(Color.bbSurface)
    }

    private func sidebarItem(index: Int) -> some View {
        SidebarItemButton(
            icon: items[index].icon,
            label: items[index].label,
            isSelected: selection == index,
            namespace: pillNamespace
        ) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selection = index
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case 0: TodayView().id(0)
        case 1: MealsView().id(1)
        case 2: TrainingView().id(2)
        case 3: ShoppingView().id(3)
        default: AccountView().id(4)
        }
    }
}

private struct SidebarItemButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                Text(label)
                    .font(.sans(14, weight: isSelected ? .semibold : .medium))
                Spacer()
            }
            .foregroundStyle(isSelected ? Color.green700 : (hovering ? .primary : .secondary))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.green500.opacity(0.13))
                        .matchedGeometryEffect(id: "pill", in: namespace)
                } else if hovering {
                    RoundedRectangle(cornerRadius: Radius.md)
                        .fill(Color.primary.opacity(0.045))
                }
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(Color.green500)
                        .frame(width: 3, height: 18)
                        .offset(x: -Spacing.sm)
                        .matchedGeometryEffect(id: "accent", in: namespace)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.12)) {
                hovering = inside
            }
        }
    }
}
#endif
