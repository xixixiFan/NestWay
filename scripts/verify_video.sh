#!/bin/bash

# SOS视频文件验证脚本
# 用于检查视频文件是否正确配置和打包

echo "=========================================="
echo "  NestWay SOS视频文件验证工具"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查视频文件是否存在
echo "1. 检查视频文件..."
if [ -f "assets/attention_video.mp4" ]; then
    echo -e "${GREEN}✓${NC} 视频文件存在: assets/attention_video.mp4"
    
    # 获取文件大小
    FILE_SIZE=$(du -h "assets/attention_video.mp4" | cut -f1)
    echo "  文件大小: $FILE_SIZE"
    
    # 检查文件是否为空
    if [ ! -s "assets/attention_video.mp4" ]; then
        echo -e "${RED}✗${NC} 警告: 视频文件为空！"
    fi
else
    echo -e "${RED}✗${NC} 错误: 视频文件不存在！"
    echo "  请确保 assets/attention_video.mp4 文件存在"
    exit 1
fi

echo ""

# 检查pubspec.yaml配置
echo "2. 检查pubspec.yaml配置..."
if grep -q "assets/attention_video.mp4" pubspec.yaml; then
    echo -e "${GREEN}✓${NC} pubspec.yaml中已配置视频资源"
else
    echo -e "${RED}✗${NC} 错误: pubspec.yaml中未配置视频资源！"
    echo "  请在pubspec.yaml的flutter.assets中添加:"
    echo "    - assets/attention_video.mp4"
    exit 1
fi

echo ""

# 检查video_player依赖
echo "3. 检查video_player依赖..."
if grep -q "video_player:" pubspec.yaml; then
    VERSION=$(grep "video_player:" pubspec.yaml | awk '{print $2}')
    echo -e "${GREEN}✓${NC} video_player依赖已配置: $VERSION"
else
    echo -e "${RED}✗${NC} 错误: 未找到video_player依赖！"
    exit 1
fi

echo ""

# 检查视频编码信息（需要ffmpeg）
echo "4. 检查视频编码信息..."
if command -v ffmpeg &> /dev/null; then
    echo "  使用ffmpeg分析视频..."
    ffmpeg -i "assets/attention_video.mp4" 2>&1 | grep -E "Duration|Video:|Audio:" | while read line; do
        echo "  $line"
    done
    
    # 检查是否为H.264编码
    if ffmpeg -i "assets/attention_video.mp4" 2>&1 | grep -q "h264"; then
        echo -e "${GREEN}✓${NC} 视频使用H.264编码（推荐）"
    else
        echo -e "${YELLOW}⚠${NC} 警告: 视频可能不是H.264编码，某些设备可能无法播放"
    fi
else
    echo -e "${YELLOW}⚠${NC} 未安装ffmpeg，跳过视频编码检查"
    echo "  建议安装ffmpeg以进行详细检查: https://ffmpeg.org/"
fi

echo ""

# 检查Android配置
echo "5. 检查Android配置..."
if [ -f "android/app/src/main/res/xml/network_security_config.xml" ]; then
    echo -e "${GREEN}✓${NC} 网络安全配置文件存在"
else
    echo -e "${YELLOW}⚠${NC} 警告: 网络安全配置文件不存在"
fi

if grep -q "networkSecurityConfig" android/app/src/main/AndroidManifest.xml; then
    echo -e "${GREEN}✓${NC} AndroidManifest.xml已配置网络安全"
else
    echo -e "${YELLOW}⚠${NC} 警告: AndroidManifest.xml未配置网络安全"
fi

echo ""

# 检查构建产物
echo "6. 检查APK构建..."
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo -e "${GREEN}✓${NC} 找到Release APK: $APK_SIZE"
    
    # 检查APK大小是否合理（应该包含视频）
    APK_SIZE_BYTES=$(stat -f%z "$APK_PATH" 2>/dev/null || stat -c%s "$APK_PATH" 2>/dev/null)
    if [ $APK_SIZE_BYTES -lt 10000000 ]; then
        echo -e "${RED}✗${NC} 警告: APK文件过小（<10MB），视频可能未打包！"
        echo "  建议执行: flutter clean && flutter build apk --release"
    else
        echo -e "${GREEN}✓${NC} APK大小正常，视频应该已打包"
    fi
else
    echo -e "${YELLOW}⚠${NC} 未找到Release APK"
    echo "  运行以下命令构建: flutter build apk --release"
fi

echo ""
echo "=========================================="
echo "  验证完成"
echo "=========================================="
echo ""
echo "建议操作:"
echo "1. 如果发现问题，请先执行: flutter clean"
echo "2. 然后重新构建: flutter build apk --release"
echo "3. 在真机上测试视频播放功能"
echo ""
