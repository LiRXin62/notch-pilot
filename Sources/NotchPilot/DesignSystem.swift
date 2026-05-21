import SwiftUI

enum NPTheme {
    static let ink = Color(red: 0.025, green: 0.027, blue: 0.031)
    static let ink2 = Color(red: 0.060, green: 0.066, blue: 0.074)
    static let line = Color.white.opacity(0.10)
    static let text = Color.white
    static let secondaryText = Color.white.opacity(0.62)
    static let mutedText = Color.white.opacity(0.42)
    static let cyan = Color(red: 0.35, green: 0.86, blue: 1.0)
    static let green = Color(red: 0.42, green: 0.93, blue: 0.62)
    static let amber = Color(red: 1.0, green: 0.72, blue: 0.35)
    static let rose = Color(red: 1.0, green: 0.43, blue: 0.52)

    static func islandFill(isExpanded: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.070, green: 0.073, blue: 0.082).opacity(isExpanded ? 0.985 : 0.97),
                Color(red: 0.020, green: 0.021, blue: 0.024).opacity(0.965)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct IconToolButton: View {
    let symbolName: String
    var isActive = false
    var accent: Color = NPTheme.cyan
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 13, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 30, height: 30)
                .foregroundStyle(isActive ? Color.black : Color.white.opacity(0.82))
                .background(isActive ? accent : Color.white.opacity(0.075))
                .overlay(
                    Circle()
                        .stroke(isActive ? Color.white.opacity(0.25) : Color.white.opacity(0.10), lineWidth: 1)
                )
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}

struct SmallActionButton: View {
    let symbolName: String
    var accent: Color = NPTheme.cyan
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.black)
                .background(accent)
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}

struct GhostIconButton: View {
    let symbolName: String
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(.white.opacity(0.72))
                .background(.white.opacity(0.055))
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }
}

struct StatusChip: View {
    let symbolName: String
    let text: String
    var tint: Color = NPTheme.cyan

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbolName)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(.white.opacity(0.070))
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

struct StatusChipButton: View {
    let symbolName: String
    let text: String
    var tint: Color = NPTheme.cyan
    var help: String = ""
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            StatusChip(symbolName: symbolName, text: text, tint: tint)
                .overlay(
                    Capsule()
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
        .help(help)
        .accessibilityLabel(help.isEmpty ? text : help)
    }
}

struct ModuleTabButton: View {
    let title: String
    let symbolName: String
    var isActive: Bool
    var accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .frame(height: 30)
            .foregroundStyle(isActive ? Color.black : Color.white.opacity(0.74))
            .background(isActive ? accent : Color.white.opacity(0.065))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isActive ? Color.white.opacity(0.24) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(title)
    }
}

struct ModuleHeader: View {
    let title: String
    let subtitle: String
    let symbolName: String
    var tint: Color = NPTheme.cyan

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 28, height: 28)
                .foregroundStyle(Color.black)
                .background(tint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NPTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }
}

struct PanelRowBackground: ViewModifier {
    var isActive = false

    func body(content: Content) -> some View {
        content
            .background(isActive ? Color.white.opacity(0.12) : Color.white.opacity(0.055))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isActive ? Color.white.opacity(0.16) : Color.white.opacity(0.075), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension View {
    func panelRow(active: Bool = false) -> some View {
        modifier(PanelRowBackground(isActive: active))
    }
}
