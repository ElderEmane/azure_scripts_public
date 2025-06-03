function tag_adhoc {
    param (
        [string]$VMname,
        [string]$VMrg,
        [string]$hour
    )
    $vmStatus = ((Get-AzVM -ResourceGroupName $VMrg -Name $VMname -Status).Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus

    if ($vmStatus -eq 'VM deallocated') {
        Write-Host "VM $VMname is already stopped (deallocated). No action needed."
    } else {
        Stop-AzVM -ResourceGroupName $VMrg -Name $VMname -Force
        Write-Host "stopping vm" $VMname
        Write-Host "executed adhoc"
    }
}

function tag_24_5 {
    param (
        [string]$VMname,
        [string]$VMrg,
        [string]$hour
    )

    $dayOfWeek = (Get-Date).DayOfWeek

    if ($dayOfWeek -ge [System.DayOfWeek]::Friday -and ($hour -eq "2000")) {
        $vmStatus = ((Get-AzVM -ResourceGroupName $VMrg -Name $VMname -Status).Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus

        if ($vmStatus -eq 'VM deallocated') {
            Write-Host "VM $VMname is already stopped (deallocated). No action needed."
        } else {
            Stop-AzVM -ResourceGroupName $VMrg -Name $VMname -Force
            Write-Host "stopping vm" $VMname
            Write-Host "executed 24/5"
        }
    }
    else {
        Write-Output "invalid day of the week"
    }
}

function tag_adhoc_24_5 {
    param (
        [string]$VMname,
        [string]$VMrg,
        [string]$hour
    )

    $dayOfWeek = (Get-Date).DayOfWeek

    if ($dayOfWeek -ge [System.DayOfWeek]::Monday -and $dayOfWeek -le [System.DayOfWeek]::Friday -and ($hour -ge "0000" -and $hour -le "2300")) {

        $vmStatus = ((Get-AzVM -ResourceGroupName $VMrg -Name $VMname -Status).Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus

        if ($vmStatus -eq 'VM deallocated') {
            Write-Host "VM $VMname is already stopped (deallocated). No action needed."
        } else {
            Stop-AzVM -ResourceGroupName $VMrg -Name $VMname -Force
            Write-Host "Stopping VM $VMname"
            Write-Host "Executed adhoc_24/5"
        }
    }
}

function tag_business_hours{
    param (
        [string]$VMname,
        [string]$VMrg,
        [string]$hour
    )

    $dayOfWeek = (Get-Date).DayOfWeek

    if ($dayOfWeek -ge [System.DayOfWeek]::Monday -and $dayOfWeek -le [System.DayOfWeek]::Friday -and $hour -ge "1800") {

        $vmStatus = ((Get-AzVM -ResourceGroupName $VMrg -Name $VMname -Status).Statuses | Where-Object { $_.Code -like "PowerState/*" }).DisplayStatus

        if ($vmStatus -eq 'VM deallocated') {
            Write-Host "VM $VMname is already stopped (deallocated). No action needed."
        } else {
            Stop-AzVM -ResourceGroupName $VMrg -Name $VMname -Force
            Write-Host "stopping vm" $VMname
        }
    }
    else {
        Write-Output "invalid day of the week"
    }

}