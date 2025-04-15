#moved functions
function tag_adhoc {
    param (
        [string]$VMname,
        [string]$VMrg
    )

    $vmStatus = (Get-AzVM -ResourceGroupName $VMrg -Name $VMname).PowerState

    if ($vmStatus -eq 'Running') {
        Write-Host "VM $VMname is already running. No action needed."
    } else {
        # Start the VM if it is not running
        Start-AzVM -ResourceGroupName $VMrg -Name $VMname -ErrorAction Stop
        Write-Host "Starting VM $VMname"
    }

    Write-Host "executed adhoc"
}

function tag_24_5 {
    param (
        [string]$VMname,
        [string]$VMrg
    )
    $hour = (Get-Date).ToString("HHmm")
    $dayOfWeek = (Get-Date).DayOfWeek

    if ($dayOfWeek -ge [System.DayOfWeek]::Monday -and $dayOfWeek -le [System.DayOfWeek]::Friday -and ($hour -ge "0000" -and $hour -le "2359")) {
        $vmStatus = (Get-AzVM -ResourceGroupName $VMrg -Name $VMname).PowerState
        if ($vmStatus -eq 'Running') {
            Write-Host "VM $VMname is already running. No action needed."
        } else {
            Start-AzVM -ResourceGroupName $VMrg -Name $VMname -ErrorAction Stop
            Write-Host "Starting VM $VMname"
        }
    } else {
        Write-Host "Invalid day of the week or time range."
    }
}

function tag_adhoc_24_5 {
    param (
        [string]$VMname,
        [string]$VMrg
    )
    Write-Output $VMrg $VMname
    if ((Get-Date).DayOfWeek -ge [System.DayOfWeek]::Monday -and (Get-Date).DayOfWeek -le [System.DayOfWeek]::Friday) {
        $vmStatus = (Get-AzVM -ResourceGroupName $VMrg -Name $VMname).PowerState
        if ($vmStatus -eq 'Running') {
            Write-Host "VM $VMname is already running. No action needed."
        } else {
            Start-AzVM -ResourceGroupName $VMrg -Name $VMname -ErrorAction Stop
            Write-Host "Starting VM $VMname"
        }
    } else {
        Write-Host "Invalid day of the week or time range."
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
        $vmStatus = (Get-AzVM -ResourceGroupName $VMrg -Name $VMname).PowerState
        if ($vmStatus -eq 'Running') {
            Write-Host "VM $VMname is already running. No action needed."
        } else {
            Start-AzVM -ResourceGroupName $VMrg -Name $VMname -ErrorAction Stop
            Write-Host "Starting VM $VMname"
        }
    } else {
        Write-Host "Invalid day of the week or time range."
    }
}
#moved functions
