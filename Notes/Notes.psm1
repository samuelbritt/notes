$imports = "functions", "constants" |
    ForEach-Object { "$PSScriptRoot\$_\*.ps1" } |
    Where-Object { Test-Path $_ } |
    Get-ChildItem -Exclude '*.Tests.ps1'

$imports | ForEach-Object {
    . $_.FullName
}

Invoke-Startup