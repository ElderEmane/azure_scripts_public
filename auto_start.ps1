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

    Start-AzVM -ResourceGroupName $VMrg -Name $VMname
}

function tag_24/5 {
    param (
        [string]$VMname,
        [string]$VMrg
    )
    $hour = (Get-Date).ToString("HHmm")
    $dayOfWeek = (Get-Date).DayOfWeek

    if ($dayOfWeek -ge [System.DayOfWeek]::Monday -and $dayOfWeek -le [System.DayOfWeek]::Friday -and ($hour -ge "0000" -and $hour -le "2359")) {
        Start-AzVM -ResourceGroupName $VMrg -Name $VMname
        Write-Host "starting vm" $VMname
    }
}

function tag_adhoc_24/5 {
    param (
        [string]$VMname,
        [string]$VMrg
    )
    Write-Output $VMrg $VMname
    if ((Get-Date).DayOfWeek -ge [System.DayOfWeek]::Monday -and (Get-Date).DayOfWeek -le [System.DayOfWeek]::Friday) {
        Start-AzVM -ResourceGroupName $VMrg -Name $VMname
        Write-Host "starting vm" $VMname
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


    $dayOfWeek = (Get-Date).DayOfWeek

    if ($dayOfWeek -ge [System.DayOfWeek]::Monday -and $dayOfWeek -le [System.DayOfWeek]::Friday -and $hour -ge "0600") {
        Start-AzVM -ResourceGroupName $VMrg -Name $VMname
        Write-Host "starting vm" $VMname
    }

}

function autostart {
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
            $startTAG = $vm.Tags['autostarttime']
            $location = $vm.location
            $operation_hours = $vm.Tags['operation_hours']

            $split = $VMid -split "/";
            $VMrg = $split[4];0.

            Write-Host $VMname $VMrg $startTAG $location

            if ($operation_hours -notmatch "24/7"){
                foreach ($key in $timezone.Keys) {
                    if ($location -eq $key){
                        $convertedDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($currentDateTime, $timezone[$key])
                        $hour = $convertedDateTime.ToString("HH") + "00"
                        Write-Output $dayoftheweek
                        if ($hour -eq $startTAG){
                            $command = "tag_$operation_hours -VMname `"$VMname`" -VMrg `"$VMrg`""
                            Invoke-Expression $command
                        }
                        else {
                            if ($operation_hours -eq "24/5" -or $operation_hours -eq "business_hours" ){
                                Write-Host "24/5 or businnes_hours"
                                $command = "tag_$operation_hours -VMname `"$VMname`" -VMrg `"$VMrg`""
                                Invoke-Expression $command
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
autostart -subscriptions $subscriptions