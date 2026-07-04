# MirrorPhone-Setup

mirrorPhone の Windows 64-bit 向けセットアップ配布リポジトリです。

このリポジトリの Release から `MirrorPhone-Setup-*.zip` をダウンロードし、
展開後に `Install-MirrorPhone.bat` を実行すると mirrorPhone を
`%LOCALAPPDATA%\Programs\MirrorPhone` へインストールします。

## 配布内容

- `Install-MirrorPhone.bat`
- `Install-MirrorPhone.ps1`
- `Uninstall-MirrorPhone.ps1`
- `README.md`

## インストール内容

- 64-bit Windows であることを確認
- Node.js / npm の存在を確認
- `Pui-core/mirrorPhone` のソースZIPを取得
- `%LOCALAPPDATA%\Programs\MirrorPhone` に展開
- `npm install` を実行
- デスクトップとスタートメニューに `mirrorPhone` ショートカットを作成

## 既定の取得元

既定では AirPlay 対応プレビューのブランチを取得します。

```text
Pui-core/mirrorPhone
feature/issue-6-airplay-receiver
```

main を入れたい場合は PowerShell から次のように実行してください。

```powershell
.\Install-MirrorPhone.ps1 -SourceRef main
```

## 必要条件

- Windows 10 / 11 64-bit
- Node.js LTS
- npm
- インターネット接続

Node.js が無い場合は先に Node.js LTS を入れてから再実行してください。

## アンインストール

展開したZIP内、またはインストール後に次を実行します。

```powershell
.\Uninstall-MirrorPhone.ps1
```

## 注意

- インストール先に `.mirrorphone-install` マーカーが無い既存フォルダがある場合は上書きしません。
- UxPlay / AirPlay エンジンなどの大きい実行ファイルは、このセットアップZIPには含めません。
  mirrorPhone本体の初回起動/セットアップ処理で取得します。
