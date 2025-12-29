param(
    [string]$BaseUrl = "http://143.110.185.159:8080/api",
    [switch]$Seed
)

Write-Host "Running VPS integration test against $BaseUrl"
$env:RUN_VPS_INTEGRATION = "1"
$env:VPS_BASE_URL = $BaseUrl

if ($Seed) {
    Write-Host "Seeding test data..."
    try {
        Invoke-RestMethod -Method Post -Uri "$BaseUrl/_seed_test_data" -ErrorAction Stop
        Write-Host "Seed completed."
    } catch {
        Write-Error "Seed failed: $_"
        exit 1
    }
}

Write-Host "Running cargo test..."
$process = Start-Process -FilePath 'cargo' -ArgumentList 'test','-p','federalnet-api','--test','integration_vps','--','--nocapture' -NoNewWindow -Wait -PassThru
if ($process.ExitCode -ne 0) {
    Write-Error "Tests failed with exit code $($process.ExitCode)"
    exit $process.ExitCode
} else {
    Write-Host "Tests passed."
}
