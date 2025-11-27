#!/bin/zsh
#
# ファイル名: func.zsh
# 説明: セットアップスクリプト用の共有関数ライブラリ
# 依存: なし
# 実行: 他のスクリプトから source される

# コマンドの存在確認
# 引数: コマンド名
# 戻り値: 0=存在する, 1=存在しない
is_exists() {
    which "$1" >/dev/null 2>&1
    return $?
}

# エラーメッセージを標準エラー出力に表示
# 引数: メッセージ
e_error() {
    printf " \033[31m%s\033[m\n" "✖ $*" 1>&2
}

# 警告メッセージを標準出力に表示
# 引数: メッセージ
e_warning() {
    printf " \033[31m%s\033[m\n" "✖ $*"
}

# 成功メッセージを表示
# 引数: メッセージ
e_success() {
    printf " \033[37;1m%s\033[m%s...\033[32mOK\033[m\n" "✔ " "$*"
}

# カラー付きテキストを出力
# 引数1: テキスト、または引数2がある場合は色名
# 引数2: テキスト（オプション）
# 色: black, red, green, yellow, blue, purple, cyan, gray, white
ink() {
    if [ "$#" -eq 0 -o "$#" -gt 2 ]; then
        echo "Usage: ink <color> <text>"
        echo "Colors:"
        echo "  black, white, red, green, yellow, blue, purple, cyan, gray"
        return 1
    fi

    local open="\033["
    local close="${open}0m"
    local black="0;30m"
    local red="1;31m"
    local green="1;32m"
    local yellow="1;33m"
    local blue="1;34m"
    local purple="1;35m"
    local cyan="1;36m"
    local gray="0;37m"
    local white="$close"

    local text="$1"
    local color="$close"

    if [ "$#" -eq 2 ]; then
        text="$2"
        case "$1" in
            black | red | green | yellow | blue | purple | cyan | gray | white)
            eval color="\$$1"
            ;;
        esac
    fi

    printf "${open}${color}${text}${close}"
}

# タイムスタンプ付きログメッセージを出力
# 引数1: フォーマット (TITLE, ERROR, WARN, INFO, SUCCESS)
# 引数2: メッセージ
logging() {
    if [ "$#" -eq 0 -o "$#" -gt 2 ]; then
        echo "Usage: ink <fmt> <msg>"
        echo "Formatting Options:"
        echo "  TITLE, ERROR, WARN, INFO, SUCCESS"
        return 1
    fi

    local color=
    local text="$2"

    case "$1" in
        TITLE)
            color=yellow
            ;;
        ERROR | WARN)
            color=red
            ;;
        INFO)
            color=blue
            ;;
        SUCCESS)
            color=green
            ;;
        *)
            text="$1"
    esac

    timestamp() {
        ink gray "["
        ink purple "$(date +%H:%M:%S)"
        ink gray "] "
    }

    timestamp; ink "$color" "$text"; echo
}

# 成功メッセージをログ形式で出力
# 引数: メッセージ
log_pass() {
    logging SUCCESS "$1"
}

# 警告メッセージをログ形式で出力
# 引数: メッセージ
log_warn() {
    logging WARN "$1"
}

# タイトルメッセージをログ形式で出力
# 引数: メッセージ
log_echo() {
    logging TITLE "$1"
}

# 処理待機中メッセージを表示（上書き表示用）
# 引数: メッセージ
e_process_waiting() {
    local waiting_text=$(log_echo $1...)
    printf "\r%${#waiting_text}s" "$waiting_text"
}

# 処理完了メッセージを表示（待機メッセージを上書き）
# 引数: メッセージ
e_process_done() {
    local waiting_text=$(log_echo $1...)
    printf "\r%-${#waiting_text}s\n" "$(log_pass "$(e_success "$1")")"
}

# 処理失敗メッセージを表示（待機メッセージを上書き）
# 引数: メッセージ
e_process_fail() {
    local waiting_text=$(log_echo $1...)
    printf "\r%-${#waiting_text}s\n" "$(log_warn "$(e_warning "$1")")"
}

# エラーメッセージを表示してスクリプトを終了
# 引数1: エラーメッセージ
# 引数2: 終了コード（オプション、デフォルト: 1）
die() {
    e_error "$1" 1>&2
    exit "${2:-1}"
}

# コマンドの存在確認（is_existsのエイリアス）
# 引数: コマンド名
# 戻り値: 0=存在する, 1=存在しない
has() {
    is_exists "$@"
}

# プログレスバー表示
# 引数1: 現在の進捗
# 引数2: 総数
# 引数3: ラベル
# 使用例: show_progress 5 10 "Installing packages"
show_progress() {
    local current=$1
    local total=$2
    local label=$3
    local percentage=$((current * 100 / total))
    local filled=$((current * 50 / total))
    local empty=$((50 - filled))

    # プログレスバー構築
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    # 出力 (上書き表示)
    printf "\r[%s] %3d%% (%d/%d) %s" "$bar" "$percentage" "$current" "$total" "$label"

    # 完了時は改行
    if [ "$current" -eq "$total" ]; then
        printf "\n"
    fi
}

# インストール結果サマリーを表示
# 引数1: 成功数
# 引数2: 失敗数
# 引数3: スキップ数
show_summary() {
    local success=$1
    local failed=$2
    local skipped=$3

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ink yellow "📊 Installation Summary"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ink green  "  ✅ Success: $success"
    echo ""
    ink red    "  ❌ Failed:  $failed"
    echo ""
    ink blue   "  ⏭  Skipped: $skipped"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ロゴを表示
logo() {
    zsh $SETUP_DIR/bin/logo.zsh
}
