#
# Module manifest for module 'StepAutomation'
#
# Generated by: Ogtay Garayev
#
# Generated on: 4/24/2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'StepAutomation.psm1'

# Version number of this module.
ModuleVersion = '1.1.3'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '4f3ddd45-020d-4c2a-8343-213807cf0070'

# Author of this module
Author = 'Ogtay Garayev'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) Ogtay Garayev. All rights reserved.'

# Description of the functionality provided by this module
Description = @'
This module allows administrators, testers to automate sequential steps (configuration based).

The module provides classes for automating operations. You can also easily extend the module with adding your own custom operations.

The Module also provides classes for automating Web Page actions over Chrome Web Browser (e.g. navigating, clicking, text adding) and some default methods for this.
'@

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = 'Assemblies/WebDriver.dll'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = '*'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'PSModule','PSEdition_Desktop','PSEdition_Core','Windows','Linux','Ubuntu','PowerShell'

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/okaraev/StepAutomation'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}


# SIG # Begin signature block
# MIIFZwYJKoZIhvcNAQcCoIIFWDCCBVQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURLt5txv+DF93qXv5/YBW/4s2
# xMKgggMEMIIDADCCAeigAwIBAgIQbPi4sIAtyKVLGqoZHqXXlTANBgkqhkiG9w0B
# AQsFADAYMRYwFAYDVQQDDA1PZ3RheSBHYXJheWV2MB4XDTIxMDczMDE0MjQzMloX
# DTIyMDczMDE0NDQzMlowGDEWMBQGA1UEAwwNT2d0YXkgR2FyYXlldjCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBALYXMDLGDEKJ/pV58dD5KbOMMPTFGFXd
# ItI3TZrHeCvS0y234HdH35e9syi//ELK62bs8QlBSFKKa47BL1pvjpkbXXuB0OVF
# f+gLxel5XYHS3cMKu4NVrKR3gY+mDWIZc5oJzr6kWvYiKb4ZG7cKBr+7UoFSINtB
# 9kvIBPbWglcCMlvzbkDD520j73+0XvqKI5rgt0Y+MPlEcb9gsYHxsXeSwDotCpe7
# 17Huz/eJ2Yg7nG2ns2UB4jDWpOOul1uMeoETf7ofBzpv7HxL8P4BaKuFWjlvhcUT
# DSjDaICmzeWbvzr/c8gery5b4TobrT7z46iKi1qWWLd3R2Ii+HVQ0lECAwEAAaNG
# MEQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMB0GA1UdDgQW
# BBSpQGoWjLBKEBibL7lPaCEOCN74TzANBgkqhkiG9w0BAQsFAAOCAQEAVQzjCunl
# iqpSE00SAXtN2nuEUV3caIdvQ5NWlCZSdF7XliKSG9RC/aZ5zDfIYKNdCc+dwz1z
# Dn0aMhT3q96KWMBOPw9oLfF1SyccAH4gKRfqELn7K+dsUvMNSS8WUc9bbQzj5Wyh
# ywkd+Dzrrxot+aLUYltV7hZ0BppdQAlKSl81NpW/wc0DIj5I1LTsOYUAqwqGi+vz
# 1pe02hZ4cykEJ9f86JcF2otVnK2s6dVPf4TMfyEXCoKJtpcqrVbzuEbzna1tkkKN
# XHD8d/BZIQsTW9bgxok4DotADEHdvA+NKpRmT1p4OMuGZTUaqpWUqSbqd+8Bdv40
# SLptB0yXRqJQ5DGCAc0wggHJAgEBMCwwGDEWMBQGA1UEAwwNT2d0YXkgR2FyYXll
# dgIQbPi4sIAtyKVLGqoZHqXXlTAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEK
# MAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3
# AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUM3yOeWvQPvRggh5s
# PGxyEGoh0ZEwDQYJKoZIhvcNAQEBBQAEggEAjF2XaixIpircEJeIgXEXkALCy9Cr
# oYDGoetknObrLeKsksJstPLOI7xYvd5Hgf5Dk4VE68d1mwzvakII4fKKxNRVsCkv
# G4vjnVpXCkZVdOpH/ZOwvMyWHgp8GxWz0RH6vAY6eEBrbTuUftEpULvGbaga671L
# xD2F23ksBXmP5YSxy95v3+HpjtkHvC5uhvUl0+GiATcBRJUznMpf95oKtx5VVbWb
# xmMrhxV+6Gl8NI9oLC9nbIgJnh0Ri+8MDrI6UYCXZsZcsJYo/gjIhCloh6gHwW+t
# V4H55Ppjc/Wh4GLBgBygHPJHHXB6t48w+VcWpeEIvTHvb4Bx9sc0P7H+Jw==
# SIG # End signature block
