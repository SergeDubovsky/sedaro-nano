# Connect to the GitHub OIDC endpoint
$tcpClient = New-Object System.Net.Sockets.TcpClient
$tcpClient.Connect("token.actions.githubusercontent.com", 443)
$sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, ({ $true }))

# Start SSL handshake
$sslStream.AuthenticateAsClient("token.actions.githubusercontent.com")

# Get the full certificate chain
$certChain = $sslStream.RemoteCertificate
$cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certChain

# Get the root certificate (last in chain)
$chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
$chain.Build($cert2) | Out-Null
$rootCert = $chain.ChainElements[-1].Certificate

# Get SHA1 thumbprint of the root certificate
$thumbprint = $rootCert.GetCertHashString()

# Output
Write-Host "OIDC Thumbprint (SHA1): $thumbprint"
