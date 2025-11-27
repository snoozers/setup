# 開発環境セットアップ

<img width="2000" alt="logo" src="https://user-images.githubusercontent.com/49787185/128835360-5d75746a-a123-49bb-bcb2-5c77a61821e0.png">

## 概要

macOS用の開発環境セットアップ自動化スクリプトです。

## 使い方

### 初回セットアップ

```bash
cd ~/setup/mac
```

```bash
make install
```

### インストール前の確認（Dry-run）

```bash
make dry-run
```

### インタラクティブインストール

fzfを使用してインストールするパッケージを対話的に選択できます：

```bash
make install-interactive
```

**使い方:**
- `↑`/`↓` キーで移動
- `SPACE` キーで選択/選択解除
- `Ctrl-A` キーで表示中の全アイテムをトグル
- `ENTER` キーで確定

### カテゴリ別インストール

```bash
# Homebrew Formulaのみインストール
make install-formula

# Homebrew Caskのみインストール
make install-cask
```

### パッケージの追加・削除

`mac/brew-packages.json` を編集してください。

詳細な構造については [brew-packages.json の構造](#brew-packagesjson-の構造) を参照してください。

### テスト実行

```bash
make test
```

### ログの確認

```bash
# 最新のログ内容を表示
make show-install-logs

# エラーログの内容を表示
make show-error-logs

# ログファイルのクリーンアップ
make clean-logs
```

### Homebrewの更新

```bash
make update
```

## ディレクトリ構造

```
mac/
├── Makefile                # メインのビルドファイル
├── brew-packages.json      # インストールするパッケージの定義
├── bin/                    # 実行スクリプト
│   ├── install.zsh         # インストールスクリプト
│   ├── select-packages.zsh # パッケージ選択スクリプト
│   ├── update.zsh          # 更新スクリプト
│   ├── test.zsh            # テストスクリプト
│   ├── func.zsh            # 共通関数ライブラリ
│   └── logo.zsh            # ロゴ表示スクリプト
├── logs/                   # ログファイル
└── iterm2/                 # iTerm2設定ファイル
```

## brew-packages.json の構造

brew-packages.json は以下の構造になっています：

```json
{
  "formula": {
    "description": "Command-line tools and utilities",
    "packages": [
      {
        "name": "パッケージ名",
        "description": "説明"
      }
    ]
  },
  "cask": {
    "description": "GUI applications",
    "groups": {
      "development": [...],
      "browsers": [...],
      "communication": [...],
      "utilities": [...],
      "productivity": [...]
    }
  }
}
```

### パッケージの追加方法

**Formula の追加:**

```json
{
  "name": "新しいパッケージ",
  "description": "パッケージの説明"
}
```

**Cask の追加:**

```json
{
  "name": "新しいアプリ",
  "description": "アプリの説明",
  "options": ["--オプション"]  // オプション（省略可能）
}
```

### カテゴリ

Cask は以下のカテゴリに分類されています：

**development** - 開発ツール
- Docker: コンテナプラットフォーム
- Visual Studio Code: コードエディタ
- iTerm2: ターミナルエミュレータ
- Postman: API開発プラットフォーム
- DBeaver: データベース管理ツール
- Stoplight Studio: API設計ツール
- Claude Code: AI駆動コーディングアシスタント

**browsers** - Webブラウザ
- Google Chrome
- Firefox

**communication** - コミュニケーションツール
- Slack: チームコミュニケーション
- Zoom: ビデオ会議

**utilities** - ユーティリティ
- xbar: メニューバーカスタマイズ
- Rectangle: ウィンドウ管理
- Stats: システムモニター
- Clipy: クリップボードマネージャー
- Alt-Tab: Windowsスタイルのウィンドウスイッチャー
- VoiceInk: 音声書き起こしユーティリティ

**productivity** - 生産性ツール
- Notion: オールインワンワークスペース

### 主要なコマンドラインツール (Formula)

- **bash**: Bourne-Again SHell
- **trash**: ゴミ箱へ移動するCLIツール
- **jq**: JSONプロセッサー（前提条件）
- **tig**: Git リポジトリ用テキストインターフェース
- **bat**: シンタックスハイライト付きcatクローン
- **vim**: 高機能テキストエディタ
- **fzf**: コマンドラインファジーファインダー
- **xcbeautify**: Xcodeビルド出力フォーマッター
- **ripgrep**: 高速検索ツール (rg)

## 必要要件

### システム要件
- macOS 10.15以降
- インターネット接続
- 管理者権限

### 前提条件

このスクリプトを実行する前に、以下をインストールしておく必要があります：

**必須:**
- [Homebrew](https://brew.sh/): macOSのパッケージマネージャー
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- [jq](https://stedolan.github.io/jq/): コマンドラインJSONプロセッサー
  ```bash
  brew install jq
  ```

**インタラクティブモード使用時のみ:**
- [fzf](https://github.com/junegunn/fzf): ファジーファインダー
  ```bash
  brew install fzf
  ```

## ライセンス

MIT License
