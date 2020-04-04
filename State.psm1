using module ".\Consts.psm1"
using module ".\Utils.psm1"

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

    static [void] Initialize([object] $Settings) {
        [State]::StateDirectoryBase = $Settings.StateDirectoryBase
    }
}
