From.[Coder]

## MirrorPhone-Setup v0.2.4-electron-prepare

## 内容
- Windows 64-bit向け `MirrorPhone-Setup.exe` にAirPlay対応済み mirrorPhone ソースZIPを埋め込みました。
- Node.js LTS / npm が無い場合は `winget` で自動インストールします。
- 既存の `%LOCALAPPDATA%\Programs\MirrorPhone` はエラーにせず、更新対象として扱います。
- 既存更新時は `vendor` を残し、`node_modules/electron` はWindows用バイナリを確実に準備するため再構築します。
- `npm install` 後、Windows用 `electron.exe` が無い場合はSetup中にElectron install scriptを実行します。
- `npm install` 後、`setup:airplay` がある場合はAirPlay受信用エンジンを自動セットアップします。
- PowerShell版インストーラーは同梱の `mirrorPhone-source.zip` を優先します。
- 既定では `Pui-core/mirrorPhone` のAirPlay対応済み `main` をビルド時に取り込みます。
- インストール先は `%LOCALAPPDATA%\Programs\MirrorPhone` です。
- デスクトップ/スタートメニューに起動ショートカットを作成します。

## 修正
- 起動時に `Preparing Windows Electron binary...` の後、`Electron binary download failed.` で止まる問題に対処しました。
- 更新時に不完全な `node_modules/electron` を残さず、Setup中にWindows用Electronを準備するようにしました。

## 使い方
1. Releaseから `MirrorPhone-Setup-v0.2.4-electron-prepare.exe` をダウンロードします。
2. EXEを実行します。

## 注意
- `winget` が無い環境では、先にNode.js LTSを入れてから再実行してください。
- AirPlayエンジン本体はこのZIPに含めず、mirrorPhone側の初回セットアップで取得します。
