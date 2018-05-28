$script:Editor = if ($env:NOTES_EDITOR) { $env:NOTES_EDITOR } else { 'code' }
$script:NotesPath = Convert-Path (Get-ValueOrDefault $env:NOTES_PATH -Default "${env:HOME}\notes")
$script:NoteTemplate = Convert-Path (Get-ValueOrDefault $env:NOTES_PATH -Default "$PSScriptRoot/../assets/NoteTemplate.md")
$script:PandocExe = Convert-Path "$PSScriptRoot\..\assets\pandoc\pandoc-2.2.1\pandoc.exe"
$script:ShortArticlesAndPrepositions = @(
    'a'
    'an'
    'and'
    'at'
    'but'
    'by'
    'for'
    'in'
    'is'
    'nor'
    'of'
    'on'
    'or'
    'so'
    'the'
    'to'
    'with'
    'yet'
)