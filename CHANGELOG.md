# Changelog

## [0.3.0] — 2026-05-22

### 新增 — UI 主题定版（MD3 浅色主题）

#### 🎨 Material Design 3 浅色主题
- 完整 MD3 浅色主题体系，设计参考稿匹配
- 紫色/靛蓝强调色 `#5B21B6` — 品牌渐变色统一
- 浅灰背景 `#F5F5F5` + 白色卡片 + MD3 组件（Card、FilledButton 等）
- 强制 `ThemeMode.light`，彻底杜绝暗色模式冲突
- 品牌渐变徽章：顶栏/分类标签/按钮统一渐变配色

#### 📱 UI/UX 修复
- 溢出问题全面修复：`SingleChildScrollView` + `FilterChip` 布局稳定
- 空状态/加载态/错误态三态覆盖完成
- 逻辑回归后状态管理正确性验证通过

#### ✅ 验证
- OPPO Android 15 真机验证通过
- 主题切换无闪烁、无溢出、无暗色残留

### Commits

| Hash | 描述 |
|------|------|
| `ada2b3b` | feat: redesign UI with professional design system |
| `889180b` | fix: resolve 5 critical feature gaps |
| `2316fa2` | feat: apply Material Design 3 theme system |
| `213572e` | fix: resolve overflow issues in filter chips and item cards |
| `9599f15` | feat: apply purple/indigo MD3 theme matching reference design |

---

## [0.2.4] — 2026-05-21

### 新增 — 引导流程与设置页

#### 🚀 引导流程（4 页）
- 零知识密码学原理介绍页
- Monica 双剪贴板使用说明页
- WebDAV 原子同步配置引导页
- 安全审计面板功能介绍页
- `PageView` + `Indicator` 分页导航，底部「跳过」入口

#### ⚙️ 设置页
- 语言切换（中/日/英）
- WebDAV 配置（URL/用户名/密码表单）
- 手动同步触发
- 应用锁定设置
- 关于页面（版本号、许可证）

#### 🔽 底部导航栏
- 双 Tab 导航：Vault（密码库）+ Settings（设置）
- 语言切换从 AppBar 🌐 移至设置页，统一管理
- 引导→密码库→设置全链路真机验证通过

### Commits

| Hash | 描述 |
|------|------|
| `bad87fb` | feat: add onboarding flow, settings page, and bottom navigation |

---

## [0.2.3] — 2026-05-21

### 新增 — i18n 国际化

#### 🌐 三语支持
- **中文**（简体）— 默认语言
- **日文**— ローカライズ完全対応
- **英文**— Full English localization
- 52 个翻译字符串 + 6 个动态插值（含复数规则）
- AppBar 🌐 按钮即时切换，无需重启

#### 技术方案
- 轻量自研：`Map<String, Map<String, String>>` + `InheritedWidget`
- 零代码生成、零第三方依赖
- 热重载友好：`context.watch<LocaleState>().t('key')`
- 真机验证三种语言界面显示正确

### Commits

| Hash | 描述 |
|------|------|
| `2f6b3e0` | feat: add trilingual i18n support (zh/ja/en) |

---

## [0.2.2] — 2026-05-21

### 新增 — UI 修复与暗色主题

#### 🎨 UI 图标兼容性修复
- Material Icons 在部分 Android 设备渲染异常 → **改用 emoji 文本图标**
- 🔐 → 密码图标 / 🔄 → 同步图标 / ✂️ → 剪贴板图标
- 彻底移除 `lucide_icons`、`google_fonts`、`flutter_animate` 未使用依赖

#### 🌙 GitHub 风格暗色主题
- 品牌渐变徽章（#58a6ff → #8250df）
- 卡片式布局 + 毛玻璃效果
- 统一色调：背景 `#0d1117`、卡片 `#161b22`、边框 `#30363d`

#### 📂 分类导航
- 分类标签栏：All / Logins / Cards / Notes
- FAB 浮动添加按钮
- 空状态提示（「暂无密码，点击 + 添加」）
- 真机验证分类筛选与渲染正确

### Commits

| Hash | 描述 |
|------|------|
| `84c20ac` | feat: fix UI icons, add dark theme and category navigation |

---

## [0.2.1] — 2026-05-21

### 修复

#### 🔧 编译错误修复
- pointycastle API 对齐：`Pointycastle/BasicUtils` → `pointycastle/extensions`（Dart 3 兼容）
- Isar 兼容性：AGP 降级至 `8.7.3`（适配 `isar_flutter_libs 3.1.0`）
- Android v2 embedding 迁移完成
- `flutter create` 重建全平台脚手架（Android / iOS / Web）

### 配置

- `android/app/build.gradle` — AGP 版本锁定 8.7.3
- 平台级 `AndroidManifest.xml`、`Info.plist` 存根

### 验证

- OPPO Android 15 debug 构建成功
- `adb install` 真机部署验证通过

### Commits

| Hash | 描述 |
|------|------|
| `7d6448c` | fix: fix compile errors, align pointycastle API, verify on real device |

---

## [0.2.0] — 2026-05-20

### 新增 — Flutter 密码管理器 (核心产品)

#### 第一阶段：代码提取与重构
- 从 dartCode.ts 提取 12 个 Dart 文件，重建完整 Flutter 项目结构
- 搭建 Material 3 暗色主题 + Riverpod 状态管理骨架
- Isar 本地数据库集成（AesGcmFileCipher 文件级加密）
- flutter_secure_storage Keychain/Keystore 密钥持久化

#### 第二阶段：密码学引擎
- Argon2id (iterations=3, memory=64MB, parallelism=4) 密钥派生 — 全部 Isolate 隔离
- PBKDF2 兼容层 — 满足跨平台密钥一致性
- AES-256-GCM 双层加密：Isar 文件块级 + 敏感字段级
- KeyManager 内存密钥缓存（5min 自动过期）

#### 第三阶段：WebDAV 原子同步
- PROPFIND → PUT.tmp → MOVE 原子写入协议（避免同步冲突）
- SyncNotifier 状态机 — idle/syncing/error/success 全链路
- 重试逻辑 + 指数退避
- 完整性标签防跨设备恢复攻击

#### 第四阶段：Monica 双剪贴板
- 双通道隔离：TOTP → 系统剪贴板 / 密码 → 安全 RAM 缓冲区
- 30s 系统剪贴板自动清除（Clipboard.setData("")）
- 复制即消失提示覆盖层（clipboard_overlay.dart）

#### 第五阶段：安全审计面板
- 弱密码/重复密码检测引擎
- 自定义动画环形健康指数图（CustomPainter）
- 一键修复入口

#### 第六阶段：原生自动填充
- Android AutofillService 完整实现（Kotlin）
- iOS CredentialProvider 扩展存根（Swift）
- MethodChannel 桥接 (autofill_channel_service.dart)
- 跨平台自动填充抽象层 (autofill_engine.dart)

#### 验证规则落地
- 零模拟状态：所有加密操作使用 pointycastle / cryptography 物理包
- 密钥隔离：原始密钥仅存在于 KeyManager 内存，5min 自动过期
- Isolate 性能保证：Argon2id、AES-GCM、JSON 序列化全部在 Isolate 执行
- 系统剪贴板 30s 无活动自动清空

### 配置

- CLAUDE.md 更新 — 新增 Flutter App 架构知识地图、验证规则、开发流程
- Flutter 项目结构建立（flutter_app/）
- Android & iOS 原生平台代码（android/、ios/）
- Chrome Extension Manifest V3 存根（web/extension/）

### Commits

| Hash | 描述 |
|------|------|
| `77407a9` | feat: build production Flutter password manager from React blueprint |
| `8bbfa26` | chore: add project CLAUDE.md, README, and CHANGELOG |

---

## [0.1.0] — 2026-05-20

### 新增

- 项目初始化 — NexPass Security Core Studio Google AI Studio 应用
- 核心功能模块：Vault（密码库模拟）、Files（源码浏览器）、Sandbox（加密沙箱）、Tests（安全测试面板）、Autofill（自动填充流程）、Security（安全审计仪表板）
- React 19 + TypeScript 5.8 + Vite 6.2 + Tailwind CSS 4 技术栈搭建
- 单文件架构（App.tsx 包含所有 UI 模块）
- AI Studio 自动部署配置（Cloud Run）

### 配置

- 项目级 CLAUDE.md — 开发规范、编码约定、安全护栏、协作规则
- Vite 配置（HMR 默认禁用、路径别名 @/）
- TypeScript 配置（tsconfig.json）
- 环境变量模板（.env.example）
- 基础 README 与 CHANGELOG 文档

### Commits

| Hash | 描述 |
|------|------|
| `0940fea` | Initial commit |
| `f1d7afa` | feat: Initialize NexPass Security Core Studio |
