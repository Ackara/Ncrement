<#
.SYNOPSIS
This function acts as a C# coalesce operator ie: boolean? trueValue: falseValue.
#>
function Coalesce()
{
	Param(
		[Alias('c')]
		[Parameter(Mandatory, ValueFromPipeline)]
		[bool]$Condition,

		[Alias('t', "true")]
		[Parameter(Mandatory, Position = 1)]
		$TrueValue,

		[Alias('f', "false")]
		[Parameter(Mandatory, Position = 2)]
		$FalseValue
	)

	if ($Condition)
	{
		return $TrueValue;
	}
	else
	{
		return $FalseValue;
	}
}