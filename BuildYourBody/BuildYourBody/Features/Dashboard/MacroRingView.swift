import SwiftUI

// Big calorie ring — fills from 0 on appear, like the web dashboard
struct CalorieRingView: View {
    let consumed: Int
    let target: Int
    var size: CGFloat = 150
    var lineWidth: CGFloat = 14
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    private var fraction: CGFloat {
        guard target > 0 else { return 0 }
        return min(CGFloat(consumed) / CGFloat(target), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.green500.opacity(0.12), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.green500, .green700],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(consumed)")
                    .font(.serifDisplay(size * 0.22))
                    .contentTransition(.numericText())
                Text("of \(target) kcal")
                    .font(.sans(size * 0.08))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            guard !reduceMotion else { progress = fraction; return }
            withAnimation(.spring(response: 1.1, dampingFraction: 0.9).delay(0.2)) {
                progress = fraction
            }
        }
    }
}

// Slim macro bar — protein / carbs / fat
struct MacroBarView: View {
    let label: String
    let value: Int
    let target: Int
    let color: Color
    let delay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    private var fraction: CGFloat {
        guard target > 0 else { return 0 }
        return min(CGFloat(value) / CGFloat(target), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.sans(12, weight: .semibold))
                Spacer()
                Text("\(value)g / \(target)g")
                    .font(.sans(12))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.14))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 7)
        }
        .onAppear {
            guard !reduceMotion else { progress = fraction; return }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.9).delay(delay)) {
                progress = fraction
            }
        }
    }
}
