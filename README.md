# NexPass Security Core Studio

> Google AI Studio 应用 — NexPass 密码管理器的交互式开发者工作室与安全 Playground

[![AI Studio](https://img.shields.io/badge/AI_Studio-Open-4285F4?logo=googlecloud)](https://ai.studio/apps/d8d1c69a-beb2-48e1-a7d3-d742d6165207)
[![GitHub](https://img.shields.io/badge/GitHub-Repo-181717?logo=github)](https://github.com/1624318455/NexPass)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.8-3178C6?logo=typescript)](https://www.typescriptlang.org/)
[![React](https://img.shields.io/badge/React-19-61DAFB?logo=react)](https://react.dev/)
[![Vite](https://img.shields.io/badge/Vite-6-646CFF?logo=vite)](https://vitejs.dev/)
[![Tailwind](https://img.shields.io/badge/Tailwind_CSS-4-06B6D4?logo=tailwindcss)](https://tailwindcss.com/)

---

## 项目概述

NexPass Security Core Studio 是一个在 **Google AI Studio** 上运行的交互式开发者工作室，旨在可视化和演示 [NexPass](https://github.com/1624318455/NexPass) Flutter 密码管理器的核心安全模块。

通过图形化界面展示 Argon2id 密钥派生、AES-256-GCM 加解密、Isolate 后台计算等密码学概念，并提供 Trace Logs 与交互式测试面板，帮助开发者和安全工程师直观理解密码管理器的安全设计。

| 功能模块 | 说明 |
|---------|------|
| **Vault** | 零知识密码库模拟 — 搜索、分类、解密展示 |
| **Files** | Dart 源码浏览器 — 语法高亮、复制、下载 |
| **Sandbox** | 交互式加密沙箱 — Argon2id + AES-256-GCM 参数调优 |
| **Tests** | 安全测试模拟面板 |
| **Autofill** | Android/iOS/Chrome 自动填充流程模拟 + Trace Log |
| **Security** | 安全审计仪表板 |

---

## 技术栈

| 类别 | 技术 |
|------|------|
| 语言框架 | TypeScript 5.8 + React 19 |
| 构建工具 | Vite 6.2 |
| 包管理器 | npm |
| UI 框架 | Tailwind CSS 4（@tailwindcss/vite） |
| 图标库 | Lucide React |
| 动画引擎 | Motion（Framer Motion 继任） |
| AI API | @google/genai（Gemini API） |
| 服务端 | Express（部署/代理用） |

---

## 快速开始

```bash
# 1. 安装依赖
npm install

# 2. 配置环境变量
cp .env.example .env.local
# 编辑 .env.local，填入你的 GEMINI_API_KEY

# 3. 启动开发服务器
npm run dev          # http://localhost:3000
```

### 其他命令

| 命令 | 用途 |
|------|------|
| `npm run dev` | 启动开发服务器（端口 3000） |
| `npm run build` | 生产构建 |
| `npm run preview` | 预览构建产物 |
| `npm run lint` | TypeScript 类型检查（tsc --noEmit） |
| `npm run clean` | 清理 dist/ 和 server.js |

---

## 项目结构

```
NexPass/
├── index.html               # 入口 HTML
├── src/
│   ├── main.tsx             # React 入口，StrictMode 挂载
│   ├── App.tsx              # 核心应用（单文件，包含所有 UI 模块）
│   ├── index.css            # Tailwind 入口
│   └── data/
│       └── dartCode.ts      # NexPass Flutter 源码片段（展示数据）
├── CLAUDE.md                # 项目级开发规范（Claude Code 协作配置）
├── .env.example             # 环境变量模板
├── metadata.json            # AI Studio 应用元数据
├── vite.config.ts           # Vite 配置
├── tsconfig.json            # TypeScript 配置
├── CHANGELOG.md             # 变更日志
└── README.md                # 本文件
```

---

## 设计决策

- **单文件架构** — App.tsx 包含所有业务逻辑，适合 AI Studio 应用的展示性质
- **HMR 默认禁用** — AI Studio 环境下关闭文件监听，防止 Agent 编辑导致页面闪烁
- **路径别名** — `@/` 映射到项目根目录

---

## 部署

由 Google AI Studio 托管（Cloud Run），AI Studio 会自动注入 `GEMINI_API_KEY` 和 `APP_URL` 环境变量。

AI Studio 地址: [https://ai.studio/apps/d8d1c69a-beb2-48e1-a7d3-d742d6165207](https://ai.studio/apps/d8d1c69a-beb2-48e1-a7d3-d742d6165207)

---

## 许可证

MIT © 2025 NexPass
