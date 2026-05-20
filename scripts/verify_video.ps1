# SOS视频文件验证脚本 (PowerShell版本)
# 用于检查视频文件是否正确配置和打包

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  NestWay SOS视频文件验证工具" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查视频文件是否存在
Write-Host "1. 检查视频文件..." -ForegroundColor Yellow
if (Test-Path "assets/attention_video.mp4") {
    Write-Host "✓ 视频文件存在: assets/attention_video.mp4" -ForegroundColor Green
    
    # 获取文件大小
    $fileSize = (Get-Item "assets/attention_video.mp4").Length
    $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
    Write-Host "  文件大小: $fileSizeMB MB" -ForegroundColor Gray
    
    # 检查文件是否为空
    if ($fileSize -eq 0) {
        Write-Host "✗ 警告: 视频文件为空！" -ForegroundColor Red
    }
} else {
    Write-Host "✗ 错误: 视频文件不存在！" -ForegroundColor Red
    Write-Host "  请确保 assets/attention_video.mp4 文件存在" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 检查pubspec.yaml配置
Write-Host "2. 检查pubspec.yaml配置..." -ForegroundColor Yellow
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match "assets/attention_video.mp4") {
    Write-Host "✓ pubspec.yaml中已配置视频资源" -ForegroundColor Green
} else {
    Write-Host "✗ 错误: pubspec.yaml中未配置视频资源！" -ForegroundColor Red
    Write-Host "  请在pubspec.yaml的flutter.assets中添加:" -ForegroundColor Red
    Write-Host "    - assets/attention_video.mp4" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 检查video_player依赖
Write-Host "3. 检查video_player依赖..." -ForegroundColor Yellow
if ($pubspecContent -match "video_player:") {
    $version = ($pubspecContent | Select-String "video_player:\s*(.+)" | ForEach-Object { $_.Matches.Groups[1].Value })
    Write-Host "✓ video_player依赖已配置: $version" -ForegroundColor Green
} else {
    Write-Host "✗ 错误: 未找到video_player依赖！" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 检查视频编码信息（需要ffmpeg）
Write-Host "4. 检查视频编码信息..." -ForegroundColor Yellow
$ffmpegExists = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($ffmpegExists) {
    Write-Host "  使用ffmpeg分析视频..." -ForegroundColor Gray
    $ffmpegOutput = & ffmpeg -i "assets/attention_video.mp4" 2>&1 | Out-String
    
    # 提取关键信息
    if ($ffmpegOutput -match "Duration: ([\d:\.]+)") {
        Write-Host "  时长: $($Matches[1])" -ForegroundColor Gray
    }
    if ($ffmpegOutput -match "Video: ([^,]+)") {
        Write-Host "  视频编码: $($Matches[1])" -ForegroundColor Gray
    }
    if ($ffmpegOutput -match "Audio: ([^,]+)") {
        Write-Host "  音频编码: $($Matches[1])" -ForegroundColor Gray
    }
    
    # 检查是否为H.264编码
    if ($ffmpegOutput -match "h264") {
        Write-Host "✓ 视频使用H.264编码（推荐）" -ForegroundColor Green
    } else {
        Write-Host "⚠ 警告: 视频可能不是H.264编码，某些设备可能无法播放" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ 未安装ffmpeg，跳过视频编码检查" -ForegroundColor Yellow
    Write-Host "  建议安装ffmpeg以进行详细检查: https://ffmpeg.org/" -ForegroundColor Gray
}

Write-Host ""

# 检查Android配置
Write-Host "5. 检查Android配置..." -ForegroundColor Yellow
if (Test-Path "android/app/src/main/res/xml/network_security_config.xml") {
    Write-Host "✓ 网络安全配置文件存在" -ForegroundColor Green
} else {
    Write-Host "⚠ 警告: 网络安全配置文件不存在" -ForegroundColor Yellow
}

$manifestContent = Get-Content "android/app/src/main/AndroidManifest.xml" -Raw
if ($manifestContent -match "networkSecurityConfig") {
    Write-Host "✓ AndroidManifest.xml已配置网络安全" -ForegroundColor Green
} else {
    Write-Host "⚠ 警告: AndroidManifest.xml未配置网络安全" -ForegroundColor Yellow
}

Write-Host ""

# 检查构建产物
Write-Host "6. 检查APK构建..." -ForegroundColor Yellow
$apkPath = "build/app/outputs/flutter-apk/app-release.apk"
if (Test-Path $apkPath) {
    $apkSize = (Get-Item $apkPath).Length
    $apkSizeMB = [math]::Round($apkSize / 1MB, 2)
    Write-Host "✓ 找到Release APK: $apkSizeMB MB" -ForegroundColor Green
    
    # 检查APK大小是否合理（应该包含视频）
    if ($apkSize -lt 10000000) {
        Write-Host "✗ 警告: APK文件过小（<10MB），视频可能未打包！" -ForegroundColor Red
        Write-Host "  建议执行: flutter clean && flutter build apk --release" -ForegroundColor Red
    } else {
        Write-Host "✓ APK大小正常，视频应该已打包" -ForegroundColor Green
    }
} else {
    Write-Host "⚠ 未找到Release APK" -ForegroundColor Yellow
    Write-Host "  运行以下命令构建: flutter build apk --release" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  验证完成" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "建议操作:" -ForegroundColor Yellow
Write-Host "1. 如果发现问题，请先执行: flutter clean" -ForegroundColor Gray
Write-Host "2. 然后重新构建: flutter build apk --release" -ForegroundColor Gray
Write-Host "3. 在真机上测试视频播放功能" -ForegroundColor Gray
Write-Host ""
