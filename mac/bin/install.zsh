#!/bin/zsh
#
# ファイル名: install.zsh
# 説明: Homebrew経由で開発ツール・アプリケーションをインストール
# 依存: func.zsh, brew-packages.json
# 実行: make install

# Makefileから実行されているかチェック
if [ -z "$SETUP_DIR" ] || [ -z "$INSTALL_LOG_FILE" ] || [ -z "$ERROR_LOG_FILE" ]; then
    echo "Error: このスクリプトは直接実行できません。"
    echo "Usage: make install"
    exit 1
fi

# Makefileから環境変数として受け取る
# SETUP_DIR, INSTALL_LOG_FILE, ERROR_LOG_FILE, PACKAGES_JSON
# DRY_RUN, SKIP_UPDATE, CATEGORY, INTERACTIVE

source "$SETUP_DIR/bin/func.zsh"

# カウンター
declare -i SUCCESS_COUNT=0
declare -i FAILED_COUNT=0
declare -i SKIPPED_COUNT=0

# 処理開始メッセージを表示
# 引数: メッセージ
start() {
    e_process_waiting "$1"
}

# ログファイルに日時付きメッセージを追記
# 引数: メッセージ
log_to_file() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$INSTALL_LOG_FILE"
}

# パッケージが選択されているかチェック
# インタラクティブモードの場合は選択ファイル、非インタラクティブモードの場合は全てインストール
# 引数1: タイプ (formula or cask)
# 引数2: パッケージ名
# 戻り値: 0=選択されている, 1=選択されていない
is_package_selected() {
    local type=$1
    local name=$2

    # インタラクティブモードの場合、選択ファイルをチェック
    if [ "$INTERACTIVE" = true ]; then
        if [ ! -f "$SELECTED_PACKAGES_FILE" ]; then
            return 1
        fi
        grep -q "^${type}:${name}$" "$SELECTED_PACKAGES_FILE"
        return $?
    fi

    # 非インタラクティブモードの場合、全てのパッケージを選択
    return 0
}

# 必須コマンドの存在確認
# Homebrew, jq, fzf（インタラクティブモード時のみ）の存在をチェック
# 戻り値: 0=全て存在, 1=不足あり（処理を中断）
check_requirements() {
    local missing=0

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Checking Requirements"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Homebrewのチェック
    if ! has "brew"; then
        e_error "Homebrew is not installed"
        echo "  Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        ((missing++))
    else
        e_success "Homebrew"
    fi

    # jqのチェック
    if ! has "jq"; then
        e_error "jq is not installed"
        echo "  Please install jq first:"
        echo "  brew install jq"
        ((missing++))
    else
        e_success "jq"
    fi

    # fzfのチェック（インタラクティブモード時のみ必須）
    if [ "$INTERACTIVE" = true ]; then
        if ! has "fzf"; then
            e_error "fzf is not installed (required for interactive mode)"
            echo "  Please install fzf first:"
            echo "  brew install fzf"
            ((missing++))
        else
            e_success "fzf"
        fi
    fi

    # brew-packages.jsonの存在チェック
    if [ ! -f "$PACKAGES_JSON" ]; then
        e_error "brew-packages.json not found: $PACKAGES_JSON"
        ((missing++))
    else
        e_success "brew-packages.json"
    fi

    echo ""

    if [ $missing -gt 0 ]; then
        die "Missing requirements. Please fix the issues above." 1
    fi
}

# 処理完了状態を記録してメッセージを表示
# 引数1: 終了ステータス (0=成功, それ以外=失敗)
# 引数2: ラベル
finish() {
    local exit_status=$1
    local label=$2
    if [ $exit_status -eq 0 ]; then
        e_process_done "$label"
        ((SUCCESS_COUNT++))
    else
        e_process_fail "$label"
        ((FAILED_COUNT++))
        # エラーログに追記
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $label (exit code: $exit_status)" >> "$ERROR_LOG_FILE"
    fi
}

# Homebrew Formulaのインストール
# brew-packages.jsonからformulaパッケージを読み込み、選択されているものをインストール
install_formula() {
    if [ "$SKIP_UPDATE" = false ]; then
        start '[brew] HomeBrewアップデート'
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] Would run: brew update"
            e_process_done '[brew] HomeBrewアップデート'
        else
            brew update > /dev/null 2>&1
            local exit_code=$?
            if [ $exit_code -eq 0 ]; then
                e_process_done '[brew] HomeBrewアップデート'
            else
                e_process_fail '[brew] HomeBrewアップデート'
                # エラーログに追記
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: [brew] HomeBrewアップデート (exit code: $exit_code)" >> "$ERROR_LOG_FILE"
            fi
        fi
    fi

    jq -r '.formula.packages[].name' "$PACKAGES_JSON" | while read -r pkg; do
        # パッケージが選択されているかチェック
        if ! is_package_selected "formula" "$pkg"; then
            log_to_file "Skipped (not selected): $pkg"
            continue
        fi

        start "[brew] $pkg"
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY-RUN] Would install: $pkg"
            e_process_done "[brew] $pkg"
            ((SUCCESS_COUNT++))
        else
            if ! brew list --formula | grep -q "^${pkg}\$"; then
                brew install "$pkg" > /dev/null 2>&1
                finish $? "[brew] $pkg"
            else
                log_to_file "Already installed: $pkg"
                ((SKIPPED_COUNT++))
                e_process_done "[brew] $pkg"
            fi
        fi
    done
}

# Homebrew Caskのインストール
# brew-packages.jsonからcaskパッケージを読み込み、選択されているものをインストール
install_cask() {
    jq -c '.cask.groups[] | .[]' "$PACKAGES_JSON" | while read -r item; do
        local pkg=$(echo "$item" | jq -r '.name')
        local options=$(echo "$item" | jq -r '.options // [] | join(" ")')
        local display_name=$(echo "$pkg" | sed 's/google-chrome/chrome/; s/visual-studio-code/vscode/')

        # パッケージが選択されているかチェック
        if ! is_package_selected "cask" "$pkg"; then
            log_to_file "Skipped (not selected): $pkg"
            continue
        fi

        start "[brew cask] $display_name"
        if [ "$DRY_RUN" = true ]; then
            if [ -n "$options" ]; then
                echo "[DRY-RUN] Would install: $pkg $options"
            else
                echo "[DRY-RUN] Would install: $pkg"
            fi
            e_process_done "[brew cask] $display_name"
            ((SUCCESS_COUNT++))
        else
            if ! brew list --cask | grep -q "^${pkg}\$"; then
                if [ -n "$options" ]; then
                    brew install --cask "$pkg" $options > /dev/null 2>&1
                else
                    brew install --cask "$pkg" > /dev/null 2>&1
                fi
                finish $? "[brew cask] $display_name"
            else
                log_to_file "Already installed: $pkg"
                ((SKIPPED_COUNT++))
                e_process_done "[brew cask] $display_name"
            fi
        fi
    done
}

# メイン処理
# ログ初期化、前提条件チェック、パッケージインストールを実行
main() {
    # ログディレクトリの作成（存在しない場合）
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
    fi

    # ログファイルの初期化
    echo "Installation started at $(date)" > "$INSTALL_LOG_FILE"
    log_to_file "SETUP_DIR: $SETUP_DIR"
    log_to_file "PACKAGES_JSON: $PACKAGES_JSON"
    log_to_file "DRY_RUN: $DRY_RUN"
    log_to_file "SKIP_UPDATE: $SKIP_UPDATE"
    log_to_file "CATEGORY: $CATEGORY"
    log_to_file "INTERACTIVE: $INTERACTIVE"
    log_to_file "INSTALL_LOG_FILE: $INSTALL_LOG_FILE"

    check_requirements

    # インタラクティブモードの場合、パッケージ選択UIを表示
    if [ "$INTERACTIVE" = true ]; then
        "$SETUP_DIR/bin/select-packages.zsh"
        if [ $? -ne 0 ] || [ ! -f "$SELECTED_PACKAGES_FILE" ]; then
            die "Package selection cancelled or failed." 1
        fi
        log_to_file "Selected packages file: $SELECTED_PACKAGES_FILE"

        # 選択ファイルが空かチェック
        if [ ! -s "$SELECTED_PACKAGES_FILE" ]; then
            echo "パッケージが選択されていません。インストールを中断します。"
            exit 0
        fi

        # 選択されたパッケージ数をカウント（空行を除外）
        local selected_count=$(grep -c . "$SELECTED_PACKAGES_FILE" 2>/dev/null || echo 0)

        # 確認メッセージを表示
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        printf " 📋 選択されたパッケージ: "
        ink cyan "${selected_count}件"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # パッケージ名のリストを表示
        local -i formula_count=$(grep -c "^formula:" "$SELECTED_PACKAGES_FILE" 2>/dev/null | tr -d '\n' || echo 0)
        local -i cask_count=$(grep -c "^cask:" "$SELECTED_PACKAGES_FILE" 2>/dev/null | tr -d '\n' || echo 0)

        if [ $formula_count -gt 0 ]; then
            printf " 🍺 "
            ink cyan "Formula"
            printf " "
            ink cyan "($formula_count)"
            echo ""
            grep "^formula:" "$SELECTED_PACKAGES_FILE" | sed 's/^formula://' | while read -r pkg; do
                printf "    ├─ "
                ink purple "$pkg"
                echo ""
            done
            echo ""
        fi

        if [ $cask_count -gt 0 ]; then
            printf " 📦 "
            ink cyan "Cask"
            printf " "
            ink cyan "($cask_count)"
            echo ""
            grep "^cask:" "$SELECTED_PACKAGES_FILE" | sed 's/^cask://' | while read -r pkg; do
                printf "    ├─ "
                ink purple "$pkg"
                echo ""
            done
            echo ""
        fi

        if [ $formula_count -eq 0 ] && [ $cask_count -eq 0 ]; then
            ink red "パッケージが選択されていません"
            echo ""
        fi

        echo -n "インストールを続行しますか? (y/N): "
        read -k 1 answer
        echo ""  # 改行を追加

        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            echo "インストールを中断しました。"
            exit 0
        fi
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 Dry-run Mode - Installation Preview"
    else
        echo "🚀 Starting Installation"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # カテゴリに応じてインストール
    if [ -z "$CATEGORY" ] || [ "$CATEGORY" = "formula" ]; then
        install_formula
        echo ""
    fi

    if [ -z "$CATEGORY" ] || [ "$CATEGORY" = "cask" ]; then
        install_cask
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 Installation Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  ✅ Success: $SUCCESS_COUNT"
    echo "  ❌ Failed:  $FAILED_COUNT"
    echo "  ⏭  Skipped: $SKIPPED_COUNT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# メイン処理の実行
main
