Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.Compute


function Connect {
    $null = Connect-AzAccount -WarningAction SilentlyContinue -Verbose:$false
    $subscriptions = Get-AzSubscription | Select-Object Id, Name

    return $subscriptions
}

function tag_adhoc {
    param (
        [string]$VMname,
        [string]$VMrg
    )

    Stop-AzVM -ResourceGroupName $VMrg -Name $VMname -Force
}

function tag_24/5 {
    param (
        [string]$VMname,
        [string]$VMrg
    )
    $convertedDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($currentDateTime, $timezone[$key])
    $hour = $convertedDateTime.ToString("HH") + "00"

    if ($hour -eq "0000" -and (Get-Date).DayOfWeek -eq [System.DayOfWeek]::Saturday){
        stop-AzVM -ResourceGroupName $VMrg -Name $VMname -Force
    }
}

function tag_adhoc_24/5 {
    param (
        [string]$VMname,
        [string]$VMrg
    )
    Write-Output $VMrg $VMname
    if ((Get-Date).DayOfWeek -ge [System.DayOfWeek]::Monday -and (Get-Date).DayOfWeek -le [System.DayOfWeek]::Friday) {
        Stop-AzVM -ResourceGroupName $VMrg -Name $VMname -Force
    }
    else {
        Write-Output "invalid day of the week"
    }
}
function tag_business_hours{
    param (
        [string]$VMname,
        [string]$VMrg
    )
    $convertedDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($currentDateTime, $timezone[$key])
    $hour = $convertedDateTime.ToString("HH") + "00"

    if ($hour -eq "0000" -and (Get-Date).DayOfWeek -ge [System.DayOfWeek]::Saturday -and (Get-Date).DayOfWeek -le [System.DayOfWeek]::Monday){
        Stop-AzVM -ResourceGroupName $VMrg -Name $VMname -Force
    }

}

function autostop {
    param (
        [array]$subscriptions
    )

    $timezone = @{
        "westeurope" = "W. Europe Standard Time"
        "southeastasia" = "China Standard Time"
        "eastus" = "Eastern Standard Time"
        "australiaeast" = "AUS Eastern Standard Time"
    }

    $currentDateTime = Get-Date

    foreach ($subscription in $subscriptions) {
        Write-Host "Processing Subscription: $($subscription.Name)"
        Select-AzSubscription -SubscriptionId $subscription.Id > $null
        $vms = Get-AzVM

        foreach ($vm in $vms) {
            $VMname = $vm.name
            $VMid = $vm.id
            $stopTAG = $vm.Tags['autostoptime']
            $location = $vm.location
            $operation_hours = $vm.Tags['operation_hours']

            $split = $VMid -split "/";
            $VMrg = $split[4];0.

            Write-Host $VMname $VMrg $stopTAG $location

            if ($operation_hours -notmatch "24/7"){
                foreach ($key in $timezone.Keys) {
                    if ($location -eq $key){
                        $convertedDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($currentDateTime, $timezone[$key])
                        $hour = $convertedDateTime.ToString("HH") + "00"
                        Write-Output $dayoftheweek
                        if ($hour -eq $stopTAG){
                            $command = "tag_$operation_hours -VMname `"$VMname`" -VMrg `"$VMrg`""
                            Invoke-Expression $command
                        }
                        else {
                            if ($operation_hours -match "24/5" -or $operation_hours -match "business_hours" ){
                                $command = "tag_$operation_hours -VMname `"$VMname`" -VMrg `"$VMrg`""
                            }
                            else {
                                Write-Host "no tag"
                            }
                        }
                    }
                }
            }
            else {
                Write-Output "24/7"
            }
        }
    }
}


$subscriptions = Connect
autostop -subscriptions $subscriptions