using module ./StepAutomation.psd1
param(
    [parameter(mandatory)]
    [string]$Secret
)

function Update-File{
    [CmdletBinding()]
    param(
        [parameter(Mandatory,Position=0)]
        [System.IO.FileInfo[]]$Source,
        [parameter(Mandatory,Position=1)]
        [System.IO.FileInfo]$Destination
    )
    foreach($SourceItem in $Source){
        $dstFile = $Destination
        $needToCopy = $false
        if(!$Destination.Name){
            [System.IO.FileInfo]$dstFile = "$($Destination.Directory)\$($SourceItem.Name)"
        }
        if(!$SourceItem.Name){
            throw "Source must be an File path array"
        }
        if(!$dstFile.Exists){
            $needToCopy = $true
        }
        elseif((Get-FileHash -Path $SourceItem).Hash -ne (Get-FileHash $dstFile).Hash){
            $needToCopy = $true
        }
        if($needToCopy){
            Try{
                Copy-Item -Path $SourceItem -Destination $dstFile -Force -ErrorAction Stop
                Write-Verbose -Message "Updating $dstFile with $SourceItem"
            }catch{
                throw $_
            }
        }
    }
}

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
        Try{
            if(!(Test-Path .\tmp)){
                New-Item -ItemType Directory tmp | Out-Null
            }
            Copy-Item .\StepAutomation.psd1,.\StepAutomation.psm1,.\Assemblies\ -Recurse -Destination .\tmp\ -Force
            Publish-Module -Path .\tmp -NuGetApiKey $Secret -Repository PSGallery -Force -Confirm:$False -ErrorAction Stop
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