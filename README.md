# Wishbox

A lightweight, local-first wishlist and inspiration inbox with optional AI-assisted organization.

Wishbox 是一个 Android 收藏箱，用于快速保存「想买、想吃、想去、想用、想做、其他」内容。

**Capture first, organize later.** 先用 Quick Capture 把文字或链接存进 Inbox，再手动整理，或使用可选 AI 辅助分类。项目仍在开发中，AI 结果需要用户自行判断。

## Features

- **Quick Capture**：输入文字或粘贴分享内容，按 Enter 保存。
- **Inbox**：未分类内容先收好，之后再整理。
- **Six intent-based categories**：按用户未来想做什么分类。
- **Search / filters**：标题与备注搜索，分类和状态筛选。
- **Local SQLite storage**：记录保存在本地，可选择一张图片并复制到应用私有目录。
- **Optional AI Auto Organize**：保留 DeepSeek Provider 和 Gemini Provider，辅助生成标题、分类和简短提示。
- **Confidence-based fallback**：置信度达到 0.85 才自动归类；低置信度内容保留在 Inbox，显示建议供用户确认。
- **Save before AI**：先保存记录，AI 请求失败不会阻止保存。
- **Local-first / no account required**：无需账户，没有云同步。

## Screenshots

TODO：补充使用合成示例数据制作的公开截图。当前不包含个人收藏截图。

## Categories

分类针对 **user intent**，而不仅是内容对象。例如，保存菜谱可能是「想做」，保存餐厅推荐可能是「想吃」。

| 分类 | English | 用户意图 |
| --- | --- | --- |
| 想买 | Want to Buy | 购买实体商品 |
| 想吃 | Want to Eat | 吃某种食物或去餐厅、咖啡店 |
| 想去 | Want to Go | 旅行、参观或体验地点 |
| 想用 | Want to Use | 使用软件、网站或在线服务 |
| 想做 | Want to Do | 学习、制作、拍摄或尝试活动 |
| 其他 | Other | 不适合上述分类的内容 |

## SDK Requirements

以当前提交的依赖锁定文件为准：

- **Flutter >= 3.44.0**；`pubspec.lock` 声明此最低版本。
- **Dart >= 3.12.0 and < 4.0.0**；`pubspec.yaml` 的声明下限为 3.4.0，但当前锁定依赖要求更高版本。
- 本次验证使用 **Flutter 3.47.2 stable / Dart 3.13.2**，对应 `.metadata` 的 SDK revision；未逐一验证其他 SDK 版本。
- 安装 Android SDK，并使用 Android 模拟器或开启 USB 调试的 Android 手机。
- Android 构建使用 Java 17 语言目标；当前 Gradle wrapper 需要兼容的 JDK（17 或更高）。可通过 `flutter doctor -v` 检查本机工具链。
- Android 的 `compileSdk`、`targetSdk`、`minSdk` 和 NDK 跟随 Flutter SDK 默认值。本次验证环境为 compile/target API **36**、minimum API **24**（Android 7.0）、NDK **28.2.13676358**。更换 Flutter SDK 时这些值可能改变。

## Getting Started

仓库地址尚未创建，请将 `<repository-url>` 替换为实际地址：

```bash
git clone <repository-url> wishbox
cd wishbox
flutter pub get
flutter doctor -v
flutter devices
flutter run
```

无需配置 API Key 即可运行。Quick Capture 会将内容保存到 Inbox，AI Organizer 自动跳过。

### Public-style debug build

```bash
flutter build apk --debug --dart-define-from-file=secrets.example.json
```

也可以不传入任何 AI 配置：

```bash
flutter build apk --debug
```

调试 APK 输出到 `build/app/outputs/flutter-apk/app-debug.apk`。它用于本地安装测试，不是已发布的正式安装包。

## AI Configuration (Optional)

AI 是可选功能。配置与否都不影响核心收藏、编辑、搜索和本地保存功能。

安全示例 `secrets.example.json`：

```json
{
  "GEMINI_API_KEY": "",
  "DEEPSEEK_API_KEY": "",
  "AI_PROVIDER": "deepseek"
}
```

复制示例，并填写自己的 Key：

```bash
cp secrets.example.json secrets.json
```

选择一个 Provider，然后使用本地配置运行：

```bash
flutter run --dart-define-from-file=secrets.json
```

Key 通过构建时的 Dart defines 提供；修改配置后需要重新运行或构建。没有 Key 时不会发送 AI 请求，内容保留在 Inbox。

### DeepSeek

在 `secrets.json` 中设置：

- `AI_PROVIDER` 为 `deepseek`。
- `DEEPSEEK_API_KEY` 为你自己的 DeepSeek API Key。

DeepSeek 是中国大陆网络环境下可尝试的可选 Provider；实际连接取决于用户网络与服务可用性，不保证任何地区始终可访问。

当前代码默认模型为 `deepseek-v4-flash`，可通过 `DEEPSEEK_MODEL` 覆盖。它使用输入文字和分享文本，不会主动抓取来源网页。模型与账户权限由 Provider 决定。

### Gemini

在 `secrets.json` 中设置：

- `AI_PROVIDER` 为 `gemini`。
- `GEMINI_API_KEY` 为你自己的 Gemini Developer API Key。

Gemini 的可访问性取决于用户自身网络环境和服务支持范围。当前代码默认模型为 `gemini-3.8-flash`，可通过 `GEMINI_MODEL` 覆盖。

当前实现使用 `interactions` API，输入含 URL 时可请求 URL Context；可通过 `GEMINI_URL_CONTEXT` 控制。页面登录、权限、平台限制和网络情况仍可能阻止读取。

`GEMINI_HTTP_PROXY` 是 **optional development/debug setting**，默认为空。仅在自己的调试环境确有需要时配置可访问的代理地址；正常构建无需代理，DeepSeek 不使用此设置。

## Privacy

### Local data

Saved items、notes、categories 和图片路径等元数据保存在本地 SQLite；选择的图片保存在应用私有存储中。当前没有账户系统，也没有云同步。

卸载应用会删除本地应用数据。当前没有应用内备份或跨设备同步功能。

### AI usage

只有配置并启用 AI Organizer 后，用于整理的 Quick Capture 原始文字和来源 URL 才会发送到所选 Provider：**DeepSeek** 或 **Google Gemini**。Gemini 的 URL Context 还可能读取所提供的公开页面。当前整理请求不上传本地图片或整份数据库。

AI Provider 有自己的 privacy policy 和数据处理规则。用户应自行阅读并判断是否愿意发送这些内容；不建议向 AI Organizer 提交敏感私人信息。本项目不承诺第三方服务不会保存请求数据。

## API Key Security Warning

**Never commit `secrets.json`.** 该文件已被 `.gitignore` 排除，应只保留在本地。

本项目通过本地构建配置提供 API Key，适合 **personal/local testing**。

**Mobile APKs cannot securely hide embedded API keys.** Dart defines 会编入应用二进制。

- 不要公开分发包含真实 API Key 的 APK。
- 不要将自己的 Key 编译进公开 Release。
- 不要上传本地签名文件、数据库、日志或私有构建缓存。
- 未来若向第三方分发带 AI 服务的应用，应使用 server-side proxy / backend 保护凭据，并控制访问和额度；当前项目未实现该后端。

公开源码不包含开发者的 API Key。启用 AI 需要用户自行配置自己的凭据。

## Current Limitations

- AI classification may be incorrect；请自行检查整理结果。
- 低置信度内容会留在 Inbox。
- 只有裸 URL 或页面不可访问时，可能没有足够上下文。
- 购物、社交平台可能只提供有限的分享文本或页面信息。
- DeepSeek 更依赖 input/share text；Gemini 的 URL Context 也受权限、网络及页面可访问性限制。
- 没有云同步或账户系统。
- Android-first；当前仓库包含 Android 工程，其他平台未验证。
- AI 需要用户自己的 API credentials，以及所选 Provider 可用的模型、权限和额度。
- 当前 Android release 配置使用 debug signing；尚未准备正式应用分发所需的签名配置。

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=secrets.example.json
```

Public build 无需 API Key。测试使用合成数据和 mock 请求；真实 Gemini 回归测试默认跳过，仅在显式设置 `RUN_LIVE_GEMINI_TESTS=true` 并提供自己的 Key 时联网运行。

## License

MIT。标准许可文本见 [LICENSE](LICENSE)。
