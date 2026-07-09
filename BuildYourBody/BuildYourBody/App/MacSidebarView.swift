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

    // MARK: floating glass dock (proper Liquid Glass)

    private var floatingDock: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(items.indices, id: \.self) { i in
                    dockButton(i)
                }
            }
        }
        .shadow(color: Color.green900.opacity(0.18), radius: 24, y: 12)
    }

    private func dockButton(_ i: Int) -> some View {
        let selected = selection == i
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selection = i
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: items[i].icon)
                    .font(.system(size: 16, weight: .medium))
                Text(items[i].label.uppercased())
                    .font(.sans(9, weight: .bold))
                    .kerning(0.5)
            }
            .foregroundStyle(selected ? .white : .secondary)
            .frame(width: 70, height: 54)
        }
        .buttonStyle(.plain)
        .glassEffect(
            selected ? .regular.tint(Color.green500).interactive() : .regular.interactive(),
            in: Capsule()
        )
        .glassEffectID(i, in: dockNamespace)
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

#endif
