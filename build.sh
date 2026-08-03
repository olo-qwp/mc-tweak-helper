#!/bin/bash
# ============================================
# Minecraft 网易版辅助工具 - 完整构建脚本
# 构建产物为 .deb 文件
# ============================================
# 使用方式:
#   bash build.sh            # 构建 deb
#   bash build.sh install    # 构建并安装到设备
#   bash build.sh clean      # 清理构建产物
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 包信息
PACKAGE_NAME="com.mc.tweak"
PACKAGE_VERSION="1.0.0"
DEB_FILE="${PACKAGE_NAME}_${PACKAGE_VERSION}_iphoneos-arm.deb"

# 检查 Theos
ensure_theos() {
    if [ -z "$THEOS" ]; then
        export THEOS="$HOME/theos"
    fi

    if [ ! -d "$THEOS" ]; then
        echo -e "${RED}✗ Theos 未安装${NC}"
        echo ""
        echo "  请先安装 Theos:"
        echo "    bash -c \"\$(curl -fsSL https://raw.github.com/theos/theos/master/bin/install-theos)\""
        echo ""
        echo "  或者手动指定路径:"
        echo "    export THEOS=/path/to/theos && bash build.sh"
        exit 1
    fi
    echo -e "${GREEN}✓ Theos: $THEOS${NC}"
}

print_header() {
    echo ""
    echo "============================================"
    echo "  Minecraft 网易版辅助工具 v${PACKAGE_VERSION}"
    echo "============================================"
    echo ""
}

# 构建 deb
build_package() {
    print_header

    echo -e "${BLUE}[1/4]${NC} 检查环境..."
    ensure_theos

    echo -e "${BLUE}[2/4]${NC} 清理旧构建..."
    make clean 2>/dev/null || true
    rm -rf packages/ 2>/dev/null || true

    echo -e "${BLUE}[3/4]${NC} 编译并打包..."
    make package

    # 查找生成的 deb
    FOUND_DEB=$(find packages/ -name "*.deb" 2>/dev/null | head -1)
    if [ -z "$FOUND_DEB" ]; then
        FOUND_DEB=$(find . -name "*.deb" -not -path "./.theos/*" 2>/dev/null | head -1)
    fi

    if [ -z "$FOUND_DEB" ]; then
        echo -e "${RED}✗ 构建失败，未找到 deb 文件${NC}"
        exit 1
    fi

    DEB_SIZE=$(du -h "$FOUND_DEB" | cut -f1)

    echo -e "${BLUE}[4/4]${NC} 构建完成!"
    echo ""
    echo "════════════════════════════════════════════"
    echo -e " ${GREEN}✅ 构建成功!${NC}"
    echo ""
    echo -e "  📦 ${YELLOW}$(basename "$FOUND_DEB")${NC}"
    echo -e "  📏 大小: ${DEB_SIZE}"
    echo ""
    echo "  🔗 文件路径:"
    echo "     $(cd "$(dirname "$FOUND_DEB")" && pwd)/$(basename "$FOUND_DEB")"
    echo ""
    echo "  📋 安装方式:"
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │  TrollStore 方式:                       │"
    echo "  │  1. 将 .deb 传到 iPhone                 │"
    echo "  │  2. 用 Filza 打开 → 用 TrollStore 安装  │"
    echo "  │                                         │"
    echo "  │  TrollFools 注入方式:                   │"
    echo "  │  1. 解压 deb: dpkg-deb -x <deb> /tmp/mc │"
    echo "  │  2. 获取 dylib:                         │"
    echo "  │     Library/MobileSubstrate/DynamicLibr │"
    echo "  │     aries/MCTweak.dylib                 │"
    echo "  │  3. 用 TrollFools 注入到 .ipa          │"
    echo "  │                                         │"
    echo "  │  越狱方式:                              │"
    echo "  │  dpkg -i com.mc.tweak_*.deb             │"
    echo "  └─────────────────────────────────────────┘"
    echo "════════════════════════════════════════════"
}

install_package() {
    build_package
    echo -e "${BLUE}[安装]${NC} 正在通过 SSH 安装到设备..."

    FOUND_DEB=$(find packages/ -name "*.deb" 2>/dev/null | head -1)
    if [ -z "$FOUND_DEB" ]; then
        FOUND_DEB=$(find . -name "*.deb" -not -path "./.theos/*" 2>/dev/null | head -1)
    fi

    if [ -n "$FOUND_DEB" ]; then
        make install
    fi
}

clean_all() {
    echo -e "${YELLOW}清理构建产物...${NC}"
    make clean 2>/dev/null || true
    rm -rf packages/ .theos/ 2>/dev/null || true
    echo -e "${GREEN}✓ 清理完成${NC}"
}

# 主入口
case "${1:-}" in
    install)
        install_package
        ;;
    clean)
        clean_all
        ;;
    *)
        build_package
        ;;
esac