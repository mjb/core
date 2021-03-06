<!--- allow output only from cfoutput tags --->
<cfsetting enablecfoutputonly="yes" />

<!--- include swatches file --->
<cfinclude template="swatches.cfm"/>

<!--- assign hex colour strings to component elements --->
<cfscript>
	/* body background */
	bgBody=hexWhite;

	/* nav backgrounds */
	bgNav=hexSecondaryDarker;							bgNavHover=hexSecondaryLighter;
	bgNavRollout=hexSecondaryDark;					bgNavRolloutHover=hexSecondaryLighter;
	bgNavActive=hexSecondaryLight;					bgNavActiveHover=hexSecondaryLighter;
	bgNavActiveRollout=hexSecondaryLight;			bgNavActiveRolloutHover=hexSecondaryLighter;

	/* first level nav borders */
	borderNavTop="";								borderNavRight=hexSecondaryDarker;
	borderNavBottom="";								borderNavLeft=hexSecondaryLighter;
	borderNavFirst="";								borderNavLast="";

	/* rollout level nav borders */	
	borderNavRolloutTop=hexSecondaryLighter;			borderNavRolloutRight=hexSecondaryDarker;
	borderNavRolloutBottom=hexSecondaryDarker;		borderNavRolloutLeft=hexSecondaryDarker;
	borderNavRolloutFirst="";						borderNavRolloutLast="";

	/* first level active nav borders */
	borderNavActiveTop="";							borderNavActiveRight=hexSecondaryDarker;
	borderNavActiveBottom="";						borderNavActiveLeft=hexSecondaryLighter;

	/* rollout level active nav borders */
	borderNavActiveRolloutTop=hexSecondaryLighter;	borderNavActiveRolloutRight=hexSecondaryDarker;
	borderNavActiveRolloutBottom=hexSecondaryDarker;borderNavActiveRolloutLeft=hexSecondaryDarker;
	borderNavActiveRolloutFirst="";					borderNavActiveRolloutLast="";


	/* search backgrounds & borders */
	bgSearchHead="transparent";			bgSearchBody=hexPrimaryDark;				bgSearchFoot="transparent";
	borderSearchHead="";				borderSearchBody=hexPrimaryDark;			borderSearchFoot=hexPrimaryDark;

	/* recent backgrounds & borders */
	bgRecentHead="transparent";			bgRecentBody=hexWhite;						bgRecentFoot="transparent";
	borderRecentHead="";				borderRecentBody=hexSecondaryLight;			borderRecentFoot=hexSecondaryLight;

	/* container backgrounds & borders */
	bgContainerHead="transparent";		bgContainerBody=hexSecondaryLightest;		bgContainerFoot="transparent";
	borderContainerHead="";				borderContainerBody=hexSecondaryLighter;	borderContainerFoot=hexSecondaryLighter;

	/* panel-tab backgrounds */
	bgPanelTabHead="transparent";

	/* panel backgrounds & borders */
	bgPanelHead="transparent";			bgPanelBody=hexWhite;						bgPanelFoot="transparent";
	borderPanelHead="";					borderPanelBody=hexPrimaryLighter;			borderPanelFoot=hexPrimaryLighter;

	/* pod-tab backgrounds  & borders */
	bgPodTabHead="transparent";

	/* pod backgrounds & borders */
	bgPodHead="transparent";			bgPodBody=hexWhite;							bgPodFoot="transparent";
	borderPodHead="";					borderPodBody=hexSecondaryDark;				borderPodFoot=hexSecondaryDark;
</cfscript>

<!---
the following style tag enables tag insight in your IDE
and is placed before the cfoutput tag to prevent being output.
--->
<style>

<!--- output css --->
<cfoutput>
/*
=================================================================================
webskin.css:
=================================================================================
this stylesheet defines the skins of page elements - and should be linked second
this stylesheet defines the following page elements:
- background colours / graphics / positions
- border colours / styles / thickness
- sprite graphics / positions
*/

/*
form skin styles
*/
form.formtool fieldset {border-color: #hexPrimaryLighter#; border-width: 3px 0px 0px 0px; border-style: solid none none none;}
form.formtool fieldset.noLegend {border: none !important;}
form.formtool fieldset fieldset {border: 1px solid #hexPrimaryLighter#;}
<!--- form.formtool .password .fieldAlign {float: none; margin: 0px 0px 0px #columnLeftWidth#; padding: 0px;} --->
form fieldset div.notes {border: 1px solid #hexPrimaryLight#; background-color: #hexPrimaryLighter#; color: inherit;}
<!--- /* form fieldset div.notes h4 {background-image: url(/images/icon_info.gif); background-repeat: no-repeat; background-position: top left; border-style: solid; border-color: ##666666;} */ --->
<!--- form div fieldset {border-width: 1px; border-style: solid; border-color: ##666666;} --->
p.error {background-color: ##ff0000; background-image: url(/images/icon_error.gif); background-repeat: no-repeat; background-position: 3px 3px; border: 1px solid ##000000; color: inherit; }
form div.error {background-color: ##ffffe1; background-image: url(/images/required_bg.gif); background-repeat: no-repeat; background-position: top left; border: 1px solid ##ff0000; color: inherit;}
form div.error p.error {background-image: url(/images/icon_error.gif); background-position: top left; background-color: transparent; border-style: none;}
form div input.inputCheckbox, form div input.inputRadio, input.inputCheckbox, input.inputRadio {background-color: transparent; border-width: 0px;}
form div input.inputSubmit, form div input.inputButton, input.inputSubmit, input.inputButton {background-color: ##cccccc; color: inherit;}
form input, form select, form textarea {background-color: #hexWhite#;}

form.formtool ##wizard-content table, form.formtool ##wizard-content table tr, form.formtool ##wizard-content table tr td, form.formtool ##wizard-content table th {border: none;}

/* formtool form components */
	/* formtool input : formButton webskin styles */	
	form.formtool input.formButton {background: ##FFFFFF url("images/form_button_bg.gif") no-repeat 0px -2px; border-top: 1px solid ##AEAFC7; border-right: 1px solid ##5A5B85; border-bottom: 1px solid ##5A5B85; border-left: 1px solid ##AEAFC7; cursor: pointer; color: inherit;}
	form.formtool input.formButton:hover {background: url("images/form_button_bg.gif") no-repeat 0px -58px;}
	/* formtool select webskin styles */
	form.formtool select {background-color: ##FFFFFF; border-top: 1px solid ##5A5B85; border-right: 1px solid ##AEAFC7; border-bottom: 1px solid ##AEAFC7; border-left: 1px solid ##5A5B85; color: inherit;}
	form.formtool select option {background-color: ##FFFFFF; color: inherit;}

/* formtool html button webskin styles */
	/* formtool default html button webskin styles */
	form.formtool div.buttonStandard {background: url("images/form_button_bg.gif") no-repeat -2px -2px; border-top: 1px solid ##AEAFC7; border-right: 1px solid ##5A5B85; border-bottom: 1px solid ##5A5B85; border-left: 1px solid ##AEAFC7; cursor: pointer;}
		form.formtool div.buttonStandard a:hover {background: url("images/form_button_bg.gif") no-repeat -2px -58px;}
	/* formtool default html view method button webskin styles */
	form.formtool div.buttonViewMethod {background: ##FFFFFF url("images/form_button_bg.gif") no-repeat -2px -2px; border-top: 1px solid ##AEAFC7; border-right: 1px solid ##5A5B85; border-bottom: 1px solid ##5A5B85; border-left: 1px solid ##AEAFC7; cursor: pointer; color: inherit;}
		form.formtool div.buttonViewMethod a:hover {background: url("images/form_button_bg.gif") no-repeat -2px -58px;}
		form.formtool div.buttonViewMethod a.selected {background: url("images/form_button_bg.gif") no-repeat -2px -58px;}

/* formtool array component webskin styles */
	form.formtool div.array div.fieldAlign ul {border: 1px solid ##AEAFC7;list-style-type: none;}
	form.formtool div.array div.fieldAlign table , form.formtool div.array div.fieldAlign tr, form.formtool div.array div.fieldAlign th, form.formtool div.array div.fieldAlign td {border:none;border-collapse:collapse;}

	/* array component : detail view webskin styles */
	ul.arrayDetailView li {border-bottom: 1px solid ##eaeaf0; background-image: none;}
	ul.arrayDetailView li:hover {background-color: ##eaeaf0; cursor: pointer; color: inherit;}
		ul.arrayDetailView li div.buttonGripper p {background: url("images/form_button_gripper.gif") no-repeat 0px 0px;}
		/*ul.arrayDetailView li div.arrayDetail p {background: transparent url("images/content_type_icon_default4.gif") no-repeat 0px 3px;}*/

	/* array component : thumbnail view webskin styles */
	ul.arrayThumbnailView li { background-image: none; background-color: ##7476a6; border-top: 1px solid ##8e8fb6; border-right: 1px solid ##61638b; border-bottom: 1px solid ##61638b; border-left: 1px solid ##8e8fb6; cursor: pointer; color: inherit;}
		ul.arrayThumbnailView li div.buttonGripper p {background: url("images/form_button_gripper.gif") no-repeat 100% -29px; border-left: 1px solid ##696a8c;}
		ul.arrayThumbnailView li div.arrayThumbnail img {border: 1px solid ##FFFFFF;}
		ul.arrayThumbnailView li:hover div.arrayThumbnail img {border: 1px solid ##e17000;}

/* formtool category component webskin styles */
	form.formtool div.category table {border: none; border-collapse: collapse;}
	form.formtool div.category table tr,
		form.formtool div.category table th,
		form.formtool div.category table td {border: none;}

/* formtool config webskin styles */
	form.formtool div.longchar fieldset {border: 0 none #hexPrimaryLighter#;}
	form.formtool div.longchar fieldset legend {font-weight:bold;}

</cfoutput>
<!--- end css output --->

</style>
<!--- end enable tag insight --->

<cfsetting enablecfoutputonly="no" />
<!--- end allow output only from cfoutput tags --->