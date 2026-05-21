# Notch Pilot

Notch Pilot 是一个原创 macOS 顶部效率岛项目，用来把 Mac 屏幕顶部的刘海区或模拟刘海区变成轻量信息中心与快捷操作入口。

本仓库当前阶段先完成需求、PRD、设计与开发计划文档。后续建议使用 SwiftUI + AppKit 实现原生 macOS 应用。

当前已经包含一个 Swift Package 版原生 macOS 原型，可直接用 SwiftPM 编译运行。

## 目录

- `docs/00-research.md`: 竞品和公开资料调研
- `docs/01-requirements.md`: 需求分析
- `docs/02-prd.md`: 产品需求文档
- `docs/03-design.md`: 交互与视觉设计
- `docs/04-architecture.md`: 技术架构方案
- `docs/05-development-plan.md`: 开发计划与里程碑
- `docs/06-privacy-and-compliance.md`: 隐私、权限与合规边界
- `docs/07-acceptance.md`: MVP 验收标准
- `docs/08-feature-coverage-matrix.md`: 同类 App 功能覆盖矩阵
- `docs/09-implementation-status.md`: 当前实现状态

## 原则

- 做同类功能的原创替代品，不依赖破解或绕过内购。
- 核心体验免费、买断或自用构建，不做强制内购墙。
- 本地优先保存数据；天气、AI 等外部能力由用户自行配置 API Key。
- 优先使用公开 macOS API；需要高权限的能力必须显式授权并可关闭。

## 运行

```bash
cd /Users/rongxinli/work_speace/notch-pilot
swift run
```

如果只想验证编译：

```bash
swift build
```

如果想离屏生成 UI 预览图：

```bash
NOTCH_PILOT_RENDER_PREVIEW=1 swift run
```

预览图会输出到：

- `/private/tmp/notchpilot-compact.png`
- `/private/tmp/notchpilot-expanded.png`

当前环境只有 Command Line Tools，没有完整 Xcode，因此先采用 Swift Package 项目结构。后续需要 App 图标、签名、DMG、Launch Services 更完整能力时，再补 Xcode 工程或生成 app bundle。

## 当前已实现

- 菜单栏入口。
- 顶部悬浮小岛 `NSPanel`。
- 重新设计后的紧凑态/展开态和悬停展开。
- `Cmd + Option + I` 展开/收起。
- `Cmd + Option + ,` 打开设置。
- 时间日期 Dashboard。
- Todo 新增、完成、删除、本地 JSON 持久化。
- 番茄钟开始、暂停、重置、通知。
- 快捷启动 App 添加、启动、删除。
- 文件暂存拖入、拖出、Finder 中显示、清空。
- 速记保存、删除、转 Todo。
- 系统状态初版：电池、CPU、内存、网络占位。
- 剪贴板初版：读取当前文本。
- 设置页：模块开关、排序、尺寸、番茄钟时长、导入导出、重置。
- 离屏 UI 预览渲染器，方便持续检查界面效果。

## 下一步优先级

- 打成真正 `.app` bundle，补 Info.plist、图标、签名配置。
- 修正文件暂存为 security-scoped bookmark。
- 日历/提醒事项 EventKit 集成。
- 剪贴板历史后台监听和敏感过滤。
- 天气 Provider。
- AI OpenAI-compatible 配置和 Keychain。
- 音乐信息、歌词、Quick Look、AirDrop。
