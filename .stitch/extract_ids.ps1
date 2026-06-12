$steps = @(71,73,75,77,79,81,83,85,87)
$basePath = "C:\Users\ACER\.gemini\antigravity-ide\brain\2635f6fe-dc8f-4a37-9de0-b16366307aa0\.system_generated\steps"

foreach ($s in $steps) {
    $p = Join-Path $basePath "$s" "output.txt"
    if (Test-Path $p) {
        $c = Get-Content $p -Raw
        $titleMatch = [regex]::Match($c, '"title":"([^"]+)"')
        $screenMatch = [regex]::Match($c, 'screens/([a-f0-9]{32})')
        if ($screenMatch.Success) {
            $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { "Unknown" }
            $screenId = $screenMatch.Groups[1].Value
            Write-Output "Step ${s}: ${title} => ${screenId}"
        }
    }
}
