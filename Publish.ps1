using module ./StepAutomation.psd1
param(
    [parameter(mandatory)]
    [string]$Secret
)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Try{
    if((Get-PackageProvider).Name -notcontains "NuGet"){
        $installResult = Install-PackageProvider -Name NuGet -Force -Confirm:$false -ErrorAction Stop
        Write-Host Installed NuGet Version $($installResult.Version.ToString())
    }
}catch{
    Throw $_
}

Try {
    $PSGalleryVersion = Find-Module StepAutomation -ErrorAction Stop | Select-Object -ExpandProperty Version
} catch {
    Throw "Cannot get Module info from PSGallery; $($_.Exception.Message)"
}
Try{
    $localVersion = Get-Module StepAutomation -ErrorAction Stop | Select-Object -ExpandProperty Version
} catch{
    Throw "Cannot get local Module info; $($_.Exception.Message)"
}
if($null -ne $PSGalleryVersion){
    if($PSGalleryVersion -lt $localVersion){
        $moduleDir = "C:\Program Files\WindowsPowershell\Modules\StepAutomation"
        Try{
            if(!(Test-Path $moduleDir)){
                New-Item -ItemType Directory $moduleDir -Force | Out-Null
            }
            Copy-Item .\StepAutomation.psd1,.\StepAutomation.psm1,.\Assemblies\ -Recurse -Destination $moduleDir -Force
            Publish-Module -Path $moduleDir -NuGetApiKey $Secret -Repository PSGallery -Force -Confirm:$False -ErrorAction Stop
            Write-Host Module Version Updated to $localVersion
        }catch{
            throw $_
        }
    }else{
        Write-Host PSGallery version is equal with current version $localVersion, Skipping Publish Stage
    }
}else{
    Throw "PSGallery Version is null"
}