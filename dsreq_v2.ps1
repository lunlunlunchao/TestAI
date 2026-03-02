$apiKey = "sk-f3551a02bf714c80bba9bfc321c8193c"  # Replace with your API Token

<#
.SYNOPSIS
Interactive chat with DeepSeek AI (UTF-8 support + loading animation)
.DESCRIPTION
Pure text version - No emojis, no Chinese, compatible with all PowerShell versions
#>

# ==================== Core Encoding Fix (Required) ====================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# ==================== Configuration Area ====================
#$apiKey = "your-deepseek-api-token-here"  # Replace with your API Token
$apiUrl = "https://api.deepseek.com/v1/chat/completions"
$model = "deepseek-chat"
$temperature = 0.7
$maxTokens = 2048
# =============================================================

# Initialize conversation history
$conversationHistory = @()

# Welcome message (no emojis)
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      DeepSeek Interactive Chat Tool      " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Type 'exit'/'quit' to end conversation" -ForegroundColor Gray
Write-Host "Type 'clear'/'reset' to clear history`n" -ForegroundColor Gray

# Define loading animation function (no emojis)
function Show-LoadingAnimation {
    param(
        [string]$Message = "Waiting for response",
        [ref]$StopLoading
    )
    
    # Loading animation characters (rotating effect)
    $loadingChars = @("/", "-", "\", "|")
    $i = 0
    
    # Show animation until stop signal is triggered
    while (-not $StopLoading.Value) {
        # Overwrite current line with loading animation (plain text)
        Write-Host "`r$Message $($loadingChars[$i % 4])" -ForegroundColor Cyan -NoNewline
        $i++
        Start-Sleep -Milliseconds 100
    }
    
    # Clear loading line (compatible syntax)
    $emptyString = Get-String -Length ($Message.Length + 4)
    Write-Host "`r$emptyString`r" -NoNewline
}

# Main conversation loop
while ($true) {
    # Get user input
    $userInput = Read-Host -Prompt "You"
    
    # 1. Exit conversation
    if ($userInput -in "exit", "quit") {
        Write-Host "`nConversation ended, thank you for using!`n" -ForegroundColor Green
        break
    }

    # 2. Clear conversation history
    if ($userInput -in "clear", "reset") {
        $conversationHistory = @()
        Write-Host "Conversation history cleared`n" -ForegroundColor Yellow
        continue
    }

    # 3. Handle empty input
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        Write-Host "Input cannot be empty, please try again`n" -ForegroundColor Red
        continue
    }

    # Add user input to conversation history
    $conversationHistory += @{
        role    = "user"
        content = $userInput
    }

    # Build API request body
    $requestBody = @{
        model       = $model
        messages    = $conversationHistory
        temperature = $temperature
        max_tokens  = $maxTokens
    } | ConvertTo-Json -Depth 10

    try {
        # Use HttpClient/async task to avoid job serialization and preserve UTF-8
        $client = New-Object System.Net.Http.HttpClient
        $client.DefaultRequestHeaders.Authorization = New-Object System.Net.Http.Headers.AuthenticationHeaderValue('Bearer', $apiKey)
        $content = New-Object System.Net.Http.StringContent($requestBody, [System.Text.Encoding]::UTF8, 'application/json')
        $task = $client.PostAsync($apiUrl, $content)

        # Show loading animation in the main thread while async task runs
        $loadingChars = @("/", "-", "\\", "|")
        $i = 0
        while (-not $task.IsCompleted) {
            Write-Host "`rWaiting for response $($loadingChars[$i % 4])" -ForegroundColor Cyan -NoNewline
            Start-Sleep -Milliseconds 120
            $i++
        }
        Write-Host "`r" -NoNewline

        # Get HTTP response and read body as string (UTF-8 preserved)
        $responseMessage = $task.Result
        $responseBody = $responseMessage.Content.ReadAsStringAsync().Result
        $response = $responseBody | ConvertFrom-Json

        # Parse and output response (plain text)
        $assistantReply = $response.choices[0].message.content
        Write-Host "DeepSeek: " -ForegroundColor Green -NoNewline
        Write-Host $assistantReply
        Write-Host ""  # Empty line separator

        # Add AI reply to conversation history
        $conversationHistory += @{
            role    = "assistant"
            content = $assistantReply
        }
    }
    catch {
        # Error prompt (plain text)
        Write-Host "`nRequest failed!" -ForegroundColor Red
        if ($_.Exception.Response) {
            Write-Host "   Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        }
        if ($_.ErrorDetails) {
            Write-Host "   Error Details: $($_.ErrorDetails.Message)`n" -ForegroundColor Red
        } else {
            Write-Host "   Error: $($_.Exception.Message)`n" -ForegroundColor Red
        }

        # Remove invalid user input from history (safe check)
        if ($conversationHistory.Count -gt 0) {
            $conversationHistory = $conversationHistory[0..($conversationHistory.Count - 2)]
        }
    }
}

# Helper function: Generate empty string (compatible with all PowerShell versions)
function Get-String {
    param([int]$Length)
    # Replace string multiplication with compatible syntax (no emojis)
    $emptyStr = [System.String]::Empty
    for ($i=0; $i -lt $Length; $i++) {
        $emptyStr += " "
    }
    return $emptyStr
}
