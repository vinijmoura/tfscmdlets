#============================
# Area & Iteration cmdlets
#============================

Function New-Area
{
	[CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string] 
        $ProjectName,
    
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)] [string] 
        $Path,
    
		[switch]
		$Force
    )

	Begin
	{
		# This void call is just to check if the global connection is set
		_GetConnection
	}

    Process
    {
        $areaPath = ("\" + $ProjectName + "\Area\" + $Path).Replace("\\", "\")
        _NewCssNode -Path $areaPath -Force:$Force.IsPresent
    }
}

Function New-Iteration
{
    param
    (
        [Parameter(Mandatory=$true)]
        [string] 
        $ProjectName,
    
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[string] 
        $Path,
    
        [Parameter()]
		[DateTime]
        $StartDate,
    
        [Parameter()]
		[DateTime]
        $EndDate,
    
		[switch]
		$Force
    )

    Process
    {
        $iterationPath = ("\" + $ProjectName + "\Iteration\" + $Path).Replace("\\", "\")
        $iterationNode = _NewCssNode -Path $iterationPath -Force:$Force.IsPresent

        if ($StartDate)
        {
            $iterationNode = Set-IterationDates @PSBoundParameters
        }

        return $iterationNode
    }
}

Function Set-IterationDates
{
    param
    (
        [Parameter(Mandatory=$true)]
		[string] 
        $ProjectName,
    
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[string] 
        $Path,

        [Parameter(Mandatory=$true)]
		[Nullable[DateTime]]
        $StartDate,
    
        [Parameter(Mandatory=$true)]
		[Nullable[DateTime]]
        $EndDate
    )

	Begin
	{
		$tpc = _GetConnection
        $cssService = $tpc.GetService([type]"Microsoft.TeamFoundation.Server.ICommonStructureService4")
	}

    Process
    {
        $iterationPath = ("\" + $ProjectName + "\Iteration\" + $Path).Replace("\\", "\")
        $iterationNode = _GetCssNode -Path $iterationPath

        if (!$iterationNode)
        {
            throw "Invalid iteration path: $Path"
        }

        [void]$cssService.SetIterationDates($iterationNode.Uri, $StartDate, $EndDate)

        return _GetCssNode -TeamProjectCollection $tpc -Path $iterationPath
    }
}

# =================
# Helper Functions
# =================

Function _GetCssNode
{
    param
    (
        [Parameter(Mandatory=$true)]
		[string]
        $ProjectName,

        [Parameter(Mandatory=$true)]
		[string]
        $Scope,

        [Parameter(Mandatory=$true)]
		[string]
        $Path,

        [Parameter()]
		[switch]
        $CreateIfMissing
    )

	Begin
	{
		$tpc = _GetConnection
        $cssService = $tpc.GetService([type]"Microsoft.TeamFoundation.Server.ICommonStructureService")
	}

    Process
    {
        $nodePath = "\${ProjectName}\${Scope}\${Path}".Replace("\\", "\")

        try
        {
            $cssService.GetNodeFromPath($nodePath)
        }
        catch
        {
            if($CreateIfMissing.IsPresent)
            {
                _NewCssNode $tpc $Path
            }
			else
			{
				throw
			}
        }
    }
}

Function _NewCssNode
{
    param
    (
        [Parameter(Mandatory=$true)]
		[string]
        $ProjectName,

        [Parameter(Mandatory=$true)]
		[string]
        $Scope,

        [Parameter(Mandatory=$true)]
		[string]
        $Path,

		[switch]
		$Force
    )

	Begin
	{
		$tpc = _GetConnection
        $cssService = $tpc.GetService([type]"Microsoft.TeamFoundation.Server.ICommonStructureService")
	}

    Process
    {
        $nodePath = "\${ProjectName}\${Scope}\${Path}".Replace("\\", "\")

        $i = $Path.LastIndexOf("\")

        $parentPath = $nodePath.Substring(0, $i)
        $nodeName = $Path.Substring($i+1)

        try
        {
            $parentNode = $cssService.GetNodeFromPath($parentPath)
        }
        catch
        {
            $parentNode = _NewCssNode -TeamProjectCollection $TeamProjectCollection -Path $parentPath
        }

        $nodeUri = $cssService.CreateNode($nodeName, $parentNode.Uri)

        return $cssService.GetNode($nodeUri)
    }
}
