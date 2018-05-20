function Get-Note
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Path
    )
    process
    {
        Set-StrictMode -Version Latest
        $metadataKeys = @("Title", "Author", "Date", "Tags") -join '|'
        $pattern = "^(?<key>${metadataKeys}):\s*(?<value>.*)$"

        if (!(Test-Path $Path))
        {
            throw ($script:Errors.INVALID_PATH -f $Path)
        }

        $pathSep = [System.IO.Path]::DirectorySeparatorChar
        $item = Get-Item $Path
        $name = $item.FullName.Replace($script:NotesPath, '').Trim($pathSep)
        $name = [Regex]::Replace($name, '\.md$', '')
        $note = New-Object psobject -Property ([ordered] @{
                Name = $name
                Title = $name
                Path = $item.FullName
                Created = $item.CreationTime
                Updated = $item.LastWriteTime
                Tags = @()
            })

        $item |
            Select-String -Pattern $pattern |
            Select-Object -ExpandProperty Matches |
            ForEach-Object {
            $key = $_.Groups['key'] | Select-Object -ExpandProperty Value
            $value = $_.Groups['value'] | Select-Object -ExpandProperty Value

            if (!$key -or !$value -or $value -eq '-')
            {
                return
            }

            switch ($key)
            {
                "tags"
                {
                    $value = @($value -split ',' | ForEach-Object { $_.Trim() })
                    if ($value -ne '-')
                    {
                        $note.Tags += $value
                    }
                }
                "date"
                {
                    [datetime] $d = Get-Date
                    if ([System.DateTime]::TryParse($value, [ref]$d))
                    {
                        $note.Created = $d
                    }
                }
                "title"
                {
                    $note.Title = $value
                }
            }
        }

        $note
    }
}
