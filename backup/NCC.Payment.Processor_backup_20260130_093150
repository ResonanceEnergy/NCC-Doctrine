param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("ProcessPayment", "Refund", "GetPaymentStatus", "ListPayments", "SetupWebhook", "Test", "Initialize", "Status")]
    [string]$Action = "Status",

    [Parameter(Mandatory=$false)]
    [string]$PaymentMethod = "Stripe",  # Stripe, PayPal, Square, Authorize.Net

    [Parameter(Mandatory=$false)]
    [decimal]$Amount = 0,

    [Parameter(Mandatory=$false)]
    [string]$Currency = "USD",

    [Parameter(Mandatory=$false)]
    [string]$CustomerEmail = "",

    [Parameter(Mandatory=$false)]
    [string]$Description = "",

    [Parameter(Mandatory=$false)]
    [string]$PaymentId = "",

    [Parameter(Mandatory=$false)]
    [string]$RefundReason = "",

    [Parameter(Mandatory=$false)]
    [int]$Limit = 10,

    [Parameter(Mandatory=$false)]
    [string]$LogFile = "$PSScriptRoot\logs\payment_processor.log"
)

# =============================================================================
# NCC PAYMENT PROCESSOR INTEGRATION
# Version: 1.0.0 | Classification: TOP SECRET
# Date: 2026-01-29 | Authority: AZ PRIME Command
# =============================================================================

$ScriptVersion = "1.0.0"
$SystemName = "NCC Payment Processor Integration"

# Configuration for different payment processors
$Config = @{
    Stripe = @{
        APIKey = $env:STRIPE_SECRET_KEY
        PublishableKey = $env:STRIPE_PUBLISHABLE_KEY
        APIBaseUrl = "https://api.stripe.com/v1"
        WebhookSecret = $env:STRIPE_WEBHOOK_SECRET
        Status = "Active"
    }
    PayPal = @{
        ClientId = $env:PAYPAL_CLIENT_ID
        ClientSecret = $env:PAYPAL_CLIENT_SECRET
        APIBaseUrl = "https://api.paypal.com/v1"
        Environment = "live"  # or "sandbox"
        Status = "Active"
    }
    Square = @{
        AccessToken = $env:SQUARE_ACCESS_TOKEN
        ApplicationId = $env:SQUARE_APPLICATION_ID
        APIBaseUrl = "https://connect.squareup.com/v2"
        Environment = "production"  # or "sandbox"
        Status = "Active"
    }
    AuthorizeNet = @{
        APIKey = $env:AUTHORIZENET_API_KEY
        TransactionKey = $env:AUTHORIZENET_TRANSACTION_KEY
        APIBaseUrl = "https://api.authorize.net/xml/v1/request.api"
        Status = "Active"
    }
    Security = @{
        EncryptionKey = "ncc-payment-enc-key-2026"
        APITimeout = 30
        RetryAttempts = 3
        RateLimitDelay = 1
    }
    Monitoring = @{
        SuccessRateThreshold = 95  # Alert if success rate drops below this
        ResponseTimeThreshold = 5000  # Alert if response time exceeds this (ms)
        HealthCheckInterval = 300  # 5 minutes
    }
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

function Write-PaymentLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "CRITICAL", "SUCCESS", "PAYMENT", "REFUND")]
        [string]$Level = "INFO",
        [string]$Component = "PaymentProcessor"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] [$Component] $Message"

    # Write to console with color coding
    switch ($Level) {
        "CRITICAL" { Write-Host $LogEntry -ForegroundColor Red -BackgroundColor White }
        "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
        "PAYMENT" { Write-Host $LogEntry -ForegroundColor Magenta }
        "REFUND" { Write-Host $LogEntry -ForegroundColor DarkMagenta }
        "INFO" { Write-Host $LogEntry -ForegroundColor Cyan }
    }

    # Write to log file
    try {
        $LogEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
    } catch {
        Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# =============================================================================
# API COMMUNICATION FUNCTIONS
# =============================================================================

function Invoke-PaymentAPI {
    param(
        [string]$Processor,
        [string]$Endpoint,
        [string]$Method = "POST",
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [hashtable]$QueryParams = @{}
    )

    $processorConfig = $Config.$Processor
    if (-not $processorConfig) {
        Write-PaymentLog "Payment processor not found: $Processor" -Level "ERROR"
        return $null
    }

    if ($processorConfig.Status -ne "Active") {
        Write-PaymentLog "Payment processor is not active: $Processor" -Level "WARNING"
        return $null
    }

    # Build URL
    $url = "$($processorConfig.APIBaseUrl)$Endpoint"

    # Add query parameters
    if ($QueryParams.Count -gt 0) {
        $queryString = ($QueryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" }) -join "&"
        $url += "?$queryString"
    }

    # Prepare headers based on processor
    $headers = @{}
    switch ($Processor) {
        "Stripe" {
            $headers["Authorization"] = "Bearer $($processorConfig.APIKey)"
            $headers["Content-Type"] = "application/x-www-form-urlencoded"
        }
        "PayPal" {
            $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($processorConfig.ClientId):$($processorConfig.ClientSecret)"))
            $headers["Authorization"] = "Basic $auth"
            $headers["Content-Type"] = "application/json"
        }
        "Square" {
            $headers["Authorization"] = "Bearer $($processorConfig.AccessToken)"
            $headers["Content-Type"] = "application/json"
            $headers["Square-Version"] = "2023-12-13"
        }
        "AuthorizeNet" {
            $headers["Content-Type"] = "application/json"
        }
    }

    # Add any additional headers
    foreach ($key in $Headers.Keys) {
        $headers[$key] = $Headers[$key]
    }

    Write-PaymentLog "Making API call to $Processor - $Method $url" -Level "INFO"

    $retryCount = 0
    do {
        try {
            $params = @{
                Uri = $url
                Method = $Method
                Headers = $headers
                TimeoutSec = $Config.Security.APITimeout
            }

            if ($Body) {
                if ($Processor -eq "Stripe") {
                    # Stripe uses form encoding
                    $params.Body = $Body
                } else {
                    # Others use JSON
                    $params.Body = ($Body | ConvertTo-Json -Depth 10)
                    $params.ContentType = "application/json"
                }
            }

            $response = Invoke-RestMethod @params

            Write-PaymentLog "API call successful for $Processor" -Level "SUCCESS"
            return $response

        } catch {
            $retryCount++
            Write-PaymentLog "API call failed for $Processor (attempt $retryCount): $($_.Exception.Message)" -Level "WARNING"

            if ($retryCount -lt $Config.Security.RetryAttempts) {
                Start-Sleep -Seconds $Config.Security.RateLimitDelay
            }
        }
    } while ($retryCount -lt $Config.Security.RetryAttempts)

    Write-PaymentLog "API call failed after $retryCount attempts for $Processor" -Level "ERROR"
    return $null
}

# =============================================================================
# PAYMENT PROCESSING FUNCTIONS
# =============================================================================

function New-Payment {
    param(
        [string]$Processor,
        [decimal]$Amount,
        [string]$Currency,
        [string]$CustomerEmail,
        [string]$Description,
        [hashtable]$Metadata = @{}
    )

    Write-PaymentLog "Processing payment: $Amount $Currency for $CustomerEmail" -Level "PAYMENT"

    $paymentData = $null
    $endpoint = ""

    switch ($Processor) {
        "Stripe" {
            $endpoint = "/payment_intents"
            $paymentData = @{
                amount = [int]($Amount * 100)  # Convert to cents
                currency = $Currency.ToLower()
                receipt_email = $CustomerEmail
                description = $Description
                metadata = $Metadata
            }
        }
        "PayPal" {
            $endpoint = "/payments/payment"
            $paymentData = @{
                intent = "sale"
                payer = @{
                    payment_method = "paypal"
                }
                transactions = @(
                    @{
                        amount = @{
                            total = $Amount.ToString("F2")
                            currency = $Currency
                        }
                        description = $Description
                    }
                )
                redirect_urls = @{
                    return_url = "https://ncc.corp/payment/success"
                    cancel_url = "https://ncc.corp/payment/cancel"
                }
            }
        }
        "Square" {
            $endpoint = "/payments"
            $paymentData = @{
                amount_money = @{
                    amount = [int]($Amount * 100)
                    currency = $Currency
                }
                note = $Description
                reference_id = "NCC-$(Get-Date -Format 'yyyyMMddHHmmss')"
            }
        }
        "AuthorizeNet" {
            $endpoint = "/createTransactionRequest"
            $paymentData = @{
                createTransactionRequest = @{
                    merchantAuthentication = @{
                        name = $Config.AuthorizeNet.APIKey
                        transactionKey = $Config.AuthorizeNet.TransactionKey
                    }
                    transactionRequest = @{
                        transactionType = "authCaptureTransaction"
                        amount = $Amount.ToString("F2")
                        payment = @{
                            creditCard = @{
                                cardNumber = "4111111111111111"  # Test card - in production, this would come from frontend
                                expirationDate = "2025-12"
                                cardCode = "123"
                            }
                        }
                        billTo = @{
                            email = $CustomerEmail
                        }
                    }
                }
            }
        }
    }

    $response = Invoke-PaymentAPI -Processor $Processor -Endpoint $endpoint -Method "POST" -Body $paymentData

    if ($response) {
        $payment = @{
            Processor = $Processor
            PaymentId = switch ($Processor) {
                "Stripe" { $response.id }
                "PayPal" { $response.id }
                "Square" { $response.payment.id }
                "AuthorizeNet" { $response.transactionResponse.transId }
            }
            Amount = $Amount
            Currency = $Currency
            Status = switch ($Processor) {
                "Stripe" { $response.status }
                "PayPal" { $response.state }
                "Square" { $response.payment.status }
                "AuthorizeNet" { if ($response.messages.resultCode -eq "Ok") { "approved" } else { "declined" } }
            }
            CustomerEmail = $CustomerEmail
            Description = $Description
            Timestamp = Get-Date
        }

        Write-PaymentLog "Payment processed: $($payment.PaymentId) - Status: $($payment.Status)" -Level "SUCCESS"
        return $payment
    }

    return $null
}

function New-Refund {
    param(
        [string]$Processor,
        [string]$PaymentId,
        [decimal]$Amount = 0,
        [string]$Reason = ""
    )

    Write-PaymentLog "Processing refund for payment $PaymentId (amount: $Amount)" -Level "REFUND"

    $refundData = $null
    $endpoint = ""

    switch ($Processor) {
        "Stripe" {
            $endpoint = "/refunds"
            $refundData = @{
                payment_intent = $PaymentId
                amount = if ($Amount -gt 0) { [int]($Amount * 100) } else { $null }
                reason = $Reason
            }
        }
        "PayPal" {
            $endpoint = "/payments/sale/$PaymentId/refund"
            $refundData = @{
                amount = @{
                    total = if ($Amount -gt 0) { $Amount.ToString("F2") } else { $null }
                    currency = "USD"
                }
            }
        }
        "Square" {
            $endpoint = "/refunds"
            $refundData = @{
                payment_id = $PaymentId
                amount_money = if ($Amount -gt 0) {
                    @{
                        amount = [int]($Amount * 100)
                        currency = "USD"
                    }
                } else { $null }
                reason = $Reason
            }
        }
        "AuthorizeNet" {
            $endpoint = "/createTransactionRequest"
            $refundData = @{
                createTransactionRequest = @{
                    merchantAuthentication = @{
                        name = $Config.AuthorizeNet.APIKey
                        transactionKey = $Config.AuthorizeNet.TransactionKey
                    }
                    transactionRequest = @{
                        transactionType = "refundTransaction"
                        amount = if ($Amount -gt 0) { $Amount.ToString("F2") } else { $null }
                        refTransId = $PaymentId
                    }
                }
            }
        }
    }

    $response = Invoke-PaymentAPI -Processor $Processor -Endpoint $endpoint -Method "POST" -Body $refundData

    if ($response) {
        $refund = @{
            Processor = $Processor
            RefundId = switch ($Processor) {
                "Stripe" { $response.id }
                "PayPal" { $response.id }
                "Square" { $response.refund.id }
                "AuthorizeNet" { $response.transactionResponse.transId }
            }
            PaymentId = $PaymentId
            Amount = $Amount
            Reason = $Reason
            Status = switch ($Processor) {
                "Stripe" { $response.status }
                "PayPal" { $response.state }
                "Square" { $response.refund.status }
                "AuthorizeNet" { if ($response.messages.resultCode -eq "Ok") { "approved" } else { "declined" } }
            }
            Timestamp = Get-Date
        }

        Write-PaymentLog "Refund processed: $($refund.RefundId) - Status: $($refund.Status)" -Level "SUCCESS"
        return $refund
    }

    return $null
}

function Get-PaymentStatus {
    param([string]$Processor, [string]$PaymentId)

    Write-PaymentLog "Checking payment status for $PaymentId" -Level "INFO"

    $endpoint = switch ($Processor) {
        "Stripe" { "/payment_intents/$PaymentId" }
        "PayPal" { "/payments/payment/$PaymentId" }
        "Square" { "/payments/$PaymentId" }
        "AuthorizeNet" { "/getTransactionDetailsRequest" }
    }

    $response = Invoke-PaymentAPI -Processor $Processor -Endpoint $endpoint -Method "GET"

    if ($response) {
        $status = @{
            Processor = $Processor
            PaymentId = $PaymentId
            Status = switch ($Processor) {
                "Stripe" { $response.status }
                "PayPal" { $response.state }
                "Square" { $response.status }
                "AuthorizeNet" { $response.transaction.status }
            }
            Amount = switch ($Processor) {
                "Stripe" { $response.amount / 100 }
                "PayPal" { [decimal]$response.transactions[0].amount.total }
                "Square" { $response.amount_money.amount / 100 }
                "AuthorizeNet" { [decimal]$response.transaction.authAmount }
            }
            Timestamp = Get-Date
        }

        return $status
    }

    return $null
}

function Get-PaymentList {
    param([string]$Processor, [int]$Limit = 10)

    Write-PaymentLog "Retrieving payment list (limit: $Limit)" -Level "INFO"

    $endpoint = switch ($Processor) {
        "Stripe" { "/payment_intents" }
        "PayPal" { "/payments/payment" }
        "Square" { "/payments" }
        "AuthorizeNet" { "/getTransactionListRequest" }
    }

    $queryParams = @{ limit = $Limit }

    $response = Invoke-PaymentAPI -Processor $Processor -Endpoint $endpoint -Method "GET" -QueryParams $queryParams

    if ($response) {
        $payments = @()
        $paymentList = switch ($Processor) {
            "Stripe" { $response.data }
            "PayPal" { $response.payments }
            "Square" { $response.payments }
            "AuthorizeNet" { $response.transactions }
        }

        foreach ($payment in $paymentList) {
            $payments += @{
                Processor = $Processor
                PaymentId = switch ($Processor) {
                    "Stripe" { $payment.id }
                    "PayPal" { $payment.id }
                    "Square" { $payment.id }
                    "AuthorizeNet" { $payment.transId }
                }
                Amount = switch ($Processor) {
                    "Stripe" { $payment.amount / 100 }
                    "PayPal" { [decimal]$payment.transactions[0].amount.total }
                    "Square" { $payment.amount_money.amount / 100 }
                    "AuthorizeNet" { [decimal]$payment.authAmount }
                }
                Status = switch ($Processor) {
                    "Stripe" { $payment.status }
                    "PayPal" { $payment.state }
                    "Square" { $payment.status }
                    "AuthorizeNet" { $payment.status }
                }
                Created = switch ($Processor) {
                    "Stripe" { [DateTime]::FromUnixTimeSeconds($payment.created) }
                    "PayPal" { [DateTime]::Parse($payment.create_time) }
                    "Square" { [DateTime]::Parse($payment.created_at) }
                    "AuthorizeNet" { [DateTime]::Parse($payment.submitTimeLocal) }
                }
            }
        }

        Write-PaymentLog "Retrieved $($payments.Count) payments" -Level "SUCCESS"
        return $payments
    }

    return @()
}

# =============================================================================
# WEBHOOK MANAGEMENT
# =============================================================================

function Register-PaymentWebhook {
    param([string]$Processor, [string]$WebhookUrl)

    Write-PaymentLog "Registering webhook for $Processor at $WebhookUrl" -Level "INFO"

    $webhookData = $null
    $endpoint = ""

    switch ($Processor) {
        "Stripe" {
            $endpoint = "/webhook_endpoints"
            $webhookData = @{
                url = $WebhookUrl
                enabled_events = @(
                    "payment_intent.succeeded",
                    "payment_intent.payment_failed",
                    "charge.dispute.created",
                    "refund.created"
                )
            }
        }
        "PayPal" {
            # PayPal webhooks are configured in the dashboard
            Write-PaymentLog "PayPal webhooks must be configured in the PayPal dashboard" -Level "WARNING"
            return $null
        }
        "Square" {
            $endpoint = "/webhooks"
            $webhookData = @{
                name = "NCC Payment Webhook"
                url = $WebhookUrl
                events = @(
                    "payment.created",
                    "payment.updated",
                    "refund.created",
                    "refund.updated"
                )
            }
        }
        "AuthorizeNet" {
            # Authorize.Net webhooks are configured in the merchant interface
            Write-PaymentLog "Authorize.Net webhooks must be configured in the merchant interface" -Level "WARNING"
            return $null
        }
    }

    if ($webhookData) {
        $response = Invoke-PaymentAPI -Processor $Processor -Endpoint $endpoint -Method "POST" -Body $webhookData

        if ($response) {
            Write-PaymentLog "Webhook registered successfully for $Processor" -Level "SUCCESS"
            return $response
        }
    }

    return $null
}

# =============================================================================
# MONITORING FUNCTIONS
# =============================================================================

function Get-PaymentProcessorHealth {
    $health = @{
        Timestamp = Get-Date
        Processors = @()
        OverallHealth = "Healthy"
        ActiveProcessors = 0
        TotalProcessors = ($Config.Keys | Where-Object { $_ -ne "Security" -and $_ -ne "Monitoring" }).Count
    }

    foreach ($processor in ($Config.Keys | Where-Object { $_ -ne "Security" -and $_ -ne "Monitoring" })) {
        $processorHealth = @{
            Name = $processor
            Status = $Config.$processor.Status
            APIHealth = "Unknown"
            LastCheck = Get-Date
        }

        # Test API connectivity (simplified health check)
        try {
            $testResponse = switch ($processor) {
                "Stripe" { Invoke-PaymentAPI -Processor $processor -Endpoint "/balance" -Method "GET" }
                "PayPal" { Invoke-PaymentAPI -Processor $processor -Endpoint "/payments/payment" -Method "GET" -QueryParams @{ count = 1 } }
                "Square" { Invoke-PaymentAPI -Processor $processor -Endpoint "/locations" -Method "GET" }
                "AuthorizeNet" { Invoke-PaymentAPI -Processor $processor -Endpoint "/getMerchantDetails" -Method "POST" -Body @{ getMerchantDetailsRequest = @{ merchantAuthentication = @{ name = $Config.AuthorizeNet.APIKey; transactionKey = $Config.AuthorizeNet.TransactionKey } } } }
            }

            if ($testResponse) {
                $processorHealth.APIHealth = "Healthy"
                $health.ActiveProcessors++
            } else {
                $processorHealth.APIHealth = "Degraded"
                $health.OverallHealth = "Degraded"
            }
        } catch {
            $processorHealth.APIHealth = "Failed"
            $health.OverallHealth = "Degraded"
        }

        $health.Processors += $processorHealth
    }

    return $health
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

Write-PaymentLog "=== $SystemName v$ScriptVersion ===" -Level "INFO"
Write-PaymentLog "Action: $Action, Processor: $PaymentMethod" -Level "INFO"

switch ($Action) {
    "Initialize" {
        Write-PaymentLog "Initializing payment processor integration..." -Level "INFO"

        # Create necessary directories
        $dirs = @("logs", "config", "reports", "backups", "data\payments", "data\refunds", "data\webhooks")
        foreach ($dir in $dirs) {
            if (-not (Test-Path "$PSScriptRoot\$dir")) {
                New-Item -ItemType Directory -Path "$PSScriptRoot\$dir" -Force | Out-Null
            }
        }

        # Create configuration file
        $Config | ConvertTo-Json -Depth 10 | Out-File "$PSScriptRoot\config\payment_config.json" -Encoding UTF8

        Write-PaymentLog "Payment processor integration initialized successfully" -Level "SUCCESS"
    }

    "ProcessPayment" {
        if ($Amount -le 0 -or -not $CustomerEmail) {
            Write-PaymentLog "Amount and customer email are required" -Level "ERROR"
            exit 1
        }

        $payment = New-Payment -Processor $PaymentMethod -Amount $Amount -Currency $Currency -CustomerEmail $CustomerEmail -Description $Description
        if ($payment) {
            Write-Host "Payment processed successfully: $($payment.PaymentId)" -ForegroundColor Green
            Write-Host "Status: $($payment.Status)" -ForegroundColor White
            Write-Host "Amount: $($payment.Amount) $($payment.Currency)" -ForegroundColor White
        } else {
            Write-Host "Payment processing failed" -ForegroundColor Red
        }
    }

    "Refund" {
        if (-not $PaymentId) {
            Write-PaymentLog "Payment ID is required for refund" -Level "ERROR"
            exit 1
        }

        $refund = New-Refund -Processor $PaymentMethod -PaymentId $PaymentId -Amount $Amount -Reason $RefundReason
        if ($refund) {
            Write-Host "Refund processed successfully: $($refund.RefundId)" -ForegroundColor Green
            Write-Host "Status: $($refund.Status)" -ForegroundColor White
            Write-Host "Amount: $($refund.Amount)" -ForegroundColor White
        } else {
            Write-Host "Refund processing failed" -ForegroundColor Red
        }
    }

    "GetPaymentStatus" {
        if (-not $PaymentId) {
            Write-PaymentLog "Payment ID is required" -Level "ERROR"
            exit 1
        }

        $status = Get-PaymentStatus -Processor $PaymentMethod -PaymentId $PaymentId
        if ($status) {
            Write-Host "Payment Status: $($status.Status)" -ForegroundColor Green
            Write-Host "Amount: $($status.Amount) $($Currency)" -ForegroundColor White
            Write-Host "Last Updated: $($status.Timestamp)" -ForegroundColor White
        } else {
            Write-Host "Failed to retrieve payment status" -ForegroundColor Red
        }
    }

    "ListPayments" {
        $payments = Get-PaymentList -Processor $PaymentMethod -Limit $Limit
        if ($payments.Count -gt 0) {
            Write-Host "Recent Payments:" -ForegroundColor Green
            foreach ($payment in $payments) {
                Write-Host "  $($payment.PaymentId): $($payment.Amount) $($Currency) - $($payment.Status) ($($payment.Created))" -ForegroundColor White
            }
        } else {
            Write-Host "No payments found" -ForegroundColor Yellow
        }
    }

    "SetupWebhook" {
        $webhookUrl = "https://ncc.corp/api/webhooks/payments"  # Default webhook URL
        $result = Register-PaymentWebhook -Processor $PaymentMethod -WebhookUrl $webhookUrl
        if ($result) {
            Write-Host "Webhook registered successfully" -ForegroundColor Green
        } else {
            Write-Host "Webhook registration failed" -ForegroundColor Red
        }
    }

    "Test" {
        Write-PaymentLog "Running payment processor tests" -Level "INFO"

        # Test processor connections
        $connectionTests = 0
        $successfulConnections = 0

        foreach ($processor in ($Config.Keys | Where-Object { $_ -ne "Security" -and $_ -ne "Monitoring" })) {
            if ($Config.$processor.Status -eq "Active") {
                $connectionTests++
                $testResult = switch ($processor) {
                    "Stripe" { Invoke-PaymentAPI -Processor $processor -Endpoint "/balance" -Method "GET" }
                    "PayPal" { Invoke-PaymentAPI -Processor $processor -Endpoint "/payments/payment" -Method "GET" -QueryParams @{ count = 1 } }
                    "Square" { Invoke-PaymentAPI -Processor $processor -Endpoint "/locations" -Method "GET" }
                    "AuthorizeNet" { Invoke-PaymentAPI -Processor $processor -Endpoint "/getMerchantDetails" -Method "POST" -Body @{ getMerchantDetailsRequest = @{ merchantAuthentication = @{ name = $Config.AuthorizeNet.APIKey; transactionKey = $Config.AuthorizeNet.TransactionKey } } } }
                }

                if ($testResult) {
                    $successfulConnections++
                    Write-Host "✓ $processor connection test passed" -ForegroundColor Green
                } else {
                    Write-Host "✗ $processor connection test failed" -ForegroundColor Red
                }
            }
        }

        Write-PaymentLog "Connection tests: $successfulConnections/$connectionTests passed" -Level $(if ($successfulConnections -eq $connectionTests) { "SUCCESS" } else { "WARNING" })
    }

    "Status" {
        $health = Get-PaymentProcessorHealth

        Write-Host "`n=== $SystemName Status ===" -ForegroundColor Cyan
        Write-Host "Version: $ScriptVersion" -ForegroundColor White
        Write-Host "Timestamp: $($health.Timestamp)" -ForegroundColor White
        Write-Host "Overall Health: $($health.OverallHealth)" -ForegroundColor $(if ($health.OverallHealth -eq "Healthy") { "Green" } else { "Red" })
        Write-Host "Active Processors: $($health.ActiveProcessors)/$($health.TotalProcessors)" -ForegroundColor $(if ($health.ActiveProcessors -eq $health.TotalProcessors) { "Green" } else { "Yellow" })
        Write-Host ""

        Write-Host "Processor Status:" -ForegroundColor Yellow
        foreach ($processor in $health.Processors) {
            $color = switch ($processor.APIHealth) {
                "Healthy" { "Green" }
                "Degraded" { "Yellow" }
                "Failed" { "Red" }
                default { "Gray" }
            }
            Write-Host "  $($processor.Name): $($processor.APIHealth) ($($processor.Status))" -ForegroundColor $color
        }

        Write-Host "`nLog File: $LogFile" -ForegroundColor White
        Write-Host ""
    }
}

Write-PaymentLog "Command completed: $Action" -Level "INFO"