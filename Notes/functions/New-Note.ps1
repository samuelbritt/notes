function New-Note
{
    param(
        [string] $Title = "Untitled",
        [string[]] $Tag = '-'
    )
    begin
    {
        function Get-Path
        {
            param(
                [string] $Title,
                [datetime] $Date
            )
            Set-StrictMode -Version Latest
            $notesPath = $script:NotesPath

            $invalidCharacters = [System.IO.Path]::GetInvalidFileNameChars()
            $titleForPath = $Title.ToLower().Replace(' ', '-')
            $titleForPath = $titleForPath.Split($invalidCharacters, [System.StringSplitOptions]::RemoveEmptyEntries) -join '_'

            $now = $Date.ToString('yyyy-MM-dd_HHmmss')
            $fileName = "${now}-${titleForPath}.md"

            Join-Path $notesPath $fileName
        }
    }
    process
    {
        Set-StrictMode -Version Latest

        $date = Get-Date
        $path = Get-Path -Title $Title -Date $date
        if (Test-Path $path)
        {
            throw ($script:Errors.PATH_EXISTS -f $path)
        }

        $Title = ConvertTo-TitleCase $Title
        $content = Get-Content $script:NoteTemplate -Raw
        $content = $content.Replace('${TITLE}', $Title)
        $content = $content.Replace('${AUTHOR}', $env:USERNAME)
        $content = $content.Replace('${DATE}', $date.ToString('yyyy-MM-ddTHH:mm:ss'))
        $content = $content.Replace('${TAGS}', ($Tag -join ', '))

        $note = New-Item $path -ItemType File -Value $content | Get-Note
        $note | Open-Note -ScrollToEnd
        $note
    }
}

Set-Alias nn New-Note
