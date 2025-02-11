Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.Compute
Import-Module ThreadJob


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
    Write-Host "stopping vm" $VMname
    Write-Host "executed adhoc"
}

function tag_24/5 {
    param (
        [string]$VMname,
        [string]$VMrg
    )

    $hour = (Get-Date).ToString("HHmm")
    $dayOfWeek = (Get-Date).DayOfWeek

    if ($dayOfWeek -ge [System.DayOfWeek]::Friday -and ($hour -eq "2000")) {
        Start-AzVM -ResourceGroupName $VMrg -Name $VMname
        Write-Host "stopping vm" $VMname
        Write-Host "executed 24/5"
    }
    else {
        Write-Output "invalid day of the week"
    }
}

function tag_adhoc_24/5 {
    param (
        [string]$VMname,
        [string]$VMrg
    )

    if ((Get-Date).DayOfWeek -ge [System.DayOfWeek]::Monday -and (Get-Date).DayOfWeek -le [System.DayOfWeek]::Friday) {
        Start-AzVM -ResourceGroupName $VMrg -Name $VMname
        Write-Host "stopping vm" $VMname
        Write-Host "executed adhoc_24/5"
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

    if ($dayOfWeek -ge [System.DayOfWeek]::Monday -and $dayOfWeek -le [System.DayOfWeek]::Friday -and $hour -ge "1800") {
        Start-AzVM -ResourceGroupName $VMrg -Name $VMname
        Write-Host "stopping vm" $VMname
    }
    else {
        Write-Output "invalid day of the week"
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
        jobs += ThreadJob -ScriptBlock {
            param($subscription)
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
                $VMrg = $VMrg.ToLower()

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
                                    if ($null -ne $operation_hours -and $operation_hours -ne " " ){
                                        Write-Host "different hour"
                                    }
                                    else {
                                        Write-Host "no tag"
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    Write-Output "24/7"
                }
            }
        } -ArgumentList $subscription
    }
    Wait-Job -Job $jobs

    foreach ($job in $jobs) {
        Receive-Job -Job $job
    }
}


$subscriptions = Connect
autostart -subscriptions $subscriptions