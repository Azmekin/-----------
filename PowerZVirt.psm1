Write-Host "Include ZVIRT Functions and additional variables..." -ForegroundColor Green
Write-Host "Register base Global Variables..." -ForegroundColor Green

[System.Collections.ArrayList]$global:ZVirt = @()

# Pre-requesites: security, certificates...

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"
if ("TrustAllCertsPolicy" -as [type]) {} else {

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
  [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
#[Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicyZVirt


$global:methods = @{
    "auth"                         = "/ovirt-engine/sso/oauth/token"
    #here
    "getProjects"                  = ":5000/v3/projects?all_tenants=1"
    "getProjectDetails"            = ":5000/v3/projects/[PROJECT_ID]"
    "getAllVMs"                    = ":8774/v2.1/servers?all_tenants=1"
    "getVM"                        = ":8774/v2.1/servers?all_tenants=1&name=[VM_NAME]"
    "getVMsPerProject"             = ":8774/v2.1/servers?all_tenants=1&project_id=[PROJECT_ID]"
    "getVMDetails"                 = ":8774/v2.1/servers/[VM_ID]"
    "getFlavor"                    = ":8774/v2.1/flavors/[FLAVOR_ID]"
    "getHosts"                     = ":8774/v2.1/os-hypervisors/detail"
    "getSecurityGroups"            = ":9696/v2.0/security-groups"
    "getvDisks"                    = ":8776/v2/[PROJECT_ID]/volumes/detail?all_tenants=True&limit=1000"
    "getStores"                    = ":8776/v2/[PROJECT_ID]/scheduler-stats/get_pools?all_tenants=True&detail=True"
}

Function GOIDA () {
    Write-Host "Goida"
}
Function Get-ZVirtAuthenticationToken () {
    Param(
        [Parameter(Mandatory=$true)]       [string] $user,
        [Parameter(Mandatory=$false)]      [string] $domain = "internal",
        [Parameter(Mandatory=$true)]       [string] $secret,
        [Parameter(Mandatory=$true)]       [string] $apiURL
        )
    $b64secret= [convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($user+"@"+$domain+":"+$secret))
    $result = Invoke-WebRequest -Headers @{"Authorization"="Basic "+$b64secret} -Method Head -Uri $apiURL -UseBasicParsing -Verbose
    $authToken = $result
    Write-Host $authToken
   # $res = @{
   #     "Content-Type"="application/json"
   #     "X-Auth-Token" = $result.Headers['X-Subject-Token']
   #     "X-OpenStack-Nova-API-Version" = "2.27"
   # }
    return  $authToken #$res
}

