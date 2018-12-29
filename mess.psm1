[hashtable] $Settings = @{
    MameBaseFileName = "mame64"
    StateDirectoryBase = "C:\Users\Heads\OneDrive\SAVEDG~1\Mess\sta"    
    MameDir = "D:\Emulators\Mame64"
    TemporaryRomsDirectory = "D:\Emulators\Mame64\roms"
    VersionFilename = "version.txt"
    CybikoBaseImage = "R:\MAME Assets\Software\cybiko\cybiko.bin"
    
    SoftwareLists = @{
        plus4 = "plus4_cart";
        plus4p = "plus4_cart";
        vic10 = "vic10";
        scv = "scv";
        supracan = "supracan";
        mpt02 = "studio2";
    }

    InferSwitchesSystems = @{
        a2600 = @{
            Cartridges = "-cart";
            Cassettes = "-cass";
        };
        a2600p = @{
            Cartridges = "-cart";
        };
        plus4 = @{
            Cassettes = "-cass";
            Diskettes = "-flop";
        };
        hx10 = @{
            Cartridges = "-cart";
            Cassettes = "-cass";
            Diskettes = "-flop";
        };
        intvoice = @{
            Cartridges = "-cart";
            "ECS cartridges" = "intvecs";
        };
        nms8250 = @{
            Cartridges = "-cart1";
            Cassettes = "-cass";
            Diskettes = "-flop";
        };
        snes = @{
            Cartridges = "-cart";
            "Sufami Turbo cartridges" = "-cart2";
        };
        spectrum = @{
            Cartridges = "-cart";
            Cassettes = "-cass";
            Diskettes = "-flop1";
        }
    }

    DummyMachines = "gnw", "hh"
}

class Consts {        
    static [string[]] $InvalidFilenameChars = '<', '>', '"', '\\', '|', '?', '*'
    static [string] $MameFileName
    static [string] $HashDirectory
    static [string] $MameSpecificVersionsFolder
    static [string] $DefaultStaFolder
    static [string] $ImgTool

    static [void] Initialize([hashtable] $Settings) {
        [Consts]::MameFileName = "$($Settings.MameBaseFileName).exe"
        [Consts]::HashDirectory = (Join-Path $Settings.MameDir "hash")
        [Consts]::MameSpecificVersionsFolder = (Join-Path $Settings.StateDirectoryBase "Versions")
        [Consts]::DefaultStaFolder = (Join-Path $Settings.StateDirectoryBase "Default")
        [Consts]::ImgTool = (Join-Path $Settings.MameDir "imgtool.exe")
    }
}

[Consts]::Initialize($Settings)

class State {        
    static [string] $StateDirectoryBase
    
    [string] $MameToInvoke = [Consts]::MameFileName
    [string[]] $ArgsToMame
    [int] $RomArgIdx = 2

    [string] GetRomPath() {
        return $this.ArgsToMame[$this.RomArgIdx]
    }

    [void] SetRomPath([string] $newPath) {
        $this.ArgsToMame[$this.RomArgIdx] = $newPath
    }

    [string] GetSystem() {
        return $this.ArgsToMame[0]
    }

    [string] GetRomName() {
        return FileWithoutExt $this.GetRomPath()
    }

    [string] GetGameStateFolder() {
        return Join-Path ([State]::StateDirectoryBase) "$($this.GetRomName()).$($this.GetSystem())"
    }

    static [void] Initialize([hashtable] $Settings) {
        [State]::StateDirectoryBase = $Settings.StateDirectoryBase
    }
}

[State]::Initialize($Settings)

function PutInQuotesIfNeeded([string] $str) {
    if ($str.Contains(" ") -and -not $str.StartsWith('"')) {
        return "`"$str`""
    } else {
        return $str
    }
}

function TransformParameters([string[]] $params) {
    $params | ForEach-Object { PutInQuotesIfNeeded $_ }
}

function InvokeMame([State] $state) {
    [hashtable] $pArgs = @{}
    
    if ($state.ArgsToMame.Length -gt 0) {
        $pArgs.ArgumentList = TransformParameters $state.ArgsToMame
    }

    [string] $previousLocation = Get-Location
    Set-Location $Settings.MameDir
    Start-Process (Join-Path $Settings.MameDir $state.MameToInvoke) -Wait -NoNewWindow @pArgs
    Set-Location $previousLocation
}

Export-ModuleMember InvokeMame

function FileWithoutExt([string] $fileName) {
    [System.IO.Path]::GetFileNameWithoutExtension($fileName)
}

function FileExt([string] $fileName) {
    [System.IO.Path]::GetExtension($fileName)
}

function GetMameSpecificVersionFile([int] $version) {
    Join-Path ([Consts]::MameSpecificVersionsFolder) "$($Settings.MameBaseFileName).$version.exe"
}

function CreateSymbolicLink([string] $link, [string] $target) {
    if (Test-Path -LiteralPath $link -PathType Leaf) {
        Remove-Item $link
    }
    
    Start-Process "cmd" -ArgumentList "/c", "mklink", (PutInQuotesIfNeeded $link), (PutInQuotesIfNeeded $target) -Wait
}

function CreateDir([string] $dirName) {
    if (!(Test-Path -LiteralPath $dirName -PathType Container)) {
        New-Item $dirName -ItemType Directory | Out-Null
    }
}

function SaveCurrentMameVersion([string] $gameStateFolder) {
    [string] $currentMameVersion = [int] (([double] (Get-Item (Join-Path $Settings.MameDir [Consts]::MameFileName)).VersionInfo.ProductVersion) * 1000)
    Set-Content -LiteralPath $(Join-Path $gameStateFolder $Settings.VersionFilename) $currentMameVersion
    [string] $mameSpecificFile = GetMameSpecificVersionFile $currentMameVersion

    if (!(Test-Path -LiteralPath $mameSpecificFile -PathType Leaf)) {
        CreateDir ([Consts]::MameSpecificVersionsFolder)
        Copy-Item ([Consts]::MameFileName) $mameSpecificFile -Force
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

    if (! $Settings.InferSwitchesSystems.ContainsKey($system)) {
        return
    }    
    
    [hashtable] $inferSwitches = $Settings.InferSwitchesSystems[$system]
    [string] $romType = FindRomType $state.ArgsToMame[1]    

    if ($inferSwitches.ContainsKey($romType)) {
        [string] $switch = $inferSwitches[$romType]
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
            } elseif (($romType -eq "-flop1") -or (($romType -eq "-cass") -and ($state.GetRomName() -like "*128k*"))) {
                $state.ArgsToMame = @("specpls3") + $state.ArgsToMame[1..($state.ArgsToMame.Length)]
            }

            break
        }
    }

    return @()
}

Export-ModuleMember InitializeSpecialSystems

function InitializeSoftwareListRom([State] $state) {
    if (! $Settings.SoftwareLists.ContainsKey($state.GetSystem())) {
        return ""
    }
    
    if ($state.ArgsToMame[1] -like "-*") {
        # The supposed rom name is in fact a switch... So use switch mode instead of software mode
        return ""
    }

    $state.romArgIdx = 1
    $softwareLists = $Settings.SoftwareLists[$state.GetSystem()]

    if ($softwareLists -is [hashtable]) {
        $softwareLists = @($softwareLists[(FindRomType $state.GetRomPath())])
    } else {
        $softwareLists = @($softwareLists)
    }

    foreach ($listName in $softwareLists) {
        [string] $romLinkName = GetLinkForSoftwareList $state.GetRomName() $listName

        if ($romLinkName -ne "") {
            CreateSymbolicLink (Join-Path $Settings.TemporaryRomsDirectory "$romLinkName.zip") $state.GetRomPath()
            $state.SetRomPath($romLinkName)
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
                CreateSymbolicLink $state.MameToInvoke (Join-Path $Settings.MameDir $mameSpecificFile)
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
    
        Remove-Item -LiteralPath $usedStateFolder -Recurse -Force
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