# 00. 调研结论

调研日期：2026-05-15

## 结论摘要

Nook X、NotchNook 这类产品的核心不是单一工具，而是“顶部微型控制中心”：利用 Mac 刘海、菜单栏中间区域或模拟刘海区域，承载高频信息展示、快捷启动、轻量任务管理和临时文件中转。

可以做一款原创替代品，推荐定位为：

> 本地优先、无强制内购、模块化的 macOS 顶部效率岛。

不建议照搬竞品 UI、命名、图标、宣传文案或破解其内购。应做“功能诉求相同、产品表达原创”的实现。

## 已确认竞品信息

### Nook X

公开 App Store 信息显示，Nook X 是一款 macOS 效率岛工具，能力包括：

- 顶部刘海/Notch 区域模拟与动态交互。
- 歌曲歌词、日期、时间、天气温度展示。
- 番茄钟、待办事项、速记。
- 快捷启动、快捷指令、应用启动台。
- 文件暂存区。
- 前置摄像头镜子。
- 照片浏览。
- AI 对话，描述中提到 DeepSeek、Qwen、GLM、Doubao、讯飞星火、文心等模型。
- 外观自定义、自选图标、岛宽调节、鼠标悬停展开等。
- 免费下载，含 App 内购买。

来源：Apple App Store - Nook X  
https://apps.apple.com/cn/app/nook-x-%E6%95%88%E7%8E%87%E5%B2%9B-notch-%E7%95%AA%E8%8C%84%E9%92%9F-%E5%88%98%E6%B5%B7-todo/id6733240772?mt=12

### NotchNook

NotchNook 公开资料显示，它将 MacBook 刘海变成工具中心，强调：

- widgets / live actions / file shelf。
- 支持无刘海屏幕的 handler 模式。
- 支持多显示器。
- 媒体控制、日历、临时文件、摄像头预览等场景。

来源：NotchNook 官网  
https://notchnook.dev/

来源：Apsgo 软件介绍页  
https://notchnook.apsgo.cn/en

## 未确认项

用户提到的 PopX / ShoX 暂未检索到足够稳定、可信的公开资料，可能存在以下情况：

- 名称记忆存在大小写或空格差异。
- 是 App Store 区域性应用、临时下架应用或小众分发渠道应用。
- 实际名称可能是同类产品的简称或变体。

因此本文档把 PopX / ShoX 作为“同类顶部效率岛产品”处理，不直接声称其具体功能。后续如果用户提供链接、截图或安装包界面，可以补充竞品拆解。

## 用户痛点推断

来自用户表达“很多内购收费”以及竞品功能结构，可推断核心痛点：

- 高频功能被拆成多个付费模块，使用成本不透明。
- 只想要实用工具，不想为装饰性功能持续付费。
- 需要一个可自定义、可扩展、可本地掌控的 Mac 工具。
- 希望在顶部小空间完成“看信息、记事情、开应用、暂存文件、问 AI”等轻操作。

## 机会点

- 免费或自用构建：先满足个人真实工作流，避免订阅压力。
- 模块化：用户只启用需要的模块，减少性能负担。
- 本地优先：Todo、速记、番茄钟、快捷启动、文件暂存都可本地完成。
- 可插拔 AI：支持用户自己的 API Key，不绑定单一模型。
- 低打扰：默认紧凑，鼠标悬停或快捷键展开。

## 技术资料参考

- Apple `NSScreen.safeAreaInsets` 可用于判断屏幕安全区域和刘海遮挡区域。  
  https://developer.apple.com/documentation/appkit/nsscreen/safeareainsets
- Apple `NSWindow.CollectionBehavior.canJoinAllSpaces` 可用于让窗口显示在所有 Spaces。  
  https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/canjoinallspaces
- Apple `NSWindow` / `NSPanel` 是实现浮层和辅助窗口的基础。  
  https://developer.apple.com/documentation/AppKit/NSWindow

