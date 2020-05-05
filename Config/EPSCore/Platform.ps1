$config.sourceSolutionPath = 'Y:\TFS\Enterprise-PlatformClassic\'
$config.linkSolutionPath = 'Y:\TFS\Enterprise-EPSCore\'
$config.linkProfiles = @(
	@{
		sourceChildPath = 'bin\Platform'
		linkChildPath   = 'bin\Core'
		filter          = 'REISys.*'
	}
)