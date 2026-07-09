import SwiftUI

#if os(macOS)
// Mac layout — top bar + floating glass bottom dock (Stitch desktop design)
struct MacRootView: View {
    @State private var selection: Int = {
        #if DEBUG
        return Int(ProcessInfo.processInfo.environment["BB_TAB"] ?? "0") ?? 0
        #else
        return 0
        #endif
    }()
    @Namespace private var dockNamespace

    private let items: [(icon: String, label: String)] = [
        ("sun.max.fill", "Today"),
        ("fork.knife", "Meals"),
        ("dumbbell.fill", "Training"),
        ("cart.fill", "Shopping"),
        ("person.fill", "Account")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                topBar
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            floatingDock
                .padding(.bottom, 24)
        }
        .background(Color.bbBackground)
    }

    // MARK: top bar

    private var topBar: some View {
        HStack {
            (Text("Build Your ").foregroundStyle(.primary)
             + Text("Body").foregroundStyle(Color.green500))
                .font(.serifDisplay(20))

            Spacer()

            HStack(spacing: 20) {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill").font(.system(size: 13))
                    Text("6").font(.sans(13, weight: .bold))
                }
                .foregroundStyle(Color.green500)

                HStack(spacing: 5) {
                    Image(systemName: "trophy.fill").font(.system(size: 12))
                    Text("Lv. 4").font(.sans(13, weight: .bold))
                }
                .foregroundStyle(Color.green500)

                Text("RR")
                    .font(.sans(12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(LinearGradient(colors: [.green500, .green900], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                    .overlay(Circle().stroke(Color.green500.opacity(0.4), lineWidth: 2))
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(Color.bbBackground)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.5)
        }
    }

    // MARK: floating glass dock

    private var floatingDock: some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { i in
                DockItem(
                    icon: items[i].icon,
                    label: items[i].label,
                    isSelected: selection == i,
                    namespace: dockNamespace
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = i
                    }
                }
            }
        }
        .padding(8)
        .glassEffect(.regular, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.green900.opacity(0.18), radius: 24, y: 12)
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

private struct DockItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label.uppercased())
                    .font(.sans(9, weight: .bold))
                    .kerning(0.5)
            }
            .foregroundStyle(isSelected ? .white : (hovering ? .primary : .secondary))
            .frame(width: 70, height: 54)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.green500)
                        .matchedGeometryEffect(id: "dockpill", in: namespace)
                } else if hovering {
                    Capsule().fill(Color.primary.opacity(0.06))
                }
            }
            .contentShape(Capsule())
            .scaleEffect(hovering && !isSelected ? 1.06 : 1)
        }
        .buttonStyle(.plain)
        .onHover { inside in
            withAnimation(.easeOut(duration: 0.14)) { hovering = inside }
        }
    }
}
#endif
