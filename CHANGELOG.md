# Changelog

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
