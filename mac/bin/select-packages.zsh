#!/bin/zsh
#
# ファイル名: select-packages.zsh
# 説明: fzfを使用したインタラクティブなパッケージ選択UI
# 依存: jq, fzf, brew-packages.json
# 実行: Makefileまたはinstall.zshから呼び出される

# Makefile経由での実行チェック
if [ -z "$SETUP_DIR" ] || [ -z "$PACKAGES_JSON" ] || [ -z "$SELECTED_PACKAGES_FILE" ]; then
    echo "Error: このスクリプトは直接実行できません。" >&2
    echo "Usage: Makefile経由で実行してください（make install-interactive）" >&2
    exit 1
fi

# 前提条件チェック
# jq, fzf, brew-packages.jsonの存在を確認
# 戻り値: 0=全て存在, 1=不足あり
check_requirements() {
    local missing=0

    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is not installed" >&2
        ((missing++))
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf is not installed" >&2
        ((missing++))
    fi

    if [ ! -f "$PACKAGES_JSON" ]; then
        echo "Error: brew-packages.json not found: $PACKAGES_JSON" >&2
        ((missing++))
    fi

    if [ $missing -gt 0 ]; then
        exit 1
    fi
}

# パッケージリストを生成
# brew-packages.jsonから全パッケージ情報を読み込み、パイプ区切り形式で出力
# 出力フォーマット: "type|name|description[|group]"
generate_package_list() {
    local list=()

    # Formula パッケージを処理
    while IFS= read -r line; do
        local name=$(echo "$line" | jq -r '.name')
        local desc=$(echo "$line" | jq -r '.description')

        # フォーマット: "type|name|description"
        list+=("formula|$name|$desc")
    done < <(jq -c '.formula.packages[]' "$PACKAGES_JSON")

    # Cask パッケージを処理（全グループを走査）
    while IFS= read -r group_name; do
        while IFS= read -r line; do
            local name=$(echo "$line" | jq -r '.name')
            local desc=$(echo "$line" | jq -r '.description')

            # フォーマット: "type|name|description|group"
            list+=("cask|$name|$desc|$group_name")
        done < <(jq -c --arg group "$group_name" '.cask.groups[$group][]' "$PACKAGES_JSON")
    done < <(jq -r '.cask.groups | keys[]' "$PACKAGES_JSON")

    printf '%s\n' "${list[@]}"
}

# fzf用の表示フォーマットを生成
# パイプ区切りのパッケージリストを人間が読みやすい形式に整形
# 入力フォーマット: "type|name|description[|group]"
# 出力フォーマット: "name (type/group) description\ttype|name"
format_for_display() {
    while IFS='|' read -r type name desc group; do
        local type_label="$type"
        [ -n "$group" ] && type_label="$type/$group"

        # 表示フォーマット: "name (type/group) - description"
        # データ部分: "type|name" (選択後に使用)
        printf "%-40s %-20s %s\t%s|%s\n" "$name" "($type_label)" "$desc" "$type" "$name"
    done
}

# fzfで選択されたパッケージを処理
# 選択結果を "type:name" 形式でファイルに保存
# 引数: なし（標準入力からfzfの出力を受け取る）
process_selection() {
    local selected=("${(@f)$(cat)}")

    # 空の配列、または空文字列のみの配列をチェック
    if [ ${#selected[@]} -eq 0 ] || [ -z "${selected[1]}" ]; then
        echo "パッケージが選択されていません。処理を中断します。" >&2
        exit 0
    fi

    # 選択されたパッケージ名を抽出して保存
    for line in "${selected[@]}"; do
        # タブ区切りで分割し、後半部分（type|name）を取得
        local data=$(echo "$line" | cut -f2)
        local type=$(echo "$data" | cut -d'|' -f1)
        local name=$(echo "$data" | cut -d'|' -f2)

        echo "$type:$name"
    done > "$SELECTED_PACKAGES_FILE"

    echo "Selected ${#selected[@]} package(s) saved to: $SELECTED_PACKAGES_FILE" >&2
}

# メイン処理
# 前提条件チェック後、fzfで選択UIを表示し、結果をファイルに保存
main() {
    check_requirements

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "📦 Interactive Package Selection" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2

    # パッケージリストを生成してfzfに渡す
    generate_package_list | format_for_display | \
        fzf --multi \
            --ansi \
            --layout=reverse \
            --bind='space:toggle' \
            --bind='ctrl-a:toggle-all' \
            --marker='✓ ' \
            --color='marker:green' \
            --header="SPACE: select/deselect | Ctrl-A: toggle all | ENTER: select and confirm" \
            --prompt="Packages > " \
            --with-nth=1 \
            --delimiter="\t" \
            --preview='echo {1}' \
            --preview-window=hidden \
            --height=80% \
            --border \
            --cycle | \
        process_selection

    # fzf終了後に画面をクリア
    clear
}

# スクリプト実行
main
