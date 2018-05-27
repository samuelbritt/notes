function Import-EvernoteNote
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [string] $Path,
        [Parameter()]
        [string] $ExtractMediaRelativePath = "assets"
    )
    process
    {
        Set-StrictMode -Version Latest
        Assert-Path $Path

        $evernotePath = Convert-Path $Path
        $evernoteItem = Get-Item $evernotePath
        $evernoteBaseName = $evernoteItem.BaseName
        $evernoteFilesPath = Join-Path $evernoteItem.Directory.FullName "${evernoteBaseName}_files"
        $hasAssets = (Test-Path $evernoteFilesPath -PathType Container)

        if ($evernoteBaseName -eq "Evernote_index")
        {
            return
        }

        $importId = New-Guid
        $tempDir = Join-Path $env:TEMP "evernote-import\$importId"
        New-Item $tempDir -ItemType Directory -Force | Out-Null

        $sourceItem = Copy-Item $evernotePath $tempDir -PassThru
        if ($hasAssets)
        {
            Copy-Item $evernoteFilesPath $tempDir -Recurse
        }

        $sourcePath = $sourceItem.FullName
        $exportedNotePath = Join-Path $tempDir "${importId}.md"
        $exportedMediaPath = Join-Path $tempDir $ExtractMediaRelativePath
        $importDate = Get-Date

        $pandocParams = @(
            "--from=""html-native_divs-native_spans-empty_paragraphs"""
            "--to=""markdown_mmd"""
            "--output=""$exportedNotePath"""
            "--template=""${script:PandocTemplate}"""
            "--extract-media=""$ExtractMediaRelativePath"""
            "--metadata=""importedOn:$($importDate.ToString('yyyy-MM-ddTHH:mm:ss'))"""
            "--metadata=""importedFrom:Evernote"""
            "--standalone"
            "--atx-headers"
            "--tab-stop=2"
            """$sourcePath"""
        )

        Write-Verbose "Import ID: $importId"
        Write-Verbose "Exporting $evernotePath to $exportedNotePath"
        if ($PSCmdlet.ShouldProcess("Command: pandoc $pandocParams", 'Evernote import'))
        {
            Push-Location $tempDir
            &$script:PandocExe $pandocParams
            Pop-Location
        }
    }
}