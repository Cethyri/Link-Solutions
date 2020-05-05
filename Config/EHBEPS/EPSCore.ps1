$config.sourceSolutionPath = 'Y:\TFS\Enterprise-EPSCore\'
$config.linkSolutionPath = 'Y:\TFS\Enterprise-EHBEPS\'
$config.linkProfiles = @(
	@{
		sourceChildPath = 'WebEPSExternal'
		linkChildPath   = 'WebEPSExternal'
	}
	,
	@{
		sourceChildPath = 'WebCommon\Include'
		linkChildPath   = 'WebEPSExternal\Include\Common'
	}
	,
	@{
		sourceChildPath = 'WebCommon\Interface'
		linkChildPath   = 'WebEPSExternal\Interface\Common'
	}
	,
	@{
		sourceChildPath = 'WebCommon\WebControls'
		linkChildPath   = 'WebEPSExternal\WebControls\Common'
	}
	,
	@{
		sourceChildPath = 'bin\core'
		linkChildPath   = 'WebEPSExternal\bin'
		filter          = 'REISys.EPS.*'
	}
	,
	@{
		sourceChildPath = 'WebEPSInternal'
		linkChildPath   = 'WebEPSInternal'
	}
	,
	@{
		sourceChildPath = 'WebCommon\Include'
		linkChildPath   = 'WebEPSInternal\Include\Common'
	}
	,
	@{
		sourceChildPath = 'WebCommon\Interface'
		linkChildPath   = 'WebEPSInternal\Interface\Common'
	}
	,
	@{
		sourceChildPath = 'WebCommon\WebControls'
		linkChildPath   = 'WebEPSInternal\WebControls\Common'
	}
	,
	@{
		sourceChildPath = 'bin\core'
		linkChildPath   = 'WebEPSInternal\bin'
		filter          = 'REISys.EPS.*'
	}
	,
	@{
		sourceChildPath = 'Config\core'
		linkChildPath   = 'Config\core'
	}
)