$apiKey = "sk-f3551a02bf714c80bba9bfc321c8193c"  # Your API Token

<#
.SYNOPSIS
DeepSeek Chat - No Byte[] Error + Fix Chinese Garbled Text
.DESCRIPTION
1. Remove all Byte[] operations to avoid type error
2. Fix Chinese garbled text with simple encoding settings
3. Compatible with PowerShell 5.1/7+
#>

# ==================== Simplified Encoding Fix (No Byte[]) ====================
# Fix console display encoding
$OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = $OutputEncoding
[Console]::InputEncoding = $OutputEncoding

# ==================== Configuration ====================
$apiUrl = "https://api.deepseek.com/v1/chat/completions"
$model = "deepseek-chat"
$temperature = 0.7
$maxTokens = 2048
# ======================================================

$conversationHistory = @()

# Welcome message
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      DeepSeek Interactive Chat Tool      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Type 'exit'/'quit' to end conversation" -ForegroundColor Gray
Write-Host "Type 'clear'/'reset' to clear history`n" -ForegroundColor Gray

# Simple loading animation (no complex functions)
function Show-Loading {
    param([ref]$StopLoading)
    $chars = @("/", "-", "\", "|")
    $i = 0
    while (-not $StopLoading.Value) {
        Write-Host "`rWaiting for response $($chars[$i % 4])" -ForegroundColor Cyan -NoNewline
        $i++
        Start-Sleep -Milliseconds 100
    }
    Write-Host "`r                                      `r" -NoNewline
}

# Main conversation loop
while ($true) {
    $userInput = Read-Host -Prompt "You"
    
    # Exit logic
    if ($userInput -in "exit", "quit") {
        Write-Host "`nConversation ended, thank you for using!`n" -ForegroundColor Green
        break
    }
    
    # Clear history logic
    if ($userInput -in "clear", "reset") {
        $conversationHistory = @()
        Write-Host "Conversation history cleared`n" -ForegroundColor Yellow
        continue
    }
    
    # Empty input check
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        Write-Host "Input cannot be empty, please try again`n" -ForegroundColor Red
        continue
    }

    # Add user input to history
    $conversationHistory += @{
        role    = "user"
        content = $userInput
    }

    # Build request body (simple JSON)
    $requestBody = @{
        model       = $model
        messages    = $conversationHistory
        temperature = $temperature
        max_tokens  = $maxTokens
    } | ConvertTo-Json -Depth 10

    try {
        # Start simple loading animation
        $stopLoading = $false
        $loadingJob = Start-Job -ScriptBlock ${function:Show-Loading} -ArgumentList ([ref]$stopLoading)
        
        # ==================== Core Fix: Use Invoke-RestMethod with UTF-8 ====================
        # No Byte[] operations - avoid type error completely
        $response = Invoke-RestMethod `
            -Uri $apiUrl `
            -Method Post `
            -Headers @{
                "Authorization" = "Bearer $apiKey"
                "Content-Type"  = "application/json"
            } `
            -Body $requestBody `
            -ErrorAction Stop `
            -ContentType "application/json; charset=utf-8"

        # Stop loading animation
        $stopLoading = $true
        Wait-Job $loadingJob | Out-Null
        Remove-Job $loadingJob

        # Get response content and fix display
        $assistantReply = $response.choices[0].message.content
        # Force UTF-8 display for Chinese characters
        $utf8Reply = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes($assistantReply))
        
        Write-Host "DeepSeek: " -ForegroundColor Green -NoNewline
        Write-Host $utf8Reply
        Write-Host ""  # Empty line separator

        # Add AI reply to history
        $conversationHistory += @{
            role    = "assistant"
            content = $utf8Reply
        }
    }
    catch {
        # Stop loading on error
        $stopLoading = $true
        Wait-Job $loadingJob -ErrorAction SilentlyContinue | Out-Null
        Remove-Job $loadingJob -ErrorAction SilentlyContinue

        # Simple error message (no complex details)
        Write-Host "`nRequest failed! Error: $($_.Exception.Message)`n" -ForegroundColor Red
        
        # Remove invalid input
        $conversationHistory = $conversationHistory[0..($conversationHistory.Count - 2)]
        exit
    }
}