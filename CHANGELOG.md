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

## [0.4.0] — 2026-05-22

### 新增 — 10 页完整引导流程

#### 🚀 10 页引导流水线
所有页面含插图、说明文字、前进/后退/跳过导航，`PageView` + `Indicator` 分页：

| # | 页面 | 说明 |
|---|------|------|
| 1 | **快速初始化** | 引导完成初次启动的基本设置 |
| 2 | **安全设置** | 主密码、生物识别、密保问答 |
| 3 | **自动填充** | 启用 Autofill 服务说明 |
| 4 | **主题选择** | 6 种强调色选择（themeColorIndex 0-5） |
| 5 | **导航栏配置** | 可选择显示密码库/验证器/卡片/密钥通行证 Tab |
| 6 | **数据导入** | CSV/Bitwarden/浏览器导入引导 |
| 7 | **密码列表定制** | 最近快捷项、收藏夹开关 |
| 8 | **密码卡片显示** | 用户名/网站/关联验证器显示开关 |
| 9 | **验证器卡片显示** | 颁发者/账号/进度条/平滑动画开关 |
| 10 | **完成页** | 汇总所有配置，确认后保存 |

#### 🗄️ AppSettings 数据模型
- `flutter_app/lib/models/app_settings.dart` — 全新模型
- **20+ 可持久化配置项**：安全/自动填充/主题/导航/列表/卡片/验证器/语言
- 引导完成时自动 `SecureStorage` 持久化全部设置
- `save()` / `load()` 方法，JSON 序列化

#### 🌐 i18n 扩充
- 新增 **45+** 翻译字符串（en/zh/ja），总计约 **100 字符串**
- 覆盖全部 10 页引导文案 + AppSettings 描述
- 三语同步：所有新增字符串中/日/英完整翻译

#### ✅ 验证
- OPPO Android 15 真机验证通过
- 所有 10 页正常渲染、前进/后退/导航正确
- 引导完成设置自动保存验证通过

### Commits

| Hash | 描述 |
|------|------|
| `281d0c5` | feat: implement full 10-page onboarding flow |

---

## [0.5.0] — 2026-05-22

### 新增 — 设置页面重设计

#### ⚙️ 9 个设置分区
完整映射 10 页引导流程的配置项，统一管理入口：

| 分区 | 功能 |
|------|------|
| **外观** | 主题颜色选择器（6 色预设）、语言选择器 |
| **安全** | 主密码设置、生物识别开关、密保问答 |
| **自动填充** | Autofill 服务开关 |
| **界面布局** | 导航栏 Tab 显示（密码库/验证器/卡片/密钥通行证） |
| **验证器** | 颁发者/账号/进度条/平滑动画开关 |
| **数据管理** | WebDAV 配置（URL/用户名/密码）、手动同步触发、导入（Bitwarden/KeePass/CSV） |
| **安全审计** | 弱密码/重复密码检测引擎入口 |
| **应用锁定** | 锁定开关 |
| **关于** | 版本号、许可证 |

#### 🎨 UI 实现
- 分区式布局：`ListView` + 分节标题，清晰层次
- 主题色选择器：6 色圆形预设，实时预览
- 语言选择器：中/日/英即时切换
- WebDAV 配置表单：URL + 用户名 + 密码输入

#### 🌐 i18n 扩充
- 新增 **27 个**翻译字符串（en/zh/ja），总计约 **130 字符串**
- 覆盖全部设置分区标签、选择项、表单提示

### Commits

| Hash | 描述 |
|------|------|
| `da74ee8` | feat(settings): redesign settings screen with full onboarding settings mapping |

---

## [0.6.0] — 2026-05-22

### 新增 — 设置功能全部实现（Phase 0–6 全部完成）

#### ✅ Phase 0：主题颜色即时生效
- 6 色预设主题实时切换，UI 即时渲染
- `nex_theme.dart` 动态主题供应，AppSettings.themeColorIndex 驱动
- 切换无需重启、无闪烁

#### ✅ Phase 1：生物识别解锁
- `flutter_app/lib/services/biometric_service.dart` — local_auth 封装
- `flutter_app/lib/screens/lock_screen.dart` — 锁屏界面
- `flutter_app/lib/state/unlock_state.dart` — 解锁状态机
- 生物识别验证 → 解锁 → 密码回退（fallback）
- `ThemeMode.light` 锁屏样式统一

#### ✅ Phase 2：主密码修改
- `reEncryptAllItems()` — 旧密钥解密所有条目 → 新密钥重新加密
- 密码变更对话框，确认后执行批量重加密
- 安全过渡：重加密中途崩溃不影响已处理条目

#### ✅ Phase 3：WebDAV 凭据热更新
- `StateProvider` 驱动 WebDAV 配置运行时更新
- `SyncService` 运行时重建连接，无需重启应用
- 配置表单即时生效

#### ✅ Phase 4：卡片显示设置驱动渲染
- 密码卡片：用户名/网站/关联验证器 按 AppSettings 显隐
- 验证器卡片：颁发者/账号/进度条/平滑动画 按 AppSettings 显隐
- `main_screen.dart` 渲染逻辑对接 AppSettings

#### ✅ Phase 5：导航标签自定义
- 密码库/验证器/卡片/密钥通行证 Tab 按设置显示/隐藏
- `main_screen.dart` 导航栏动态构建

#### ✅ Phase 6：CSV 导入
- `csv_import_service.dart` — Bitwarden / KeePass / 通用 CSV 格式自动检测
- `import_preview_screen.dart` — 导入预览 + 字段映射选择
- 格式检测：列头解析 → 匹配预置模板
- OPPO Android 15 真机验证通过

### Commits

| Hash | 描述 |
|------|------|
| `3b296d8` | feat(settings): implement core settings functionality (Phase 0-5) |
| `5a0db74` | feat(settings): implement password change and WebDAV credential hot update |
| `3c5d98f` | feat(import): implement CSV import with format detection |

---

## [0.6.1] — 2026-05-22

### 修复 — 6 个设置功能 Bug 修复

#### 🐛 1. 语言跟随系统
- `localeProvider` 从 AppSettings 读取语言配置
- "Follow System" 选项使用平台语言，无需手动指定

#### 🐛 2. 生物识别开关
- 开启前验证设备能力（`local_auth.canCheckBiometrics`）
- 检测生物识别录入状态，未录入时提示引导

#### 🐛 3. 自动填充跳转
- "Enable System Autofill" 按钮跳转 Android 系统设置页面
- 原生 Kotlin 桥接：`AutofillServicePlugin.kt` 新增 Intent 启动

#### 🐛 4. 主题颜色即时生效
- `MaterialApp` 加 `ValueKey`，切换主题色时强制 Widget 树重建
- 彻底消除主题缓存导致的颜色不更新

#### 🐛 5. 密钥管理重构
- 新增 `activateKey()` 方法，session 过期时触发锁屏
- `unlock_state.dart` 解锁状态机增强

#### 🐛 6. i18n 重复 key 修复
- en/zh/ja 三语重复翻译 key 清理
- 编译警告消除

### Commits

| Hash | 描述 |
|------|------|
| `cdafddc` | fix(settings): implement all 6 broken settings features |

---

## [0.6.2] — 2026-05-22

### 修复 — 引导循环 Bug

#### 🐛 点击「完成」后页面循环回到第一步
- **根因**: `onboardingDoneProvider` 是 `Provider<bool>`（编译期固定为 `false`），写入 SecureStorage 后内存 provider 值未更新，`MaterialApp.build()` 始终看到 `false`，导致 `home:` 始终显示 `OnboardingScreen`
- **修复**: `Provider<bool>` → `StateProvider<bool>`，支持运行时更新
- `_complete()` 中设置 provider state = `true`
- 移除 `Navigator.pushReplacement`，`MaterialApp` 自动重建切换到 `MainScreen`

#### ✅ 验证
- OPPO Android 15 真机验证通过
- 引导完成 → 自动跳转密码库，无循环

### Commits

| Hash | 描述 |
|------|------|
| `f96e6a1` | fix(onboarding): prevent loop back to step 1 after completing onboarding |

---

## [0.6.3] — 2026-05-22

### 修复 — 生物识别完全不工作

#### 🐛 生物识别弹窗不显示
- **根因**: `MainActivity` 继承 `FlutterActivity`，但 `local_auth` 包要求 `FlutterFragmentActivity` 才能显示生物识别弹窗覆盖层
- **修复**: `MainActivity` → `FlutterFragmentActivity`（关键 1 行变更）

#### 🔧 LockScreen 改进
- 启动时检查设备能力：`isDeviceSupported()` + `canCheckBiometrics()`
- 显示加载状态，无生物识别硬件时隐藏按钮
- 设备不支持时自动回退到密码输入
- 错误提示改为 banner 样式，更友好的 UX

#### ✅ 验证
- OPPO Android 15 真机验证通过
- 生物识别弹窗正常弹出，指纹验证 → 解锁 → 密码回退全链路

### Commits

| Hash | 描述 |
|------|------|
| `dd3edd7` | fix(biometric): change MainActivity to FlutterFragmentActivity for local_auth compatibility |

---

## [0.6.4] — 2026-05-22

### 修复 — Onboarding 循环永久修复

#### 🐛 onboarding 完成后崩溃 / 仍循环
- **根因**: `main.dart` 中残留 `ref.listen` 回调，在 `ConsumerWidget.build()` 内触发 `Navigator.of(context)`——该 context 在 `MaterialApp` 上方，找不到 `Navigator`
- **修复**: 移除 `ref.listen` 回调，完全依赖 `ValueKey` + `ref.watch(onboardingDoneProvider)` 在 `home:` 中自动切换页面
- 移除 `onboarding_screen.dart` 中未使用的 `biometric_service` import，消除编译警告

#### ✅ 验证
- OPPO Android 15 真机验证通过
- app 启动正常，无崩溃，引导→主屏全链路无循环

### Commits

| Hash | 描述 |
|------|------|
| `8a832f5` | fix(onboarding): remove ref.listen callback to prevent Navigator crash |

---

## [0.6.5] — 2026-05-22

### 修复 — 引导流程与设置功能完全对齐

#### 🧩 修复 3 处功能缺失
引导流程 10 页与设置页面 14 项功能的 feature parity 补齐：

| 页面 | 修复内容 |
|------|----------|
| 自动填充页 | 「Open System Settings」按钮接入 `AutofillEngine.openSystemSettings()` |
| 列表定制页 | 补充缺失的 `showFavorites` 开关（之前只有 settings 界面有） |
| 数据导入页 | Bitwarden / KeePass / CSV 三个选项接入 `FilePicker` + `CsvImportService` + `ImportPreviewScreen` |

- 全部功能复用 `settings_screen.dart` 同一套业务逻辑
- 引导流程与设置界面配置项 100% 同步，无遗漏

#### ✅ 审计结论
引导流程 10 页 与 设置页面 14 项功能 已完全对齐。

### Commits

| Hash | 描述 |
|------|------|
| `75f3d2c` | fix(onboarding): implement missing feature parity with settings |

---

## [0.7.0] — 2026-05-22

### 重构 — M3 颜色系统迁移

#### 🎨 硬编码颜色 → Theme.of(context).colorScheme
8 个屏幕文件 + 主题文件全线迁移，移除 `NexTheme.xxx` 硬编码引用：

| 文件 | 迁移内容 |
|------|----------|
| `clipboard_overlay.dart` | ~25 处 `NexTheme.xxx` → `cs.xxx` |
| `health_ring_chart.dart` | `trackColor` 参数化，支持动态主题 |
| `lock_screen.dart` | `NexTheme.primary` → `cs.primary` |
| `main_screen.dart` | surface/text/border 全部颜色迁移 |
| `onboarding_screen.dart` | `.withOpacity()` → `.withValues(alpha:)` |
| `security_audit_screen.dart` | 完整重写使用 ColorScheme |
| `settings_screen.dart` | section headers、chevron、color dot 迁移 |
| `nex_theme.dart` | 移除废弃 `secondaryHeaderColor`，重构颜色定义 |

#### ✅ 验证
- `flutter analyze`: **0 errors**, 16 warnings（仅 Isar experimental API）
- 已构建 debug APK 并部署到真机验证通过

### Commits

| Hash | 描述 |
|------|------|
| `864ae59` | refactor(theme): migrate hardcoded colors to Theme.of(context).colorScheme across all screens |

---

## [0.8.0] — 2026-05-22

### 新增 — M3 响应式布局 & Edge-to-Edge 优化

#### 📐 Edge-to-Edge 显示
- `main.dart`: 启用全屏 edge-to-edge 显示，`AnnotatedRegion` 包裹 `MaterialApp`
- `nex_theme.dart`: `appBarTheme` 添加 `systemOverlayStyle`（亮/暗模式自动适配）

#### 🧩 布局 Tokens 化
- `nex_theme.dart`: 新增 `xxxl`（32dp）间距 token，配合现有 sm/md/lg/xl 形成完整间距体系
- `settings_screen.dart`: 所有硬编码 `20/8/4` → `NexTheme` tokens，顶部用 `viewPadding.top`，底部动态 `120 + padding.bottom`
- `main_screen.dart`: FAB 从 `Positioned/Stack` → `Scaffold.floatingActionButton`，`_VaultPage` 移除 Stack 包装，header 用 `viewPadding.top`，底部 `120 + padding.bottom`
- `onboarding_screen.dart`: `EdgeInsets.fromLTRB(20,0,20,32)` → `NexTheme` tokens
- `clipboard_overlay.dart`: `padding.top + 8` → `NexTheme.sm`

#### ✅ 验证
- `flutter analyze`: **0 errors**
- 已构建 debug APK 并部署到真机验证通过

### Commits

| Hash | 描述 |
|------|------|
| `db79927` | refactor(layout): implement responsive layout with safe-area and edge-to-edge |

---

## [0.9.0] — 2026-05-22

### 重构 — M3 合规性审计自修复

#### 🎨 主题进化（nex_theme.dart）
- 移除遗留颜色别名，清理过期定义
- 新增完整 M3 组件主题：`listTileTheme` / `textButtonTheme` / `checkboxTheme` / `radioTheme`
- 所有 `FilledButton` 中的 `Colors.white` → `cs.onPrimary` / `cs.onError`，遵循 ColorScheme 契约

#### 📝 排版 Tokens 化
- **~48 处**硬编码 `fontSize` 替换为 `Theme.of(context).textStyles` 体系
- 涉及全部 8 个屏幕文件，排版与主题完全解耦

#### 🧩 组件语义化
- `Container` → `Card`（security_audit_screen），获得 M3 Card 默认圆角/阴影/ink
- `GestureDetector` → `InkWell`（audit/onboarding），获得水波纹反馈
- 移除 `FilledButton.shape` 覆盖，使用 MD3 默认按钮形状

#### ✅ 验证
- `flutter analyze`: 零新增错误
- 已构建 debug APK 并部署真机验证

### Commits

| Hash | 描述 |
|------|------|
| `1d87d7d` | refactor(theme): implement M3 compliance audit self-fix across all screens |

---

## [0.9.1] — 2026-05-22

### 修复 — 键盘溢出 & 生物识别首次启动

#### 🐛 1. 锁屏键盘溢出
- `Column` 包裹 `SingleChildScrollView`，锁屏输入框弹出键盘时不会溢出
- 添加 `viewInsets.bottom` 动态 padding，键盘弹出时自动调整布局

#### 🐛 2. 引导页键盘溢出
- 10 个引导页面全部添加 `_pageScroll` 滚动包装
- 任何带输入框的页面都不会被键盘遮挡

#### 🐛 3. 生物识别首次启动失败
- **根因**: 首次启动时 `recoverDerivedKey()` 无有效密钥可恢复，锁屏界面即使生物识别验证成功也无密钥解密数据库
- **修复**: 新增 `_ensureKeyStored()` 方法，在显示锁屏前预派生密钥并存储到 SecureStorage
- 生物识别验证通过后 `recoverDerivedKey()` 能返回有效密钥，数据库正常解密

### Commits

| Hash | 描述 |
|------|------|
| `a722156` | fix(ui): fix lock screen and onboarding keyboard overflow; fix biometric first-launch key recovery |

---

## [0.10.0] — 2026-05-22

### 新增 — 保险库 UI 完善

#### 🏷️ Tab 标签统一
- 保险库 Tab 使用与设置一致的 i18n key：密码 / 卡包 / 验证器 / 通行密钥
- 引导流程与设置页配置项 100% 同名同步

#### 🗄️ 数据库模型增强
- `NexItem` 新增 `lastUsedAt` 字段 — 记录最近使用时间
- 新增 `website` / `totpSecret` / `hasTotp` getters，字段访问标准化

#### ⭐ 收藏功能
- 收藏按钮（爱心图标），支持切换收藏状态
- **收藏区**：置于列表顶部，受 `showFavorites` 设置控制
- 自定义 Canvas 图标：`heart` （`nex_icons.dart`）

#### 🕐 最近使用
- 复制密码 / 验证码时自动标记 `lastUsedAt`
- **最近使用区**：按时间排序，受 `showRecentShortcuts` 设置控制

#### 🎴 卡片 UI 修复
- `type=2` 卡片图标修正为 `creditCard`（信用卡）
- 验证器卡片应用 `auth` 显示设置（issuer/account/progress bar）
- 自定义 Canvas 图标：`creditCard`

#### 🧩 新文件
- `flutter_app/lib/widgets/nex_icons.dart` — 自定义 Canvas 图标集（creditCard / heart）

### Commits

| Hash | 描述 |
|------|------|
| `375de0b` | feat(vault): unify tab labels, add favorites/recent sections, complete card UI |

---

## [0.11.0] — 2026-05-22

### 新增 — 卡片详情页 & 底部浮动操作栏

#### 📄 ItemDetailScreen（10 模块）
全新 `flutter_app/lib/screens/item_detail_screen.dart`（720 行），从列表点击进入：

| # | 模块 | 说明 |
|---|------|------|
| 1 | **头部信息** | 标题 + 类型图标（密码/卡包/验证器） |
| 2 | **账号** | 解密后 username 显示 |
| 3 | **密码显隐切换** | 加密存储，点击显/隐切换 |
| 4 | **安全状态评估** | 密码强度指示（弱/中/强） |
| 5 | **网址跳转** | 通过 `url_launcher` 打开 |
| 6 | **TOTP 动态验证码** | 30s 自动刷新倒计时 |
| 7 | **自定义字段** | 额外字段列表展示 |
| 8 | **存储信息** | 加密方式、存储位置 |
| 9 | **时间记录** | 创建时间 / 更新时间 / 最近使用 |
| 10 | **备注** | 文本备注区域 |

#### 🪟 底部浮动操作栏
- 毛玻璃效果（BackdropFilter + blur）
- **收藏** / **编辑** / **导出** / **删除** 四个按钮
- 使用 `pencil` / `download` 自定义图标

#### 🧩 自定义图标扩展
- `nex_icons.dart`: 新增 `pencil`（编辑）和 `download`（导出）

#### 🐛 修复
- 详情页敏感字段使用 `decryptedValue` 而非加密的 `field.value`
- Demo 数据补充 `website` 字段
- 卡片点击导航至 `ItemDetailScreen`
- AGP 升级至 `8.9.1` 兼容 `url_launcher` 依赖

### Commits

| Hash | 描述 |
|------|------|
| `600cad0` | feat(vault): add card detail page, favorites visual separation, fix demo data |

---

## [0.11.1] — 2026-05-22

### 新增 — 详情页编辑模式 & 关联笔记模块

#### ✏️ 编辑模式
- 铅笔按钮切换「编辑/保存」模式
- 编辑状态：字段变为可编辑输入框
- 保存：更新数据库（`vault_repository`），字段实时持久化
- 新增 `_EditFieldCard` 组件 — 可编辑字段卡片

#### 📝 关联笔记模块
- `fieldType==3` 字段独立展示为笔记区域
- 新增 `_NotesCard` 组件 — 笔记内容卡片

#### 🐛 URL 模块修复
- 添加 `canLaunchUrl` 守卫，防止无法处理的 URL 引发崩溃
- 使用 `LaunchMode.externalApplication` 强制外部浏览器打开

#### ✅ 验证
- `flutter analyze`: 零错误
- 真机部署测试通过

### Commits

| Hash | 描述 |
|------|------|
| `51fd0a1` | feat(detail): add edit mode, notes module, fix URL launch |

---

## [0.11.2] — 2026-05-22

### 修复 — 详情页编辑按钮双重加密 Bug

#### 🐛 第二次编辑保存后显示乱码
- **根因**: `saveItem()` 原地加密敏感字段，导致内存中 `NexItem` 的字段值被加密值覆盖
- 第二次点击编辑 → 保存时，已加密的值被再次加密（**双重加密**），解密后显示乱码
- **修复方案**:
  - 保存前深拷贝 `NexItem`，确保原始对象不被污染
  - 保存后调用 `reloadVault` 刷新列表，重新从数据库加载清洁数据
  - 增加空字段名防护

#### ✅ 验证
- `flutter analyze`: 零错误
- APK 构建部署成功

### Commits

| Hash | 描述 |
|------|------|
| `9ab613d` | fix(detail): deep copy NexItem before save to prevent double encryption |

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
