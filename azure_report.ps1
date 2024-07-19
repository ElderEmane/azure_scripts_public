<#-----------------------------------------------------------------------------
author: Monika Zagozdon
This PowerShell script generates a report on Azure Virtual Machines (VMs) across selected subscriptions.
# Users can specify subscriptions and filter VMs based on a tag and its value.
# Additionally, there is an option to include the estimated monthly cost of each VM, though this will increase the script's completion time and memory usage.
# The report includes VM details such as subscription, VM name, resource group, IP address, owner tag, operating system, and the specified tag.
# If the cost option is selected, the monthly cost will also be included.
# The final report is exported to a CSV file named "AzureVMReport.csv".

-----------------------------------------------------------------------------#>

function Connect {
    Connect-AzAccount > $null 2>&1 -WarningAction SilentlyContinue -Verbose:$false
    return Get-AzSubscription
}

# Function to generate report from all subscriptions
function report {
    param (
        [array]$subscriptions
    )

    $report = @()

    Write-Host "Do you want to chose subscription?"
    Write-Host "By default script run through all subscriptions"
    $input3 = Read-Host "y/n default n"

    if ($input3 -match 'y'){
        Write-Host "Available Subscriptions:"
        for ($i = 0; $i -lt $subscriptions.Count; $i++) {
            $subscription = $subscriptions[$i]
            Write-Host "$($i + 1): $($subscription.Name)"
        }
        $choice = Read-Host "Enter the number of the subscription to choose (1-$($subscriptions.Count))"
        if ($choice -ge 1 -and $choice -le $subscriptions.Count) {
            $subscriptions = $subscriptions[$choice - 1]

        } else {
            Write-Host "Invalid choice. Please enter a number between 1 and $($subscriptions.Count)"
            # Recursively call the function to prompt again
            Choose-Subscription -subscriptions $subscriptions
        }
    }

    Write-Host "Do you want to add estimated cost of the VM?"
    Write-Host "This option will significally rise time of completion and RAM usage."

    $input = Read-Host "y/n default n"

    Write-Host "Do you want to add additional tags?"
    $input2 = Read-Host "y/n default n"

    if ($input2 -match 'y'){
        $inputString = Read-Host "Enter values separated by comma (e.g., value1, value2, value3)"
        $tags = $inputString -split ',' | ForEach-Object { $_.Trim() }
    }

    # Loop through each subscription
    foreach ($subscription in $subscriptions) {

        Write-Host "Processing Subscription: $($subscription.Name)"

        # Select the current subscription
        Select-AzSubscription -SubscriptionId $subscription.Id > $null

        # Get all VMs in the current subscription
        $vms = Get-AzVM

        # Loop through each VM
        foreach ($vm in $vms) {
            $nic = $vm.NetworkProfile.NetworkInterfaces
            if ($input -match 'y') {
                $vmUsage = Get-AzConsumptionUsageDetail -ResourceGroup $vm.ResourceGroupName -StartDate (Get-Date).AddMonths(-1) -EndDate (Get-Date) -InstanceName $vm.Name
                $Costs = $vmUsage.PretaxCost
                $total = 0
                foreach ($Cost in $Costs) {
                    $monthlyCost += $Cost
                }
                $total = [math]::Round($monthlyCost,2)
            }

            $vmDetails = [PSCustomObject]@{
                Subscription = $subscription.Name
                VMName = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                IP = (Get-AzNetworkInterface -Name $nic.Id.Split('/')[-1] -ResourceGroupName $nic.Id.Split('/')[4]).IpConfigurations.PrivateIpAddress
                OwnerTag = $vm.Tags['owner']
                OperatingSystem = $vm.StorageProfile.OsDisk.OsType
                SKU = $vm.StorageProfile.imageReference.sku
            }

            if ($input2 -match 'y'){
                foreach ($tag in $tags){
                    $vmDetails | Add-Member -MemberType NoteProperty -Name $tag -Value $vm.Tags[$tag]
                }
            }

            if ($input -match 'y') {
                $vmDetails | Add-Member -MemberType NoteProperty -Name MonthlyCost -Value $total
            }

            $report += $vmDetails
        }
    }

    # Export report to CSV file
    $report | Export-Csv -Path "AzureVMReport.csv" -NoTypeInformation
    Write-Host "Report exported to AzureVMReport.csv"
}

function report1 {
    param (
        [array]$subscriptions
    )

    $report = @()

    Write-Host "Tag:"
    $input1 = Read-Host

    Write-Host "Value of the tag:"

    $input2 = Read-Host

    Write-Host "Do you want to add estimated cost of the VM?"
    Write-Host "This option will significally rise time of completion and RAM usage."

    $input3 = Read-Host "y/n default n"

    Write-Host "Do you want to add additional tags?"
    $input4 = Read-Host "y/n default n"

    if ($input4 -match 'y'){
        $inputString = Read-Host "Enter values separated by comma (e.g., value1, value2, value3)"
        $tags = $inputString -split ',' | ForEach-Object { $_.Trim() }
    }

    # Loop through each subscription
    foreach ($subscription in $subscriptions) {

        Write-Host "Processing Subscription: $($subscription.Name)"

        # Select the current subscription
        Select-AzSubscription -SubscriptionId $subscription.Id > $null

        # Get all VMs in the current subscription
        $vms = Get-AzVM

        # Loop through each VM
        foreach ($vm in $vms)
        {
            $nic = $vm.NetworkProfile.NetworkInterfaces
            if ($input3 -match 'y')
            {
                $vmUsage = Get-AzConsumptionUsageDetail -ResourceGroup $vm.ResourceGroupName -StartDate (Get-Date).AddMonths(-1) -EndDate (Get-Date) -InstanceName $vm.Name
                $Costs = $vmUsage.PretaxCost
                $total = 0
                foreach ($Cost in $Costs)
                {
                    $monthlyCost += $Cost
                }
                $total = [math]::Round($monthlyCost, 2)
            }

            if ($vm.Tags[$input1] -match $input2)
            {

                $vmDetails = [PSCustomObject]@{
                    Subscription = $subscription.Name
                    VMName = $vm.Name
                    ResourceGroup = $vm.ResourceGroupName
                    IP = (Get-AzNetworkInterface -Name $nic.Id.Split('/')[-1] -ResourceGroupName $nic.Id.Split('/')[4]).IpConfigurations.PrivateIpAddress
                    OwnerTag = $vm.Tags['owner']
                    OperatingSystem = $vm.StorageProfile.OsDisk.OsType
                    SKU = $vm.StorageProfile.imageReference.sku
                    FilerTag = $vm.Tags[$input]
                }

                if ($input -match 'y')
                {
                    $vmDetails | Add-Member -MemberType NoteProperty -Name MonthlyCost -Value $total
                }

                if ($input4 -match 'y'){
                    foreach ($tag in $tags){
                        $vmDetails | Add-Member -MemberType NoteProperty -Name $tag -Value $vm.Tags[$tag]
                    }
                }

                $report += $vmDetails
            }
        }
    }

    # Export report to CSV file
    $report | Export-Csv -Path "AzureVMReport.csv" -NoTypeInformation
    Write-Host "Report exported to AzureVMReport.csv"
}

Write-Host "Option of the report:"
Write-Host "1. Standard report (choice: subscription, tags, monthly cost)"
Write-Host "2. Filter by tag value"

$key = Read-Host "1-2"

if ($key -match '^[1-2]$') {
    $option = [int]$key

    Switch ($option) {
        1 { $subscriptions = Connect
        report -subscriptions $subscriptions }
        2 { $subscriptions = Connect
        report1 -subscriptions $subscriptions  }
        default { Write-Host "Invalid option" }
    }
} else {
    Write-Host "Invalid input. Please enter a number between 0 and 1."
}
