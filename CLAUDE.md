# NexPass — 零知识离线优先密码管理器

## 项目概述

NexPass 由两部分组成：

1. **React Studio** (`src/`) — Google AI Studio 展示应用，交互式 Play
2. **Flutter App** (`flutter_app/`) — 生产级移动密码管理器（核心产品）

核心哲学：离线优先、零知识信封加密、Monica 双剪贴板、WebDAV 原子同步。

- **GitHub**: https://github.com/1624318455/NexPass
- **AI Studio**: https://ai.studio/apps/d8d1c69a-beb2-48e1-a7d3-d742d6165207

## 项目架构

```
NexPass/
├── CLAUDE.md                    # 本文件（静态知识地图）
├── flutter_app/                 # ★ 核心产品：Flutter 密码管理器
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart            # 入口：密钥派生 → Isar 加密初始化 → Riverpod
│       ├── models/
│       │   ├── nex_item.dart    # Isar @collection 数据模型
│       │   └── nex_item.g.dart  # Isar 代码生成
│       ├── repositories/
│       │   └── vault_repository.dart   # 批量加解密仓储（单 Isolate）
│       ├── services/
│       │   ├── crypto_utils.dart           # Argon2id + PBKDF2 + AES-256-GCM（Isolate）
│       │   ├── secure_storage_service.dart # Keychain/Keystore 密钥管理
│       │   ├── database_service.dart       # Isar 加密配置（AesGcmFileCipher）
│       │   ├── clipboard_service.dart      # Monica 双剪贴板引擎
│       │   ├── sync_service.dart           # WebDAV 原子同步（PROPFIND→PUT.tmp→MOVE）
│       │   ├── security_audit_service.dart # 弱密码/重复密码审计
│       │   ├── password_generator_service.dart
│       │   ├── autofill_engine.dart        # 跨平台自动填充抽象层
│       │   └── autofill_channel_service.dart # MethodChannel 桥接
│       ├── state/
│       │   ├── vault_state_notifier.dart   # Vault CRUD + 搜索
│       │   └── sync_state.dart             # 同步进度状态机
│       └── screens/
│           ├── main_screen.dart            # 主仪表板（搜索/分类/复制）
│           ├── clipboard_overlay.dart      # 双剪贴板提示覆盖层
│           ├── security_audit_screen.dart  # 安全审计面板
│           └── health_ring_chart.dart      # 自定义环形图
├── src/                         # React Studio（AI Studio 展示）
│   ├── App.tsx                  # 展示 UI
│   └── data/dartCode.ts         # Dart 源码参考数据
├── android/                     # Android AutofillService 存根
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/io/nexpass/
│       │   ├── AutofillService.kt
│       │   ├── AutofillStructureParser.kt
│       │   ├── AuthActivity.kt
│       │   └── AutofillServicePlugin.kt
│       └── res/
├── ios/                         # iOS CredentialProvider 扩展
│   └── CredentialProvider/
│       ├── CredentialProviderViewController.swift
│       ├── CredentialStore.swift
│       └── Info.plist
└── web/extension/               # Chrome Extension Manifest V3
```

## 技术栈

### Flutter App（核心产品）

| 领域 | 技术 |
|------|------|
| 语言 | Dart 3.0+ |
| 状态管理 | flutter_riverpod 2.4 |
| 本地数据库 | Isar 3.1（AES-256-GCM 加密文件） |
| 密钥存储 | flutter_secure_storage 9.0 |
| 加密引擎 | pointycastle (Argon2id) + cryptography (AES-GCM) |
| 网络同步 | http (WebDAV 原子事务) |
|| UI | Material 3 浅色主题（MD3 Light + #5B21B6 紫色/靛蓝强调色） |

### React Studio（展示应用）

| 领域 | 技术 |
|------|------|
| 语言 | TypeScript 5.8 + React 19 |
| 构建 | Vite 6.2 |
| UI | Tailwind CSS 4 |
| AI API | @google/genai (Gemini) |

## 密码学架构

```
主密码 (用户输入)
    ↓
Argon2id (iterations=3, memory=64MB, parallelism=4)
    ↓
256-bit 派生密钥
    ├──→ AesGcmFileCipher → Isar 文件级加密
    ├──→ VaultRepository → 字段级 AES-256-GCM 加密
    ├──→ SecureStorageService → Keychain/Keystore 持久化
    └──→ KeyManager → 内存缓存（5min 自动过期）
```

**双层加密**：Isar 文件块级（AesGcmFileCipher）+ 敏感字段级（VaultRepository）。

## 开发流程（自动执行）

1. 理解 → 2. 规划 → 3. 执行 → 4. 审查 → 5. 提交推送 → 6. 通知 Hermes
- 不询问"要提交吗"等问题，自动执行。

## 常用命令

### Flutter App
- 安装依赖: `cd flutter_app && flutter pub get`
- 代码生成: `dart run build_runner build --delete-conflicting-outputs`
- 运行: `flutter run`
- 构建 APK: `flutter build apk`
- 类型检查: `flutter analyze`

### React Studio
- 安装依赖: `npm install`
- 开发: `npm run dev` (端口 3000)
- 构建: `npm run build`

## 验证规则（强制执行）

### 1. 核心数据无模拟状态
- `lib/` 中禁止 React 级模拟值，必须使用原生加密包的物理加密类
- 所有密码学操作通过 pointycastle / cryptography 包实现
- Demo 数据仅在 `_seedDemoDataIfEmpty()` 中使用合成值

### 2. 安全性
- 原始密钥通过 KeyManager 隔离在内存中，5min 自动过期
- 系统剪贴板在 30s 无活动后自动清空（Clipboard.setData("")）
- 派生密钥通过 flutter_secure_storage 存储在 Keychain/Keystore
- 完整性标签防跨设备恢复攻击

### 3. 性能
- 所有 CPU 密集操作（Argon2id、AES-GCM、JSON 大载荷）在 Isolate 中执行
- VaultRepository 批量加解密：单个 Isolate 处理所有字段
- SyncService JSON 序列化/反序列化在 Isolate 中执行
- 主线程仅处理 UI 渲染和轻量状态更新

## 编码规范

- **Dart**: snake_case 文件名，camelCase 变量/函数，PascalCase 类名
- **TypeScript**: camelCase 变量/函数，PascalCase 组件/接口
- **通用**: 不写废话注释，三次原则，优先编辑现有文件，安全优先

## 环境变量

### React Studio
| 变量 | 用途 |
|------|------|
| `GEMINI_API_KEY` | Gemini AI API 密钥 |
| `APP_URL` | 应用托管地址 |

### Flutter App（通过 --dart-define 传入）
| 变量 | 用途 |
|------|------|
| `NEXPASS_MASTER_PASSWORD` | 主密码（首次启动必须提供） |
| `NEXPASS_WEBDAV_URL` | WebDAV 服务地址 |
| `NEXPASS_WEBDAV_USER` | WebDAV 用户名 |
| `NEXPASS_WEBDAV_PASS` | WebDAV 密码 |

## 安全护栏

- 人工确认: 数据库迁移、认证、支付、基础设施
- 禁止命令: `rm -rf /`, `DROP TABLE`, `git push --force main`
- 发布命令前展示摘要
- `.env*` 已在 .gitignore 中排除，仅 `.env.example` 可提交

## 协作规则 (Hermes)
- 完成任务后通过飞书通知 Hermes（bot open_id: ou_bcb48e73ca7890a12ac93b588437167b）
- API: http://127.0.0.1:8642（OpenAI 兼容格式）
- 消息内容：项目路径、GitHub URL（https://github.com/1624318455/NexPass）、commit hashes、变更摘要、待办事项
- 使用 Node.js 发送飞书消息（避免 Windows curl 中文乱码）
- 飞书 @ 提及必须使用富文本格式 (msg_type: "post")，纯文本 `@名字` 不会触发通知：
  ```json
  {
    "msg_type": "post",
    "content": {
      "zh_cn": {
        "title": "",
        "content": [[
          {"tag": "at", "user_id": "ou_xxx"},
          {"tag": "text", "text": " 消息内容"}
        ]]
      }
    }
  }
  ```
- 注意：不同应用下同一个用户的 open_id 不同，需要使用当前应用识别到的 ID

## 决策权限矩阵

- 局部: 单文件内部修改 → 自主
- 模块内: 功能模块调整 → 自主
- 跨模块: 修改数据模型或 vite.config.ts → 必须确认
- 全局: 架构变更、依赖升级、环境变量修改 → 必须确认

## 记忆维护

- 本 CLAUDE.md 只放静态知识，过程记忆由 claude-mem 负责。
- 发现坑点、特殊用法立即更新；milestone 后精简合并。

## 部署与发布

- React Studio: Google AI Studio 托管（Cloud Run）
- Flutter App: `flutter build apk` / `flutter build ios`
- 本地开发: `flutter run`
