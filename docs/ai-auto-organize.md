# AI Auto Organize 开发记录

- 模型：`gemini-3.8-flash`（可用 `GEMINI_MODEL` 覆盖），在 `generation_config` 中使用 `thinking_level: low`。
- 调用：Gemini Developer API 的 `interactions` REST 接口；Flutter 目前没有维护中的官方 Gemini SDK，因此使用官方 REST 格式。
- 结构化输出：顶层 `response_format` 的 `application/json` schema，固定返回 `title`、`category`、`note`、`confidence`。
- 分类：按用户保存内容后未来最可能执行的动作分类，而非只识别内容对象；分享文字中的明确意图优先于网页内容，网页内容优先于 URL 域名。
- URL：输入含公开 URL 时，请求 `url_context`；平台限制、登录、短链、动态页面或读取失败时自动退回到分享文本/原始输入判断。
- 阈值：`confidence >= 0.85` 才自动归类；否则仍在 Inbox，并显示轻量的 AI 建议。
- 回退：先把原始输入、清理后的 URL 与本地默认记录写入 SQLite；Key 缺失、离线、超时、额度、URL Context 或 JSON 失败都只会留下 Inbox，不会丢记录。
- Key：仅由 `--dart-define-from-file=secrets.json` 提供；`secrets.json` 被忽略，不写入数据库或源码。该值仍会编入本地测试 APK，正式分发前需要轻量 API Proxy。
- 回归：`intent_classification_regression_test.dart` 含 12 个高风险意图案例；只有显式传入 `RUN_LIVE_GEMINI_TESTS=true` 时才会使用本地 Key 执行真实 Gemini 回归。
- 数据库：v2 → v3 增加原始输入与 AI 元数据；v3 → v4 增加短暂的 `ai_pending` 标记。用户手动保存编辑时会清除此标记，延迟返回的 AI 结果不能覆盖手动内容。
