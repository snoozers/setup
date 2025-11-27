#!/bin/zsh
#
# ファイル名: update.zsh
# 説明: Homebrewパッケージの更新処理（プログレスバーとサマリー表示付き）
# 依存: brew, func.zsh
# 実行: make update から呼び出される

set -e

# 共通関数を読み込み
source "${SETUP_DIR}/bin/func.zsh"

# Makefileから実行されているかチェック
if [ -z "$UPDATE_LOG_FILE" ]; then
    echo "Error: このスクリプトは直接実行できません。"
    echo "Usage: make update"
    exit 1
fi

# メイン処理
main() {
    echo ""
    logging INFO "Homebrewパッケージの更新を開始します"
    echo ""

    # ステップカウンター
    local step=0
    local total_steps=6

    # Homebrewのアップデート
    step=$((step + 1))
    show_progress $step $total_steps "Homebrewのアップデート"
    logging INFO "Homebrewのアップデート中..."
    brew update 2>&1 | tee -a "${UPDATE_LOG_FILE}" | grep -v "^$" | tail -3
    echo ""

    # 更新可能なパッケージの確認
    step=$((step + 1))
    show_progress $step $total_steps "更新可能なパッケージの確認"
    logging INFO "更新可能なパッケージを確認中..."

    # outdatedの結果を取得
    local outdated_output=$(brew outdated --greedy 2>&1)
    local outdated_count=$(echo "$outdated_output" | grep -v "^$" | wc -l | tr -d ' ')

    if [ "$outdated_count" -eq 0 ]; then
        logging SUCCESS "すべてのパッケージは最新です"
        echo ""
        show_summary 0 0 0
        return 0
    fi

    echo ""
    echo "$outdated_output" | tee -a "${UPDATE_LOG_FILE}"
    echo ""

    # カテゴリごとの集計
    local formula_count=0
    local cask_count=0

    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi

        # caskかformulaかを判定（brew outdatedの出力形式に基づく）
        if echo "$line" | grep -q " (auto-update)"; then
            cask_count=$((cask_count + 1))
        else
            formula_count=$((formula_count + 1))
        fi
    done <<< "$outdated_output"

    # カテゴリごとの統計表示
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ink cyan "📊 更新可能なパッケージの統計"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    ink blue "  📦 Formula: $formula_count パッケージ"
    echo ""
    ink purple "  🖥️  Cask:    $cask_count パッケージ"
    echo ""
    ink yellow "  📊 合計:    $outdated_count パッケージ"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # パッケージのアップグレード
    step=$((step + 1))
    show_progress $step $total_steps "パッケージのアップグレード"
    logging INFO "パッケージをアップグレード中..."
    echo ""

    # アップグレード実行（--greedyでauto-update付きcaskも更新）
    local upgrade_success=0
    local upgrade_failed=0

    if brew upgrade --greedy 2>&1 | tee -a "${UPDATE_LOG_FILE}"; then
        upgrade_success=$outdated_count
        logging SUCCESS "パッケージのアップグレードが完了しました"
    else
        upgrade_failed=$outdated_count
        logging ERROR "パッケージのアップグレード中にエラーが発生しました"
    fi
    echo ""

    # 古いバージョンの確認
    step=$((step + 1))
    show_progress $step $total_steps "古いバージョンの確認"
    logging INFO "削除可能な古いバージョンを確認中..."

    local cleanup_list=$(brew cleanup -n 2>&1)
    local cleanup_count=$(echo "$cleanup_list" | grep "Would remove:" | wc -l | tr -d ' ')

    if [ "$cleanup_count" -gt 0 ]; then
        echo ""
        echo "$cleanup_list" | tee -a "${UPDATE_LOG_FILE}"
    else
        logging SUCCESS "削除可能な古いバージョンはありません"
    fi
    echo ""

    # 古いバージョンの削除
    step=$((step + 1))
    show_progress $step $total_steps "古いバージョンの削除"

    if [ "$cleanup_count" -gt 0 ]; then
        logging INFO "古いバージョンを削除中..."
        brew cleanup 2>&1 | tee -a "${UPDATE_LOG_FILE}" | tail -5
        logging SUCCESS "${cleanup_count}個の古いバージョンを削除しました"
    else
        logging INFO "削除する古いバージョンはありません"
    fi
    echo ""

    # ヘルスチェック
    step=$((step + 1))
    show_progress $step $total_steps "ヘルスチェック"
    logging INFO "Homebrewのヘルスチェック中..."
    echo ""

    if brew doctor 2>&1 | tee -a "${UPDATE_LOG_FILE}" | grep -q "Your system is ready to brew"; then
        logging SUCCESS "Homebrewは正常な状態です"
    else
        logging WARN "いくつかの警告があります（詳細はログを確認してください）"
    fi
    echo ""

    # 最終サマリー
    show_summary $upgrade_success $upgrade_failed 0

    echo ""
    logging SUCCESS "更新処理が完了しました"
    logging INFO "ログファイル: ${UPDATE_LOG_FILE}"
    echo ""
}

# メイン処理実行
main "$@"
