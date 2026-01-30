# NCC Security Access Control Module
# Implements RBAC, MFA, and authentication for Security 10 Directive

# Access Control Configuration
$AccessControlConfig = @{
    RBACEnabled = $true
    MFARequired = $true
    SessionTimeout = 3600
    MaxLoginAttempts = 3
    LockoutDuration = 900  # 15 minutes
    PasswordPolicy = @{
        MinLength = 12
        RequireUppercase = $true
        RequireLowercase = $true
        RequireNumbers = $true
        RequireSpecialChars = $true
        MaxAge = 90  # days
    }
}

# Role definitions
$SecurityRoles = @{
    "SystemAdmin" = @{
        Permissions = @("FullSystemAccess", "SecurityAdmin", "UserManagement", "AuditRead", "AuditWrite")
        Level = 100
        Description = "Full system administration access"
    }
    "SecurityOfficer" = @{
        Permissions = @("SecurityAdmin", "AuditRead", "AuditWrite", "IncidentResponse", "ComplianceRead")
        Level = 80
        Description = "Security operations and compliance"
    }
    "AgentOperator" = @{
        Permissions = @("AgentManagement", "ReadOnly", "BasicAudit")
        Level = 50
        Description = "Standard agent operations"
    }
    "Auditor" = @{
        Permissions = @("AuditRead", "ComplianceRead", "ReportGeneration")
        Level = 30
        Description = "Audit and compliance monitoring"
    }
    "Guest" = @{
        Permissions = @("ReadOnly")
        Level = 10
        Description = "Limited read-only access"
    }
}

# Active sessions
$ActiveSessions = @{}

function Initialize-AgentSecurity {
    param([string]$AgentName)

    Write-SecurityLog "Initializing security for agent: $AgentName" -Component "AccessControl"

    # Register agent with security system
    Register-Agent -AgentName $AgentName

    # Initialize local security policies
    Initialize-LocalSecurity

    Write-SecurityLog "Security initialization completed for $AgentName" -Level "SUCCESS" -Component "AccessControl"
}

function Register-Agent {
    param([string]$AgentName)

    $agentRecord = @{
        Name = $AgentName
        Registered = Get-Date
        Role = "AgentOperator"
        Status = "Active"
        LastActivity = Get-Date
        SecurityLevel = 50
    }

    # Store agent record (in production, this would be in a secure database)
    $agentsPath = Join-Path $PSScriptRoot "..\data\registered_agents.json"
    $agents = @()
    if (Test-Path $agentsPath) {
        $agents = Get-Content $agentsPath | ConvertFrom-Json
    }
    $agents = $agents | Where-Object { $_.Name -ne $AgentName }
    $agents += $agentRecord
    $agents | ConvertTo-Json -Depth 10 | Out-File $agentsPath -Encoding UTF8
}

function Initialize-LocalSecurity {
    # Set up local security policies
    try {
        # Configure PowerShell execution policy for security
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -ErrorAction SilentlyContinue

        # Initialize secure logging
        $logPath = Join-Path $PSScriptRoot "..\logs\security_events.log"
        if (-not (Test-Path $logPath)) {
            New-Item -ItemType File -Path $logPath -Force | Out-Null
        }
    }
    catch {
        Write-SecurityLog "Failed to initialize local security: $($_.Exception.Message)" -Level "ERROR" -Component "AccessControl"
    }
}

function Authenticate-User {
    param(
        [string]$Username,
        [string]$Password,
        [string]$MFAToken = $null,
        [string]$AgentName = $null
    )

    Write-SecurityLog "Authentication attempt for user: $Username" -Component "AccessControl"

    # Validate credentials (simplified for demo)
    if (-not $Username -or -not $Password) {
        Write-SecurityLog "Authentication failed: Missing credentials" -Level "WARNING" -Component "AccessControl"
        return $false
    }

    # Check MFA if required
    if ($AccessControlConfig.MFARequired -and -not $MFAToken) {
        Write-SecurityLog "Authentication failed: MFA required but not provided" -Level "WARNING" -Component "AccessControl"
        return $false
    }

    # Validate MFA token (simplified)
    if ($AccessControlConfig.MFARequired) {
        if (-not (Test-MFAToken -Token $MFAToken)) {
            Write-SecurityLog "Authentication failed: Invalid MFA token" -Level "WARNING" -Component "AccessControl"
            return $false
        }
    }

    # Create session
    $sessionId = New-Guid
    $session = @{
        SessionId = $sessionId
        Username = $Username
        AgentName = $AgentName
        Created = Get-Date
        LastActivity = Get-Date
        Expires = (Get-Date).AddSeconds($AccessControlConfig.SessionTimeout)
        IPAddress = $env:COMPUTERNAME  # Simplified
    }

    $ActiveSessions[$sessionId] = $session

    Write-SecurityLog "Authentication successful for user: $Username" -Level "SUCCESS" -Component "AccessControl"
    return $sessionId
}

function Authorize-Action {
    param(
        [string]$SessionId,
        [string]$Action,
        [string]$Resource = $null
    )

    # Validate session
    if (-not (Test-Session -SessionId $SessionId)) {
        Write-SecurityLog "Authorization failed: Invalid session" -Level "WARNING" -Component "AccessControl"
        return $false
    }

    $session = $ActiveSessions[$SessionId]
    $userRole = Get-UserRole -Username $session.Username

    # Check permissions
    $rolePermissions = $SecurityRoles[$userRole].Permissions

    if ($rolePermissions -contains $Action -or $rolePermissions -contains "FullSystemAccess") {
        Write-SecurityLog "Authorization granted for action: $Action" -Level "SUCCESS" -Component "AccessControl"
        return $true
    }

    Write-SecurityLog "Authorization denied for action: $Action (insufficient permissions)" -Level "WARNING" -Component "AccessControl"
    return $false
}

function Test-Session {
    param([string]$SessionId)

    if (-not $ActiveSessions.ContainsKey($SessionId)) {
        return $false
    }

    $session = $ActiveSessions[$SessionId]

    # Check expiration
    if ((Get-Date) -gt $session.Expires) {
        $ActiveSessions.Remove($SessionId)
        Write-SecurityLog "Session expired: $SessionId" -Level "INFO" -Component "AccessControl"
        return $false
    }

    # Update last activity
    $session.LastActivity = Get-Date
    $session.Expires = (Get-Date).AddSeconds($AccessControlConfig.SessionTimeout)

    return $true
}

function Get-UserRole {
    param([string]$Username)

    # Simplified role lookup (in production, this would query a user database)
    switch -Regex ($Username) {
        "admin|system" { return "SystemAdmin" }
        "security|sec" { return "SecurityOfficer" }
        "audit" { return "Auditor" }
        default { return "AgentOperator" }
    }
}

function Test-MFAToken {
    param([string]$Token)

    # Simplified MFA validation (in production, this would validate TOTP or similar)
    return $Token -match '^\d{6}$'
}

function Get-SecurityHealth {
    $health = @{
        ActiveSessions = $ActiveSessions.Count
        FailedAuthAttempts = 0  # Would track in production
        SecurityEvents = 0
        LastSecurityScan = Get-Date
        OverallHealth = "Good"
    }

    return $health
}

function Write-SecurityLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Component = "AccessControl")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [ACCESS] [$Component] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch($Level){"ERROR"{"Red"}"WARNING"{"Yellow"}"SUCCESS"{"Green"}default{"Cyan"}})

    # Log to file
    $logPath = Join-Path $PSScriptRoot "..\logs\access_control.log"
    $logMessage | Out-File $logPath -Append -Encoding UTF8
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-AgentSecurity',
    'Authenticate-User',
    'Authorize-Action',
    'Test-Session',
    'Get-SecurityHealth',
    'Write-SecurityLog'
)