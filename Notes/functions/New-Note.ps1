function New-Note
{
    param(
        [string] $Title = "Untitled",
        [string[]] $Tag = '-'
    )
    Set-StrictMode -Version Latest

    $notesPath = $script:NotesPath
    $now = Get-Date
    $nowForFileName = $now.ToString('yyyy-MM-dd_HHmmss')
    $nowForFileMetadata = $now.ToString('yyyy-MM-ddTHH:mm:ss')

    $fileName = "$nowForFileName-${Title}.md"
    $fileName = $fileName.Replace(' ', '-')
    $path = Join-Path $notesPath $fileName
    if (Test-Path $path)
    {
        throw ($script:Errors.PATH_EXISTS -f $path)
    }

    $content = Get-Content $script:NoteTemplate -Raw
    $content = $content.Replace('${TITLE}', $title)
    $content = $content.Replace('${AUTHOR}', $env:USERNAME)
    $content = $content.Replace('${DATE}', $nowForFileMetadata)
    $content = $content.Replace('${TAGS}', ($Tag -join ','))

    New-Item $path -ItemType File -Value $content | Open-Note -ScrollToEnd
}

Set-Alias nn New-Note
