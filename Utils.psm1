function PutInQuotesIfNeeded([string] $str) {
    if ($str.Contains(" ") -and -not $str.StartsWith('"')) {
        return "`"$str`""
    } else {
        return $str
    }
}

Export-ModuleMember PutInQuotesIfNeeded

function TransformParameters([string[]] $params) {
    $params | ForEach-Object { PutInQuotesIfNeeded $_ }
}

Export-ModuleMember TransformParameters

function FileWithoutExt([string] $fileName) {
    [System.IO.Path]::GetFileNameWithoutExtension($fileName)
}

Export-ModuleMember FileWithoutExt

function FileExt([string] $fileName) {
    [System.IO.Path]::GetExtension($fileName)
}

Export-ModuleMember FileExt

function CreateSymbolicLink([string] $link, [string] $target) {
    if (Test-Path -LiteralPath $link -PathType Leaf) {
        Remove-Item $link
    }
    
    Start-Process "cmd" -ArgumentList "/c", "mklink", (PutInQuotesIfNeeded $link), (PutInQuotesIfNeeded $target) -Wait
}

Export-ModuleMember CreateSymbolicLink

function CreateDir([string] $dirName) {
    if (!(Test-Path -LiteralPath $dirName -PathType Container)) {
        New-Item $dirName -ItemType Directory | Out-Null
    }
}

Export-ModuleMember CreateDir

function ContainsMember([object] $obj, [string] $name) {
	return $null -ne (Get-Member -Name $name -inputObject $obj)
}

Export-ModuleMember ContainsMember