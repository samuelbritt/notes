function Find-Note
{
    [CmdletBinding()]
    param(
        [string] $Pattern,
        [string[]] $Tag
    )
    begin
    {
        function Test-NoteMatchesPattern
        {
            param(
                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [string] $Name,
                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [string] $Path,
                [Parameter(Mandatory)]
                [string] $Pattern
            )
            Set-StrictMode -Version Latest
            ($Name -match $Pattern) -or (Select-String $Pattern -Path $Path -Quiet)
        }
    }
    process
    {
        Set-StrictMode -Version Latest

        $path = $script:NotesPath

        Get-ChildItem $path -Recurse -Include *.md |
            ForEach-Object {
            $note = $_ | Get-Note

            Write-Verbose "Searching $($note.Name) ( $($note | ConvertTo-Json -Compress ) )"

            $match = $true
            if ($match -and $Pattern -and !($note | Test-NoteMatchesPattern -Pattern $Pattern))
            {
                $match = $false
            }

            if ($match -and $Tag -and ($Tag | Where-Object { $note.Tags -notcontains $_ }))
            {
                $match = $false
            }

            if ($match)
            {
                Write-Output $note
            }
        }
    }
}

Set-Alias fn Find-Note
