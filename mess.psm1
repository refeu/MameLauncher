[hashtable] $Settings = @{
    MameBaseFileName = "mame64"
    StateDirectoryBase = "C:\Users\Heads\OneDrive\SAVEDG~1\Mess\sta"    
    MameDir = "D:\Emulators\Mame64"
    TemporaryRomsDirectory = "D:\Emulators\Mame64\roms"
    VersionFilename = "version.txt"
    CybikoBaseImage = "R:\MAME Assets\Software\cybiko\cybiko.bin"

    SoftwareLists = @{
        aes = "neogeo"
        bbcb = @{
            ROMs = "bbc_rom"
        }
        bbcm = @{
            Cartridges = "bbcm_cart"
        }
        electron = @{
            Cartridges = "electron_cart"
            ROMs = "electron_rom"
        }
        gba = "gba"
        mpt02 = "studio2"
        pegasus = "pegasus_cart"
        pegasusm = "pegasus_cart"
        pico = "pico"
        plus4 = @{
            Cartridges = "plus4_cart"
        }
        plus4p = @{
            Cartridges = "plus4_cart"
        }
        scv = "scv"
        supracan = "supracan"
        vic10 = "vic10"
        vsmile = "vsmile_cart", "vsmilem_cart"
        vsmileg = "vsmile_cart", "vsmilem_cart"
        vsmilef = "vsmile_cart", "vsmilem_cart"
    }

    InferSwitchesSystems = @{
        a2600 = @{
            Cartridges = "-cart"
            Cassettes = "-cass"
        }
        a2600p = @{
            Cartridges = "-cart"
        }
        a800 = @{
            Cartridges = "-cart1"
            "Floppy disks" = "-flop1"
            Cassettes = "-cass"
        }
        a800pal = @{
            Cartridges = "-cart1"
            "Floppy disks" = "-flop1"            
        }
        apple2ep = @{
            "5.25 miscellaneous disks" = "-flop1"
            "5.25 original disks" = "-flop1"
            Cassettes = "-cass"
            "Cleanly cracked 5.25 disks" = "-flop1"
        }
        atom = @{
            Cassettes = "-cass"
            "Disk images" = "-flop1"
            "Utility ROMs" = "-cart"
        }
        bbcb = @{
            "Acorn 65C102 Co-Processor discs" = "65c102"
            "Acorn 6502 2nd Processor discs" = "6502"
            "Acorn 32016 Co-Processor discs" = "32016"
            "Acorn ARM Co-Processor discs" = "arm"
            "Acorn Z80 2nd Processor discs" = "z80"
            "Casper 68000 2nd Processor discs" = "casper"
            "Model A cassettes" = "bbca"
            "Model B (German) cassettes" = "bbcb_de"
            "Model B (US) disks" = "bbcb_us"
            "Model B cassettes" = "-cass"
            "Model B disks" = "-flop1"
            "Model B Original disks" = "-flop1"
            "Torch Z80-68000 Co-Processor discs" = "torchf"            
        }
        bbcm = @{
            "Acorn 80186 Co-Processor discs" = "bbcm512"
            Cassettes = "-cass"
            Disks = "-flop1"
            "Master Compact disks" = "bbcmc"
        }
        cpc6128 = @{
            Cassettes = "-cass"
            "Disk images" = "-flop1"
        }
        electron = @{
            Cartridges = "-cart1"
            Cassettes = "-cass"
            Disks = "-flop"
            ROMs = "-rom1"
        }
        fmtmarty = @{
            "CD-ROMs" = "-cdrm"
            "Disk images" = "-flop1"
        }
        plus4 = @{
            Cassettes = "-cass"
            Diskettes = "-flop"
        }
        hx10 = @{
            Cartridges = "-cart"
            Cassettes = "-cass"
            Diskettes = "-flop"
        }
        intvoice = @{
            Cartridges = "-cart"
            "ECS cartridges" = "intvecs"
        }
        nms8250 = @{
            Cartridges = "-cart1"
            Cassettes = "-cass"
            Diskettes = "-flop"
        }
        sc3000h = @{
            Cartridges = "-cart"
            Cassettes = "-cass"
            "Super Control Station SF-7000 disk images" = "-flop"
        }
        snes = @{
            Cartridges = "-cart"
            "Sufami Turbo cartridges" = "-cart2"
        }
        spectrum = @{
            "+3 disk images" = "-flop1"
            "Beta Disc & TR-DOS disk images" = "pentagon"
            Cartridges = "-cart"
            Cassettes = "-cass"
            "MGT Disciple - Plus D disks" = "plusd"
            "Microdrive tapes & cartridges" = "-magt1"
            "Opus Discovery disk images" = "opus"
            "Wafadrive tapes & cartridges" = "wafadrive"
        }
        x1turbo40 = @{
            Cassettes = "-cass"
            "Disk images" = "-flop1"
        }
    }

    DummyMachines = "gnw", "electronic"
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
            if ($romType -eq "bbca") {
                $state.ArgsToMame = @("bbca", "-cass") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "torchf") {
                $state.ArgsToMame = ("torchf", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "bbcb_de") {
                $state.ArgsToMame = ("bbcb_de", "-cass") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "bbcb_us") {
                $state.ArgsToMame = ("bbcb_us", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "z80") {
                $state.ArgsToMame = ("bbcb", "-tube", "z80", "-flop1", "cpmsys", "-flop2") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 4
            } elseif (($romType -eq "65c102") -or ($romType -eq "6502") -or ($romType -eq "32016") -or ($romType -eq "arm") -or ($romType -eq "casper"))  {
                $state.ArgsToMame = ("bbcb", "-tube", $romType, "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
                $state.RomArgIdx += 2
            }

            break
        }
        "bbcm" {
            if ($romType -eq "bbcm512") {
                $state.ArgsToMame = ("bbcm512", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
            } elseif ($romType -eq "bbcmc") {
                $state.ArgsToMame = ("bbcmc", "-flop1") + $state.ArgsToMame[2..($state.ArgsToMame.Length)]
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