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
                    "--to=""markdown_mmd+yaml_metadata_block"""
                    "--output=""$DestinationPath"""
                    "--extract-media=""$ExtractMediaRelativePath"""
                    "--standalone"
                    "--atx-headers"
                    "--tab-stop=2"
                    "--metadata=""imported:$($importDate.ToString('yyyy-MM-dd HH:mm:ss'))"""
                    "--metadata=""importedFrom:Evernote"""
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

        function Read-Metadata
        {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [string] $Path
            )
            process
            {
                $metadata = @{}
                Set-StrictMode -Version Latest
                $metadata = @{}
                Get-Content $Path | ForEach-Object {
                    if ($_ -match '^\|\s*\*\*(Created|Updated|Source|Tags):\*\*\s*\|\s*\*(.*)\*\s*\|$')
                    {
                        $metadataKey = $Matches[1]
                        $metadataValue = $Matches[2]
                        switch ($metadataKey)
                        {
                            'Created' { $metadata['created'] = (Get-Date $metadataValue) }
                            'Updated' { $metadata['updated'] = (Get-Date $metadataValue) }
                            'Source' { $metadata['source'] = $metadataValue }
                            'Tags' { $metadata['tags'] = ($metadataValue -split ', ') }
                        }
                    }
                    elseif ($_ -match '^kw:?(.*)$')
                    {
                        $metadata['keywords'] = (($Matches[1] -split ',') -split ' ') | ForEach-Object { $_.Trim() }
                    }
                }
                $metadata
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

                $cr = '(\r\n|\r|\n)'
                $singleLineOption = [System.Text.RegularExpressions.RegexOptions]::Singleline
                $multiLineOption = [System.Text.RegularExpressions.RegexOptions]::Multiline

                $content = Get-Content $Path -Raw

                # Strip null characters
                $pattern = '\0'
                $regex = New-Object regex $pattern, $multiLineOption
                $content = $regex.Replace($content, [string]::Empty)

                # Strip the metadata table
                $pattern = @(
                    '\|\s*\|\s*\|' + $cr
                    '\|-*\|-*\|' + $cr
                    '(\|\s*\*\*.*:\*\*\s*\|\s*.*\s*\|' + $cr + ')+'
                ) -join [string]::Empty
                $regex = New-Object regex $pattern, $singleLineOption
                $content = $regex.Replace($content, [string]::Empty)

                # Strip any ad-hoc keywords
                $pattern = '^kw:?(.*)$'
                $regex = New-Object regex $pattern, $multiLineOption
                $content = $regex.Replace($content, [string]::Empty)

                # Strip empty spans
                $pattern = '^<span.*>\s*</span>\r?$'
                $regex = New-Object regex $pattern, $multiLineOption
                $content = $regex.Replace($content, [string]::Empty)

                # Strip empty lines
                $pattern = '^\s+\r?$'
                $regex = New-Object regex $pattern, $multiLineOption
                $content = $regex.Replace($content, [System.Environment]::NewLine)

                # Strip duplicate newlines
                $pattern = $cr + '{3,}'
                $regex = New-Object regex $pattern, $singleLineOption
                $content = $regex.Replace($content, [System.Environment]::NewLine * 2)

                # Strip trailing newlines
                $content = $content.TrimEnd([System.Environment]::NewLine)

                $content | Out-File $DestinationPath -Force -Encoding utf8
                $DestinationPath
            }
        }

        function Write-FinalMarkdown
        {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory)]
                [string] $Path,
                [Parameter(Mandatory)]
                [string] $DestinationPath,
                [Parameter(Mandatory)]
                [hashtable] $Metadata
            )
            process
            {
                Set-StrictMode -Version Latest
                $pandocParams = @(
                    "--from=""markdown_mmd+yaml_metadata_block"""
                    "--to=""markdown_mmd+yaml_metadata_block"""
                    "--output=""$DestinationPath"""
                    "--standalone"
                    "--atx-headers"
                    "--tab-stop=2"
                )

                foreach ($key in $Metadata.Keys) {
                    $value = $Metadata[$key]
                    if ($value -is [datetime])
                    {
                        $value = $value.ToString('yyyy-MM-dd HH:mm:ss')
                    }
                    elseif ($value -is [array])
                    {
                        $value = ($value |
                            ForEach-Object { $_.Trim() } |
                            Where-Object { ![string]::IsNullOrEmpty($_) }
                        ) -join ', '
                    }

                    $pandocParams += "--metadata=""${key}:${value}"""
                }

                $pandocParams += """$Path"""

                $workingDirectory = Split-Path $Path
                Push-Location $workingDirectory
                &$script:PandocExe $pandocParams
                Pop-Location

                $DestinationPath
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

        $metadata = Read-Metadata -Path $converted.Path

        Write-Verbose "02: Cleaning up export and extracting metadata"
        $params = @{
            Path = $converted.Path
            DestinationPath = (Join-Path $preparedFiles.WorkingDirectory "${importId}_02.md")
        }
        $cleanedPath = Resolve-ExportedMarkdown @params
        if (!(Test-Path $converted.Path))
        {
            throw ($script.Errors.FAILED_IMPORT -f $Path)
        }

        Write-Verbose "02: Write final markdown"
        $params = @{
            Path = $cleanedPath
            DestinationPath = (Join-Path $preparedFiles.WorkingDirectory "${importId}_03.md")
            Metadata = $metadata
        }
        $finalPath = Write-FinalMarkdown @params

    }
}