function ConvertTo-TitleCase
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $InputObject
    )
    process
    {
        Set-StrictMode -Version Latest
        $textInfo = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo

        $inputTokens = $InputObject -split '\s+'
        $outputTokens = @()


        $isFirstToken = $true
        foreach ($token in $inputTokens)
        {
            if ($token -ceq $token.ToUpper())
            {
                # ingnore acronyms
                $outputTokens += $token
            }
            elseif ($token -match '[<>*|/\\]')
            {
                # ingnore anything that looks weird
                $outputTokens += $token
            }
            elseif (!$isFirstToken -and $script:ShortArticlesAndPrepositions -contains $token.ToLower())
            {
                # lower-case articles, etc
                $outputTokens += $token.ToLower()
            }
            else
            {
                $outputTokens += $textInfo.ToTitleCase($token.ToLower())
            }

            $isFirstToken = $false
        }

        $outputTokens -join ' '
    }
}