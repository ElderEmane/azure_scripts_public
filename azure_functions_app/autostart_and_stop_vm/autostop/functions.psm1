function tag_adhoc {
    param (
        [string]$VMname,
        [string]$VMrg
    )

    Start-AzVM -ResourceGroupName $VMrg -Name $VMname
    Write-Host "stopping vm" $VMname
    Write-Host "executed adhoc"
}

function tag_24_5 {
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

function tag_adhoc_24_5 {
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