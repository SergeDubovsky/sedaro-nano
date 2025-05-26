#!/bin/bash
# Terraform Validation Script
# Tests the modular terraform structure to ensure everything works correctly

set -e

echo "🔍 Starting Terraform validation for modular structure..."
echo "==============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Test individual modules
echo ""
echo "📦 Testing individual modules..."
echo "-------------------------------"

MODULES=("bootstrap" "eks-cluster" "eks-addons" "github-secrets")

for module in "${MODULES[@]}"; do
    echo ""
    print_info "Testing module: $module"
    
    cd "terraform/modules/$module"
    
    # Initialize
    terraform init -backend=false > /dev/null 2>&1
    print_status $? "Module $module - terraform init"
    
    # Validate
    terraform validate > /dev/null 2>&1
    print_status $? "Module $module - terraform validate"
    
    # Format check
    terraform fmt -check > /dev/null 2>&1
    print_status $? "Module $module - terraform fmt check"
    
    # Clean up
    rm -rf .terraform* > /dev/null 2>&1
    
    cd ../../..
done

# Test demo environment
echo ""
echo "🏗️  Testing demo environment..."
echo "-----------------------------"

cd "terraform/environments/demo"

# Initialize
terraform init -backend=false > /dev/null 2>&1
print_status $? "Demo environment - terraform init"

# Validate
terraform validate > /dev/null 2>&1
print_status $? "Demo environment - terraform validate"

# Format check
terraform fmt -check > /dev/null 2>&1
print_status $? "Demo environment - terraform fmt check"

# Clean up
rm -rf .terraform* > /dev/null 2>&1

cd ../../..

# Check workflow files
echo ""
echo "⚙️  Validating GitHub Actions workflows..."
echo "---------------------------------------"

WORKFLOWS=(".github/workflows/terraform-deploy.yml" ".github/workflows/terraform-destroy.yml" ".github/workflows/ci.yml")

for workflow in "${WORKFLOWS[@]}"; do
    if [ -f "$workflow" ]; then
        print_status 0 "Workflow exists: $(basename $workflow)"
        
        # Check if workflow uses correct terraform paths
        if grep -q "terraform/environments/demo" "$workflow"; then
            print_status 0 "Workflow uses correct terraform paths"
        else
            print_warning "Workflow may not be using updated terraform paths"
        fi
    else
        print_status 1 "Workflow missing: $workflow"
    fi
done

# Check documentation
echo ""
echo "📚 Checking documentation..."
echo "-------------------------"

DOCS=("TERRAFORM_MIGRATION.md" "TERRAFORM_CLEANUP_PLAN.md" "README.md")

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        print_status 0 "Documentation exists: $doc"
    else
        print_status 1 "Documentation missing: $doc"
    fi
done

# Check .gitignore
echo ""
echo "🚫 Checking .gitignore patterns..."
echo "--------------------------------"

if [ -f ".gitignore" ]; then
    if grep -q "terraform/" ".gitignore"; then
        print_status 0 ".gitignore has terraform patterns"
    else
        print_warning ".gitignore may be missing terraform patterns"
    fi
else
    print_status 1 ".gitignore file missing"
fi

echo ""
echo "🎉 Validation completed successfully!"
echo "=================================="
echo ""
echo "✅ All modules validate correctly"
echo "✅ Demo environment is properly configured"
echo "✅ GitHub Actions workflows are updated"
echo "✅ Documentation is in place"
echo ""
echo "🚀 The modular terraform structure is ready for deployment!"
