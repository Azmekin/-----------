Write-Host "Include ZVIRT Functions and additional variables..." -ForegroundColor Green
Write-Host "Register base Global Variables..." -ForegroundColor Green

[System.Collections.Generic.Dictionary[string,string]]$global:ZVirt = @{}



Function Connect-zVirtController () {
    Param(
        [Parameter(Mandatory=$true)]       [string] $user,
        [Parameter(Mandatory=$true)]      [string] $domain,
        [Parameter(Mandatory=$true)]       [string] $secret,
        [Parameter(Mandatory=$true)]       [string] $apiURL
        )
    $apiURL=$apiURL+"/ovirt-engine/api"
    $b64secret= [convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($user+"@"+$domain+":"+$secret))
    $result = Invoke-WebRequest -Headers @{"Authorization"="Basic "+$b64secret;"Prefer"="persistent-auth"} -Method Head -Uri $apiURL -UseBasicParsing -Verbose -SkipCertificateCheck -SessionVariable websession
    $cookies = $websession.Cookies.GetCookies($apiURL) 
    $ZVirt["$apiURL"]=$cookies.Value
    $RAWData=@{"ZVIRT"=$ZVirt;"RAWData"=$result}
    return  [pscustomobject]$RAWData
}

function Get-zVirtConnectedControllers {
    return  $ZVirt
}

function Disconnect-zVirtController {
    param (
        [Parameter(Mandatory=$true)]       [string] $apiURL
    )
    $ZVirt.Remove($apiURL)
    return  $ZVirt
}



function Get-zVirtHosts {
    param (
        [Parameter(Mandatory=$false)]       [string] $name
    )
    $list=[System.Collections.ArrayList]::new()
    $RAWData=""
    if ( $ZVirt.Count -eq 0 ){
        Write-Error "There is no ZVIRT connections. Create one by Connect-zVirtController"
    }
    foreach ($h in $ZVirt.GetEnumerator()){
        if ($name.Length -ne 0){
            $ht=$h.Key+"/hosts?search=name%3D"+$name
        }
        else {
            $ht=$h.Key+"/hosts"
        }
        $cookie = [System.Net.Cookie]::new('JSESSIONID', $h.Value)
        $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $session.Cookies.Add($h.Key, $cookie)
        $result = Invoke-WebRequest -Headers @{"Prefer"="persistent-auth";"Accept"="application/json"} -Method Get -Uri $ht -SkipCertificateCheck -UseBasicParsing -Verbose -WebSession $session
        if ( $result.Count -eq 0 ){
            Write-Error "Output of request to ZVirtHost is empty"
        }
        $RAWData=$result.Content
        $result=$result | ConvertFrom-Json -AsHashtable
        foreach($i in $result["host"]){

            $hostinfo=@{"Name" = $i["name"];"ip"=$i["address"];"os"=$i["os"]["version"];"memory"=$i["memory"];"CPU"=$i["cpu"];"serial number"=$i["hardware_information"]["serial_number"];"cluster"=$i["cluster"]["id"];"state"=$i["status"]}
            [void]$list.Add([pscustomobject]$hostinfo)
        }
        $RAWData=@{"RAWData"=$RAWData}
        [void]$list.Add([pscustomobject]$RAWData)


    }
    return $list

}

function Get-zVirtStores {
    param (
        [Parameter(Mandatory=$false)]       [string] $name
    )
    $list=[System.Collections.ArrayList]::new()
    $RAWData=""
    if ( $ZVirt.Count -eq 0 ){
        Write-Error "There is no ZVIRT connections. Create one by Connect-zVirtController"
    }
    foreach ($h in $ZVirt.GetEnumerator()){
        if ($name.Length -ne 0){
            $ht=$h.Key+"/storagedomains?search=name%3D"+$name
        }
        else {
            $ht=$h.Key+"/storagedomains"
        }
        $cookie = [System.Net.Cookie]::new('JSESSIONID', $h.Value)
        $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $session.Cookies.Add($h.Key, $cookie)
        $result = Invoke-WebRequest -Headers @{"Prefer"="persistent-auth";"Accept"="application/json"} -Method Get -Uri $ht -SkipCertificateCheck -UseBasicParsing -Verbose -WebSession $session
        if ( $result.Count -eq 0 ){
            Write-Error "Output of request to ZVirtHost is empty"
        }
        $RAWData=$result.Content
                $result=$result | ConvertFrom-Json -AsHashtable
        foreach($i in $result["storage_domain"]){
            $total=0
            try {
                $total=[Int64]$i["available"]+[int64]$i["used"]
            }
            catch {
                $total=0
            }
            $hostinfo=@{"Name" = $i["name"];"type"=$i["storage"]["type"];"total"= $total;"available"=$i["available"];"used"=$i["used"]}
            [void]$list.Add([pscustomobject]$hostinfo)
        }
        $RAWData=@{"RAWData"=$RAWData}
        [void]$list.Add([pscustomobject]$RAWData)


    }
    return $list

}

function Get-zVirtVMs {
    param (
        [Parameter(Mandatory=$false)]       [string] $name,
        [Parameter(Mandatory=$false)]       [string] $ID
    )
    $list=[System.Collections.ArrayList]::new()
    $RAWData=""
    if ( $ZVirt.Count -eq 0 ){
        Write-Error "There is no ZVIRT connections. Create one by Connect-zVirtController"
    }
    foreach ($h in $ZVirt.GetEnumerator()){
        if ($name.Length -ne 0){
            $ht=$h.Key+"/vms?search=name%3D"+$name+"&follow=disk_attachments.disk,cluster,hostdevices,cpu_profile,nics"
        }
        elseif ($ID.Length -ne 0) {
            $ht=$h.Key+"/vms/"+$ID+"?follow=disk_attachments.disk,cluster,hostdevices,cpu_profile,nics"
        } 
        else{
            $ht=$h.Key+"/vms?follow=disk_attachments.disk,cluster,hostdevices,cpu_profile,nics"
        }
        $cookie = [System.Net.Cookie]::new('JSESSIONID', $h.Value)
        $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $session.Cookies.Add($h.Key, $cookie)
        $result = Invoke-WebRequest -Headers @{"Prefer"="persistent-auth";"Accept"="application/json"} -Method Get -Uri $ht -SkipCertificateCheck -UseBasicParsing -Verbose -WebSession $session
        if ( $result.Count -eq 0 ){
            Write-Error "Output of request to ZVirtHost is empty"
        }
        $RAWData=$result.Content
        $result=$result | ConvertFrom-Json -AsHashtable
        foreach($i in $result["vm"]){
            Write-Host $i
            $hostinfo=@{"NameVM" = $i["name"];"description"=$i["description"];"comment"= $i["comment"];"cpu"=$i["cpu"]| ConvertTo-Json;"memory"=$i["memory"];"cluster"=$i["cluster"]| ConvertTo-Json;"disk_attachments"=$i["disk_attachments"]| ConvertTo-Json;"host_devices"=$i["host_devices"]| ConvertTo-Json;"nics"=$i["nics"]| ConvertTo-Json}
            [void]$list.Add([pscustomobject]$hostinfo)
        }
        $RAWData=@{"RAWData"=$RAWData}
        [void]$list.Add([pscustomobject]$RAWData)


    }
    return $list | Format-List

}


function Get-zVirtVMDisks {
    param (
        [Parameter(Mandatory=$false)]       [string] $VMName
    )
    $list=[System.Collections.ArrayList]::new()
    $RAWData=""
    if ( $ZVirt.Count -eq 0 ){
        Write-Error "There is no ZVIRT connections. Create one by Connect-zVirtController"
    }
    foreach ($h in $ZVirt.GetEnumerator()){
        if ($VMName.Length -ne 0){
            $ht=$h.Key+"/vms?search=name%3D"+$VMName+"&follow=disk_attachments.disk"
        }
        else {
            $ht=$h.Key+"/vms?follow=disk_attachments.disk"
        }
        $cookie = [System.Net.Cookie]::new('JSESSIONID', $h.Value)
        $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
        $session.Cookies.Add($h.Key, $cookie)
        $result = Invoke-WebRequest -Headers @{"Prefer"="persistent-auth";"Accept"="application/json"} -Method Get -Uri $ht -SkipCertificateCheck -UseBasicParsing -Verbose -WebSession $session
        if ( $result.Count -eq 0 ){
            Write-Error "Output of request to ZVirtHost is empty"
        }
        $RAWData=$result.Content 
        $result=$result | ConvertFrom-Json -AsHashtable
        foreach($i in $result["vm"]){
            foreach($j in $i["disk_attachments"]["disk_attachment"]){
                $diskinfo=@{"NameVM" = $i["name"];"disk_size" = $j["disk"]["actual_size"];"storage_type"=$j["disk"]["storage_type"];"status"=$j["disk"]["status"]}
            }
            [void]$list.Add([pscustomobject]$diskinfo)
        }
        $RAWData=@{"RAWData"=$RAWData}
        [void]$list.Add([pscustomobject]$RAWData)


    }
    return $list | Format-List

}