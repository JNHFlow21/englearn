# Thought2English

[English](README.en.md)

一个 macOS 小工具：把你每天的中文/英文输入，快速变成两份英文输出：

- **Spoken Script**：更口语、更像你在真实表达（偏 Crypto Twitter / 圈内表达）
- **Formal Writing**：更正式、更适合工作场景

支持 **Gemini** / **DeepSeek**，使用你自己的 API Key（保存在本机 `UserDefaults`，明文）。

## 截图

把截图放到 `assets/screenshots/`（例如：`assets/screenshots/write.png`），然后在这里用相对路径引用即可：

```md
![Write](assets/screenshots/write.png)
![History](assets/screenshots/history.png)
![Settings](assets/screenshots/settings.png)
```

## 安装（推荐）

```bash
brew tap jnhflow21/thought2english
brew install --cask thought2english
```

更新到最新版本：

```bash
brew upgrade --cask thought2english
```

## 使用

1) 打开 Thought2English  
2) 在 Write 页粘贴中文或英文  
3) 选择输出（Spoken / Formal / Both）  
4) 点 Generate，复制或朗读结果  

## 配置

在 **Settings** 页配置：

- Provider（Gemini / DeepSeek）
- Model
- Base URL
- API Key

推荐默认值：

- DeepSeek：Base URL `https://api.deepseek.com`，model `deepseek-chat`
- Gemini：Base URL `https://generativelanguage.googleapis.com`，model `gemini-3-flash-preview`
