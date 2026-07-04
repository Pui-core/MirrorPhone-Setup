# MirrorPhone-Setup

mirrorPhone の Windows 64-bit 向けセットアップ配布リポジトリです。

このリポジトリの Release から `MirrorPhone-Setup-v0.2.1-embedded-source.exe`
をダウンロードして実行すると、mirrorPhone を
`%LOCALAPPDATA%\Programs\MirrorPhone` へインストールします。

## 推奨

```text
MirrorPhone-Setup-v0.2.1-embedded-source.exe
```

EXE版は Node.js LTS / npm が無い場合、`winget` で自動インストールします。
mirrorPhone本体のソースはEXE内に同梱しているため、インストール時のGitHubアクセスは不要です。

## ZIP版の配布内容

- `MirrorPhone-Setup-v0.2.1-embedded-source.exe`
- `mirrorPhone-source.zip`
- `Install-MirrorPhone.bat`
- `Install-MirrorPhone.ps1`
- `Uninstall-MirrorPhone.ps1`
- `README.md`
- `VERSION`

## インストール内容

- 64-bit Windows であることを確認
- Node.js / npm の存在を確認し、不足時は `winget` で Node.js LTS を導入
- EXEに埋め込まれた `Pui-core/mirrorPhone` のソースZIPを展開
- `%LOCALAPPDATA%\Programs\MirrorPhone` に展開
- `npm install` を実行
- デスクトップとスタートメニューに `mirrorPhone` ショートカットを作成

## 既定の取得元

既定では `Pui-core/mirrorPhone` の `main` をビルド時に取り込み、EXEへ埋め込みます。

```text
Pui-core/mirrorPhone
main
```

ZIP版を展開してPowerShell版を使う場合は、同梱の `mirrorPhone-source.zip` を優先します。
別のソースZIPを指定する場合は次のように実行してください。

```powershell
.\Install-MirrorPhone.ps1 -SourceZipPath .\mirrorPhone-source.zip
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
- `Pui-core/mirrorPhone` はpublic repositoryですが、EXE版は安定性のためインストール時にGitHubから直接取得しません。
- UxPlay / AirPlay エンジンなどの大きい実行ファイルは、このセットアップ配布物には含めません。
  mirrorPhone本体の初回起動/セットアップ処理で取得します。
