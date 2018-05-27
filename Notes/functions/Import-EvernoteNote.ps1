function Import-EvernoteNote
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline)]
        [string] $Path
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
        $tempDirPath = Join-Path $env:TEMP "evernote-import\$importId"
        $sourceDir = Join-Path $tempDirPath 'src'
        $exportDir = Join-Path $tempDirPath 'export'

        $tempDirPath, $sourceDir, $exportDir | ForEach-Object {
            New-Item $_ -ItemType Directory -Force | Out-Null
        }

        $sourceItem = Copy-Item $evernotePath $sourceDir -PassThru
        if ($hasAssets)
        {
            Copy-Item $evernoteFilesPath $sourceDir -Recurse
        }

        $sourcePath = $sourceItem.FullName
        $exportedNotePath = Join-Path $exportDir "${importId}.md"
        $exportedAssetsRelativePath = "assets"
        $sourceAssetsPath = Join-Path $sourceDir $exportedAssetsRelativePath
        $exportedAssetsPath = Join-Path $exportDir $exportedAssetsRelativePath
        $exportDate = Get-Date

        $pandocParams = @(
            "--from=""html-native_divs-native_spans-empty_paragraphs"""
            "--to=""markdown_mmd"""
            "--output=""${exportedNotePath}"""
            "--template=""${script:PandocTemplate}"""
            "--extract-media=""$exportedAssetsRelativePath"""
            "--metadata=""exportedOn:$($exportDate.ToString('yyyy-MM-ddTHH:mm:ss'))"""
            "--standalone"
            "--atx-headers"
            "--tab-stop=2"
            """$sourcePath"""
        )

        Write-Verbose "Import ID: $importId"
        Write-Verbose "Exporting $evernotePath to $exportedNotePath"
        if ($PSCmdlet.ShouldProcess("Command: pandoc $pandocParams", 'Evernote import'))
        {
            Push-Location $sourceDir
            &$script:PandocExe $pandocParams
            Pop-Location

            if (Test-Path $sourceAssetsPath -Type Container)
            {
                Move-Item $sourceAssetsPath $exportedAssetsPath
            }
        }
        <#

        pandoc -f html -t markdown_mmd -o export/the-log.md --extract-media ./assets '.\The Log What every software engineer should k.html'

        pandoc -f html-native_divs-native_spans -t markdown_mmd -o .\export\currency-microservice-nonativedivs.md --atx-headers --extract-media ./assets -s -M 'foo=bar' -M 'baz=bat,bam' '.\Currency Microservice.html'

        pandoc -f html-native_divs-native_spans -t markdown_mmd -o .\export\currency-microservice-nonativedivs.md --atx-headers --extract-media ./assets -s -M 'foo=bar' -M 'baz=bat,bam' --template .\template_md.txt --standalone --tab-stop=2 '.\Currency Microservice.html'

        pandoc -f html-native_divs-native_spans -t markdown_mmd+empty_paragraphs -o .\export\currency-microservice-nonativedivs.md --atx-headers --extract-media ./assets --metadata 'foo:bar' --metadata 'baz:bat,bam' --template .\template_md.txt --standalone --tab-stop=2 '.\Currency Microservice.html'

        #>
    }
}