$script:Editor = if ($env:NOTES_EDITOR) { $env:NOTES_EDITOR } else { 'code' }
$script:NotesPath = if ($env:NOTES_PATH) { $env:NOTES_PATH } else { "${env:HOME}\notes" }
$script:NoteTemplate = if ($env:NOTES_TEMPLATE_PATH) { $env:NOTES_TEMPLATE_PATH } else { "$PSScriptRoot/../assets/NoteTemplate.md" }

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