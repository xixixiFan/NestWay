#!/bin/bash

# SOS视频播放问题快速修复脚本
# 自动执行所有必要的修复步骤

echo "=========================================="
echo "  SOS视频播放问题快速修复"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 步骤1: 清理构建缓存
echo -e "${BLUE}步骤 1/4: 清理构建缓存...${NC}"
flutter clean
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 清理完成${NC}"
else
    echo -e "${RED}✗ 清理失败${NC}"
    exit 1
fi
echo ""

# 步骤2: 重新获取依赖
echo -e "${BLUE}步骤 2/4: 重新获取依赖...${NC}"
flutter pub get
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 依赖获取完成${NC}"
else
    echo -e "${RED}✗ 依赖获取失败${NC}"
    exit 1
fi
echo ""

# 步骤3: 验证配置
echo -e "${BLUE}步骤 3/4: 验证配置...${NC}"

# 检查视频文件
if [ -f "assets/attention_video.mp4" ]; then
    FILE_SIZE=$(du -h "assets/attention_video.mp4" | cut -f1)
    echo -e "${GREEN}✓${NC} 视频文件存在 (大小: $FILE_SIZE)"
else
    echo -e "${RED}✗ 视频文件不存在！${NC}"
    exit 1
fi

# 检查pubspec.yaml
if grep -q "assets/attention_video.mp4" pubspec.yaml; then
    echo -e "${GREEN}✓${NC} pubspec.yaml配置正确"
else
    echo -e "${RED}✗ pubspec.yaml配置错误！${NC}"
    exit 1
fi

# 检查Android配置
if [ -f "android/app/src/main/res/xml/network_security_config.xml" ]; then
    echo -e "${GREEN}✓${NC} Android网络安全配置存在"
else
    echo -e "${YELLOW}⚠${NC} Android网络安全配置不存在（已自动创建）"
fi

echo ""

# 步骤4: 构建Release APK
echo -e "${BLUE}步骤 4/4: 构建Release APK...${NC}"
echo "这可能需要几分钟时间，请耐心等待..."
echo ""

flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ APK构建成功！${NC}"
    
    # 显示APK信息
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    if [ -f "$APK_PATH" ]; then
        APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
        echo ""
        echo "=========================================="
        echo -e "${GREEN}构建完成！${NC}"
        echo "=========================================="
        echo "APK路径: $APK_PATH"
        echo "APK大小: $APK_SIZE"
        echo ""
        
        # 检查APK大小
        APK_SIZE_BYTES=$(stat -f%z "$APK_PATH" 2>/dev/null || stat -c%s "$APK_PATH" 2>/dev/null)
        if [ $APK_SIZE_BYTES -lt 10000000 ]; then
            echo -e "${RED}⚠ 警告: APK文件过小（<10MB），视频可能未打包！${NC}"
            echo "建议重新运行此脚本"
        else
            echo -e "${GREEN}✓ APK大小正常，视频应该已正确打包${NC}"
        fi
        
        echo ""
        echo "下一步操作:"
        echo "1. 在手机上完全卸载旧版本应用"
        echo "2. 安装新构建的APK: $APK_PATH"
        echo "3. 测试SOS视频播放功能"
        echo ""
    fi
else
    echo ""
    echo -e "${RED}✗ APK构建失败${NC}"
    echo "请检查错误信息并重试"
    exit 1
fi

echo "=========================================="
echo -e "${GREEN}修复完成！${NC}"
echo "=========================================="
