$modulePath = Split-Path $PSScriptRoot
$moduleName = Split-Path $modulePath -Leaf
Import-Module "$(Join-Path $modulePath $moduleName).psd1" -Force

$global:SampleNotes = @{
    NoMetadata = @"
# Header text

body text
"@

    NoTags = @"
---
Title:    Sample Title
Author:   sampleauthor
Date:     2018-05-19T20:47:00
Tags:     -
---

# Header text

body text
"@

    BadDate = @"
---
Title:    Sample Title
Author:   sampleauthor
Date:     __not_a_date__
Tags:     foo
---

# Header text

body text
"@

    FullMetadata = @"
---
Title:    Sample Title
Author:   sampleauthor
Date:     2018-05-19T20:47:00
Tags:     foo, bar
---

# Header text

body text
"@
}

InModuleScope $moduleName {
    Describe 'Get-Note' {
        Set-StrictMode -Version Latest

        $script:NotesPath = Resolve-Path "TestDrive:\" | Select-Object -ExpandProperty ProviderPath
        $testCases = @(
            @{
                Name = "NoMetadata"
                Title = "NoMetadata"
                Value = $SampleNotes.NoMetadata
                Author = $null
                Created = $null
                Tags = $null
            }
            @{
                Name = "NoTags"
                Title = "Sample Title"
                Value = $SampleNotes.NoTags
                Author = 'sampleauthor'
                Created = (Get-Date '05/19/2018 20:47:00')
                Tags = $null
            }
            @{
                Name = "BadDate"
                Title = "Sample Title"
                Value = $SampleNotes.BadDate
                Author = 'sampleauthor'
                Created = $null
                Tags = 'foo'
            }
            @{
                Name = "FullMetadata"
                Title = "Sample Title"
                Value = $SampleNotes.FullMetadata
                Author = 'sampleauthor'
                Created = (Get-Date '05/19/2018 20:47:00')
                Tags = 'foo', 'bar'
            }
        )

        It "Correctly parses for <Name>" -TestCases $testCases {
            param($Name, $Title, $Value, $Author, $Created, $Tags)
            $path = "TestDrive:\${Name}.md"
            if (Test-Path $path)
            {
                Remove-Item $Path
            }

            $item = New-Item -Path $Path -Value $Value
            $note = $item | Get-Note

            $note.Path | Should BeExactly $item.FullName
            $note.Name | Should BeExactly $Name
            $note.Title | Should BeExactly $Title
            $note.Created | Should Be $( if ($Created) { $Created } else { $item.CreationTime } )
            if ($Tags)
            {
                @($note.Tags | Select-Object -Unique) | Should HaveCount @($Tags).Count
                @($note.Tags | Sort-Object) | Should Be ($Tags | Sort-Object)
            }
            else
            {
                $note.Tags | Should BeNullOrEmpty
            }
        }
    }
}