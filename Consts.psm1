class Consts {        
    static [string[]] $InvalidFilenameChars = '<', '>', '"', '\\', '|', '?', '*'
    static [string] $MameFileName
    static [string] $HashDirectory
    static [string] $MameSpecificVersionsFolder
    static [string] $DefaultStaFolder
    static [string] $ImgTool

    static [void] Initialize([object] $Settings) {
        [Consts]::MameFileName = "$($Settings.MameBaseFileName).exe"
        [Consts]::HashDirectory = (Join-Path $Settings.MameDir "hash")
        [Consts]::MameSpecificVersionsFolder = (Join-Path $Settings.StateDirectoryBase "Versions")
        [Consts]::DefaultStaFolder = (Join-Path $Settings.StateDirectoryBase "Default")
        [Consts]::ImgTool = (Join-Path $Settings.MameDir "imgtool.exe")
    }
}
