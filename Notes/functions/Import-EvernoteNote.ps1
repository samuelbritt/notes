function Import-EvernoteNote
{
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string] $Path,
        [Parameter()]
        [string] $ExtractMediaRelativePath = "assets"
    )
    begin
    {
        function Initialize-WorkingDirectory
        {
            [CmdletBinding()]
            param(
                [Parameter(ValueFromPipeline)]
                [string] $Path,
                [Parameter()]
                [guid] $ImportId
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
                $tempDir = Join-Path $env:TEMP "evernote-import\$ImportId"
                New-Item $tempDir -ItemType Directory -Force | Out-Null

                $sourceItem = Copy-Item $evernotePath $tempDir -PassThru
                $sourceAssets = $null
                if ($hasAssets)
                {
                    $sourceAssets = Copy-Item $evernoteFilesPath $tempDir -Recurse -PassThru
                }

                New-Object psobject -Property @{
                    WorkingDirectory = $tempDir
                    EvernotePath = $evernotePath
                    SourcePath = $sourceItem.FullName
                    SourceAssetsPath = ($sourceAssets | Get-MemberOrDefault FullName)
                }
            }
        }

        function ConvertFrom-EvernoteHtml
        {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [string] $Path,
                [Parameter(Mandatory)]
                [string] $DestinationPath,
                [Parameter(Mandatory)]
                [string] $ExtractMediaRelativePath,
                [Parameter(Mandatory)]
                [string] $WorkingDirectory
            )
            process
            {
                Set-StrictMode -Version Latest

                $importDate = Get-Date
                $pandocParams = @(
                    "--from=""html-native_divs-native_spans-empty_paragraphs"""
                    "--to=""markdown_mmd"""
                    "--output=""$DestinationPath"""
                    "--template=""${script:PandocTemplate}"""
                    "--extract-media=""$ExtractMediaRelativePath"""
                    "--metadata=""importedOn:$($importDate.ToString('yyyy-MM-ddTHH:mm:ss'))"""
                    "--metadata=""importedFrom:Evernote"""
                    "--standalone"
                    "--atx-headers"
                    "--tab-stop=2"
                    """$Path"""
                )

                Push-Location $WorkingDirectory
                &$script:PandocExe $pandocParams
                Pop-Location

                New-Object psobject -Property @{
                    Path = $DestinationPath
                    ImportDate = $importDate
                }
            }
        }

        function Resolve-ExportedMarkdown
        {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [string] $Path,
                [Parameter(Mandatory)]
                [string] $DestinationPath
            )
            process
            {
                Set-StrictMode -Version Latest
                $metadata = @{}
                $content = Get-Content $Path
                $content | ForEach-Object {
                    $line = $_

                    if ($line -match '^\|\s*\*\*(Created|Updated|Source|Tags):\*\*\s*\|\s*\*(.*)\*\s*\|$')
                    {
                        $metadataKey = $Matches[1]
                        $metadataValue = $Matches[2]
                        switch ($metadataKey)
                        {
                            'Created' { $metadata['date'] = (Get-Date $metadataValue) }
                            'Updated' { $metadata['updated'] = (Get-Date $metadataValue) }
                            'Source' { $metadata['source'] = $metadataValue }
                            'Tags' { $metadata['tags'] = ($metadataValue -split ', ') }
                        }

                    }
                }
                $content = $content -join [System.Environment]::NewLine

                $cr = '(\r\n|\r|\n)'
                $singleLineOption = [System.Text.RegularExpressions.RegexOptions]::Singleline
                $multiLineOption = [System.Text.RegularExpressions.RegexOptions]::Multiline

                # Clear out non-ascii characters
                $pattern = '[^\x00-\x7F]'
                $regex = New-Object regex $pattern, $multiLineOption
                $content = $regex.Replace($content, [string]::Empty)

                # Clear out the metdata table
                $pattern = @(
                    '\|\s*\|\s*\|' + $cr
                    '\|-*\|-*\|' + $cr
                    '(\|\s*\*\*.*:\*\*\s*\|\s*.*\s*\|' + $cr + ')+'
                ) -join [string]::Empty
                $regex = New-Object regex $pattern, $singleLineOption
                $content = $regex.Replace($content, [string]::Empty)

                # Clear out empty spans
                $pattern = '^<span.*>\s*</span>\r?$'
                $regex = New-Object regex $pattern, $multiLineOption
                $content = $regex.Replace($content, [string]::Empty)

                # Clear out empty lines
                $pattern = '^\s+\r?$'
                $regex = New-Object regex $pattern, $multiLineOption
                $content = $regex.Replace($content, [System.Environment]::NewLine)

                # Clear out duplicate newlines
                $pattern = $cr + '{3,}'
                $regex = New-Object regex $pattern, $singleLineOption
                $content = $regex.Replace($content, [System.Environment]::NewLine * 2)

                $content | Set-Content $DestinationPath -Force
                New-Object psobject -Property @{
                    Path = $DestinationPath
                    Metadata = $metadata
                }
            }
        }
    }
    process
    {
        Set-StrictMode -Version Latest

        $importId = New-Guid
        Write-Verbose "Import ID: $importId"

        Write-Verbose "00: Preparing the working directory"
        $params = $PSBoundParameters | New-HashSlice -Key Path
        $preparedFiles = Initialize-WorkingDirectory @params -ImportId $importId

        Write-Verbose "01: Converting from evernote HTML"
        $params = @{
            Path = $preparedFiles.SourcePath
            DestinationPath = (Join-Path $preparedFiles.WorkingDirectory "${importId}_01.md")
            ExtractMediaRelativePath = $ExtractMediaRelativePath
            WorkingDirectory = $preparedFiles.WorkingDirectory
        }
        $converted = ConvertFrom-EvernoteHtml @params
        if (!(Test-Path $converted.Path))
        {
            throw ($script.Errors.FAILED_IMPORT -f $Path)
        }


        Write-Verbose "02: Cleaning up export and extracting metadata"
        $params = @{
            Path = $converted.Path
            DestinationPath = (Join-Path $preparedFiles.WorkingDirectory "${importId}_02.md")
        }
        $cleaned = Resolve-ExportedMarkdown @params
        if (!(Test-Path $converted.Path))
        {
            throw ($script.Errors.FAILED_IMPORT -f $Path)
        }
    }
}