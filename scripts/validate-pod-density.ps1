# Pod Density Validation Script
# Run this after GitHub Actions deployment to verify the optimization worked

Write-Host "🔍 Validating Pod Density Optimization..." -ForegroundColor Cyan

# Check if kubectl is available
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl not found. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Update kubeconfig
Write-Host "📋 Updating kubeconfig..." -ForegroundColor Yellow
aws eks update-kubeconfig --region us-east-1 --name sedaro-nano-demo

# Check node capacity
Write-Host "`n📊 Checking node pod capacity..." -ForegroundColor Yellow
kubectl get nodes -o custom-columns="NAME:.metadata.name,PODS:.status.capacity.pods" --no-headers

# Check VPC CNI environment variables
Write-Host "`n🔧 Checking VPC CNI configuration..." -ForegroundColor Yellow
$cniEnv = kubectl get daemonset aws-node -n kube-system -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="ENABLE_PREFIX_DELEGATION")].value}'
if ($cniEnv -eq "true") {
    Write-Host "✅ Prefix delegation is enabled" -ForegroundColor Green
} else {
    Write-Host "❌ Prefix delegation is NOT enabled" -ForegroundColor Red
}

# Check CNI warm targets
$warmPrefix = kubectl get daemonset aws-node -n kube-system -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="WARM_PREFIX_TARGET")].value}'
$warmIP = kubectl get daemonset aws-node -n kube-system -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="WARM_IP_TARGET")].value}'

Write-Host "📝 CNI Configuration:" -ForegroundColor Yellow
Write-Host "   WARM_PREFIX_TARGET: $warmPrefix" -ForegroundColor White
Write-Host "   WARM_IP_TARGET: $warmIP" -ForegroundColor White

# Check current pod allocation
Write-Host "`n📋 Current pod allocation by node:" -ForegroundColor Yellow
kubectl get pods -A -o wide --no-headers | Group-Object { ($_ -split '\s+')[7] } | ForEach-Object {
    $nodeName = $_.Name
    $podCount = $_.Count
    Write-Host "   $nodeName : $podCount pods" -ForegroundColor White
}

# Success summary
$nodeCapacities = kubectl get nodes -o jsonpath='{.items[*].status.capacity.pods}' | ForEach-Object { $_ -split ' ' }
$maxCapacity = ($nodeCapacities | Measure-Object -Maximum).Maximum

Write-Host "`n🎯 Optimization Summary:" -ForegroundColor Green
if ($maxCapacity -gt 50) {
    Write-Host "✅ Pod density optimization successful!" -ForegroundColor Green
    Write-Host "✅ Maximum pod capacity: $maxCapacity (target: 110+ for m6g.large)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Pod capacity still low: $maxCapacity" -ForegroundColor Yellow
    Write-Host "💡 Node replacement may be required for changes to take effect" -ForegroundColor Yellow
}

Write-Host "`n📚 To manually cycle nodes if needed:" -ForegroundColor Cyan
Write-Host "   kubectl get nodes" -ForegroundColor Gray
Write-Host "   kubectl cordon <node-name>" -ForegroundColor Gray
Write-Host "   kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data --force" -ForegroundColor Gray
Write-Host "   # Then terminate the EC2 instance - ASG will create a new one" -ForegroundColor Gray
