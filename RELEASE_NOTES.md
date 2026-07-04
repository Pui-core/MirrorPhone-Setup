From.[Coder]

## MirrorPhone-Setup v0.2.1-embedded-source

## 内容
- Windows 64-bit向け `MirrorPhone-Setup.exe` に mirrorPhone ソースZIPを埋め込みました。
- Node.js LTS / npm が無い場合は `winget` で自動インストールします。
- PowerShell版インストーラーは同梱の `mirrorPhone-source.zip` を優先します。
- 既定では `Pui-core/mirrorPhone` の `main` をビルド時に取り込みます。
- インストール先は `%LOCALAPPDATA%\Programs\MirrorPhone` です。
- デスクトップ/スタートメニューに起動ショートカットを作成します。

## 修正
- 以前private repositoryだったGitHub archiveを実行時に未認証取得していたため、EXE実行時に404で停止する問題を修正しました。
- `Pui-core/mirrorPhone` をpublic化しつつ、EXE版は安定性のためソース同梱方式にしました。
- GitHub zipballの展開ディレクトリ名が `mirrorPhone-*` 以外でも検出できるようにしました。

## 使い方
1. Releaseから `MirrorPhone-Setup-v0.2.1-embedded-source.exe` をダウンロードします。
2. EXEを実行します。

## 注意
- `winget` が無い環境では、先にNode.js LTSを入れてから再実行してください。
- AirPlayエンジン本体はこのZIPに含めず、mirrorPhone側の初回セットアップで取得します。
