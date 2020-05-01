$config.sourceSolutionPath = "Y:\TFS\Enterprise-PlatformClassic\"
$config.linkSolutionPath = "Y:\TFS\Enterprise-EHBEPS\"
$config.syncProfiles = @(
	@{
		sourceChildPath = "Web\Platform"
		linkChildPath   = "WebEPSExternal\Platform"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "bin\Platform"
		linkChildPath   = "WebEPSExternal\bin"
		filter          = "REISys.*"
	}
	,
	@{
		sourceChildPath = "Web\Platform"
		linkChildPath   = "WebEPSInternal\Platform"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "bin\Platform"
		linkChildPath   = "WebEPSInternal\bin"
		filter          = "REISys.*"
	}
	,
	@{
		sourceChildPath = "Config\Platform"
		linkChildPath   = "Config\Platform"
		filter          = ""
	}
)