function Test-Git
{
	return (&git version | out-string) -match '(?i)(v|ver|version)\s*\d+\.\d+\.\d+';
}