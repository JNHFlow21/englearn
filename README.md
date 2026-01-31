# Thought2English

[English](README.en.md)

一个 macOS 小工具：把你每天的中文/英文输入，快速变成两份英文输出：

- **Spoken Script**：更口语、更像你在真实表达（偏 Crypto Twitter / 圈内表达）
- **Formal Writing**：更正式、更适合工作场景

支持 **Gemini** / **DeepSeek**，使用你自己的 API Key（保存在本机 `UserDefaults`，明文）。

## 截图

（待补）

## 快速开始（开发模式）

```bash
swift run
```

## 打包成 `.app`（不需要 Xcode）

```bash
./scripts/package_app.sh
open dist/Thought2English.app
```

## Homebrew 安装（推荐）

```bash
brew tap jnhflow21/thought2english
brew install --cask thought2english
```

更新到最新版本：

```bash
brew upgrade --cask thought2english
```

## 配置

在 **Settings** 页配置：

- Provider（Gemini / DeepSeek）
- Model
- Base URL
- API Key

推荐默认值：

- DeepSeek：Base URL `https://api.deepseek.com`，model `deepseek-chat`
- Gemini：Base URL `https://generativelanguage.googleapis.com`，model `gemini-3-flash-preview`

## Icon（可选）

你可以提供一张 1024×1024 的 PNG（建议：居中、留白足够、对比强，适合深色/浅色背景）。

```bash
# 1) 放到 Assets/AppIcon-1024.png
# 2) 生成 Assets/AppIcon.icns
./scripts/build_icon.sh

# 3) 重新打包
./scripts/package_app.sh
```

## 隐私

见 `PRIVACY.md`。
