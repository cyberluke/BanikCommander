function Invoke-OpenAIRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$InputText,

        [Parameter(Mandatory)]
        [string]$ApiKey
    )

    $Headers = @{
        'Authorization' = "Bearer $ApiKey"
        'Content-Type' = 'application/json'
    }

    $SystemPrompt = @"
You are a PowerShell command generator. Convert natural language to PowerShell commands.
Follow these rules:
1. Only return the exact PowerShell command without any explanation or markdown
2. Use proper PowerShell command syntax and naming conventions
3. For system information queries, use Get-* cmdlets
4. For Azure AD queries, use appropriate AzureAD module cmdlets
5. Include necessary parameters and formatting where appropriate
6. Prefer pipeline operations over multiple commands where possible
7. Never include destructive commands unless explicitly requested
8. Return 'exit' for any exit/quit/stop requests
"@

    $Body = @{
        'model' = 'gpt-4'
        'messages' = @(
            @{
                'role' = 'system'
                'content' = $SystemPrompt
            },
            @{
                'role' = 'user'
                'content' = $InputText
            }
        )
        'temperature' = 0.3
        'max_tokens' = 150
    } | ConvertTo-Json

    try {
        Write-Verbose "Sending request to OpenAI API..."
        $Response = Invoke-RestMethod -Uri 'https://api.openai.com/v1/chat/completions' `
                                    -Method Post `
                                    -Headers $Headers `
                                    -Body $Body

        $GeneratedCommand = $Response.choices[0].message.content.Trim()
        Write-Verbose "Generated command: $GeneratedCommand"
        return $GeneratedCommand
    }
    catch {
        Write-Error "OpenAI API request failed: $($_.Exception.Message)"
        return $null
    }
}