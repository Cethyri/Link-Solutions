$config.sourceSolutionPath = "Y:\TFS\Enterprise-EPSCore\"
$config.linkSolutionPath = "Y:\TFS\Enterprise-EHBEPS\"
$config.syncProfiles = @(
	@{
		sourceChildPath = "WebEPSExternal"
		linkChildPath   = "WebEPSExternal"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "WebCommon\Include"
		linkChildPath   = "WebEPSExternal\Include\Common"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "WebCommon\Interface"
		linkChildPath   = "WebEPSExternal\Interface\Common"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "WebCommon\WebControls"
		linkChildPath   = "WebEPSExternal\WebControls\Common"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "bin\core"
		linkChildPath   = "WebEPSExternal\bin"
		filter          = "REISys.EPS.*"
	}
	,
	@{
		sourceChildPath = "WebEPSInternal"
		linkChildPath   = "WebEPSInternal"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "WebCommon\Include"
		linkChildPath   = "WebEPSInternal\Include\Common"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "WebCommon\Interface"
		linkChildPath   = "WebEPSInternal\Interface\Common"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "WebCommon\WebControls"
		linkChildPath   = "WebEPSInternal\WebControls\Common"
		filter          = ""
	}
	,
	@{
		sourceChildPath = "bin\core"
		linkChildPath   = "WebEPSInternal\bin"
		filter          = "REISys.EPS.*"
	}
	,
	@{
		sourceChildPath = "Config\core"
		linkChildPath   = "Config\core"
		filter          = ""
	}
)