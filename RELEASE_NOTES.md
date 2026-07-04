From.[Coder]

## MirrorPhone-Setup v0.2.0-exe-bootstrapper

## 内容
- Windows 64-bit向け `MirrorPhone-Setup.exe` を追加しました。
- Node.js LTS / npm が無い場合は `winget` で自動インストールします。
- PowerShell版インストーラーにもNode.js自動導入を追加しました。
- 既定では `Pui-core/mirrorPhone` の `feature/issue-6-airplay-receiver` を取得します。
- インストール先は `%LOCALAPPDATA%\Programs\MirrorPhone` です。
- デスクトップ/スタートメニューに起動ショートカットを作成します。

## 使い方
1. Releaseから `MirrorPhone-Setup-v0.2.0-exe-bootstrapper.exe` をダウンロードします。
2. EXEを実行します。

## 注意
- `winget` が無い環境では、先にNode.js LTSを入れてから再実行してください。
- AirPlayエンジン本体はこのZIPに含めず、mirrorPhone側の初回セットアップで取得します。
