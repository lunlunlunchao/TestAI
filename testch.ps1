# 1. 设置控制台输出编码为 UTF-8（核心步骤）

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8 # 控制台显示编码

$OutputEncoding = [System.Text.Encoding]::UTF8 # 脚本输出编码

Write-Host "DEBUG: script started" -ForegroundColor Cyan

# 2. 定义 JWT 令牌（示例）

$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzUxNzE3OTIwLCJpYXQiOjE3NTE3MDM1MjAsImp0aSI6IjUxMzlhYjA4Njk2ODQ2ZmZhMjcyOGUzODdjZjMzYzRkIiwidXNlcl9pZCI6IjdjODQxN2JiLTliYTMtNGVjMC04NjZiLWNhOTMyNDg0ODY5MyIsImF1ZCI6WyJ3ZWItYXBwIiwibW9iaWxlLWFwcCJdLCJpc3MiOiJzYWZlLXNlbnRyeS1hdXRoLXNlcnZpY2UifQ.G6IXXX_9NSm9tkg6v0X1BIPThQVwLCEjLzUjV8KkBp0"

try {

# 3. 发送请求并捕获响应头（用于检测实际编码）

$response = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/auth/diagnostic/" `

-Headers @{

"Authorization" = "Bearer $token"

"Content-Type" = "application/json; charset=utf-8" # 明确请求编码

"Accept-Charset" = "utf-8" # 要求响应使用 UTF-8

} `

-Method Get `

-ResponseHeadersVariable 'ResponseHeaders' # 保存响应头到变量

-UseBasicParsing # 避免依赖 IE 解析引擎（提升兼容性）

# 4. 手动处理响应内容编码（双重保障）

$content = $response.Content

# 从响应头提取编码（默认 UTF-8）

$charset = "utf-8"

if ($ResponseHeaders -and $ResponseHeaders['Content-Type'] -match 'charset\s*=\s*"?([\w\-.]+)"?') {
	$charset = $matches[1].Trim().ToLower() # 如响应头指定其他编码（如 GBK），自动适配并标准化
}

# 若内容为字节数组（非字符串），转换为指定编码的字符串

if ($content -isnot [string]) {

$encoding = [System.Text.Encoding]::GetEncoding($charset)

$content = $encoding.GetString($content)

}

# 5. 显示响应内容（支持中文）

Write-Host ('Status code: {0}' -f $response.StatusCode) -ForegroundColor Green

Write-Host "Response content:"

# 尝试解析 JSON（兼容非 JSON 响应）

try {

$jsonResponse = $content | ConvertFrom-Json

$jsonResponse | Format-List # 格式化显示 JSON 内容

}

catch {

Write-Host $content # 非 JSON 内容直接输出

}

}

catch {

# 6. 错误处理（支持中文错误信息）

Write-Host ('Request failed: {0}' -f $_.Exception.Message) -ForegroundColor Red

# 解析错误详情（处理中文乱码）

if ($_.ErrorDetails) {

try {

$errorContent = $_.ErrorDetails.Message

# 若错误内容为字节数组，转换为 UTF-8 字符串

if ($errorContent -isnot [string]) {

$errorContent = [System.Text.Encoding]::UTF8.GetString($errorContent)

}

Write-Host "Error details:" -ForegroundColor Red

# 尝试解析错误内容为 JSON

try {

$errorJson = $errorContent | ConvertFrom-Json

$errorJson | Format-List

}

catch {

Write-Host $errorContent -ForegroundColor Red # 非 JSON 直接输出

}

}

catch {

Write-Host ('Unable to parse error details: {0}' -f $_.Exception.Message) -ForegroundColor Red

}

}

else {

Write-Host "No additional error information" -ForegroundColor Red

}

# 7. 显示状态码（可选）

if ($_.Exception.Response) {
	Write-Host ('状态码: {0}' -f $_.Exception.Response.StatusCode.value__) -ForegroundColor Red
}

}