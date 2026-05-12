param(
    [string]$resourcegroupname,
    [string]$vmname,
    [string]$snapshotprefix
)

Connect-AzAccount -Identity

$vm = Get-AzVM `
    -ResourceGroupName $resourcegroupname `
    -Name $vmname

$osDiskId = $vm.StorageProfile.OsDisk.ManagedDisk.Id

$disk = Get-AzDisk | Where-Object {
    $_.Id -eq $osDiskId
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$snapshotName = "$snapshotprefix-$vmName-$timestamp"

$snapshotConfig = New-AzSnapshotConfig `
    -SourceUri $disk.Id `
    -Location $vm.Location `
    -CreateOption Copy

New-AzSnapshot `
    -Snapshot $snapshotConfig `
    -SnapshotName $snapshotName `
    -ResourceGroupName $resourcegroupname

Update-AzTag `
    -ResourceId "/subscriptions/$($disk.Id.Split('/')[2])/resourceGroups/$resourcegroupname/providers/Microsoft.Compute/snapshots/$snapshotName" `
    -Tag @{
        CreatedBy  = "AutomationRunbook"
        Environment = "uat"
        SourceVM   = $vmname
    } `
    -Operation Merge