# Required for Get-AutomationPSCredential Command
Import-Module Orchestrator.AssetManagement.Cmdlets -ErrorAction SilentlyContinue


# ============= AZ LOGIN CODE
# Use a Service Principal instead of Run-As account. The credentials are stored in the Automation Account Credentials
try {
    $Cred = Get-AutomationPSCredential -Name 'ADCredentials'
} catch {
    $ErrorMessage = "ERROR: Cannot find AD Credentials"
    throw $ErrorMessage
}
Write-Output $Cred

# Login with Service Principal
try
{
    Write-Output "Logging in to Azure..."
    Add-AzAccount `
        -ServicePrincipal `
        -TenantId '{Tenant-ID}' `
        -Credential $Cred
}
catch 
{
        Write-Error -Message $_.Exception
        throw $_.Exception
}
# ============= AZ LOGIN CODE

Write-Output "Get VMs"

$vm = Get-AzVM -Status

Write-Output $vm