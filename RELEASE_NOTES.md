From.[Coder]

## MirrorPhone-Setup v0.1.0-airplay-preview

## 内容
- Windows 64-bit向けセットアップZIPを追加しました。
- 既定では `Pui-core/mirrorPhone` の `feature/issue-6-airplay-receiver` を取得します。
- インストール先は `%LOCALAPPDATA%\Programs\MirrorPhone` です。
- デスクトップ/スタートメニューに起動ショートカットを作成します。

## 使い方
1. Releaseから `MirrorPhone-Setup-v0.1.0-airplay-preview.zip` をダウンロードします。
2. ZIPを展開します。
3. `Install-MirrorPhone.bat` を実行します。

## 注意
- Node.js LTS / npm が必要です。
- AirPlayエンジン本体はこのZIPに含めず、mirrorPhone側の初回セットアップで取得します。
