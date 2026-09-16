# NexPass — 零知识离线优先密码管理器

- GitHub: https://github.com/1624318455/NexPass
- chat_id: `oc_359d87fb0ba4b2e8495c4f490806b75b`

两部分组成：React Studio (src/) 展示应用 + Flutter App (flutter_app/) 生产级移动密码管理器。

## 技术栈

### Flutter App（核心产品）
Dart 3.0+ | flutter_riverpod 2.4 | Isar 3.1 (AES-256-GCM 加密) | flutter_secure_storage 9.0 | pointycastle (Argon2id) + cryptography (AES-GCM) | http (WebDAV) | Material 3 (#5B21B6 紫色)

### React Studio（展示）
TypeScript 5.8 + React 19 | Vite 6.2 | Tailwind CSS 4 | @google/genai (Gemini)

## 架构

```
flutter_app/lib/
├── main.dart                    # 入口: Argon2id → Isar 加密 → Riverpod
├── models/
│   ├── nex_item.dart            # Isar @collection (含 NexField 嵌入)
│   └── app_settings.dart        # 20+ 可配置设置项
├── repositories/vault_repository.dart  # 批量加解密（单 Isolate）
├── services/
│   ├── crypto_utils.dart        # KeyManager + Argon2id + PBKDF2 + AES-256-GCM (Isolate)
│   ├── secure_storage_service.dart # Keychain/Keystore
│   ├── database_service.dart    # Isar AesGcmFileCipher
│   ├── clipboard_service.dart   # Monica 双剪贴板 + 30s 自动清空
│   ├── biometric_service.dart   # local_auth 生物识别封装
│   ├── sync_service.dart        # WebDAV 原子同步 (PROPFIND→PUT.tmp→MOVE)
│   ├── security_audit_service.dart # 弱密码/重复/泄露检测 + 健康指数
│   ├── password_generator_service.dart # 安全密码生成 + 强度评估
│   ├── csv_import_service.dart  # CSV + Bitwarden/KeePass 格式检测
│   ├── autofill_engine.dart     # 跨平台自动填充抽象层
│   └── autofill_channel_service.dart # MethodChannel 桥接
├── state/
│   ├── unlock_state.dart        # 解锁状态机（生物识别/密码回退）
│   ├── vault_state_notifier.dart # Vault CRUD + 搜索 + 收藏
│   └── sync_state.dart          # 同步进度状态机
├── screens/
│   ├── main_screen.dart         # 搜索/分类/复制
│   ├── item_detail_screen.dart  # 10 模块卡片 + 编辑模式 + 浮动操作栏
│   ├── settings_screen.dart     # 9 分区设置页
│   ├── onboarding_screen.dart   # 10 页引导流程
│   ├── lock_screen.dart         # 生物识别 + 密码回退
│   ├── import_preview_screen.dart # CSV 导入预览
│   ├── security_audit_screen.dart # 安全审计面板
│   ├── clipboard_overlay.dart   # 剪贴板 Toast 浮层
│   └── health_ring_chart.dart   # 自定义环形图 (CustomPainter)
├── widgets/
│   └── nex_icons.dart           # 自定义 Canvas 图标
├── theme/
│   └── nex_theme.dart           # Material 3 主题 (#5B21B6 紫色)
└── i18n/
    ├── app_localizations.dart   # 国际化入口
    ├── l10n_en.dart             # 英文
    ├── l10n_zh.dart             # 中文
    └── l10n_ja.dart             # 日文
```

## 密码学架构

```
主密码 → Argon2id (iter=3, mem=64MB, par=4) → 256-bit 派生密钥
  ├──→ AesGcmFileCipher → Isar 文件级加密
  ├──→ VaultRepository → 字段级 AES-256-GCM
  ├──→ SecureStorageService → Keychain/Keystore
  └──→ KeyManager → 内存缓存（5min 自动过期）
```

双层加密: Isar 文件块级 + 敏感字段级。

## 验证规则（强制）

1. **核心数据无模拟**: lib/ 中禁止模拟值，必须用 pointycastle/cryptography 物理加密类
2. **安全性**: 原始密钥 KeyManager 隔离 5min 过期 | 剪贴板 30s 自动清空 | 完整性标签防跨设备恢复
3. **性能**: Argon2id/AES-GCM/JSON 大载荷在 Isolate 执行 | VaultRepository 单 Isolate 批量加解密

## 常用命令

- `cd flutter_app && flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`（代码生成）
- `flutter run` | `flutter build apk` | `flutter analyze`
- React Studio: `npm install` | `npm run dev`（端口 3000） | `npm run build`

## 环境变量（--dart-define）

`NEXPASS_MASTER_PASSWORD` | `NEXPASS_WEBDAV_URL` | `NEXPASS_WEBDAV_USER` | `NEXPASS_WEBDAV_PASS`

React Studio: `GEMINI_API_KEY` | `APP_URL`

## 部署

- React Studio: Google AI Studio (Cloud Run)
- Flutter App: `flutter build apk` / `flutter build ios`
