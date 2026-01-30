param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("GetPortfolio", "BuyAsset", "SellAsset", "GetAssetPrice", "GetMarketData", "CreatePortfolio", "Rebalance", "Monitor", "Test", "Initialize", "Status")]
    [string]$Action = "Status",

    [Parameter(Mandatory=$false)]
    [string]$PortfolioId = "",

    [Parameter(Mandatory=$false)]
    [string]$AssetSymbol = "",

    [Parameter(Mandatory=$false)]
    [decimal]$Quantity = 0,

    [Parameter(Mandatory=$false)]
    [decimal]$Price = 0,

    [Parameter(Mandatory=$false)]
    [string]$AssetType = "stock",  # stock, crypto, bond, etf, mutual_fund

    [Parameter(Mandatory=$false)]
    [string]$Exchange = "NYSE",  # NYSE, NASDAQ, CRYPTO, etc.

    [Parameter(Mandatory=$false)]
    [string]$Provider = "Alpaca",  # Alpaca, Interactive Brokers, TD Ameritrade, Robinhood

    [Parameter(Mandatory=$false)]
    [int]$MonitorInterval = 300,  # 5 minutes

    [Parameter(Mandatory=$false)]
    [string]$LogFile = "$PSScriptRoot\logs\asset_management.log"
)

# =============================================================================
# NCC ASSET MANAGEMENT INTEGRATION
# Version: 1.0.0 | Classification: TOP SECRET
# Date: 2026-01-29 | Authority: AZ PRIME Command
# =============================================================================

$ScriptVersion = "1.0.0"
$SystemName = "NCC Asset Management Integration"

# Configuration for different asset management providers
$Config = @{
    Alpaca = @{
        APIKey = $env:ALPACA_API_KEY
        APISecret = $env:ALPACA_API_SECRET
        BaseUrl = "https://api.alpaca.markets"
        DataUrl = "https://data.alpaca.markets"
        Environment = "live"  # or "paper"
        Status = "Active"
    }
    InteractiveBrokers = @{
        APIKey = $env:IB_API_KEY
        APISecret = $env:IB_API_SECRET
        BaseUrl = "https://api.ibkr.com"
        Status = "Active"
    }
    TDAmeritrade = @{
        APIKey = $env:TD_API_KEY
        APISecret = $env:TD_API_SECRET
        BaseUrl = "https://api.tdameritrade.com"
        RefreshToken = $env:TD_REFRESH_TOKEN
        Status = "Active"
    }
    Robinhood = @{
        Username = $env:ROBINHOOD_USERNAME
        Password = $env:ROBINHOOD_PASSWORD
        BaseUrl = "https://api.robinhood.com"
        Status = "Active"
    }
    Security = @{
        EncryptionKey = "ncc-asset-enc-key-2026"
        APITimeout = 30
        RetryAttempts = 3
        RateLimitDelay = 1
    }
    Monitoring = @{
        PortfolioValueThreshold = 100000  # Alert if portfolio value drops below this
        LossThreshold = -5000  # Alert for losses exceeding this
        HealthCheckInterval = 300  # 5 minutes
    }
    RiskManagement = @{
        MaxPositionSize = 0.1  # Max 10% of portfolio in single asset
        MaxDrawdown = 0.2  # Max 20% drawdown before alerts
        DiversificationMin = 5  # Minimum number of different assets
    }
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

function Write-AssetLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "CRITICAL", "SUCCESS", "TRADE", "PORTFOLIO")]
        [string]$Level = "INFO",
        [string]$Component = "AssetManagement"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] [$Component] $Message"

    # Write to console with color coding
    switch ($Level) {
        "CRITICAL" { Write-Host $LogEntry -ForegroundColor Red -BackgroundColor White }
        "ERROR" { Write-Host $LogEntry -ForegroundColor Red }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
        "TRADE" { Write-Host $LogEntry -ForegroundColor Magenta }
        "PORTFOLIO" { Write-Host $LogEntry -ForegroundColor DarkCyan }
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

function Invoke-AssetAPI {
    param(
        [string]$Provider,
        [string]$Endpoint,
        [string]$Method = "GET",
        [hashtable]$Headers = @{},
        [object]$Body = $null,
        [hashtable]$QueryParams = @{}
    )

    $providerConfig = $Config.$Provider
    if (-not $providerConfig) {
        Write-AssetLog "Asset provider not found: $Provider" -Level "ERROR"
        return $null
    }

    if ($providerConfig.Status -ne "Active") {
        Write-AssetLog "Asset provider is not active: $Provider" -Level "WARNING"
        return $null
    }

    # Build URL
    $url = "$($providerConfig.BaseUrl)$Endpoint"

    # Add query parameters
    if ($QueryParams.Count -gt 0) {
        $queryString = ($QueryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" }) -join "&"
        $url += "?$queryString"
    }

    # Prepare headers based on provider
    $headers = @{}
    switch ($Provider) {
        "Alpaca" {
            $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($providerConfig.APIKey):$($providerConfig.APISecret)"))
            $headers["Authorization"] = "Basic $auth"
            $headers["Content-Type"] = "application/json"
        }
        "InteractiveBrokers" {
            $headers["Authorization"] = "Bearer $($providerConfig.APIKey)"
            $headers["Content-Type"] = "application/json"
        }
        "TDAmeritrade" {
            $headers["Authorization"] = "Bearer $($providerConfig.APIKey)"
            $headers["Content-Type"] = "application/json"
        }
        "Robinhood" {
            # Robinhood uses token-based auth after login
            $headers["Content-Type"] = "application/json"
        }
    }

    # Add any additional headers
    foreach ($key in $Headers.Keys) {
        $headers[$key] = $Headers[$key]
    }

    Write-AssetLog "Making API call to $Provider - $Method $url" -Level "INFO"

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
                $params.Body = ($Body | ConvertTo-Json -Depth 10)
            }

            $response = Invoke-RestMethod @params

            Write-AssetLog "API call successful for $Provider" -Level "SUCCESS"
            return $response

        } catch {
            $retryCount++
            Write-AssetLog "API call failed for $Provider (attempt $retryCount): $($_.Exception.Message)" -Level "WARNING"

            if ($retryCount -lt $Config.Security.RetryAttempts) {
                Start-Sleep -Seconds $Config.Security.RateLimitDelay
            }
        }
    } while ($retryCount -lt $Config.Security.RetryAttempts)

    Write-AssetLog "API call failed after $retryCount attempts for $Provider" -Level "ERROR"
    return $null
}

# =============================================================================
# PORTFOLIO MANAGEMENT FUNCTIONS
# =============================================================================

function Get-Portfolio {
    param([string]$Provider, [string]$PortfolioId = "default")

    Write-AssetLog "Retrieving portfolio $PortfolioId from $Provider" -Level "PORTFOLIO"

    $endpoint = switch ($Provider) {
        "Alpaca" { "/v2/positions" }
        "InteractiveBrokers" { "/portfolio/accounts/$PortfolioId/positions" }
        "TDAmeritrade" { "/v1/accounts/$PortfolioId" }
        "Robinhood" { "/accounts/$PortfolioId/positions" }
    }

    $response = Invoke-AssetAPI -Provider $Provider -Endpoint $endpoint -Method "GET"

    if ($response) {
        $portfolio = @{
            Provider = $Provider
            PortfolioId = $PortfolioId
            Positions = @()
            TotalValue = 0
            Timestamp = Get-Date
        }

        $positions = switch ($Provider) {
            "Alpaca" { $response }
            "InteractiveBrokers" { $response.positions }
            "TDAmeritrade" { $response.positions }
            "Robinhood" { $response.results }
        }

        foreach ($position in $positions) {
            $pos = @{
                Symbol = switch ($Provider) {
                    "Alpaca" { $position.symbol }
                    "InteractiveBrokers" { $position.contract.symbol }
                    "TDAmeritrade" { $position.instrument.symbol }
                    "Robinhood" { $position.instrument.symbol }
                }
                Quantity = switch ($Provider) {
                    "Alpaca" { [decimal]$position.qty }
                    "InteractiveBrokers" { [decimal]$position.position }
                    "TDAmeritrade" { [decimal]$position.longQuantity }
                    "Robinhood" { [decimal]$position.quantity }
                }
                AveragePrice = switch ($Provider) {
                    "Alpaca" { [decimal]$position.avg_entry_price }
                    "InteractiveBrokers" { [decimal]$position.avgCost }
                    "TDAmeritrade" { [decimal]$position.averagePrice }
                    "Robinhood" { [decimal]$position.average_buy_price }
                }
                CurrentPrice = switch ($Provider) {
                    "Alpaca" { [decimal]$position.current_price }
                    "InteractiveBrokers" { [decimal]$position.marketPrice }
                    "TDAmeritrade" { [decimal]$position.marketValue / [decimal]$position.longQuantity }
                    "Robinhood" { [decimal]$position.last_trade_price }
                }
                MarketValue = switch ($Provider) {
                    "Alpaca" { [decimal]$position.market_value }
                    "InteractiveBrokers" { [decimal]$position.marketValue }
                    "TDAmeritrade" { [decimal]$position.marketValue }
                    "Robinhood" { [decimal]$position.quantity * [decimal]$position.last_trade_price }
                }
                UnrealizedPL = switch ($Provider) {
                    "Alpaca" { [decimal]$position.unrealized_pl }
                    "InteractiveBrokers" { [decimal]$position.unrealizedPnL }
                    "TDAmeritrade" { [decimal]$position.longOpenPnL }
                    "Robinhood" { [decimal]$position.quantity * ([decimal]$position.last_trade_price - [decimal]$position.average_buy_price) }
                }
            }

            $portfolio.Positions += $pos
            $portfolio.TotalValue += $pos.MarketValue
        }

        Write-AssetLog "Portfolio retrieved: $($portfolio.Positions.Count) positions, total value: $($portfolio.TotalValue)" -Level "SUCCESS"
        return $portfolio
    }

    return $null
}

function New-AssetOrder {
    param(
        [string]$Provider,
        [string]$Symbol,
        [string]$Side,  # buy, sell
        [decimal]$Quantity,
        [string]$OrderType = "market",  # market, limit, stop
        [decimal]$Price = 0
    )

    Write-AssetLog "Placing $Side order for $Quantity shares of $Symbol" -Level "TRADE"

    $orderData = $null
    $endpoint = ""

    switch ($Provider) {
        "Alpaca" {
            $endpoint = "/v2/orders"
            $orderData = @{
                symbol = $Symbol
                qty = $Quantity.ToString()
                side = $Side
                type = $OrderType
                time_in_force = "day"
            }
            if ($OrderType -eq "limit" -and $Price -gt 0) {
                $orderData.limit_price = $Price.ToString()
            }
        }
        "InteractiveBrokers" {
            $endpoint = "/v1/orders"
            $orderData = @{
                symbol = $Symbol
                quantity = $Quantity
                side = $Side
                type = $OrderType
            }
            if ($OrderType -eq "limit" -and $Price -gt 0) {
                $orderData.price = $Price
            }
        }
        "TDAmeritrade" {
            $endpoint = "/v1/accounts/$PortfolioId/orders"
            $orderData = @{
                orderType = $OrderType
                session = "NORMAL"
                duration = "DAY"
                orderStrategyType = "SINGLE"
                orderLegCollection = @(
                    @{
                        instruction = if ($Side -eq "buy") { "BUY" } else { "SELL" }
                        quantity = $Quantity
                        instrument = @{
                            symbol = $Symbol
                            assetType = "EQUITY"
                        }
                    }
                )
            }
            if ($OrderType -eq "limit" -and $Price -gt 0) {
                $orderData.price = $Price.ToString()
            }
        }
        "Robinhood" {
            $endpoint = "/orders/"
            $orderData = @{
                symbol = $Symbol
                quantity = $Quantity
                side = $Side
                type = $OrderType
                time_in_force = "gfd"  # good for day
            }
            if ($OrderType -eq "limit" -and $Price -gt 0) {
                $orderData.price = $Price.ToString()
            }
        }
    }

    $response = Invoke-AssetAPI -Provider $Provider -Endpoint $endpoint -Method "POST" -Body $orderData

    if ($response) {
        $order = @{
            Provider = $Provider
            OrderId = switch ($Provider) {
                "Alpaca" { $response.id }
                "InteractiveBrokers" { $response.orderId }
                "TDAmeritrade" { $response.orderId }
                "Robinhood" { $response.id }
            }
            Symbol = $Symbol
            Side = $Side
            Quantity = $Quantity
            OrderType = $OrderType
            Price = $Price
            Status = switch ($Provider) {
                "Alpaca" { $response.status }
                "InteractiveBrokers" { $response.status }
                "TDAmeritrade" { $response.status }
                "Robinhood" { $response.state }
            }
            Timestamp = Get-Date
        }

        Write-AssetLog "Order placed: $($order.OrderId) - Status: $($order.Status)" -Level "SUCCESS"
        return $order
    }

    return $null
}

function Get-AssetPrice {
    param([string]$Provider, [string]$Symbol)

    Write-AssetLog "Retrieving price for $Symbol from $Provider" -Level "INFO"

    $endpoint = switch ($Provider) {
        "Alpaca" { "/v2/stocks/$Symbol/quotes/latest" }
        "InteractiveBrokers" { "/v1/markets/quotes?symbols=$Symbol" }
        "TDAmeritrade" { "/v1/marketdata/$Symbol/quotes" }
        "Robinhood" { "/quotes/?symbols=$Symbol" }
    }

    $response = Invoke-AssetAPI -Provider $Provider -Endpoint $endpoint -Method "GET"

    if ($response) {
        $price = @{
            Provider = $Provider
            Symbol = $Symbol
            Price = switch ($Provider) {
                "Alpaca" { [decimal]$response.quote.ap }
                "InteractiveBrokers" { [decimal]$response.$Symbol.last }
                "TDAmeritrade" { [decimal]$response.$Symbol.lastPrice }
                "Robinhood" { [decimal]$response.results[0].last_trade_price }
            }
            Change = switch ($Provider) {
                "Alpaca" { [decimal]$response.quote.c }
                "InteractiveBrokers" { [decimal]$response.$Symbol.change }
                "TDAmeritrade" { [decimal]$response.$Symbol.netChange }
                "Robinhood" { [decimal]$response.results[0].last_trade_price - [decimal]$response.results[0].previous_close }
            }
            Volume = switch ($Provider) {
                "Alpaca" { [int]$response.quote.v }
                "InteractiveBrokers" { [int]$response.$Symbol.volume }
                "TDAmeritrade" { [int]$response.$Symbol.totalVolume }
                "Robinhood" { [int]$response.results[0].volume }
            }
            Timestamp = Get-Date
        }

        Write-AssetLog "Price retrieved: $Symbol = $($price.Price)" -Level "SUCCESS"
        return $price
    }

    return $null
}

function Get-MarketData {
    param([string]$Provider, [string]$Symbol, [string]$Timeframe = "1D", [int]$Limit = 100)

    Write-AssetLog "Retrieving market data for $Symbol ($Timeframe, limit: $Limit)" -Level "INFO"

    $endpoint = switch ($Provider) {
        "Alpaca" { "/v2/stocks/$Symbol/bars?timeframe=$Timeframe&limit=$Limit" }
        "InteractiveBrokers" { "/v1/historical/$Symbol/bars?period=1D&bar=1min" }
        "TDAmeritrade" { "/v1/marketdata/$Symbol/pricehistory?periodType=day&period=1&frequencyType=minute&frequency=1" }
        "Robinhood" { "/marketdata/historicals/$Symbol/?interval=$Timeframe" }
    }

    $response = Invoke-AssetAPI -Provider $Provider -Endpoint $endpoint -Method "GET"

    if ($response) {
        $marketData = @{
            Provider = $Provider
            Symbol = $Symbol
            Timeframe = $Timeframe
            Bars = @()
            Timestamp = Get-Date
        }

        $bars = switch ($Provider) {
            "Alpaca" { $response.bars }
            "InteractiveBrokers" { $response.bars }
            "TDAmeritrade" { $response.candles }
            "Robinhood" { $response.historicals }
        }

        foreach ($bar in $bars) {
            $marketData.Bars += @{
                Timestamp = switch ($Provider) {
                    "Alpaca" { [DateTime]::Parse($bar.t) }
                    "InteractiveBrokers" { [DateTime]::FromUnixTimeSeconds($bar.time) }
                    "TDAmeritrade" { [DateTime]::FromUnixTimeMilliseconds($bar.datetime) }
                    "Robinhood" { [DateTime]::Parse($bar.begins_at) }
                }
                Open = switch ($Provider) {
                    "Alpaca" { [decimal]$bar.o }
                    "InteractiveBrokers" { [decimal]$bar.o }
                    "TDAmeritrade" { [decimal]$bar.open }
                    "Robinhood" { [decimal]$bar.open_price }
                }
                High = switch ($Provider) {
                    "Alpaca" { [decimal]$bar.h }
                    "InteractiveBrokers" { [decimal]$bar.h }
                    "TDAmeritrade" { [decimal]$bar.high }
                    "Robinhood" { [decimal]$bar.high_price }
                }
                Low = switch ($Provider) {
                    "Alpaca" { [decimal]$bar.l }
                    "InteractiveBrokers" { [decimal]$bar.l }
                    "TDAmeritrade" { [decimal]$bar.low }
                    "Robinhood" { [decimal]$bar.low_price }
                }
                Close = switch ($Provider) {
                    "Alpaca" { [decimal]$bar.c }
                    "InteractiveBrokers" { [decimal]$bar.c }
                    "TDAmeritrade" { [decimal]$bar.close }
                    "Robinhood" { [decimal]$bar.close_price }
                }
                Volume = switch ($Provider) {
                    "Alpaca" { [int]$bar.v }
                    "InteractiveBrokers" { [int]$bar.v }
                    "TDAmeritrade" { [int]$bar.volume }
                    "Robinhood" { [int]$bar.volume }
                }
            }
        }

        Write-AssetLog "Market data retrieved: $($marketData.Bars.Count) bars" -Level "SUCCESS"
        return $marketData
    }

    return $null
}

# =============================================================================
# PORTFOLIO ANALYSIS FUNCTIONS
# =============================================================================

function Test-PortfolioRisk {
    param([object]$Portfolio)

    Write-AssetLog "Analyzing portfolio risk" -Level "PORTFOLIO"

    $risk = @{
        TotalValue = $Portfolio.TotalValue
        PositionCount = $Portfolio.Positions.Count
        LargestPosition = ($Portfolio.Positions | Sort-Object MarketValue -Descending | Select-Object -First 1).MarketValue
        LargestPositionPercent = if ($Portfolio.TotalValue -gt 0) { ($Portfolio.Positions | Sort-Object MarketValue -Descending | Select-Object -First 1).MarketValue / $Portfolio.TotalValue } else { 0 }
        TotalUnrealizedPL = ($Portfolio.Positions | Measure-Object -Property UnrealizedPL -Sum).Sum
        DiversificationScore = $Portfolio.Positions.Count
        RiskAlerts = @()
    }

    # Check position size limits
    if ($risk.LargestPositionPercent -gt $Config.RiskManagement.MaxPositionSize) {
        $risk.RiskAlerts += "Largest position exceeds maximum size limit ($([Math]::Round($risk.LargestPositionPercent * 100, 2))% > $([Math]::Round($Config.RiskManagement.MaxPositionSize * 100, 2))%)"
    }

    # Check diversification
    if ($risk.DiversificationScore -lt $Config.RiskManagement.DiversificationMin) {
        $risk.RiskAlerts += "Portfolio lacks diversification (only $($risk.DiversificationScore) positions, minimum $($Config.RiskManagement.DiversificationMin))"
    }

    # Check drawdown
    $drawdown = if ($risk.TotalValue -gt 0) { $risk.TotalUnrealizedPL / $risk.TotalValue } else { 0 }
    if ($drawdown -lt -$Config.RiskManagement.MaxDrawdown) {
        $risk.RiskAlerts += "Portfolio drawdown exceeds limit ($([Math]::Round($drawdown * 100, 2))% < $(-[Math]::Round($Config.RiskManagement.MaxDrawdown * 100, 2))%)"
    }

    return $risk
}

function Optimize-Portfolio {
    param([object]$Portfolio, [hashtable]$TargetAllocations)

    Write-AssetLog "Optimizing portfolio allocations" -Level "PORTFOLIO"

    $currentValue = $Portfolio.TotalValue
    $optimization = @{
        CurrentAllocations = @{}
        TargetAllocations = $TargetAllocations
        RebalancingOrders = @()
        Timestamp = Get-Date
    }

    # Calculate current allocations
    foreach ($position in $Portfolio.Positions) {
        $allocation = if ($currentValue -gt 0) { $position.MarketValue / $currentValue } else { 0 }
        $optimization.CurrentAllocations[$position.Symbol] = $allocation
    }

    # Generate rebalancing orders
    foreach ($symbol in $TargetAllocations.Keys) {
        $targetValue = $currentValue * $TargetAllocations[$symbol]
        $currentPosition = $Portfolio.Positions | Where-Object { $_.Symbol -eq $symbol }

        if ($currentPosition) {
            $currentValue = $currentPosition.MarketValue
            $difference = $targetValue - $currentValue

            if ([Math]::Abs($difference) / $currentValue -gt 0.05) {  # Rebalance if difference > 5%
                $sharesToTrade = [Math]::Round($difference / $currentPosition.CurrentPrice, 0)
                if ($sharesToTrade -ne 0) {
                    $optimization.RebalancingOrders += @{
                        Symbol = $symbol
                        Side = if ($sharesToTrade -gt 0) { "buy" } else { "sell" }
                        Quantity = [Math]::Abs($sharesToTrade)
                        EstimatedValue = [Math]::Abs($difference)
                    }
                }
            }
        } else {
            # New position
            if ($targetValue -gt 0) {
                $price = (Get-AssetPrice -Provider $Portfolio.Provider -Symbol $symbol)
                if ($price) {
                    $sharesToBuy = [Math]::Round($targetValue / $price.Price, 0)
                    $optimization.RebalancingOrders += @{
                        Symbol = $symbol
                        Side = "buy"
                        Quantity = $sharesToBuy
                        EstimatedValue = $targetValue
                    }
                }
            }
        }
    }

    Write-AssetLog "Portfolio optimization complete: $($optimization.RebalancingOrders.Count) rebalancing orders generated" -Level "SUCCESS"
    return $optimization
}

# =============================================================================
# MONITORING FUNCTIONS
# =============================================================================

function Start-AssetMonitoring {
    Write-AssetLog "Starting asset monitoring (interval: $MonitorInterval seconds)" -Level "INFO"

    while ($true) {
        try {
            # Monitor all portfolios across all providers
            foreach ($provider in ($Config.Keys | Where-Object { $_ -ne "Security" -and $_ -ne "Monitoring" -and $_ -ne "RiskManagement" })) {
                if ($Config.$provider.Status -eq "Active") {
                    $portfolio = Get-Portfolio -Provider $provider

                    if ($portfolio) {
                        # Check portfolio value threshold
                        if ($portfolio.TotalValue -lt $Config.Monitoring.PortfolioValueThreshold) {
                            Write-AssetLog "Portfolio value alert: $($portfolio.TotalValue) below threshold $($Config.Monitoring.PortfolioValueThreshold)" -Level "WARNING"
                        }

                        # Check for significant losses
                        $totalPL = ($portfolio.Positions | Measure-Object -Property UnrealizedPL -Sum).Sum
                        if ($totalPL -lt $Config.Monitoring.LossThreshold) {
                            Write-AssetLog "Portfolio loss alert: $($totalPL) exceeds loss threshold $($Config.Monitoring.LossThreshold)" -Level "WARNING"
                        }

                        # Risk analysis
                        $risk = Test-PortfolioRisk -Portfolio $portfolio
                        foreach ($alert in $risk.RiskAlerts) {
                            Write-AssetLog "Risk alert: $alert" -Level "WARNING"
                        }
                    }
                }
            }

        } catch {
            Write-AssetLog "Monitoring error: $($_.Exception.Message)" -Level "ERROR"
        }

        Start-Sleep -Seconds $MonitorInterval
    }
}

function Get-AssetManagementHealth {
    $health = @{
        Timestamp = Get-Date
        Providers = @()
        OverallHealth = "Healthy"
        ActiveProviders = 0
        TotalProviders = ($Config.Keys | Where-Object { $_ -ne "Security" -and $_ -ne "Monitoring" -and $_ -ne "RiskManagement" }).Count
    }

    foreach ($provider in ($Config.Keys | Where-Object { $_ -ne "Security" -and $_ -ne "Monitoring" -and $_ -ne "RiskManagement" })) {
        $providerHealth = @{
            Name = $provider
            Status = $Config.$provider.Status
            APIHealth = "Unknown"
            LastCheck = Get-Date
        }

        # Test API connectivity
        try {
            $testResponse = Invoke-AssetAPI -Provider $provider -Endpoint "/v2/account" -Method "GET"  # Alpaca-specific, adjust for others
            if ($testResponse) {
                $providerHealth.APIHealth = "Healthy"
                $health.ActiveProviders++
            } else {
                $providerHealth.APIHealth = "Degraded"
                $health.OverallHealth = "Degraded"
            }
        } catch {
            $providerHealth.APIHealth = "Failed"
            $health.OverallHealth = "Degraded"
        }

        $health.Providers += $providerHealth
    }

    return $health
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

Write-AssetLog "=== $SystemName v$ScriptVersion ===" -Level "INFO"
Write-AssetLog "Action: $Action, Provider: $Provider" -Level "INFO"

switch ($Action) {
    "Initialize" {
        Write-AssetLog "Initializing asset management integration..." -Level "INFO"

        # Create necessary directories
        $dirs = @("logs", "config", "reports", "backups", "data\portfolios", "data\orders", "data\marketdata")
        foreach ($dir in $dirs) {
            if (-not (Test-Path "$PSScriptRoot\$dir")) {
                New-Item -ItemType Directory -Path "$PSScriptRoot\$dir" -Force | Out-Null
            }
        }

        # Create configuration file
        $Config | ConvertTo-Json -Depth 10 | Out-File "$PSScriptRoot\config\asset_config.json" -Encoding UTF8

        Write-AssetLog "Asset management integration initialized successfully" -Level "SUCCESS"
    }

    "GetPortfolio" {
        $portfolio = Get-Portfolio -Provider $Provider -PortfolioId $PortfolioId
        if ($portfolio) {
            Write-Host "Portfolio Value: $($portfolio.TotalValue.ToString('C'))" -ForegroundColor Green
            Write-Host "Positions: $($portfolio.Positions.Count)" -ForegroundColor White
            Write-Host ""

            Write-Host "Top Positions:" -ForegroundColor Yellow
            foreach ($position in ($portfolio.Positions | Sort-Object MarketValue -Descending | Select-Object -First 5)) {
                $plColor = if ($position.UnrealizedPL -ge 0) { "Green" } else { "Red" }
                Write-Host "  $($position.Symbol): $($position.Quantity) shares @ $($position.CurrentPrice.ToString('C')) = $($position.MarketValue.ToString('C')) (P/L: $($position.UnrealizedPL.ToString('C')))" -ForegroundColor $plColor
            }
        } else {
            Write-Host "Failed to retrieve portfolio" -ForegroundColor Red
        }
    }

    "BuyAsset" {
        if (-not $AssetSymbol -or $Quantity -le 0) {
            Write-AssetLog "Asset symbol and quantity are required" -Level "ERROR"
            exit 1
        }

        $order = New-AssetOrder -Provider $Provider -Symbol $AssetSymbol -Side "buy" -Quantity $Quantity -OrderType "market"
        if ($order) {
            Write-Host "Buy order placed: $($order.OrderId)" -ForegroundColor Green
            Write-Host "Symbol: $($order.Symbol), Quantity: $($order.Quantity), Status: $($order.Status)" -ForegroundColor White
        } else {
            Write-Host "Buy order failed" -ForegroundColor Red
        }
    }

    "SellAsset" {
        if (-not $AssetSymbol -or $Quantity -le 0) {
            Write-AssetLog "Asset symbol and quantity are required" -Level "ERROR"
            exit 1
        }

        $order = New-AssetOrder -Provider $Provider -Symbol $AssetSymbol -Side "sell" -Quantity $Quantity -OrderType "market"
        if ($order) {
            Write-Host "Sell order placed: $($order.OrderId)" -ForegroundColor Green
            Write-Host "Symbol: $($order.Symbol), Quantity: $($order.Quantity), Status: $($order.Status)" -ForegroundColor White
        } else {
            Write-Host "Sell order failed" -ForegroundColor Red
        }
    }

    "GetAssetPrice" {
        if (-not $AssetSymbol) {
            Write-AssetLog "Asset symbol is required" -Level "ERROR"
            exit 1
        }

        $price = Get-AssetPrice -Provider $Provider -Symbol $AssetSymbol
        if ($price) {
            $changeColor = if ($price.Change -ge 0) { "Green" } else { "Red" }
            Write-Host "$($price.Symbol): $($price.Price.ToString('C'))" -ForegroundColor White
            Write-Host "Change: $($price.Change.ToString('C'))" -ForegroundColor $changeColor
            Write-Host "Volume: $($price.Volume.ToString('N0'))" -ForegroundColor White
        } else {
            Write-Host "Failed to retrieve price" -ForegroundColor Red
        }
    }

    "GetMarketData" {
        if (-not $AssetSymbol) {
            Write-AssetLog "Asset symbol is required" -Level "ERROR"
            exit 1
        }

        $marketData = Get-MarketData -Provider $Provider -Symbol $AssetSymbol
        if ($marketData) {
            Write-Host "Market data for $($marketData.Symbol):" -ForegroundColor Green
            Write-Host "Bars: $($marketData.Bars.Count)" -ForegroundColor White
            Write-Host ""

            Write-Host "Recent bars:" -ForegroundColor Yellow
            foreach ($bar in ($marketData.Bars | Select-Object -Last 5)) {
                Write-Host "  $($bar.Timestamp.ToString('yyyy-MM-dd HH:mm')): O=$($bar.Open.ToString('F2')) H=$($bar.High.ToString('F2')) L=$($bar.Low.ToString('F2')) C=$($bar.Close.ToString('F2')) V=$($bar.Volume)" -ForegroundColor White
            }
        } else {
            Write-Host "Failed to retrieve market data" -ForegroundColor Red
        }
    }

    "CreatePortfolio" {
        Write-AssetLog "Creating new portfolio with $Provider" -Level "INFO"
        # Implementation would depend on specific provider API
        Write-Host "Portfolio creation not yet implemented for $Provider" -ForegroundColor Yellow
    }

    "Rebalance" {
        $portfolio = Get-Portfolio -Provider $Provider -PortfolioId $PortfolioId
        if ($portfolio) {
            # Example target allocations (would be configurable)
            $targetAllocations = @{
                "AAPL" = 0.3
                "MSFT" = 0.25
                "GOOGL" = 0.2
                "AMZN" = 0.15
                "TSLA" = 0.1
            }

            $optimization = Optimize-Portfolio -Portfolio $portfolio -TargetAllocations $targetAllocations
            Write-Host "Portfolio rebalancing analysis:" -ForegroundColor Green
            Write-Host "Rebalancing orders needed: $($optimization.RebalancingOrders.Count)" -ForegroundColor White
            Write-Host ""

            foreach ($order in $optimization.RebalancingOrders) {
                Write-Host "  $($order.Side.ToUpper()) $($order.Quantity) shares of $($order.Symbol) (Value: $($order.EstimatedValue.ToString('C')))" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Failed to retrieve portfolio for rebalancing" -ForegroundColor Red
        }
    }

    "Monitor" {
        Start-AssetMonitoring
    }

    "Test" {
        Write-AssetLog "Running asset management tests" -Level "INFO"

        # Test provider connections
        $connectionTests = 0
        $successfulConnections = 0

        foreach ($provider in ($Config.Keys | Where-Object { $_ -ne "Security" -and $_ -ne "Monitoring" -and $_ -ne "RiskManagement" })) {
            if ($Config.$provider.Status -eq "Active") {
                $connectionTests++
                $testResult = Invoke-AssetAPI -Provider $provider -Endpoint "/v2/account" -Method "GET"
                if ($testResult) {
                    $successfulConnections++
                    Write-Host "✓ $provider connection test passed" -ForegroundColor Green
                } else {
                    Write-Host "✗ $provider connection test failed" -ForegroundColor Red
                }
            }
        }

        Write-AssetLog "Connection tests: $successfulConnections/$connectionTests passed" -Level $(if ($successfulConnections -eq $connectionTests) { "SUCCESS" } else { "WARNING" })

        # Test price retrieval
        if ($successfulConnections -gt 0) {
            $testPrice = Get-AssetPrice -Provider "Alpaca" -Symbol "AAPL"
            if ($testPrice) {
                Write-Host "✓ Price retrieval test passed" -ForegroundColor Green
            } else {
                Write-Host "✗ Price retrieval test failed" -ForegroundColor Red
            }
        }
    }

    "Status" {
        $health = Get-AssetManagementHealth

        Write-Host "`n=== $SystemName Status ===" -ForegroundColor Cyan
        Write-Host "Version: $ScriptVersion" -ForegroundColor White
        Write-Host "Timestamp: $($health.Timestamp)" -ForegroundColor White
        Write-Host "Overall Health: $($health.OverallHealth)" -ForegroundColor $(if ($health.OverallHealth -eq "Healthy") { "Green" } else { "Red" })
        Write-Host "Active Providers: $($health.ActiveProviders)/$($health.TotalProviders)" -ForegroundColor $(if ($health.ActiveProviders -eq $health.TotalProviders) { "Green" } else { "Yellow" })
        Write-Host ""

        Write-Host "Provider Status:" -ForegroundColor Yellow
        foreach ($provider in $health.Providers) {
            $color = switch ($provider.APIHealth) {
                "Healthy" { "Green" }
                "Degraded" { "Yellow" }
                "Failed" { "Red" }
                default { "Gray" }
            }
            Write-Host "  $($provider.Name): $($provider.APIHealth) ($($provider.Status))" -ForegroundColor $color
        }

        Write-Host "`nLog File: $LogFile" -ForegroundColor White
        Write-Host ""
    }
}

Write-AssetLog "Command completed: $Action" -Level "INFO"