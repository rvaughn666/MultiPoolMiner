using module ..\Include.psm1

param(
    $Config
)

$Name = Get-Item $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty BaseName
$PoolConfig = $Config.Pools.$Name

$APIWalletRequest = [PSCustomObject]@{}

if (!$PoolConfig.BTC) {
    Write-Log -Level Verbose "Cannot get balance on pool ($Name) - no wallet address specified."
    return
}

try {
    $APIWalletRequest = Invoke-RestMethod "http://pool.hashrefinery.com/api/wallet?address=$($PoolConfig.BTC)" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
}
catch {
    Write-Log -Level Warn "Pool Balance API ($Name) has failed. "
}

if (($APIWalletRequest | Get-Member -MemberType NoteProperty -ErrorAction Ignore | Measure-Object Name).Count -le 1) {
    Write-Log -Level Warn "Pool Balance API ($Name) returned nothing. "
    return
}

[PSCustomObject]@{
    Name        = "$($Name) ($($APIWalletRequest.currency))"
    Pool        = $Name
    Currency    = $APIWalletRequest.currency
    Balance     = $APIWalletRequest.balance
    Pending     = $APIWalletRequest.unsold
    Total       = $APIWalletRequest.unpaid
    Lastupdated = (Get-Date).ToUniversalTime()
}