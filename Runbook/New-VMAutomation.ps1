param
(
    [Parameter (Mandatory = $false)]
    [object] $WebhookData
)

# Required for Get-AutomationPSCredential Command
Import-Module Orchestrator.AssetManagement.Cmdlets -ErrorAction SilentlyContinue

Write-Output "Starting script to create environment..."

If ($WebhookData) {
    $vmData = (ConvertFrom-Json -InputObject $WebhookData.RequestBody)
    Write-Output "Webhook data passed in:"
    Write-Output $vmData
    
    $vmName = $vmData.VMName
    $rgName = $vmData.ResourceGroup
    $vmRegion = $vmData.VMRegion
    $vmTags = $vmData.Tags
}

# Check values, if not passed in, set to default values
If (-Not $vmName) { $vmName = 'TestVM01' }
If (-Not $rgName) { $rgName = 'MyTestRG' }
If (-Not $vmRegion) { $vmRegion = 'EastUS' }
If (-Not $vmTags) { $vmTags = '10101010' }

$vmObj = @{ResourceGroup=$rgName;VMName=$vmName;VMRegion=$vmRegion;Tags=$vmTags}
Write-Output "Final values set for VM Creation:"
Write-Output $vmObj

try {
    $vmCred = Get-AutomationPSCredential -Name 'VMCredentials'
} catch {
    $ErrorMessage = "ERROR: Cannot find Vm Credentials"
    throw $ErrorMessage
}
Write-Output $vmCred

# ============= AZ LOGIN CODE
Write-Output "Connecting to Azure"
# Use the RunAs Credentials for this automation runbook to login to Az
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
# ============= AZ LOGIN CODE


# ============= CUSTOM CODE HERE
Write-Output "Create new Virtual Machine..."

$tags = @{CostCenter=$vmTags}

New-AzVm `
    -ResourceGroupName $rgName `
    -Name $vmName `
    -Location $vmRegion `
    -VirtualNetworkName 'vnetTestVM' `
    -SubnetName 'subnetMain' `
    -SecurityGroupName "myNetworkSecurityGroup" `
    -PublicIpAddressName "myPublicIpAddress" `
    -OpenPorts 80,3389 `
    -Credential $vmCred

Write-Output "Add Cost Center tag to VM..."

Set-AzResource -ResourceGroupName $rgName -Name $vmName -ResourceType "Microsoft.Compute/VirtualMachines" -Tag $tags -Force
# ============= CUSTOM CODE HERE

If ($Error) {
    Write-Output "Error in Script. Please check logs for details. VM was not created."
    Write-Output $Error
} else {
    Write-Output "Virtual Machine created."
}
