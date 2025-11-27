#!/bin/zsh
#
# ファイル名: test.zsh
# 説明: インストール済みコマンドの実行可否をチェック
# 依存: func.zsh, brew-packages.json
# 実行: make test

# Makefile経由での実行チェック
if [ -z "$SETUP_DIR" ] || [ -z "$PACKAGES_JSON" ]; then
    echo "Error: このスクリプトは直接実行できません。"
    echo "Usage: make test"
    exit 1
fi

# func.zsh を明示的に読み込む
source "$SETUP_DIR/bin/func.zsh"

# カウンター
SUCCESS=0
FAILED=0

# brew-packages.jsonが存在しない場合のエラー
if [ ! -f "$PACKAGES_JSON" ]; then
    die "brew-packages.json not found: $PACKAGES_JSON"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Testing Installations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 基本コマンドのテスト
echo "📦 Basic Commands:"
BASIC_COMMANDS=(brew zsh git)
for cmd in "${BASIC_COMMANDS[@]}"; do
    if has "$cmd"; then
        e_success "$cmd"
        ((SUCCESS++))
    else
        e_error "$cmd"
        ((FAILED++))
    fi
done

# パッケージ名と実行コマンド名のマッピング
typeset -A COMMAND_MAP
COMMAND_MAP=(
    ripgrep rg
)

echo ""
echo "📦 Homebrew Formulae:"
# packages.jsonからformulaを読み込んでテスト
while IFS= read -r pkg; do
    cmd=${COMMAND_MAP[$pkg]:-$pkg}  # マッピングがあればそれを使用、なければパッケージ名
    if has "$cmd"; then
        e_success "$pkg"
        ((SUCCESS++))
    else
        e_error "$pkg"
        ((FAILED++))
    fi
done < <(jq -r '.formula.packages[].name' "$PACKAGES_JSON")

echo ""
echo "🖥️  Homebrew Casks:"
# Caskは実行ファイル名とパッケージ名が異なることが多いため、
# brew list --cask でインストール確認
while IFS= read -r pkg; do
    if brew list --cask 2>/dev/null | grep -q "^${pkg}\$"; then
        e_success "$pkg (installed)"
        ((SUCCESS++))
    else
        e_warning "$pkg (not installed)"
        ((FAILED++))
    fi
done < <(jq -r '.cask.groups[] | .[].name' "$PACKAGES_JSON")

# サマリー表示
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Success: $SUCCESS"
echo "  ❌ Failed:  $FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 終了コード
[ $FAILED -eq 0 ] && exit 0 || exit 1
