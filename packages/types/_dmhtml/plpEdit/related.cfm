<cfsetting enablecfoutputonly="yes">
<!--- 
|| LEGAL ||
$Copyright: Daemon Pty Limited 1995-2003, http://www.daemon.com.au $
$License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php$

|| VERSION CONTROL ||
$Header: /cvs/farcry/farcry_core/packages/types/_dmhtml/plpEdit/related.cfm,v 1.13 2005/09/01 00:45:46 gstewart Exp $
$Author: gstewart $
$Date: 2005/09/01 00:45:46 $
$Name: milestone_3-0-0 $
$Revision: 1.13 $

|| DESCRIPTION || 
$Description: dmHTML PLP for edit handler - Related Links Step $
$TODO: clean up whispace management & formatting, add external links option 20030503 GB$

|| DEVELOPER ||
$Developer: Geoff Bowers (modius@daemon.com.au) $
--->
<cfimport taglib="/farcry/farcry_core/tags/widgets" prefix="widgets">
	
<!--- copy related items to a list for looping --->
<cfset relatedItems = arraytolist(output.arelatedIDs)>
<cfset thisstep.isComplete = 0>
<cfset thisstep.name = stplp.currentstep>

<widgets:plpAction>

<cfif NOT thisstep.isComplete>

<widgets:plpWrapper>

<cfoutput>
<form action="#cgi.script_name#?#cgi.query_string#" method="post" name="editform">
	<fieldset></cfoutput>
	<widgets:relatedContent lRelatedTypeName="dmHtml,dmNews,dmEvents,dmFacts,dmLink">
	<cfoutput></fieldset>		
	<input style="display:none;" type="submit" name="buttonSubmit" value="submit" />
	<input type="hidden" name="plpAction" value="" />
</form></cfoutput>

</widgets:plpWrapper>

</cfif>

<cfsetting enablecfoutputonly="No">
