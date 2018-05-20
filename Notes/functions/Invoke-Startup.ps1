function Invoke-Startup
{
    Set-StrictMode -Version Latest

    if (!(Test-Path $script:NotesPath))
    {
        New-Item -Path $script:NotesPath -ItemType Directory | Out-Null
    }
    else
    {
        $path = Get-Item $script:NotesPath
        if (!$path.PSIsContainer)
        {
            throw ($script:Errors.INVALID_NOTES_DIR)
        }
    }
}
