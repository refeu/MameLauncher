using module .\mess.psm1

[State] $state = New-Object State -Property @{ ArgsToMame = $args }

if ($args.Length -lt 2) {
    InvokeMame $state
    Break
}

InitializeInferSwitches $state
[string[]] $temporaryFiles = InitializeSpecialSystems $state
[string] $romLinkName = InitializeSoftwareListRom $state
[string] $usedStateFolder = InitializeStateDirectory $state
InitializeLaunchboxRom $state
InvokeMame $state
FinalizeStateDirectory $state $usedStateFolder
FinalizeSoftwareListRom $romLinkName
FinalizeSpecialSystems $temporaryFiles