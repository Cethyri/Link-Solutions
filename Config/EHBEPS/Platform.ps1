$config.sourceSolutionPath = 'Y:\TFS\Enterprise-PlatformClassic\'
$config.linkSolutionPath = 'Y:\TFS\Enterprise-EHBEPS\'
$config.linkProfiles = @(
	@{
		sourceChildPath = 'Web\Platform'
		linkChildPath   = 'WebEPSExternal\Platform'
	}
	,
	@{
		sourceChildPath = 'bin\Platform'
		linkChildPath   = 'WebEPSExternal\bin'
		filter          = 'REISys.*'
	}
	,
	@{
		sourceChildPath = 'Web\Platform'
		linkChildPath   = 'WebEPSInternal\Platform'
	}
	,
	@{
		sourceChildPath = 'bin\Platform'
		linkChildPath   = 'WebEPSInternal\bin'
		filter          = 'REISys.*'
	}
	,
	@{
		sourceChildPath = 'Config\Platform'
		linkChildPath   = 'Config\Platform'
		avoid			= '*.token'
	}
)