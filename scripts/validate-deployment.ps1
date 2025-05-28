#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Enhanced validation script for Sedaro Nano domain configuration and AWS readiness
.DESCRIPTION
    This script performs comprehensive validation of the Sedaro Nano deployment
    including AWS resources, domain configuration, and deployment readiness.
.PARAMETER TestMode
    Specify the test mode: 'template', 'aws', 'domain', or 'full'
.PARAMETER Domain
    Domain name (e.g., k8sdemo.click)
.PARAMETER Subdomain
    Subdomain/host (e.g., sedaro)
.PARAMETER AwsRegion
    AWS region for resource validation (default: us-east-1)
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('template', 'aws', 'domain', 'full')]
    [string]$TestMode = 'template',
    
    [Parameter(Mandatory = $false)]
    [string]$Domain = 'k8sdemo.click',
    
    [Parameter(Mandatory = $false)]
    [string]$Subdomain = 'sedaro',
    
    [Parameter(Mandatory = $false)]
    [string]$AwsRegion = 'us-east-1'
)

# Color functions for output
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Header { param($Message) Write-Host "`n$Message" -ForegroundColor Blue }

$FullDomain = "$Subdomain.$Domain"

function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    $prerequisites = @{}
    
    # Check if helm is installed
    if (Get-Command helm -ErrorAction SilentlyContinue) {
        Write-Success "Helm is available"
        $prerequisites["Helm"] = $true
    } else {
        Write-Error "Helm is not installed or not in PATH"
        $prerequisites["Helm"] = $false
    }
    
    # Check if kubectl is installed
    if (Get-Command kubectl -ErrorAction SilentlyContinue) {
        Write-Success "kubectl is available"
        $prerequisites["kubectl"] = $true
    } else {
        Write-Warning "kubectl is not installed - Kubernetes tests will be skipped"
        $prerequisites["kubectl"] = $false
    }
    
    # Check if AWS CLI is installed
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        Write-Success "AWS CLI is available"
        $prerequisites["AWS CLI"] = $true
    } else {
        Write-Warning "AWS CLI is not installed - AWS tests will be skipped"
        $prerequisites["AWS CLI"] = $false
    }
    
    return $prerequisites
}

function Test-HelmTemplates {
    Write-Header "Testing Helm Templates"
    
    $chartPath = ".\helm\sedaro-nano"
    if (-not (Test-Path $chartPath)) {
        Write-Error "Helm chart not found at $chartPath"
        return $false
    }
    
    $tests = @{}
    
    # Test 1: Basic template rendering without domain
    Write-Info "Test 1: Basic template rendering (no domain)"
    try {
        $output = helm template test-release $chartPath 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Basic template rendering passed"
            $tests["Basic Template"] = $true
        } else {
            Write-Error "Basic template rendering failed: $output"
            $tests["Basic Template"] = $false
        }
    } catch {
        Write-Error "Basic template rendering failed: $_"
        $tests["Basic Template"] = $false
    }
    
    # Test 2: Template rendering with domain configuration
    Write-Info "Test 2: Template rendering with domain configuration"
    try {
        $output = helm template test-release $chartPath `
            --set domain.enabled=true `
            --set domain.name="$Domain" `
            --set domain.host="$Subdomain" `
            --set domain.fullName="$FullDomain" `
            --set tls.enabled=true `
            --set tls.certificate.arn="arn:aws:acm:$AwsRegion:123456789012:certificate/test-cert-id" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Domain template rendering passed"
            
            # Check if output contains expected domain configuration
            if ($output -match $FullDomain) {
                Write-Success "Domain configuration found in templates"
                $tests["Domain Template"] = $true
            } else {
                Write-Warning "Domain configuration not found in template output"
                $tests["Domain Template"] = $false
            }
            
            # Check for TLS configuration
            if ($output -match "certificate-arn") {
                Write-Success "TLS certificate configuration found"
            } else {
                Write-Warning "TLS certificate configuration not found"
            }
            
        } else {
            Write-Error "Domain template rendering failed: $output"
            $tests["Domain Template"] = $false
        }
    } catch {
        Write-Error "Domain template rendering failed: $_"
        $tests["Domain Template"] = $false
    }
    
    # Test 3: Template validation
    Write-Info "Test 3: Template validation (helm lint)"
    try {
        $output = helm lint $chartPath 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Helm lint passed"
            $tests["Helm Lint"] = $true
        } else {
            Write-Error "Helm lint failed: $output"
            $tests["Helm Lint"] = $false
        }
    } catch {
        Write-Error "Helm lint failed: $_"
        $tests["Helm Lint"] = $false
    }
    
    return $tests
}

function Test-AwsResources {
    Write-Header "Testing AWS Resources"
    
    $tests = @{}
    
    # Test AWS authentication
    Write-Info "Testing AWS authentication"
    try {
        $identity = aws sts get-caller-identity --output json 2>&1 | ConvertFrom-Json
        if ($LASTEXITCODE -eq 0) {
            Write-Success "AWS authentication successful - Account: $($identity.Account)"
            $tests["AWS Auth"] = $true
        } else {
            Write-Error "AWS authentication failed"
            $tests["AWS Auth"] = $false
            return $tests
        }
    } catch {
        Write-Error "AWS authentication failed: $_"
        $tests["AWS Auth"] = $false
        return $tests
    }
    
    # Test EKS cluster access
    Write-Info "Testing EKS cluster access"
    try {
        $clusterInfo = kubectl cluster-info 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "EKS cluster access successful"
            $tests["EKS Access"] = $true
        } else {
            Write-Warning "EKS cluster access failed - cluster may not be configured"
            $tests["EKS Access"] = $false
        }
    } catch {
        Write-Warning "EKS cluster access failed: $_"
        $tests["EKS Access"] = $false
    }
    
    # Check ACM certificates
    Write-Info "Checking ACM certificates"
    try {
        $certificates = aws acm list-certificates --region $AwsRegion --output json 2>&1 | ConvertFrom-Json
        if ($LASTEXITCODE -eq 0) {
            $domainCerts = $certificates.CertificateSummaryList | Where-Object { $_.DomainName -eq $FullDomain -or $_.DomainName -eq "*.$Domain" }
            if ($domainCerts) {
                Write-Success "ACM certificate found for domain: $($domainCerts[0].DomainName)"
                Write-Info "Certificate ARN: $($domainCerts[0].CertificateArn)"
                $tests["ACM Certificate"] = $true
            } else {
                Write-Warning "No ACM certificate found for $FullDomain or *.$Domain"
                $tests["ACM Certificate"] = $false
            }
        } else {
            Write-Error "Failed to list ACM certificates"
            $tests["ACM Certificate"] = $false
        }
    } catch {
        Write-Error "Failed to check ACM certificates: $_"
        $tests["ACM Certificate"] = $false
    }
    
    # Check Route53 hosted zones
    Write-Info "Checking Route53 hosted zones"
    try {
        $hostedZones = aws route53 list-hosted-zones --output json 2>&1 | ConvertFrom-Json
        if ($LASTEXITCODE -eq 0) {
            $domainZone = $hostedZones.HostedZones | Where-Object { $_.Name -eq "$Domain." }
            if ($domainZone) {
                Write-Success "Route53 hosted zone found for $Domain"
                $tests["Route53 Zone"] = $true
            } else {
                Write-Warning "No Route53 hosted zone found for $Domain"
                $tests["Route53 Zone"] = $false
            }
        } else {
            Write-Error "Failed to list Route53 hosted zones"
            $tests["Route53 Zone"] = $false
        }
    } catch {
        Write-Error "Failed to check Route53 hosted zones: $_"
        $tests["Route53 Zone"] = $false
    }
    
    # Check ECR repositories
    Write-Info "Checking ECR repositories"
    try {
        $repositories = aws ecr describe-repositories --region $AwsRegion --output json 2>&1 | ConvertFrom-Json
        if ($LASTEXITCODE -eq 0) {
            $frontendRepo = $repositories.repositories | Where-Object { $_.repositoryName -like "*frontend*" }
            $backendRepo = $repositories.repositories | Where-Object { $_.repositoryName -like "*backend*" }
            
            if ($frontendRepo -and $backendRepo) {
                Write-Success "ECR repositories found for frontend and backend"
                $tests["ECR Repositories"] = $true
            } else {
                Write-Warning "ECR repositories not found or incomplete"
                $tests["ECR Repositories"] = $false
            }
        } else {
            Write-Error "Failed to list ECR repositories"
            $tests["ECR Repositories"] = $false
        }
    } catch {
        Write-Error "Failed to check ECR repositories: $_"
        $tests["ECR Repositories"] = $false
    }
    
    return $tests
}

function Test-DomainConfiguration {
    Write-Header "Testing Domain Configuration"
    
    $tests = @{}
    
    # Test DNS resolution
    Write-Info "Testing DNS resolution for $FullDomain"
    try {
        $dnsResult = Resolve-DnsName -Name $FullDomain -ErrorAction SilentlyContinue
        if ($dnsResult) {
            Write-Success "DNS resolution successful for $FullDomain"
            $tests["DNS Resolution"] = $true
        } else {
            Write-Warning "DNS resolution failed for $FullDomain (this is expected if not yet deployed)"
            $tests["DNS Resolution"] = $false
        }
    } catch {
        Write-Warning "DNS resolution test failed: $_"
        $tests["DNS Resolution"] = $false
    }
    
    # Test HTTP access (if domain resolves)
    if ($tests["DNS Resolution"]) {
        Write-Info "Testing HTTP access to $FullDomain"
        try {
            $response = Invoke-WebRequest -Uri "http://$FullDomain" -TimeoutSec 10 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "HTTP access successful"
                $tests["HTTP Access"] = $true
            } elseif ($response.StatusCode -eq 301 -or $response.StatusCode -eq 302) {
                Write-Success "HTTP redirect detected (likely HTTPS redirect)"
                $tests["HTTP Access"] = $true
            } else {
                Write-Warning "HTTP access returned status: $($response.StatusCode)"
                $tests["HTTP Access"] = $false
            }
        } catch {
            Write-Warning "HTTP access failed: $_"
            $tests["HTTP Access"] = $false
        }
        
        # Test HTTPS access
        Write-Info "Testing HTTPS access to $FullDomain"
        try {
            $response = Invoke-WebRequest -Uri "https://$FullDomain" -TimeoutSec 10 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Success "HTTPS access successful"
                $tests["HTTPS Access"] = $true
            } else {
                Write-Warning "HTTPS access returned status: $($response.StatusCode)"
                $tests["HTTPS Access"] = $false
            }
        } catch {
            Write-Warning "HTTPS access failed: $_"
            $tests["HTTPS Access"] = $false
        }
    } else {
        Write-Info "Skipping HTTP/HTTPS tests - domain does not resolve"
        $tests["HTTP Access"] = $null
        $tests["HTTPS Access"] = $null
    }
    
    return $tests
}

function Show-TestResults {
    param($AllResults)
    
    Write-Host "`n" + "="*80 -ForegroundColor Blue
    Write-Host "COMPREHENSIVE TEST RESULTS SUMMARY" -ForegroundColor Blue
    Write-Host "="*80 -ForegroundColor Blue
    Write-Host "Domain: $FullDomain" -ForegroundColor Cyan
    Write-Host "AWS Region: $AwsRegion" -ForegroundColor Cyan
    Write-Host ""
    
    $totalTests = 0
    $passedTests = 0
    $skippedTests = 0
    
    foreach ($category in $AllResults.GetEnumerator()) {
        Write-Host "$($category.Key):" -ForegroundColor Yellow
        foreach ($test in $category.Value.GetEnumerator()) {
            $totalTests++
            if ($test.Value -eq $true) {
                Write-Success "  $($test.Key): PASSED"
                $passedTests++
            } elseif ($test.Value -eq $false) {
                Write-Error "  $($test.Key): FAILED"
            } else {
                Write-Warning "  $($test.Key): SKIPPED"
                $skippedTests++
            }
        }
        Write-Host ""
    }
    
    Write-Host "Overall Results:" -ForegroundColor Blue
    Write-Host "  Passed: $passedTests" -ForegroundColor Green
    Write-Host "  Failed: $($totalTests - $passedTests - $skippedTests)" -ForegroundColor Red
    Write-Host "  Skipped: $skippedTests" -ForegroundColor Yellow
    Write-Host "  Total: $totalTests" -ForegroundColor Cyan
    
    if ($passedTests -eq ($totalTests - $skippedTests)) {
        Write-Success "`nAll available tests passed! Domain configuration is ready for deployment."
    } else {
        Write-Warning "`nSome tests failed. Please review the issues above before deployment."
    }
}

# Main execution
Write-Host "Sedaro Nano Enhanced Validation Suite" -ForegroundColor Blue
Write-Host "====================================" -ForegroundColor Blue
Write-Host "Test Mode: $TestMode" -ForegroundColor Cyan
Write-Host "Domain: $FullDomain" -ForegroundColor Cyan
Write-Host "AWS Region: $AwsRegion" -ForegroundColor Cyan

$allResults = @{}

# Check prerequisites
$prerequisites = Test-Prerequisites
$allResults["Prerequisites"] = $prerequisites

# Run tests based on mode
switch ($TestMode) {
    'template' {
        if ($prerequisites["Helm"]) {
            $allResults["Helm Templates"] = Test-HelmTemplates
        }
    }
    'aws' {
        if ($prerequisites["AWS CLI"]) {
            $allResults["AWS Resources"] = Test-AwsResources
        }
    }
    'domain' {
        $allResults["Domain Configuration"] = Test-DomainConfiguration
    }
    'full' {
        if ($prerequisites["Helm"]) {
            $allResults["Helm Templates"] = Test-HelmTemplates
        }
        if ($prerequisites["AWS CLI"]) {
            $allResults["AWS Resources"] = Test-AwsResources
        }
        $allResults["Domain Configuration"] = Test-DomainConfiguration
    }
}

Show-TestResults $allResults

# Set exit code based on results
$failedCategories = 0
foreach ($category in $allResults.GetEnumerator()) {
    if ($category.Key -eq "Prerequisites") { continue }
    $categoryFailed = $false
    foreach ($test in $category.Value.GetEnumerator()) {
        if ($test.Value -eq $false) {
            $categoryFailed = $true
            break
        }
    }
    if ($categoryFailed) { $failedCategories++ }
}

exit $failedCategories
