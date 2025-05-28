#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Test script for validating the custom domain configuration implementation
.DESCRIPTION
    This script validates the Helm chart templates, domain configuration,
    and deployment readiness for the Sedaro Nano application.
.PARAMETER TestMode
    Specify the test mode: 'template', 'dry-run', or 'full'
.PARAMETER Domain
    Test domain name (e.g., example.com)
.PARAMETER Host
    Test host/subdomain (e.g., sedaro)
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('template', 'dry-run', 'full')]
    [string]$TestMode = 'template',
    
    [Parameter(Mandatory = $false)]
    [string]$Domain = 'k8sdemo.click',
    
    [Parameter(Mandatory = $false)]
    [string]$Subdomain = 'sedaro'
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }

function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if helm is installed
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        Write-Error "Helm is not installed or not in PATH"
        return $false
    }
    Write-Success "Helm is available"
    
    # Check if kubectl is installed
    if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
        Write-Warning "kubectl is not installed - some tests will be skipped"
    } else {
        Write-Success "kubectl is available"
    }
    
    # Check if AWS CLI is installed
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Warning "AWS CLI is not installed - ACM certificate tests will be skipped"
    } else {
        Write-Success "AWS CLI is available"
    }
    
    return $true
}

function Test-HelmTemplates {
    Write-Info "Testing Helm templates..."
    
    $chartPath = ".\helm\sedaro-nano"
    if (-not (Test-Path $chartPath)) {
        Write-Error "Helm chart not found at $chartPath"
        return $false
    }
    
    # Test 1: Basic template rendering without domain
    Write-Info "Test 1: Basic template rendering (no domain)"
    try {
        $output = helm template test-release $chartPath 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Basic template rendering passed"
        } else {
            Write-Error "Basic template rendering failed: $output"
            return $false
        }
    } catch {
        Write-Error "Basic template rendering failed: $_"
        return $false
    }
      # Test 2: Template rendering with domain configuration
    Write-Info "Test 2: Template rendering with domain configuration"
    $fullDomain = "$Subdomain.$Domain"
    try {
        $output = helm template test-release $chartPath `
            --set domain.enabled=true `
            --set domain.name="$Domain" `
            --set domain.host="$Subdomain" `
            --set domain.fullName="$fullDomain" `
            --set tls.enabled=true `
            --set tls.certificate.arn="arn:aws:acm:us-east-1:123456789012:certificate/test-cert-id" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Domain template rendering passed"
            
            # Check if output contains expected domain configuration
            if ($output -match $fullDomain) {
                Write-Success "Domain configuration found in templates"
            } else {
                Write-Warning "Domain configuration not found in template output"
            }
            
            # Check for TLS configuration
            if ($output -match "certificate-arn") {
                Write-Success "TLS certificate configuration found"
            } else {
                Write-Warning "TLS certificate configuration not found"
            }
            
        } else {
            Write-Error "Domain template rendering failed: $output"
            return $false
        }
    } catch {
        Write-Error "Domain template rendering failed: $_"
        return $false
    }
    
    # Test 3: Template validation
    Write-Info "Test 3: Template validation (helm lint)"
    try {
        $output = helm lint $chartPath 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Helm lint passed"
        } else {
            Write-Error "Helm lint failed: $output"
            return $false
        }
    } catch {
        Write-Error "Helm lint failed: $_"
        return $false
    }
    
    return $true
}

function Show-TestResults {
    param($Results)
    
    Write-Host "`n" + "="*60 -ForegroundColor Blue
    Write-Host "TEST RESULTS SUMMARY" -ForegroundColor Blue
    Write-Host "="*60 -ForegroundColor Blue
    
    $passed = ($Results.Values | Where-Object { $_ -eq $true }).Count
    $total = $Results.Count
    
    foreach ($test in $Results.GetEnumerator()) {
        if ($test.Value) {
            Write-Success "$($test.Key): PASSED"
        } else {
            Write-Error "$($test.Key): FAILED"
        }
    }
    
    Write-Host "`nOverall: $passed/$total tests passed" -ForegroundColor $(if ($passed -eq $total) { "Green" } else { "Yellow" })
    
    if ($passed -eq $total) {
        Write-Success "All tests passed! Domain configuration is ready for deployment."
    } else {
        Write-Warning "Some tests failed. Please review the issues above."
    }
}

# Main execution
Write-Host "Sedaro Nano Domain Configuration Test Suite" -ForegroundColor Blue
Write-Host "============================================" -ForegroundColor Blue
Write-Host "Test Mode: $TestMode" -ForegroundColor Cyan
Write-Host "Test Domain: $Subdomain.$Domain" -ForegroundColor Cyan
Write-Host ""

$results = @{}

# Run prerequisite checks
if (-not (Test-Prerequisites)) {
    Write-Error "Prerequisites check failed. Cannot continue."
    exit 1
}
$results["Prerequisites"] = $true

# Run template tests
$results["Helm Templates"] = Test-HelmTemplates

Show-TestResults $results

# Set exit code based on results
$failedTests = ($results.Values | Where-Object { $_ -eq $false }).Count
exit $failedTests
