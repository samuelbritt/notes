function Get-Editor
{
    $editorExe = $script:Editor
    $editor = New-Object psobject -Property @{
        Editor = $editorExe
    }

    $editor | Add-Member -Name 'Open' -MemberType ScriptMethod -Value {
        param($Path)
        &$this.Editor $Path
    }

    switch ($editorExe)
    {
        "code" {
            $editor | Add-Member -Name 'OpenToEnd' -MemberType ScriptMethod -Value {
                param($Path)
                $lines = (Get-Content $Path | Measure-Object | Select-Object -ExpandProperty Count) + 1
                &$this.Editor -g "${Path}:${lines}"
            }
        }
        default {
            $editor | Add-Member -Name 'OpenToEnd' -MemberType ScriptMethod -Value {
                param($Path)
                &$this.Editor $Path
            }
        }
    }

    $editor
}