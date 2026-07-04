From.[Coder]

## MirrorPhone-Setup v0.2.2-airplay-embedded

## 内容
- Windows 64-bit向け `MirrorPhone-Setup.exe` にAirPlay対応済み mirrorPhone ソースZIPを埋め込みました。
- Node.js LTS / npm が無い場合は `winget` で自動インストールします。
- `npm install` 後、`setup:airplay` がある場合はAirPlay受信用エンジンを自動セットアップします。
- PowerShell版インストーラーは同梱の `mirrorPhone-source.zip` を優先します。
- 既定では `Pui-core/mirrorPhone` のAirPlay対応済み `main` をビルド時に取り込みます。
- インストール先は `%LOCALAPPDATA%\Programs\MirrorPhone` です。
- デスクトップ/スタートメニューに起動ショートカットを作成します。

## 修正
- `v0.2.1-embedded-source` がAirPlay対応前の `mirrorPhone main` を埋め込んでいたため、iPhoneの画面ミラーリング一覧に出ない問題を修正しました。
- `mirrorPhone` PR #8 merge後のAirPlay対応ソースを埋め込みました。
- AirPlay受信用エンジン準備をSetup側でも自動実行します。

## 使い方
1. Releaseから `MirrorPhone-Setup-v0.2.2-airplay-embedded.exe` をダウンロードします。
2. EXEを実行します。

## 注意
- `winget` が無い環境では、先にNode.js LTSを入れてから再実行してください。
- AirPlayエンジン本体はこのZIPに含めず、mirrorPhone側の初回セットアップで取得します。
