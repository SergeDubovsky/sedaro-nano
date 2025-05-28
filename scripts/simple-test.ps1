Write-Host "Sedaro Nano Simple Validation Test" -ForegroundColor Blue
Write-Host "Domain: sedaro.k8sdemo.click" -ForegroundColor Cyan

# Test Helm
if (Get-Command helm -ErrorAction SilentlyContinue) {
    Write-Host "✓ Helm is available" -ForegroundColor Green
    
    # Test basic template
    cd c:\Project\sedaro-nano
    $result = helm template test-release .\helm\sedaro-nano 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Basic Helm template test passed" -ForegroundColor Green
    } else {
        Write-Host "✗ Basic Helm template test failed" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
    }
    
    # Test domain template
    $result = helm template test-release .\helm\sedaro-nano --set domain.enabled=true --set domain.name="k8sdemo.click" --set domain.host="sedaro" --set domain.fullName="sedaro.k8sdemo.click" --set tls.enabled=true --set tls.certificate.arn="arn:aws:acm:us-east-1:123456789012:certificate/test-cert-id" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Domain Helm template test passed" -ForegroundColor Green
        if ($result -match "sedaro.k8sdemo.click") {
            Write-Host "✓ Domain configuration found in templates" -ForegroundColor Green
        }
    } else {
        Write-Host "✗ Domain Helm template test failed" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
    }
} else {
    Write-Host "✗ Helm is not available" -ForegroundColor Red
}

Write-Host "`nValidation completed!" -ForegroundColor Blue
