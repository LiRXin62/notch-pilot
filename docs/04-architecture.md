# 04. 技术架构方案

## 技术栈

推荐：

- 语言：Swift 6
- UI：SwiftUI + AppKit
- 数据：SwiftData 或 SQLite
- 密钥：Keychain
- 通知：UserNotifications
- 打包：Xcode project，后续可加入 Sparkle 更新
- 最低系统：macOS 14 起步，后续根据实现评估是否下探到 macOS 13

## 架构分层

```text
App
├── Shell
│   ├── AppDelegate
│   ├── MenuBarController
│   └── SettingsWindowController
├── Island
│   ├── IslandWindowController
│   ├── IslandPositioner
│   ├── IslandStateMachine
│   └── DragDropCoordinator
├── Modules
│   ├── ClockModule
│   ├── TodoModule
│   ├── PomodoroModule
│   ├── LauncherModule
│   ├── FileShelfModule
│   ├── NoteModule
│   ├── WeatherModule
│   └── AIModule
├── Services
│   ├── SettingsStore
│   ├── PermissionCenter
│   ├── NotificationService
│   ├── LaunchService
│   ├── WeatherService
│   ├── AIService
│   └── FileBookmarkStore
└── Persistence
    ├── Models
    ├── Repositories
    └── Migration
```

## 顶部窗口实现

使用 AppKit 创建无边框 `NSPanel` 或 `NSWindow`：

- `styleMask`: borderless / nonactivating panel 视具体交互测试决定。
- `level`: floating 或 statusBar 级别，避免覆盖系统关键 UI。
- `collectionBehavior`: `canJoinAllSpaces`，必要时加 full screen auxiliary。
- `isOpaque`: false。
- `backgroundColor`: clear。
- 内容使用 `NSHostingView` 承载 SwiftUI。

## 定位算法

输入：

- 当前屏幕 frame。
- 当前屏幕 visibleFrame。
- `NSScreen.safeAreaInsets`。
- 用户配置宽高。
- 是否真实刘海。
- 是否多显示器。

输出：

- 小岛紧凑态 frame。
- 小岛展开态 frame。

规则：

- 默认使用主屏。
- 如果 `safeAreaInsets.top > 0`，认为可能存在顶部遮挡区域。
- 有刘海时，小岛中心对齐屏幕中心，顶部贴近菜单栏区域。
- 无刘海时，小岛作为顶部居中 handler。
- 展开态不超过屏幕宽度的 80%，不超过屏幕高度的 60%。

## 模块系统

定义统一协议：

```swift
protocol IslandModule {
    var id: String { get }
    var title: String { get }
    var iconName: String { get }
    var compactView: AnyView { get }
    var expandedView: AnyView { get }
    var permissions: [AppPermission] { get }
}
```

模块由 `ModuleRegistry` 注册，用户可在设置中启用、排序。

## 数据模型

### TodoItem

- id
- title
- notes
- isCompleted
- dueAt
- createdAt
- updatedAt

### PomodoroSession

- id
- mode
- duration
- remaining
- startedAt
- endedAt
- state

### QuickLaunchItem

- id
- displayName
- appBundleIdentifier
- appURLBookmark
- iconCacheKey
- order

### ShelfItem

- id
- fileName
- bookmarkData
- fileSize
- addedAt

### QuickNote

- id
- content
- createdAt
- updatedAt

## 外部能力

### 天气

- 抽象 `WeatherProvider`。
- MVP 可先支持一个 Provider。
- 缓存最近成功结果。
- 无网络时显示缓存或空状态。

### AI

- 使用 OpenAI-compatible chat completions 接口。
- 配置项：Base URL、API Key、Model。
- API Key 存入 Keychain。
- 请求超时和错误必须可见。

### 音乐与歌词

建议放到 P2。原因：

- Apple Music、Spotify、浏览器播放器的公开能力差异大。
- 歌词来源涉及版权和服务限制。
- 若使用私有 API 会影响稳定性和分发。

可选路线：

- App Store 友好：优先 AppleScript / ScriptingBridge / MusicKit 能力。
- 自用增强版：用户明确接受时再评估非公开能力，但不作为默认方案。

## 权限

- 通知：番茄钟完成提醒。
- 文件访问：文件暂存区安全书签。
- 自动化：控制或读取第三方 App 时按需申请。
- 辅助功能：只有需要全局快捷键增强或复杂控制时申请。
- 摄像头：镜子模块启用时申请。

## 性能策略

- 计时器集中管理，避免每个模块独立高频刷新。
- 紧凑态只渲染启用模块。
- 展开态懒加载模块内容。
- 天气、AI 请求异步执行，失败不阻塞 UI。
- 文件图标缓存。

## 测试策略

- 单元测试：定位算法、番茄钟状态机、数据仓库。
- UI 测试：展开/收起、拖拽文件、Todo 操作。
- 快照测试：亮色/暗色、不同宽度。
- 手工测试：有刘海 Mac、无刘海外接屏、多显示器、全屏应用。

