# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

Import-Module Az.Accounts
Import-Module Az.Resources
Import-Module Az.Compute

function Connect {
    $null = Connect-AzAccount -WarningAction SilentlyContinue -Verbose:$false
    $subscriptions = Get-AzSubscription | Select-Object Id, Name

    return $subscriptions
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

        $vms | ForEach-Object -Parallel {

            $functionsPath = "/home/site/wwwroot/autostop/functions.psm1"
            Write-Host "Importing functions module from: $functionsPath"
            Import-Module $functionsPath

            $currentDateTime = Get-Date

            $timezone = @{
                "westeurope" = "W. Europe Standard Time"
                "southeastasia" = "China Standard Time"
                "eastus" = "Eastern Standard Time"
                "australiaeast" = "AUS Eastern Standard Time"
            }

            $VMname = $_.name
            $VMid = $_.id
            $stopTAG = $_.Tags['autostoptime']
            $location = $_.location
            $operation_hours = $_.Tags['operation_hours'] -replace '/', '_'

            $split = $VMid -split "/";
            $VMrg = $split[4];0.
            $VMrg = $VMrg.ToLower()


            Write-Host $VMname $VMrg $stopTAG $operation_hours

            if ($operation_hours -eq "24/7"){
                foreach ($key in $timezone.Keys) {
                    if ($location -eq $key){
                        $convertedDateTime = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($currentDateTime, $timezone[$key])
                        $hour = $convertedDateTime.ToString("HH") + "00"
                        Write-Output $dayoftheweek
                        if ($hour -eq $stopTAG){
                            $command = "tag_$operation_hours -VMname `"$VMname`" -VMrg `"$VMrg`" -hour `"$hour`""
                            Invoke-Expression $command
                        }
                        else {
                            if ($operation_hours -eq "24/5" -or $operation_hours -eq "business_hours" ){
                                Write-Host "24/5 or businnes_hours"
                                $command = "tag_$operation_hours -VMname `"$VMname`" -VMrg `"$VMrg`" -hour `"$hour`""
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
    }
    foreach ($job in $jobs) {
        if ($job.State -eq 'Running') {
            Write-Host "Job is still running, waiting for it to complete..."
            Wait-Job -Job $job
        }
    }

    foreach ($job in $jobs) {
        $result = Receive-Job -Job $job
        Write-Host "Job result: $result"
    }
}


$subscriptions = Connect
autostop -subscriptions $subscriptions