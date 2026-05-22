import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "capsule.tophalf.filled")
                        .font(.system(size: 22, weight: .semibold))
                        .frame(width: 42, height: 42)
                        .foregroundStyle(Color.black)
                        .background(NPTheme.cyan)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notch Pilot")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("顶部效率岛设置")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                settingsSection("通用") {
                    Toggle("悬停展开", isOn: store.binding(\.expandOnHover))
                    Toggle("所有显示器显示", isOn: store.binding(\.showOnAllDisplays))
                    Toggle("全屏应用时隐藏", isOn: store.binding(\.hideInFullscreen))
                    Toggle("显示模块图标", isOn: store.binding(\.showModuleIcons))
                }

                settingsSection("尺寸") {
                    sliderRow("紧凑宽度", value: store.binding(\.compactWidth), range: 220...420)
                    sliderRow("紧凑高度", value: store.binding(\.compactHeight), range: 34...60)
                    sliderRow("展开宽度", value: store.binding(\.expandedWidth), range: 520...980)
                    sliderRow("展开高度", value: store.binding(\.expandedHeight), range: 360...720)
                    sliderRow("悬停延迟", value: store.binding(\.hoverDelay), range: 0.05...0.8, valueText: "\(String(format: "%.2f", store.settings.hoverDelay))s")
                }

                settingsSection("模块") {
                    Picker("默认模块", selection: store.binding(\.activeModuleRawValue)) {
                        ForEach(IslandModuleKind.allCases) { module in
                            Text(module.title).tag(module.rawValue)
                        }
                    }
                    .pickerStyle(.menu)

                    ForEach(IslandModuleKind.allCases) { module in
                        HStack {
                            Toggle(module.title, isOn: store.moduleEnabledBinding(module))
                            Spacer()
                            Button {
                                store.moveModule(module, offset: -1)
                            } label: {
                                Image(systemName: "chevron.up")
                            }
                            .buttonStyle(.plain)
                            Button {
                                store.moveModule(module, offset: 1)
                            } label: {
                                Image(systemName: "chevron.down")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                settingsSection("番茄钟") {
                    Stepper("专注 \(store.settings.pomodoroFocusMinutes)m", value: store.binding(\.pomodoroFocusMinutes), in: 1...180)
                    Stepper("休息 \(store.settings.pomodoroBreakMinutes)m", value: store.binding(\.pomodoroBreakMinutes), in: 1...60)
                }

                settingsSection("天气") {
                    HStack {
                        Text("API Key")
                            .frame(width: 80, alignment: .leading)
                        SecureField("OpenWeatherMap API Key", text: store.binding(\.weatherAPIKey))
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("城市")
                            .frame(width: 80, alignment: .leading)
                        TextField("Beijing", text: store.binding(\.weatherCity))
                            .textFieldStyle(.roundedBorder)
                    }
                    Stepper("刷新间隔 \(store.settings.weatherRefreshMinutes) 分钟", value: store.binding(\.weatherRefreshMinutes), in: 5...120)
                    Link("免费申请 OpenWeatherMap API Key →", destination: URL(string: "https://openweathermap.org/appid")!)
                        .font(.system(size: 11))
                        .foregroundStyle(NPTheme.cyan)
                }

                settingsSection("数据") {
                    HStack {
                        Button("导出 JSON") { exportData() }
                        Button("导入 JSON") { importData() }
                        Button("重置") { confirmReset() }
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 640, minHeight: 520)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
            content()
        }
        .font(.system(size: 13))
        .padding(14)
        .background(Color.primary.opacity(0.035))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, valueText: String? = nil) -> some View {
        HStack {
            Text(title)
                .frame(width: 130, alignment: .leading)
            Slider(value: value, in: range, step: 1)
            Text(valueText ?? "\(Int(value.wrappedValue))")
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
        }
    }

    private func exportData() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "notch-pilot-export.json"
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try store.exportSnapshot(to: url)
            } catch {
                presentError(error)
            }
        }
    }

    private func importData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try store.importSnapshot(from: url)
            } catch {
                presentError(error)
            }
        }
    }

    private func confirmReset() {
        let alert = NSAlert()
        alert.messageText = "重置 Notch Pilot?"
        alert.informativeText = "这会清空本地待办、速记、启动项、文件暂存和设置。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn {
            store.reset()
        }
    }
}

@MainActor
func presentError(_ error: Error) {
    let alert = NSAlert(error: error)
    alert.runModal()
}
