<#
.SYNOPSIS
This function acts as a C# coalesce operator ie: boolean? trueValue: falseValue.

.PARAMETER Condition
This boolean expression.

.PARAMETER TrueValue
The value to return if the condition is true.

.PARAMETER FalseValue
The value to return if the condition is false.

.EXAMPLE
$value = (1 -eq 1) | Coalesce "TrueValue" "FalseValue";
This example set the $value with the 'trueValue' if the condition is true; 'falseValue' if otherwise.
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