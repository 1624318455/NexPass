# NexPass

> 零知识离线优先密码管理器 — Flutter 移动端核心产品 + React AI Studio 交互式工作室

[![GitHub](https://img.shields.io/badge/GitHub-Repo-181717?logo=github)](https://github.com/1624318455/NexPass)
[![AI Studio](https://img.shields.io/badge/AI_Studio-Open-4285F4?logo=googlecloud)](https://ai.studio/apps/d8d1c69a-beb2-48e1-a7d3-d742d6165207)
[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8-3178C6?logo=typescript)](https://www.typescriptlang.org/)

**NexPass** 由两部分组成：

| 组件 | 说明 | 目录 |
|------|------|------|
| **Flutter App** | 生产级移动密码管理器（核心产品） | `flutter_app/` |
| **React Studio** | Google AI Studio 交互式开发者工作室 | `src/` |

核心哲学：**离线优先**、**零知识信封加密**、**Monica 双剪贴板**、**WebDAV 原子同步**。

---

## Flutter App（核心产品）

移动端密码管理器，采用 **Argon2id + AES-256-GCM 双层加密**、**Isolate 隔离密码学引擎**、**WebDAV 原子同步**和 **Monica 双剪贴板**设计。

### 技术栈

| 领域 | 技术 |
|------|------|
| 语言 | Dart 3.0+ |
| 状态管理 | flutter_riverpod 2.4 |
| 本地数据库 | Isar 3.1（AES-256-GCM 加密文件） |
| 密钥存储 | flutter_secure_storage 9.0（Keychain/Keystore） |
| 加密引擎 | pointycastle (Argon2id + PBKDF2) + cryptography (AES-GCM) |
| 网络同步 | http (WebDAV 原子事务) |
| UI | Material 3 暗色主题 + CustomPainter 动画环形图 |
| 原生桥接 | MethodChannel — AutofillService (Android) / CredentialProvider (iOS) |

### 密码学架构

```
主密码 (用户输入)
    ↓
Argon2id (iterations=3, memory=64MB, parallelism=4)  ← Isolate
    ↓
256-bit 派生密钥
    ├──→ AesGcmFileCipher → Isar 文件级加密
    ├──→ VaultRepository → 字段级 AES-256-GCM 加密
    ├──→ SecureStorageService → Keychain/Keystore 持久化
    └──→ KeyManager → 内存缓存（5min 自动过期）
```

**双层加密**：Isar 文件块级（AesGcmFileCipher）+ 敏感字段级（VaultRepository），所有加密操作在 Isolate 中执行。

### 核心功能

#### 🔐 密码学引擎（Isolate 隔离）
- Argon2id (iterations=3, memory=64MB, parallelism=4) 密钥派生
- PBKDF2 兼容层 — 跨平台密钥一致性
- AES-256-GCM 字段级加密 / 解密
- KeyManager 内存密钥缓存（5min 自动过期）
- 所有 CPU 密集操作在独立 Isolate 中执行

#### 🔄 WebDAV 原子同步
- PROPFIND → PUT.tmp → MOVE 原子写入协议
- SyncNotifier 状态机：idle / syncing / error / success
- 指数退避重试逻辑
- 完整性标签防跨设备恢复攻击

#### ✂️ Monica 双剪贴板
| 类型 | 去向 | 清理 |
|------|------|------|
| TOTP 验证码 | 系统剪贴板 | 30s 自动清除 |
| 密码 | 安全 RAM 缓冲区 | 退出复制界面即清除 |

- 复制即消失提示覆盖层（clipboard_overlay.dart）
- 系统剪贴板 30s 无活动自动清空

#### 🛡️ 安全审计面板
- 弱密码检测（长度、复杂度规则）
- 重复密码检测
- 自定义动画环形健康指数图（CustomPainter）
- 一键修复入口

#### 📱 原生自动填充
- **Android**: AutofillService 完整 Kotlin 实现
- **iOS**: CredentialProvider 扩展 Swift 存根
- **抽象层**: autofill_engine.dart 跨平台统一接口 + MethodChannel 桥接

### 项目结构

```
NexPass/
├── flutter_app/                 # ★ 核心产品
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart                    # 入口：密钥派生 → Isar 初始化 → Riverpod
│       ├── models/
│       │   └── nex_item.dart            # Isar @collection 数据模型
│       ├── repositories/
│       │   └── vault_repository.dart    # 批量加解密仓储（单 Isolate）
│       ├── services/
│       │   ├── crypto_utils.dart             # Argon2id + PBKDF2 + AES-256-GCM
│       │   ├── secure_storage_service.dart   # Keychain/Keystore 密钥管理
│       │   ├── database_service.dart         # Isar 加密配置
│       │   ├── clipboard_service.dart        # Monica 双剪贴板引擎
│       │   ├── sync_service.dart             # WebDAV 原子同步
│       │   ├── security_audit_service.dart   # 弱密码/重复密码审计
│       │   ├── password_generator_service.dart
│       │   ├── autofill_engine.dart          # 跨平台自动填充抽象层
│       │   └── autofill_channel_service.dart # MethodChannel 桥接
│       ├── state/
│       │   ├── vault_state_notifier.dart     # Vault CRUD + 搜索
│       │   └── sync_state.dart               # 同步进度状态机
│       └── screens/
│           ├── main_screen.dart             # 主仪表板（搜索/分类/复制）
│           ├── clipboard_overlay.dart       # 双剪贴板提示覆盖层
│           ├── security_audit_screen.dart   # 安全审计面板
│           └── health_ring_chart.dart       # 自定义环形图
├── android/                     # Android AutofillService 存根
│   └── app/src/main/kotlin/io/nexpass/
│       ├── AutofillService.kt
│       ├── AutofillStructureParser.kt
│       ├── AuthActivity.kt
│       └── AutofillServicePlugin.kt
├── ios/                         # iOS CredentialProvider 扩展
│   └── CredentialProvider/
│       ├── CredentialProviderViewController.swift
│       └── CredentialStore.swift
└── web/extension/               # Chrome Extension Manifest V3
```

### 快速开始

```bash
# 1. 安装 Flutter 依赖
cd flutter_app && flutter pub get

# 2. 代码生成（Isar）
dart run build_runner build --delete-conflicting-outputs

# 3. 运行
flutter run

# 4. 构建 APK
flutter build apk
```

### 环境变量（--dart-define）

| 变量 | 用途 |
|------|------|
| `NEXPASS_MASTER_PASSWORD` | 主密码（首次启动必须提供） |
| `NEXPASS_WEBDAV_URL` | WebDAV 服务地址 |
| `NEXPASS_WEBDAV_USER` | WebDAV 用户名 |
| `NEXPASS_WEBDAV_PASS` | WebDAV 密码 |

---

## React Studio（交互式开发者工作室）

> Google AI Studio 应用 — NexPass 密码管理器的交互式开发者工作室与安全 Playground

[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react)](https://react.dev/)
[![Vite](https://img.shields.io/badge/Vite-6-646CFF?logo=vite)](https://vitejs.dev/)
[![Tailwind](https://img.shields.io/badge/Tailwind_CSS-4-06B6D4?logo=tailwindcss)](https://tailwindcss.com/)

NexPass Security Core Studio 是一个在 **Google AI Studio** 上运行的交互式开发者工作室，旨在可视化和演示 Flutter 密码管理器的核心安全模块。

| 功能模块 | 说明 |
|---------|------|
| **Vault** | 零知识密码库模拟 — 搜索、分类、解密展示 |
| **Files** | Dart 源码浏览器 — 语法高亮、复制、下载 |
| **Sandbox** | 交互式加密沙箱 — Argon2id + AES-256-GCM 参数调优 |
| **Tests** | 安全测试模拟面板 |
| **Autofill** | Android/iOS/Chrome 自动填充流程模拟 + Trace Log |
| **Security** | 安全审计仪表板 |

### 技术栈

| 类别 | 技术 |
|------|------|
| 语言框架 | TypeScript 5.8 + React 19 |
| 构建工具 | Vite 6.2 |
| UI 框架 | Tailwind CSS 4（@tailwindcss/vite） |
| 图标库 | Lucide React |
| 动画引擎 | Motion（Framer Motion 继任） |
| AI API | @google/genai（Gemini API） |

### 快速开始

```bash
# 1. 安装依赖
npm install

# 2. 配置环境变量
cp .env.example .env.local
# 编辑 .env.local，填入你的 GEMINI_API_KEY

# 3. 启动开发服务器
npm run dev          # http://localhost:3000
```

| 命令 | 用途 |
|------|------|
| `npm run dev` | 启动开发服务器（端口 3000） |
| `npm run build` | 生产构建 |
| `npm run lint` | TypeScript 类型检查（tsc --noEmit） |

### 设计决策

- **单文件架构** — App.tsx 包含所有业务逻辑，适合 AI Studio 应用的展示性质
- **HMR 默认禁用** — AI Studio 环境下关闭文件监听，防止 Agent 编辑导致页面闪烁
- **路径别名** — `@/` 映射到项目根目录

### 部署

由 Google AI Studio 托管（Cloud Run），AI Studio 会自动注入 `GEMINI_API_KEY` 和 `APP_URL` 环境变量。

AI Studio 地址: [https://ai.studio/apps/d8d1c69a-beb2-48e1-a7d3-d742d6165207](https://ai.studio/apps/d8d1c69a-beb2-48e1-a7d3-d742d6165207)

---

## 安全护栏

- 零模拟状态：所有加密操作使用物理加密包，无 mock
- 密钥隔离：原始密钥仅存在于 KeyManager 内存，5min 自动过期
- Isolate 强制：Argon2id、AES-GCM、JSON 序列化全部在 Isolate 执行
- 剪贴板自动清空：系统剪贴板 30s 无活动自动清除

## 许可证

MIT © 2025 NexPass
