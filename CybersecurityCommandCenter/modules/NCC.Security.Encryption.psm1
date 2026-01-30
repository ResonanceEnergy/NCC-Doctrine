# NCC Security Encryption Module
# Implements AES-256 encryption and certificate management for Security 10 Directive

# Encryption Configuration
$EncryptionConfig = @{
    Algorithm = "AES"
    KeySize = 256
    HashAlgorithm = "SHA256"
    KeyRotationDays = 90
    CertificateValidityDays = 365
    SecureDeletePasses = 3
}

# Certificate store
$CertificateStore = @{}

function Initialize-Encryption {
    param([string]$AgentName)

    Write-SecurityLog "Initializing encryption framework for agent: $AgentName" -Component "Encryption"

    # Generate agent-specific keys
    Generate-AgentKeys -AgentName $AgentName

    # Initialize certificate
    Generate-AgentCertificate -AgentName $AgentName

    Write-SecurityLog "Encryption initialization completed for $AgentName" -Level "SUCCESS" -Component "Encryption"
}

function Generate-AgentKeys {
    param([string]$AgentName)

    Write-SecurityLog "Generating encryption keys for $AgentName" -Component "Encryption"

    try {
        # Generate AES-256 key
        $aesKey = New-Object byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($aesKey)

        # Generate RSA key pair for signing
        $rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider(2048)
        $rsaKeyXml = $rsa.ToXmlString($true)

        # Store keys securely
        $keyDir = Join-Path $PSScriptRoot "..\keys"
        if (-not (Test-Path $keyDir)) { New-Item -ItemType Directory -Path $keyDir -Force | Out-Null }

        $aesKeyPath = Join-Path $keyDir "$AgentName`_aes.key"
        [Convert]::ToBase64String($aesKey) | Out-File $aesKeyPath -Encoding UTF8

        $rsaKeyPath = Join-Path $keyDir "$AgentName`_rsa.xml"
        $rsaKeyXml | Out-File $rsaKeyPath -Encoding UTF8

        Write-SecurityLog "Keys generated and stored for $AgentName" -Level "SUCCESS" -Component "Encryption"
    }
    catch {
        Write-SecurityLog "Failed to generate keys for $AgentName: $($_.Exception.Message)" -Level "ERROR" -Component "Encryption"
        throw
    }
}

function Generate-AgentCertificate {
    param([string]$AgentName)

    Write-SecurityLog "Generating certificate for $AgentName" -Component "Encryption"

    try {
        # Create self-signed certificate (in production, this would be from CA)
        $certParams = @{
            Subject = "CN=$AgentName, O=Nathan Command Corp, OU=Agents"
            KeyLength = 2048
            KeyAlgorithm = "RSA"
            HashAlgorithm = "SHA256"
            KeyUsage = "DigitalSignature", "KeyEncipherment"
            EnhancedKeyUsage = "Client Authentication", "Server Authentication"
            NotBefore = Get-Date
            NotAfter = (Get-Date).AddDays($EncryptionConfig.CertificateValidityDays)
            FriendlyName = "NCC Agent Certificate - $AgentName"
        }

        # Store certificate info
        $certInfo = @{
            Subject = $certParams.Subject
            Issued = Get-Date
            Expires = $certParams.NotAfter
            Status = "Active"
            Thumbprint = "SIMULATED_" + [Guid]::NewGuid().ToString().Replace("-", "").Substring(0, 16).ToUpper()
        }

        $CertificateStore[$AgentName] = $certInfo

        # Save certificate store
        $certPath = Join-Path $PSScriptRoot "..\certificates\agent_certificates.json"
        $CertificateStore | ConvertTo-Json -Depth 10 | Out-File $certPath -Encoding UTF8

        Write-SecurityLog "Certificate generated for $AgentName" -Level "SUCCESS" -Component "Encryption"
    }
    catch {
        Write-SecurityLog "Failed to generate certificate for $AgentName: $($_.Exception.Message)" -Level "ERROR" -Component "Encryption"
    }
}

function Encrypt-Data {
    param(
        [string]$Data,
        [string]$Key = $null,
        [string]$AgentName = $null
    )

    if (-not $Key -and $AgentName) {
        $Key = Get-AgentKey -AgentName $AgentName
    }

    if (-not $Key) {
        throw "No encryption key available"
    }

    try {
        $aes = [Security.Cryptography.Aes]::Create()
        $aes.KeySize = $EncryptionConfig.KeySize
        $aes.Key = [Convert]::FromBase64String($Key)
        $aes.GenerateIV()

        $encryptor = $aes.CreateEncryptor()
        $dataBytes = [System.Text.Encoding]::UTF8.GetBytes($Data)
        $encryptedBytes = $encryptor.TransformFinalBlock($dataBytes, 0, $dataBytes.Length)

        # Combine IV and encrypted data
        $result = $aes.IV + $encryptedBytes
        $encryptedString = [Convert]::ToBase64String($result)

        Write-SecurityLog "Data encrypted successfully" -Level "SUCCESS" -Component "Encryption"
        return $encryptedString
    }
    catch {
        Write-SecurityLog "Encryption failed: $($_.Exception.Message)" -Level "ERROR" -Component "Encryption"
        throw
    }
}

function Decrypt-Data {
    param(
        [string]$EncryptedData,
        [string]$Key = $null,
        [string]$AgentName = $null
    )

    if (-not $Key -and $AgentName) {
        $Key = Get-AgentKey -AgentName $AgentName
    }

    if (-not $Key) {
        throw "No decryption key available"
    }

    try {
        $encryptedBytes = [Convert]::FromBase64String($EncryptedData)
        $aes = [Security.Cryptography.Aes]::Create()
        $aes.KeySize = $EncryptionConfig.KeySize
        $aes.Key = [Convert]::FromBase64String($Key)

        # Extract IV (first 16 bytes for AES)
        $aes.IV = $encryptedBytes[0..15]
        $encryptedContent = $encryptedBytes[16..($encryptedBytes.Length - 1)]

        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($encryptedContent, 0, $encryptedContent.Length)
        $decryptedString = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

        Write-SecurityLog "Data decrypted successfully" -Level "SUCCESS" -Component "Encryption"
        return $decryptedString
    }
    catch {
        Write-SecurityLog "Decryption failed: $($_.Exception.Message)" -Level "ERROR" -Component "Encryption"
        throw
    }
}

function Get-AgentKey {
    param([string]$AgentName)

    $keyPath = Join-Path $PSScriptRoot "..\keys\$AgentName`_aes.key"
    if (Test-Path $keyPath) {
        return Get-Content $keyPath -Raw
    }

    Write-SecurityLog "No key found for agent: $AgentName" -Level "WARNING" -Component "Encryption"
    return $null
}

function Rotate-Keys {
    param([string]$AgentName = "All")

    Write-SecurityLog "Starting key rotation for $AgentName" -Component "Encryption"

    if ($AgentName -eq "All") {
        # Get all agents
        $agentsPath = Join-Path $PSScriptRoot "..\data\registered_agents.json"
        if (Test-Path $agentsPath) {
            $agents = Get-Content $agentsPath | ConvertFrom-Json
            foreach ($agent in $agents) {
                Rotate-AgentKeys -AgentName $agent.Name
            }
        }
    } else {
        Rotate-AgentKeys -AgentName $AgentName
    }

    Write-SecurityLog "Key rotation completed" -Level "SUCCESS" -Component "Encryption"
}

function Rotate-AgentKeys {
    param([string]$AgentName)

    # Backup old keys
    $keyDir = Join-Path $PSScriptRoot "..\keys"
    $backupDir = Join-Path $keyDir "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    $oldAesKey = Join-Path $keyDir "$AgentName`_aes.key"
    $oldRsaKey = Join-Path $keyDir "$AgentName`_rsa.xml"

    if (Test-Path $oldAesKey) { Copy-Item $oldAesKey $backupDir }
    if (Test-Path $oldRsaKey) { Copy-Item $oldRsaKey $backupDir }

    # Generate new keys
    Generate-AgentKeys -AgentName $AgentName

    Write-SecurityLog "Keys rotated for agent: $AgentName" -Level "SUCCESS" -Component "Encryption"
}

function Secure-Delete {
    param([string]$FilePath, [int]$Passes = $EncryptionConfig.SecureDeletePasses)

    if (-not (Test-Path $FilePath)) { return }

    Write-SecurityLog "Securely deleting file: $FilePath" -Component "Encryption"

    try {
        $fileInfo = Get-Item $FilePath
        $fileSize = $fileInfo.Length

        # Overwrite file multiple times
        for ($pass = 1; $pass -le $Passes; $pass++) {
            $randomData = New-Object byte[] $fileSize
            [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($randomData)
            [System.IO.File]::WriteAllBytes($FilePath, $randomData)
        }

        # Finally delete the file
        Remove-Item $FilePath -Force

        Write-SecurityLog "File securely deleted: $FilePath" -Level "SUCCESS" -Component "Encryption"
    }
    catch {
        Write-SecurityLog "Failed to securely delete file: $($_.Exception.Message)" -Level "ERROR" -Component "Encryption"
    }
}

function Get-EncryptionHealth {
    $health = @{
        TotalKeys = 0
        ExpiredCertificates = 0
        KeysRotatedToday = 0
        LastKeyRotation = Get-Date
        EncryptionStatus = "Healthy"
    }

    # Count keys
    $keyDir = Join-Path $PSScriptRoot "..\keys"
    if (Test-Path $keyDir) {
        $health.TotalKeys = (Get-ChildItem $keyDir -Filter "*.key").Count
    }

    # Check certificates
    $certPath = Join-Path $PSScriptRoot "..\certificates\agent_certificates.json"
    if (Test-Path $certPath) {
        $certs = Get-Content $certPath | ConvertFrom-Json
        foreach ($cert in $certs.Values) {
            if ((Get-Date) -gt $cert.Expires) {
                $health.ExpiredCertificates++
            }
        }
    }

    return $health
}

function Write-SecurityLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "Encryption")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [ENCRYPT] [$Component] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch($Level){"ERROR"{"Red"}"WARNING"{"Yellow"}"SUCCESS"{"Green"}default{"Cyan"}})

    # Log to file
    $logPath = Join-Path $PSScriptRoot "..\logs\encryption.log"
    $logMessage | Out-File $logPath -Append -Encoding UTF8
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-Encryption',
    'Encrypt-Data',
    'Decrypt-Data',
    'Rotate-Keys',
    'Secure-Delete',
    'Get-EncryptionHealth',
    'Write-SecurityLog'
)