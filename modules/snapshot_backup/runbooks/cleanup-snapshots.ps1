param(
    [string]$resourcegroupname,
    [string]$snapshotprefix,
    [int]$retentionhours
)

Connect-AzAccount -Identity

$cutoff = (Get-Date).AddHours(-$retentionHours)

$snapshots = Get-AzSnapshot `
    -ResourceGroupName $resourcegroupname |
Where-Object {
    $_.Name -like "$snapshotprefix*" -and
    $_.TimeCreated -lt $cutoff
}

foreach ($snapshot in $snapshots) {
    Remove-AzSnapshot `
        -ResourceGroupName $resourcegroupname `
        -SnapshotName $snapshot.Name `
        -Force
}