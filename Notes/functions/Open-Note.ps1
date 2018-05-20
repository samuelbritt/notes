function Open-Note
{
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("FullName")]
        [string] $Path = $script:NotesPath,

        [Parameter()]
        [switch] $ScrollToEnd
    )
    Set-StrictMode -Version Latest

    $editor = Get-Editor

    if ($ScrollToEnd)
    {
        $editor.OpenToEnd($Path)
    }
    else
    {
        $editor.Open($Path)
    }
}

Set-Alias on Open-Note