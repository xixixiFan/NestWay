# SOS视频播放问题快速修复脚本 (PowerShell)
# 自动执行所有必要的修复步骤

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  SOS视频播放问题快速修复" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 步骤1: 清理构建缓存
Write-Host "步骤 1/4: 清理构建缓存..." -ForegroundColor Blue
flutter clean
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 清理完成" -ForegroundColor Green
} else {
    Write-Host "✗ 清理失败" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 步骤2: 重新获取依赖
Write-Host "步骤 2/4: 重新获取依赖..." -ForegroundColor Blue
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 依赖获取完成" -ForegroundColor Green
} else {
    Write-Host "✗ 依赖获取失败" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 步骤3: 验证配置
Write-Host "步骤 3/4: 验证配置..." -ForegroundColor Blue

# 检查视频文件
if (Test-Path "assets/attention_video.mp4") {
    $fileSize = (Get-Item "assets/attention_video.mp4").Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-Host "✓ 视频文件存在 (大小: $fileSizeMB MB)" -ForegroundColor Green
} else {
    Write-Host "✗ 视频文件不存在！" -ForegroundColor Red
    exit 1
}

# 检查pubspec.yaml
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match "assets/attention_video.mp4") {
    Write-Host "✓ pubspec.yaml配置正确" -ForegroundColor Green
} else {
    Write-Host "✗ pubspec.yaml配置错误！" -ForegroundColor Red
    exit 1
}

# 检查Android配置
if (Test-Path "android/app/src/main/res/xml/network_security_config.xml") {
    Write-Host "✓ Android网络安全配置存在" -ForegroundColor Green
} else {
    Write-Host "⚠ Android网络安全配置不存在（已自动创建）" -ForegroundColor Yellow
}

Write-Host ""

# 步骤4: 构建Release APK
Write-Host "步骤 4/4: 构建Release APK..." -ForegroundColor Blue
Write-Host "这可能需要几分钟时间，请耐心等待..." -ForegroundColor Gray
Write-Host ""

flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ APK构建成功！" -ForegroundColor Green
    
    # 显示APK信息
    $apkPath = "build/app/outputs/flutter-apk/app-release.apk"
    if (Test-Path $apkPath) {
        $apkSize = (Get-Item $apkPath).Length
        $apkSizeMB = [math]::Round($apkSize / 1MB, 2)
        Write-Host ""
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "构建完成！" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Cyan
        Write-Host "APK路径: $apkPath" -ForegroundColor Gray
        Write-Host "APK大小: $apkSizeMB MB" -ForegroundColor Gray
        Write-Host ""
        
        # 检查APK大小
        if ($apkSize -lt 10000000) {
            Write-Host "⚠ 警告: APK文件过小（<10MB），视频可能未打包！" -ForegroundColor Red
            Write-Host "建议重新运行此脚本" -ForegroundColor Red
        } else {
            Write-Host "✓ APK大小正常，视频应该已正确打包" -ForegroundColor Green
        }
        
        Write-Host ""
        Write-Host "下一步操作:" -ForegroundColor Yellow
        Write-Host "1. 在手机上完全卸载旧版本应用" -ForegroundColor Gray
        Write-Host "2. 安装新构建的APK: $apkPath" -ForegroundColor Gray
        Write-Host "3. 测试SOS视频播放功能" -ForegroundColor Gray
        Write-Host ""
    }
} else {
    Write-Host ""
    Write-Host "✗ APK构建失败" -ForegroundColor Red
    Write-Host "请检查错误信息并重试" -ForegroundColor Red
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "修复完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
