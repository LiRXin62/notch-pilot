# 09. 实现状态

更新时间：2026-05-22

## 项目形态

当前实现为 Swift Package 原生 macOS App：

- 入口：`Sources/NotchPilot/main.swift`
- 状态栏和窗口管理：`AppDelegate.swift`
- 顶部岛窗口：`IslandWindowController.swift`
- SwiftUI 顶部岛：`IslandViews.swift`
- 模块 UI：`ModuleViews.swift`
- 设置页：`SettingsView.swift`
- 本地状态：`AppStore.swift`
- 系统服务：`SystemServices.swift`
- AI 对话：`AIChatService.swift`
- 剪贴板历史：`ClipboardService.swift`
- 日历/提醒：`CalendarService.swift`
- 音乐控制：`MusicService.swift`
- 摄像头镜子：`CameraMirrorService.swift`
- 快捷指令：`ShortcutsService.swift`
- Keychain：`KeychainHelper.swift`

## 已完成

- 菜单栏 App。
- 顶部悬浮 `NSPanel`。
- 重新设计后的紧凑态和展开态。
- 顶部状态胶囊、模块图标工具条、控制中心式模块面板。
- 悬停展开。
- 快捷键：`Cmd + Option + I` 展开/收起，`Cmd + Option + ,` 设置。
- 顶部居中定位，初步考虑刘海 safe area。
- 本地 JSON 持久化。
- Todo。
- 番茄钟。
- 快捷启动。
- 文件暂存。
- 速记。
- 系统状态：电池、CPU、内存、实时网络监控（NWPathMonitor）。
- 剪贴板历史：后台监听、敏感内容过滤、搜索、置顶、复制。
- 天气模块（OpenWeatherMap API，用户自配 Key）。
- AI 对话模块（OpenAI 兼容接口，流式输出，Keychain 存储）。
- 日历/提醒事项（EventKit 集成）。
- 音乐控制（Apple Music/Spotify 检测和控制）。
- 摄像头镜子（AVCaptureSession）。
- 快捷指令（CLI 执行）。
- 多显示器支持。
- 开机启动（SMAppService）。
- 设置页（含天气配置、AI 配置、系统设置）。
- JSON 导入导出。
- UI 预览渲染器：`NOTCH_PILOT_RENDER_PREVIEW=1 swift run`。

## 编译验证

已执行：

```bash
swift build
swift run
NOTCH_PILOT_SMOKE_TEST=1 swift run
NOTCH_PILOT_RENDER_PREVIEW=1 swift run
```

结果：通过。零警告零错误。

注意：

- 本机当前 `xcodebuild` 指向 Command Line Tools，不是完整 Xcode。
- SwiftPM 编译需要访问用户目录下 SwiftPM / clang 缓存，因此在沙盒环境下需要授权。
- SwiftPM 直接运行不是 `.app` bundle，系统通知能力已做降级；打成 `.app` 后会使用 `UNUserNotificationCenter`。

## 未完成

- `.app` bundle、Info.plist、图标、签名和 DMG。
- 全屏应用行为精细控制。
- 文件安全书签。
- 歌词显示功能。
- Quick Look 和 AirDrop。
- 插件系统。

## 技术债

- CPU 采样目前展示 App 自身可见的简要 CPU 变化，后续可做更准确的系统级摘要。
- 文件暂存现在保存路径，后续要升级为 security-scoped bookmark，避免重启或沙盒后路径访问失败。
- Swift Package 可运行但不是标准 macOS App bundle，系统集成能力有限。
