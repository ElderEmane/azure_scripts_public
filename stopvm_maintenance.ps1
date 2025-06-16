#post maintenance script, stopping VM started for patching leaving all others running
#base taken from https://learn.microsoft.com/en-us/azure/automation/update-management/pre-post-scripts

param
(

    [Parameter(Mandatory=$false)]
    [object] $WebhookData
)

Connect-AzAccount -Identity -AccountId "<your service account>" #can be also managed identity

$notificationPayload = ConvertFrom-Json -InputObject $WebhookData.RequestBody
$eventType = $notificationPayload[0].eventType

if ($eventType -ne “Microsoft.Maintenance.PostMaintenanceEvent”) {
    Write-Output "Webhook not triggered as part of post-patching for 		  maintenance run"
    return
}

$maintenanceRunId = $notificationPayload[0].data.CorrelationId
$resourceSubscriptionIds = $notificationPayload[0].data.ResourceSubscriptionIds

if ($resourceSubscriptionIds.Count -eq 0) {
    Write-Output "Resource subscriptions are not present."
    break
}

Start-Sleep -Seconds 30
Write-Output "Querying ARG to get machine details [MaintenanceRunId=$maintenanceRunId][ResourceSubscriptionIdsCount=$($resourceSubscriptionIds.Count)]"
$argQuery = @"

maintenanceresources

| where type =~ 'microsoft.maintenance/applyupdates'

| where properties.correlationId =~ '$($maintenanceRunId)'

| where id has '/providers/microsoft.compute/virtualmachines/'

| project id, resourceId = tostring(properties.resourceId)

| order by id asc
"@

Write-Output "Arg Query Used: $argQuery"
$allMachines = [System.Collections.ArrayList]@()
$skipToken = $null

do
{
    $res = Search-AzGraph -Query $argQuery -First 1000 -SkipToken $skipToken -Subscription $resourceSubscriptionIds
    $skipToken = $res.SkipToken
    $allMachines.AddRange($res.Data)
} while ($skipToken -ne $null -and $skipToken.Length -ne 0)
if ($allMachines.Count -eq 0) {
    Write-Output "No Machines were found."
    break
}

$jobIDs= New-Object System.Collections.Generic.List[System.Object]
$stoppableStates = "starting", "running"


$OperationName = "Start Virtual Machine" #id of "Start Virtual Machine" event

$allMachines | ForEach-Object {
    $vmId =  $_.resourceId
    $split = $vmId -split "/";
    $subscriptionId = $split[2];
    $rg = $split[4];
    $name = $split[8];

    #finding starting VM logs and determinating time range
    $logs = Get-AzLog -ResourceId $vmId `
    -DetailedOutput `
    -StartTime (Get-Date).AddHours(-6) `
    -EndTime (Get-Date)

    Write-Output ("logs cout: " + $logs.count)

    Write-Output ("VM name " + $name)

    $vmLogs = $logs | Where-Object { ($_.ResourceId -eq $vmId) -and ($_.OperationName -eq $OperationName) } # Checking if VM was started for patching

    # Get the most recent event and select only the EventTimestamp property
    $lastEvent = $vmLogs | Sort-Object -Property EventTimestamp -Descending | Select-Object -ExpandProperty EventTimestamp -First 1

    $mute = Set-AzContext -Subscription $subscriptionId
    $vm = Get-AzVM -ResourceGroupName $rg -Name $name -Status -DefaultProfile $mute

    $state = ($vm.Statuses[1].DisplayStatus -split " ")[1]
    if ($state -in $stoppableStates)
    {

        # Output only the DateTime without "EventTimestamp:"
        if ($lastEvent)
        {
            Write-Output $lastEvent.DateTime
            $uptime = [Math]::Round((New-TimeSpan -Start $lastEvent.DateTime -End (Get-Date)).TotalHours)
            Write-Output $uptime
            Write-Output "VM was powered on $uptime hours ago."
            if ($uptime -le 6)
            {
                Write-Output "Stopping '$( $name )' ..."
                $newJob = Start-ThreadJob -ScriptBlock { param($resource, $vmname, $sub) $context = Set-AzContext -Subscription $sub; Stop-AzVM -ResourceGroupName $resource -Name $vmname -Force -DefaultProfile $context} -ArgumentList $rg, $name, $subscriptionId
                $jobIDs.Add($newJob.Id)
            }
        }
    }
    else
    {
        Write-Output "No events found for VM."
    }
}

$jobsList = $jobIDs.ToArray()
if ($jobsList)
{
    Write-Output "Waiting for machines to finish stop operation..."
    Wait-Job -Id $jobsList
}

foreach($id in $jobsList)
{
    $job = Get-Job -Id $id
    if ($job.Error)
    {
        Write-Output $job.Error
    }
}

