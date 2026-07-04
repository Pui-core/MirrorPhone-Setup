# MirrorPhone-Setup

mirrorPhone の Windows 64-bit 向けセットアップ配布リポジトリです。

このリポジトリの Release から `MirrorPhone-Setup-v0.2.0-exe-bootstrapper.exe`
をダウンロードして実行すると、mirrorPhone を
`%LOCALAPPDATA%\Programs\MirrorPhone` へインストールします。

## 推奨

```text
MirrorPhone-Setup-v0.2.0-exe-bootstrapper.exe
```

EXE版は Node.js LTS / npm が無い場合、`winget` で自動インストールします。

## ZIP版の配布内容

- `Install-MirrorPhone.bat`
- `Install-MirrorPhone.ps1`
- `Uninstall-MirrorPhone.ps1`
- `README.md`
- `VERSION`

## インストール内容

- 64-bit Windows であることを確認
- Node.js / npm の存在を確認し、不足時は `winget` で Node.js LTS を導入
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

main を入れたい場合はZIP版を展開し、PowerShellから次のように実行してください。

```powershell
.\Install-MirrorPhone.ps1 -SourceRef main
```

## 必要条件

- Windows 10 / 11 64-bit
- インターネット接続
- `winget`

Node.js LTS / npm はEXEが自動導入します。`winget` が無い古いWindows環境では、
先に Node.js LTS を入れてから再実行してください。

## アンインストール

展開したZIP内、またはインストール後に次を実行します。

```powershell
.\Uninstall-MirrorPhone.ps1
```

## 注意

- インストール先に `.mirrorphone-install` マーカーが無い既存フォルダがある場合は上書きしません。
- UxPlay / AirPlay エンジンなどの大きい実行ファイルは、このセットアップ配布物には含めません。
  mirrorPhone本体の初回起動/セットアップ処理で取得します。
