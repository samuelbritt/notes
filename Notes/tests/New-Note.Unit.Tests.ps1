$modulePath = Split-Path $PSScriptRoot
$moduleName = Split-Path $modulePath -Leaf
Import-Module "$(Join-Path $modulePath $moduleName).psd1" -Force

InModuleScope $moduleName {
    Describe 'New-Note' {
        Set-StrictMode -Version Latest

        $script:NotesPath = Resolve-Path "TestDrive:\" | Select-Object -ExpandProperty ProviderPath
        Mock Open-Note { }

        Context 'When creating a note with no arguments' {
            Set-StrictMode -Version Latest

            $note = New-Note

            It 'Creates a new file' {
                Test-Path $note.Path | Should BeTrue
            }

            It 'Creates a file in the notes directory' {
                $pathSep = [System.IO.Path]::DirectorySeparatorChar
                (Get-Item $note.Path).DirectoryName.Trim($pathSep) | Should BeExactly $script:NotesPath.Trim($pathSep)
            }

            It 'Creates a new markdown file' {
                (Get-Item $note.Path).Extension | Should Be '.md'
            }

            It 'Creates an untitled note' {
                $note.Title | Should BeLikeExactly '*Untitled*'
                $note.Path | Should BeLikeExactly '*Untitled*'
            }

            It 'Does not add tags' {
                $note.Tags | Should BeNullOrEmpty
            }
        }

        Context 'When creating a note with a title' {
            Set-StrictMode -Version Latest

            $note = New-Note -Title 'My new note'

            It 'Creates a new file' {
                Test-Path $note.Path | Should BeTrue
            }

            It 'Creates a file in the notes directory' {
                $pathSep = [System.IO.Path]::DirectorySeparatorChar
                (Get-Item $note.Path).DirectoryName.Trim($pathSep) | Should BeExactly $script:NotesPath.Trim($pathSep)
            }

            It 'Creates a new markdown file' {
                (Get-Item $note.Path).Extension | Should Be '.md'
            }

            It 'Adds the requested title' {
                $note.Title | Should BeExactly 'My new note'
            }

            It 'Subsitutes special characters in path' {
                $note.Path | Should BeLikeExactly '*My-new-note*'
            }

            It 'Does not add tags' {
                $note.Tags | Should BeNullOrEmpty
            }
        }

        Context 'When creating a note with a tags' {
            Set-StrictMode -Version Latest

            $note = New-Note -Title 'My new note' -Tag spam, eggs

            It 'Creates a new file' {
                Test-Path $note.Path | Should BeTrue
            }

            It 'Creates a file in the notes directory' {
                $pathSep = [System.IO.Path]::DirectorySeparatorChar
                (Get-Item $note.Path).DirectoryName.Trim($pathSep) | Should BeExactly $script:NotesPath.Trim($pathSep)
            }

            It 'Creates a new markdown file' {
                (Get-Item $note.Path).Extension | Should Be '.md'
            }

            It 'Adds the requested title' {
                $note.Title | Should BeExactly 'My new note'
            }

            It 'Subsitutes special characters in path' {
                $note.Path | Should BeLikeExactly '*My-new-note*'
            }

            It 'Does not add tags' {
                $note.Tags | Should Be @('spam', 'eggs')
            }
        }

        Context 'When creating a note special characters in the title' {
            Set-StrictMode -Version Latest

            $note = $null
            $title      = 'Hello: This/is\a|*terrible* <"title">?'
            $cleanTitle = 'Hello_-This_is_a_terrible_-_title'

            $hash = @{}
            It 'Does not throw' {
                { $hash.note = New-Note -Title $title } | Should Not Throw
            }
            $note = $hash.note

            It 'Creates a new file' {
                Test-Path $note.Path | Should BeTrue
            }

            It 'Creates a file in the notes directory' {
                $pathSep = [System.IO.Path]::DirectorySeparatorChar
                (Get-Item $note.Path).DirectoryName.Trim($pathSep) | Should BeExactly $script:NotesPath.Trim($pathSep)
            }

            It 'Creates a new markdown file' {
                (Get-Item $note.Path).Extension | Should Be '.md'
            }

            It 'Adds the requested title' {
                $note.Title | Should BeExactly $title
            }

            It 'Subsitutes special characters in path' {
                $note.Path | Should BeLikeExactly "*${cleanTitle}*"
            }

            It 'Does not add tags' {
                $note.Tags | Should BeNullOrEmpty
            }
        }

    }
}