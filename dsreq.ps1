<#
.SYNOPSIS
使用DeepSeek API在PowerShell中与模型对话
.DESCRIPTION
通过DeepSeek API Token调用模型，实现简单的文本对话功能
#>

# ==================== 配置区域 ====================
# 替换为你的DeepSeek API Token
$apiKey = "sk-f3551a02bf714c80bba9bfc321c8193c"
# DeepSeek API端点（官方默认）
$apiUrl = "https://api.deepseek.com/v1/chat/completions"
# 要发送的问题/对话内容
$userMessage = "请介绍一下PowerShell的主要特点"
# 使用的模型（可根据需要调整，如deepseek-chat, deepseek-coder等）
$model = "deepseek-chat"
# =================================================

# 构建请求头
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
}

# 构建请求体
$body = @{
    model    = $model
    messages = @(
        @{
            role    = "user"
            content = $userMessage
        }
    )
    temperature = 0.7  # 随机性，0-1之间，值越高回答越多样
    max_tokens  = 2048 # 最大生成token数
} | ConvertTo-Json

try {
    # 发送请求到DeepSeek API
    Write-Host "正在请求DeepSeek API...`n" -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -ErrorAction Stop

    # 解析并输出响应结果
    Write-Host "=== DeepSeek 回复 ===" -ForegroundColor Green
    $response.choices[0].message.content
    Write-Host "`n=== 结束 ===" -ForegroundColor Green

    # 可选：输出完整的响应信息（便于调试）
    # Write-Host "`n完整响应信息：" -ForegroundColor Gray
    # $response | ConvertTo-Json -Depth 10
}
catch {
    # 错误处理
    Write-Host "`n请求失败！错误信息：" -ForegroundColor Red
    Write-Host "状态码：$($_.Exception.Response.StatusCode)" -ForegroundColor Red
    Write-Host "错误详情：$($_.ErrorDetails.Message)" -ForegroundColor Red
}