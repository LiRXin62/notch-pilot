import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: AppStore
    @EnvironmentObject var localizer: Localizer

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
                        Text(localizer.t("顶部效率岛设置"))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                settingsSection(localizer.t("通用")) {
                    Toggle(localizer.t("悬停展开"), isOn: store.binding(\.expandOnHover))
                    Toggle(localizer.t("所有显示器显示"), isOn: store.binding(\.showOnAllDisplays))
                    Toggle(localizer.t("全屏应用时隐藏"), isOn: store.binding(\.hideInFullscreen))
                    Toggle(localizer.t("显示模块图标"), isOn: store.binding(\.showModuleIcons))

                    HStack {
                        Text(localizer.t("语言"))
                            .frame(width: 130, alignment: .leading)
                        Picker("", selection: languageBinding) {
                            ForEach(Language.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }

                settingsSection(localizer.t("尺寸")) {
                    sliderRow(localizer.t("紧凑宽度"), value: store.binding(\.compactWidth), range: 220...420)
                    sliderRow(localizer.t("紧凑高度"), value: store.binding(\.compactHeight), range: 34...60)
                    sliderRow(localizer.t("展开宽度"), value: store.binding(\.expandedWidth), range: 520...980)
                    sliderRow(localizer.t("展开高度"), value: store.binding(\.expandedHeight), range: 360...720)
                    sliderRow(localizer.t("悬停延迟"), value: store.binding(\.hoverDelay), range: 0.05...0.8, valueText: "\(String(format: "%.2f", store.settings.hoverDelay))s")
                }

                settingsSection(localizer.t("模块")) {
                    Picker(localizer.t("默认模块"), selection: store.binding(\.activeModuleRawValue)) {
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

                settingsSection(localizer.t("番茄钟")) {
                    Stepper(localizer.t("专注") + " \(store.settings.pomodoroFocusMinutes)m", value: store.binding(\.pomodoroFocusMinutes), in: 1...180)
                    Stepper(localizer.t("休息") + " \(store.settings.pomodoroBreakMinutes)m", value: store.binding(\.pomodoroBreakMinutes), in: 1...60)
                }

                settingsSection(localizer.t("天气")) {
                    HStack {
                        Text("API Key")
                            .frame(width: 80, alignment: .leading)
                        SecureField("OpenWeatherMap API Key", text: store.binding(\.weatherAPIKey))
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text(localizer.t("城市"))
                            .frame(width: 80, alignment: .leading)
                        TextField("Beijing", text: store.binding(\.weatherCity))
                            .textFieldStyle(.roundedBorder)
                    }
                    Stepper(localizer.t("刷新间隔") + " \(store.settings.weatherRefreshMinutes) " + localizer.t("分钟"), value: store.binding(\.weatherRefreshMinutes), in: 5...120)
                    Link(localizer.t("免费申请 OpenWeatherMap API Key →"), destination: URL(string: "https://openweathermap.org/appid")!)
                        .font(.system(size: 11))
                        .foregroundStyle(NPTheme.cyan)
                }

                settingsSection(localizer.t("AI 对话")) {
                    HStack {
                        Text("API Key")
                            .frame(width: 80, alignment: .leading)
                        SecureField("OpenAI API Key", text: store.binding(\.aiAPIKey))
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text(localizer.t("接口地址"))
                            .frame(width: 80, alignment: .leading)
                        TextField("https://api.openai.com/v1", text: store.binding(\.aiBaseURL))
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text(localizer.t("模型"))
                            .frame(width: 80, alignment: .leading)
                        TextField("gpt-3.5-turbo", text: store.binding(\.aiModelName))
                            .textFieldStyle(.roundedBorder)
                    }
                    Text(localizer.t("支持 OpenAI 兼容接口（OpenAI、DeepSeek、Moonshot 等）"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                settingsSection(localizer.t("系统")) {
                    Toggle(localizer.t("开机启动"), isOn: store.binding(\.launchAtLogin))
                }

                settingsSection(localizer.t("数据")) {
                    HStack {
                        Button(localizer.t("导出 JSON")) { exportData() }
                        Button(localizer.t("导入 JSON")) { importData() }
                        Button(localizer.t("重置")) { confirmReset() }
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

    private var languageBinding: Binding<Language> {
        Binding(
            get: { Language(rawValue: store.settings.languageRaw) ?? .system },
            set: { newValue in
                store.updateSettings { $0.languageRaw = newValue.rawValue }
                localizer.language = newValue
            }
        )
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
        alert.messageText = localizer.t("重置 Notch Pilot?")
        alert.informativeText = localizer.t("这会清空本地待办、速记、启动项、文件暂存和设置。")
        alert.alertStyle = .warning
        alert.addButton(withTitle: localizer.t("重置"))
        alert.addButton(withTitle: localizer.t("取消"))
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
