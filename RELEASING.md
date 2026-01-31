# Releasing / Homebrew 自动更新（维护者）

你希望做到：**每次 push 到 GitHub（main 分支）就自动发布一个新版本，并自动更新 Homebrew cask** —— 这确实需要 GitHub Actions。

本仓库已经提供一个工作流（见 `.github/workflows/release-homebrew.yml`），它会在每次 push 到 `main` 时：

1. 在 macOS runner 上打包 `.app`
2. 生成 zip 并计算 `sha256`
3. 创建一个新的 GitHub Release（tag 形如 `v0.1.0.<run_number>`）
4. 自动更新 tap 仓库 `JNHFlow21/homebrew-thought2english` 里的 cask（更新 version / sha256 / url）

## 你需要做的唯一手动步骤：添加一个 Secret

在 GitHub → 你的 `englearn`（主仓库） → Settings → Secrets and variables → Actions：

- 新增 `HOMEBREW_TAP_TOKEN`
  - 值：一个 GitHub Personal Access Token（建议 fine-grained）
  - 权限：对 `JNHFlow21/homebrew-thought2english` 具有读写权限（Contents: Read/Write）

之后，每次你 `git push` 到 `main`，Homebrew 用户就可以：

```bash
brew upgrade --cask thought2english
```

