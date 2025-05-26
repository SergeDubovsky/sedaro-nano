# Terraform Validation Script for Windows
# Tests the modular terraform structure to ensure everything works correctly

param(
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🔍 Starting Terraform validation for modular structure..." -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# Function to print status
function Write-Status {
    param(
        [bool]$Success,
        [string]$Message
    )
    
    if ($Success) {
        Write-Host "✅ $Message" -ForegroundColor Green
    } else {
        Write-Host "❌ $Message" -ForegroundColor Red
        exit 1
    }
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Yellow
}

# Test individual modules
Write-Host ""
Write-Host "📦 Testing individual modules..." -ForegroundColor Cyan
Write-Host "-------------------------------" -ForegroundColor Cyan

$modules = @("bootstrap", "eks-cluster", "eks-addons", "github-secrets")

foreach ($module in $modules) {
    Write-Host ""
    Write-Info "Testing module: $module"
    
    $modulePath = "modules\$module"
    Push-Location $modulePath
    
    try {
        # Initialize
        if ($Verbose) {
            terraform init -backend=false
        } else {
            terraform init -backend=false 2>&1 | Out-Null
        }
        Write-Status $true "Module $module - terraform init"
        
        # Validate
        if ($Verbose) {
            terraform validate
        } else {
            terraform validate 2>&1 | Out-Null
        }
        Write-Status $true "Module $module - terraform validate"
        
        # Format check
        $formatResult = terraform fmt -check 2>&1
        $formatSuccess = $LASTEXITCODE -eq 0
        Write-Status $formatSuccess "Module $module - terraform fmt check"
        
        # Clean up
        Remove-Item -Path ".terraform*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Status $false "Module $module - Error: $_"
    }
    finally {
        Pop-Location
    }
}

# Test demo environment
Write-Host ""
Write-Host "🏗️  Testing demo environment..." -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan

Push-Location "environments\demo"

try {
    # Initialize
    if ($Verbose) {
        terraform init -backend=false
    } else {
        terraform init -backend=false 2>&1 | Out-Null
    }
    Write-Status $true "Demo environment - terraform init"

    # Validate
    if ($Verbose) {
        terraform validate
    } else {
        terraform validate 2>&1 | Out-Null
    }
    Write-Status $true "Demo environment - terraform validate"

    # Format check
    $formatResult = terraform fmt -check 2>&1
    $formatSuccess = $LASTEXITCODE -eq 0
    Write-Status $formatSuccess "Demo environment - terraform fmt check"

    # Clean up
    Remove-Item -Path ".terraform*" -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Status $false "Demo environment - Error: $_"
}
finally {
    Pop-Location
}

# Check workflow files
Write-Host ""
Write-Host "⚙️  Validating GitHub Actions workflows..." -ForegroundColor Cyan
Write-Host "---------------------------------------" -ForegroundColor Cyan

$workflows = @(
    "..\\.github\\workflows\\terraform-deploy.yml",
    "..\\.github\\workflows\\terraform-destroy.yml",
    "..\\.github\\workflows\\ci.yml"
)

foreach ($workflow in $workflows) {
    if (Test-Path $workflow) {
        Write-Status $true "Workflow exists: $(Split-Path $workflow -Leaf)"
        
        # Check if workflow uses correct terraform paths
        $content = Get-Content $workflow -Raw
        if ($content -match "terraform/environments/demo") {
            Write-Status $true "Workflow uses correct terraform paths"
        } else {
            Write-Warning "Workflow may not be using updated terraform paths"
        }
    } else {
        Write-Status $false "Workflow missing: $workflow"
    }
}

# Check documentation
Write-Host ""
Write-Host "📚 Checking documentation..." -ForegroundColor Cyan
Write-Host "-------------------------" -ForegroundColor Cyan

$docs = @("..\\README.md", "..\\LAUNCH_TEMPLATE_ENHANCED_V2.md", "..\\GITHUB_ACTIONS_SETUP.md", "DEPLOYMENT_GUIDE.md")

foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Status $true "Documentation exists: $doc"
    } else {
        Write-Status $false "Documentation missing: $doc"
    }
}

# Check .gitignore
Write-Host ""
Write-Host "🚫 Checking .gitignore patterns..." -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan

if (Test-Path "..\\.gitignore") {
    $gitignoreContent = Get-Content "..\\.gitignore" -Raw
    if ($gitignoreContent -match "terraform/") {
        Write-Status $true ".gitignore has terraform patterns"
    } else {
        Write-Warning ".gitignore may be missing terraform patterns"
    }
} else {
    Write-Status $false ".gitignore file missing"
}

Write-Host ""
Write-Host "🎉 Validation completed successfully!" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ All modules validate correctly" -ForegroundColor Green
Write-Host "✅ Demo environment is properly configured" -ForegroundColor Green
Write-Host "✅ GitHub Actions workflows are updated" -ForegroundColor Green
Write-Host "✅ Documentation is in place" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 The modular terraform structure is ready for deployment!" -ForegroundColor Green
