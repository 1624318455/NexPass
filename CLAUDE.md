# NexPass Security Core Studio - 交互式开发者工作室

## 项目概述

Google AI Studio 应用，作为 NexPass Flutter 密码管理器安全模块的交互式开发者工作室和 Playground。展示 Argon2id 密钥派生、AES-256-GCM 加解密、Isolate 后台计算等核心安全概念，并提供可视化的 Trace Logs 和交互式测试界面。

- **GitHub**: https://github.com/1624318455/NexPass
- **AI Studio**: https://ai.studio/apps/d8d1c69a-beb2-48e1-a7d3-d742d6165207

## 技术栈

- **语言**: TypeScript 5.8 + React 19
- **构建工具**: Vite 6.2
- **包管理器**: npm
- **UI 框架**: Tailwind CSS 4 (via @tailwindcss/vite)
- **图标库**: Lucide React
- **动画**: Motion (Framer Motion 继任)
- **AI API**: @google/genai (Gemini API)
- **服务端**: Express (用于部署/代理)
- **测试框架**: 无 [待配置]
- **Lint/Format**: 仅 `tsc --noEmit` 类型检查
- **数据库**: 无（前端纯展示应用）

## 项目架构

```
NexPass/
├── index.html              # 入口 HTML
├── src/
│   ├── main.tsx            # React 入口，StrictMode 挂载
│   ├── App.tsx             # 核心应用（大单文件，包含所有 UI 模块）
│   ├── index.css           # Tailwind 入口
│   └── data/
│       └── dartCode.ts     # NexPass Flutter 源码片段（作为展示数据）
├── .env.example            # 环境变量模板
├── metadata.json           # AI Studio 应用元数据
├── vite.config.ts          # Vite 配置（含 HMR 控制）
└── tsconfig.json           # TypeScript 配置
```

### 功能模块（均在 App.tsx 内）

- **Vault**: 零知识密码库模拟（搜索、分类、解密展示）
- **Files**: Dart 源码浏览器（语法高亮、复制、下载）
- **Sandbox**: 交互式加密沙箱（Argon2id + AES-256-GCM 参数调优）
- **Tests**: 安全测试模拟面板
- **Autofill**: Android/iOS/Chrome 自动填充流程模拟 + Trace Log
- **Security**: 安全审计仪表板

### 关键设计决策

- **HMR 默认禁用**: 通过 `DISABLE_HMR` 环境变量控制，AI Studio 环境下关闭文件监听防止 Agent 编辑闪烁
- **路径别名**: `@/` 映射到项目根目录
- **单文件架构**: App.tsx 包含所有业务逻辑，适合 AI Studio 应用的展示性质

## 开发流程（自动执行）

1. 理解 → 2. 规划 → 3. 执行 → 4. 审查 → 5. 提交推送 → 6. 通知 Hermes
- 不询问"要提交吗"等问题，自动执行。

## 常用命令

- 安装依赖: `npm install`
- 启动开发: `npm run dev` (端口 3000, 0.0.0.0)
- 构建: `npm run build`
- 预览构建: `npm run preview`
- 类型检查: `npm run lint` (实际是 tsc --noEmit)
- 清理: `npm run clean` (删除 dist/ 和 server.js)

## 编码规范

- **文件命名**: camelCase (TypeScript), kebab-case (CSS)
- **变量/函数**: camelCase
- **组件**: PascalCase (React 函数组件)
- **接口**: PascalCase + I 前缀可选（当前使用不带前缀风格）
- **通用原则**: 不写废话注释，三次原则，优先编辑现有文件，安全优先。

## 环境变量

| 变量 | 用途 | 来源 |
|------|------|------|
| `GEMINI_API_KEY` | Gemini AI API 调用密钥 | AI Studio 自动注入 / .env.local |
| `APP_URL` | 应用托管地址 | AI Studio 自动注入 (Cloud Run) |

## 测试策略

- 当前无测试框架 [待配置]
- **推荐**: Vitest + React Testing Library
- **提交前检查清单**: tsc 类型检查、无调试代码、无硬编码密钥、构建成功

## 安全护栏

- 人工确认: 数据库迁移、认证、支付、基础设施
- 禁止命令: `rm -rf /`, `DROP TABLE`, `git push --force main`
- 发布命令前展示摘要
- 注意: `.env*` 已在 .gitignore 中排除，仅 `.env.example` 可提交

## 协作规则 (Hermes)

- 完成任务后通知 Hermes（飞书群聊 @爱马仕）
- Hermes 负责: CHANGELOG.md、README.md 等文档创建和维护
- 通知内容需包含: 项目路径、GitHub URL、commit hashes、变更摘要、需要做的事
- Hermes bot open_id: ou_bcb48e73ca7890a12ac93b588437167b
- Hermes API: http://127.0.0.1:8642（OpenAI 兼容格式）
- 使用 Node.js 发送飞书消息（Windows 下 curl 中文乱码）

## 决策权限矩阵

- 局部: 单文件内部修改 → 自主
- 模块内: App.tsx 内功能模块调整 → 自主
- 跨模块: 修改 dartCode.ts 数据结构或 vite.config.ts → 必须确认
- 全局: 架构变更、依赖升级、环境变量修改 → 必须确认

## 记忆维护

- 本项目 CLAUDE.md 只放静态知识，过程记忆由 claude-mem 负责。
- 发现坑点、特殊用法立即更新；milestone 后精简合并。

## 部署与发布

- 由 Google AI Studio 托管（Cloud Run）
- 本地开发: `npm run dev`
- 生产构建: `npm run build`
