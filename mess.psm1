using module ".\Consts.psm1"
using module ".\State.psm1"

[object] $Settings = Get-Content (Join-Path $PSScriptRoot "settings.json") -Raw | ConvertFrom-Json
[Consts]::Initialize($Settings)
[State]::Initialize($Settings)

function InvokeMame([State] $state) {
    [hashtable] $pArgs = @{}
    
    if ($state.ArgsToMame.Length -gt 0) {
        $pArgs.ArgumentList = TransformParameters $state.ArgsToMame
        [bool] $windowArgPresent = $false

        foreach ($arg in $pArgs.ArgumentList) {
            if (($arg -eq "-window") -or ($arg -eq "-nowindow")) {
                $windowArgPresent = $true
                break
            }
        }

        if ( ! $windowArgPresent) {
            $pArgs.ArgumentList += "-nowindow"
        }
    }

    [string] $previousLocation = Get-Location
    Set-Location $Settings.MameDir
    Start-Process (Join-Path $Settings.MameDir $state.MameToInvoke) -Wait -NoNewWindow @pArgs
    Set-Location $previousLocation
}

Export-ModuleMember InvokeMame

function GetMameSpecificVersionFile([int] $version) {
    Join-Path ([Consts]::MameSpecificVersionsFolder) "$($Settings.MameBaseFileName).$version.exe"
}

function SaveCurrentMameVersion([string] $gameStateFolder) {
    [string] $mameFileName = Join-Path $Settings.MameDir ([Consts]::MameFileName)
    [string] $currentMameVersion = [int] (([double] (Get-Item $mameFileName).VersionInfo.ProductVersion) * 1000)    
    Set-Content -LiteralPath $(Join-Path $gameStateFolder $Settings.VersionFilename) $currentMameVersion
    [string] $mameSpecificFile = GetMameSpecificVersionFile $currentMameVersion

    if (!(Test-Path -LiteralPath $mameSpecificFile -PathType Leaf)) {
        CreateDir ([Consts]::MameSpecificVersionsFolder)
        Copy-Item $mameFileName $mameSpecificFile -Force
    }
}

function GetListDescriptionFilename([string] $description) {
    [string] $result = $description -replace "\s*:\s*", " - "
    $result = $result -replace "\s*/\s*", " & "
    
    foreach ($c in [Consts]::InvalidFilenameChars) {
        $result = $result.Replace($c, " ")
    }
   
    return $result.Trim()   
}

function GetLinkForSoftwareList([string] $romName, [string] $listName) {
    [xml] $xmlList = Get-Content -LiteralPath (Join-Path ([Consts]::HashDirectory) "$listName.xml")
    return ($xmlList.DocumentElement.software | Where-Object { (GetListDescriptionFilename $_.description) -eq $romName }).name
}

function FindRomType([string] $romPath) {
    [string] $parentDirectory = Split-Path $romPath -Parent
    [string] $result = Split-Path $parentDirectory -Leaf
    
    if ($result.Length -eq 1) {  # It's a index directory
        return FindRomType $parentDirectory
    }

    return $result
}

#----------------------------------------------------------------------

function InitializeInferSwitches([State] $state) {
    if ($state.ArgsToMame[1] -like "-*") {
        # The supposed rom name is in fact a switch... So don't infer the switch
        return
    }
    
    [string] $system = $state.GetSystem()

    if (! (ContainsMember $Settings.InferSwitchesSystems $system)) {
        return
    }    
    
    [object] $inferSwitches = $Settings.InferSwitchesSystems.($system)
    [string] $romType = FindRomType $state.ArgsToMame[1]

    if (ContainsMember $inferSwitches $romType) {
        [string] $switch = $inferSwitches.($romType)
        $state.ArgsToMame = ($state.GetSystem(), $switch) + $state.ArgsToMame[1..$state.ArgsToMame.Length]
    }
}

Export-ModuleMember InitializeInferSwitches

function InitializeSpecialSystems([State] $state) {
    [string] $system = $state.GetSystem()

    if ($Settings.DummyMachines.Contains($system)) {
        $state.ArgsToMame = $state.ArgsToMame[1..($state.ArgsToMame.Length)]
        $state.RomArgIdx = 0
        return @()
    }

    [string] $romType = $state.ArgsToMame[1]
    
    switch ($system) {
        "a2600" {
            if ($romType -eq "-cass") {
                $state.ArgsToMame = ("a2600", "-cart", "scharger") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            }

            break
        }
        "a800" {
            if ($romType -eq "-cass") {
                $state.ArgsToMame = ("a800", "-sio", "cassette") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            }

            break
        }
        "apple2ep" {
            if ($romType -eq "-cass") {
                $state.ArgsToMame = ("apple2ep", "-flop1", "dos3383") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            }

            break
        }
        "bbcb" {
            if ($romType -eq "torchf") {
                $state.ArgsToMame = ("torchf", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "bbcb_us") {
                $state.ArgsToMame = ("bbcb_us", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "z80") {
                $state.ArgsToMame = ("bbcb", "-tube", "z80", "-flop1", "cpmsys", "-flop2") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 4
            } elseif (($romType -eq "6502") -or ($romType -eq "32016") -or ($romType -eq "arm") -or ($romType -eq "casper"))  {
                if (($romType -eq "6502") -and ($state.GetRomName() -like "*65c102*")) {
                    $romType = "65c102"
                }

                $state.ArgsToMame = ("bbcb", "-tube", $romType, "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            } elseif ($romType -eq "bbcm512") {
                $state.ArgsToMame = ("bbcm512", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "bbcmc") {
                $state.ArgsToMame = ("bbcmc", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "bbcm") {
                $state.ArgsToMame = ("bbcm", "-cart") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "bbcm-flop1") {
                $state.ArgsToMame = ("bbcm", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "m5000") {
                $state.ArgsToMame = ("bbcb", "-1mhzbus", "m5000", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            }

            break
        }
        "cybikov2" {
            if ((FileExt $state.GetRomPath()) -eq ".app") {
                # We need to invoke the imgtool on the cybiko base image
                [string] $destImg = Join-Path $Settings.TemporaryRomsDirectory "$($state.GetRomName()).bin"
                Copy-Item $Settings.CybikoBaseImage $destImg
                Start-Process ([Consts]::ImgTool) -ArgumentList "put", "cybiko", (PutInQuotesIfNeeded $destImg), (PutInQuotesIfNeeded $state.GetRomPath()), "game.app" -Wait -NoNewWindow
                $state.SetRomPath($destImg)
                return @($destImg)
            }

            break
        }
        "electron" {
            if (($romType -eq "-cart1") -or ($romType -eq "-rom1")) {
                $state.ArgsToMame = @("electron") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                [string] $romLinkName = InitializeSoftwareListRom $state
                [string[]] $newArgs = ("electron", "-exp")

                if ($romType -eq "-cart1") {
                    $newArgs += "plus1"
                } else {
                    $newArgs += "rombox"
                }

                $state.ArgsToMame = $newArgs + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
                return @(Join-Path $Settings.TemporaryRomsDirectory "$romLinkName.zip")
            } elseif ($romType -eq "-flop") {
                $state.ArgsToMame = ("electron", "-exp:plus3:exp", "fbjoy") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            } else {
                $state.ArgsToMame = ("electron", "-exp", "fbjoy") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            } 

            break
        }
        "fmtmarty" {
            if ($romType -notlike "-*") {
                $state.ArgsToMame = ("fmtmarty", "-cdrm") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
            }
        }
        "hx10" { 
            if ($romType -eq "-flop") {
                $state.ArgsToMame = ("hx10", "-cart", "fsfd1") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            }

            break
        }
        "intvoice" { 
            if ($romType -eq "intvecs") {
                $state.ArgsToMame = ("intvecs", "-cart") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            }

            break
        }
        "nes" {
            if ($romType -eq "-cass") {
                [string] $romLinkName = GetLinkForSoftwareList $state.GetRomName() "famicom_cass"

                if ($romLinkName -ne "") {
                    [string] $linkFullPath = Join-Path $Settings.TemporaryRomsDirectory "$romLinkName.zip"
                    CreateSymbolicLink $linkFullPath $state.GetRomPath()
                    $state.ArgsToMame = ("famicom", "-cart", "famibs30", "-exp", "fc_keyboard") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                    $state.romArgIdx += 4
                    return @($linkFullPath)
                }
            }

            break
        }
        "sc3000h" {
            if ($romType -eq "-cass") {
                $state.ArgsToMame = ("sc3000h", "-cart", "basic3") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            } elseif ($romType -eq "-flop") {
                $state.ArgsToMame = @("sf7000") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
            }

            break
        }
        "snes" { 
            if ($romType -eq "-cart2") {
                $state.ArgsToMame = ("snes", "-cart", "sufami") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            }

            break
        }
        "spectrum" {
            if ($romType -eq "-cart") {
                $state.ArgsToMame = ("spectrum", "-exp", "intf2") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            } elseif ($romType -eq "opus") {
                $state.ArgsToMame = ("spectrum", "-exp", "opus", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            } elseif (($romType -eq "-flop1") -or (($romType -eq "-cass") -and ($state.GetRomName() -like "*128k*"))) {
                $state.ArgsToMame = @("specpls3") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "pentagon") {
                $state.ArgsToMame = ("pentagon", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "-magt1") {
                $state.ArgsToMame = ("spectrum", "-exp", "intf1") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            } elseif ($romType -eq "wafadrive") {
                $state.ArgsToMame = ("spectrum", "-exp", "wafadrive", "-magt1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            } elseif ($romType -eq "plusd") {
                if ($state.GetRomName() -like "*DISCiPLE*") {
                    $state.ArgsToMame = ("spectrum", "-exp", "disciple", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                    $state.RomArgIdx += 2
                } else {
                    $state.ArgsToMame = ("spectrum", "-exp", "plusd", "-flop1", "plusdsys", "-flop2") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                    $state.RomArgIdx += 4
                }                
            } elseif ($romType -eq "ts2068") {
                $state.ArgsToMame = ("ts2068", "-cass") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            }

            break
        }
        "vectrex" {
            [string] $firstWordRomName = ($state.GetRomName() -split ' ')[0]
            $state.ArgsToMame += ("-view", $firstWordRomName)
        }
        "x68000" {
            $state.ArgsToMame += ("-flop2", $state.GetRomPath())
        }
        "x1turbo40" {
            if ($romType -eq "-cass") {
                $state.ArgsToMame += ("-flop2", "tapbas")
            }
        }
    }

    return @()
}

Export-ModuleMember InitializeSpecialSystems

function InitializeSoftwareListRom([State] $state) {
    if (! (ContainsMember $Settings.SoftwareLists $state.GetSystem())) {
        return ""
    }

    if ($state.ArgsToMame[1] -notlike "-*") {
        # The supposed switch is in fact a rom name...
        $state.RomArgIdx = 1        
    }

    if ((FileExt $state.GetRomPath()).ToLower() -ne ".zip") {
        return ""
    }
        
    $softwareLists = $Settings.SoftwareLists.($state.GetSystem())

    if ($softwareLists -is [PSCustomObject]) {
        [string] $romType = FindRomType $state.GetRomPath()

        if (! (ContainsMember $softwareLists $romType)) {
            return ""
        }

        $softwareLists = @($softwareLists.($romType))
    } else {
        $softwareLists = @($softwareLists)
    }

    foreach ($listName in $softwareLists) {
        [string] $romLinkName = GetLinkForSoftwareList $state.GetRomName() $listName

        if ($romLinkName -ne "") {
            CreateSymbolicLink (Join-Path $Settings.TemporaryRomsDirectory "$romLinkName.zip") $state.GetRomPath()
            $state.ArgsToMame = ($state.ArgsToMame[0], $romLinkName) + $state.ArgsToMame[($state.romArgIdx + 1)..($state.ArgsToMame.Length)]
            $state.romArgIdx = 1
            return $romLinkName
        }
    }

    return ""
}

Export-ModuleMember InitializeSoftwareListRom

function InitializeStateDirectory([State] $state) {
    [string] $gameStateFolder = $state.GetGameStateFolder()
    [string] $stateDirectory = ""

    if (Test-Path -LiteralPath $gameStateFolder -PathType Container) {
        $stateDirectory = $gameStateFolder
        [string] $versionFilePath = Join-Path $gameStateFolder $Settings.VersionFilename
        
        if (Test-Path -LiteralPath $versionFilePath -PathType Leaf) {
            [int] $versionToUse = [int] (Get-Content -LiteralPath $versionFilePath -ReadCount 1)
            [string] $mameSpecificFile = GetMameSpecificVersionFile $versionToUse
    
            if (Test-Path -LiteralPath $mameSpecificFile -PathType Leaf) {
                $state.MameToInvoke = (Split-Path $mameSpecificFile -Leaf)
                CreateSymbolicLink (Join-Path $Settings.MameDir $state.MameToInvoke) $mameSpecificFile
            } else {
                SaveCurrentMameVersion $gameStateFolder
            }
        } else {
            SaveCurrentMameVersion $gameStateFolder
        }    
    
        [string] $lastStaFile = Get-ChildItem -LiteralPath $gameStateFolder -Filter "*.sta" -Recurse -Exclude "auto.sta" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 `
            | ForEach-Object { $_.FullName }
    
        if ($lastStaFile -ne "") {
            [int] $staNumber = [int] (FileWithoutExt $lastStaFile)
            $state.ArgsToMame += "-state"
            $state.ArgsToMame += $staNumber
        }
    } else {
        $stateDirectory = [Consts]::DefaultStaFolder
        CreateDir $stateDirectory
    }

    $state.ArgsToMame += "-state_directory"
    $state.ArgsToMame += $stateDirectory
    return $stateDirectory
}

Export-ModuleMember InitializeStateDirectory

function InitializeLaunchboxRom([State] $state) {
    if ((FileExt $state.GetRomPath()) -eq ".launchbox") {
        [string[]] $newArgsToMame = @($state.GetSystem())
    
        if ($state.ArgsToMame.Length -gt ($state.RomArgIdx + 1)) {
            $newArgsToMame += $state.ArgsToMame[$($state.RomArgIdx + 1)..$state.ArgsToMame.Length]
        }
    
        $state.ArgsToMame = $newArgsToMame
    }
}

Export-ModuleMember InitializeLaunchboxRom

function FinalizeStateDirectory([State] $state, [string] $usedStateFolder) {
    if ($state.MameToInvoke -ne ([Consts]::MameFileName)) {
        Remove-Item (Join-Path $Settings.MameDir $state.MameToInvoke)
    }
    
    if ($usedStateFolder -eq ([Consts]::DefaultStaFolder)) {
        if ((Get-ChildItem -LiteralPath $usedStateFolder -Filter "*.sta" -Recurse).Length -gt 0) {
            [string] $gameStateFolder = $state.GetGameStateFolder()
            CreateDir $gameStateFolder
            Get-ChildItem -LiteralPath $usedStateFolder | ForEach-Object { Move-Item -LiteralPath $_.FullName $gameStateFolder -Force }
            SaveCurrentMameVersion $gameStateFolder
        }
    
        [object[]] $items = Get-ChildItem -LiteralPath $usedStateFolder -Recurse

        foreach ($item in $items) {
            if ($item.PSIsContainer -eq $false) {
                try {
                    $item.Delete()
                }
                catch {
                    Write-Warning "FinalizeStateDirectory - Couldn't delete $($item.FullName), error: $($_.Exception.Message)"
                }
            }
        }

        $items = Get-ChildItem -LiteralPath $usedStateFolder -Recurse
        foreach ($item in $items) {
            try {
                $item.Delete()
            }
            catch {
                Write-Warning "FinalizeStateDirectory - Couldn't delete $($item.FullName), error: $($_.Exception.Message)"
            }
        }
        
        [System.IO.DirectoryInfo] $item = Get-Item -LiteralPath $usedStateFolder
        try {
            $item.Delete($true)
        }
        catch {
            Write-Warning "FinalizeStateDirectory - Couldn't delete $($item.FullName), error: $($_.Exception.Message)"
        }
    }
}

Export-ModuleMember FinalizeStateDirectory

function FinalizeSoftwareListRom([string] $romLinkName) {
    if ($romLinkName -ne "") {
        Remove-Item (Join-Path $Settings.TemporaryRomsDirectory "$romLinkName.zip")
    }
}

Export-ModuleMember FinalizeSoftwareListRom

function FinalizeSpecialSystems([string] $temporaryFiles) {
    $temporaryFiles | Where-Object { $_ -ne "" } | ForEach-Object { Remove-Item $_ }
}

Export-ModuleMember FinalizeSpecialSystems