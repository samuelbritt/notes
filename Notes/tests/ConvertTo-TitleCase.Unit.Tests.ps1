$modulePath = Split-Path $PSScriptRoot
$moduleName = Split-Path $modulePath -Leaf
Import-Module "$(Join-Path $modulePath $moduleName).psd1" -Force

InModuleScope $moduleName {
    Describe 'ConvertTo-TitleCase' {
        Set-StrictMode -Version Latest

        $testCases = @(
            @{
                InputObject = "foo bar"
                Expected = "Foo Bar"
            }

            @{
                InputObject = "foo and baR"
                Expected = "Foo and Bar"
            }

            @{
                InputObject = "foo         and            baR"
                Expected = "Foo and Bar"
            }

            @{
                InputObject = "FOO AND BAR"
                Expected = "FOO AND BAR"
            }

            @{
                InputObject = "foo-and-bar"
                Expected = "Foo-And-Bar"
            }
        )
        It "Converts '<InputObject>' to title case" -TestCases $testCases {
            param ($InputObject, $Expected)
            $InputObject | ConvertTo-TitleCase | Should BeExactly $Expected
        }
    }
}