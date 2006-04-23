<!--- 
|| LEGAL ||
$Copyright: Daemon Pty Limited 1995-2003, http://www.daemon.com.au $
$License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php$ 

|| VERSION CONTROL ||
$Header: /cvs/farcry/farcry_core/admin/archive.cfm,v 1.2 2005/10/06 06:18:35 daniela Exp $
$Author: daniela $
$Date: 2005/10/06 06:18:35 $
$Name: milestone_3-0-0 $
$Revision: 1.2 $

|| DESCRIPTION || 
$Description: shows archived objects $


|| DEVELOPER ||
$Developer: Brendan Sisson (brendan@daemon.com.au)$

|| ATTRIBUTES ||
$in: $
$out:$
--->

<cfprocessingDirective pageencoding="utf-8">

<cfparam name="finish_url" default="#cgi.http_referer#">
<!--- check permissions --->
<cfset iArchiveTab = request.dmSec.oAuthorisation.checkPermission(reference="policyGroup",permissionName="ObjectArchiveTab")>

<!--- set up page header --->
<cfimport taglib="/farcry/farcry_core/tags/admin/" prefix="admin">
<admin:header writingDir="#session.writingDir#" userLanguage="#session.userLanguage#">

<cfif iArchiveTab eq 1>

	<h3><cfoutput>#application.adminBundle[session.dmProfile.locale].archive#</cfoutput></h3>

	
	<!--- check if rollback is required --->
	<cfif isdefined("url.archiveid")>
		
		<!--- get type --->
		<cfset oFourq = createObject("component","farcry.fourq.fourq")>
		<cfset typename = oFourq.findType(url.objectid)>
		<cfset oType = createObject("component",application.types[typename].typepath)>
		
		<!--- rollback arvhice --->
		<cfset stRollback = oType.archiveRollback(objectID="#url.objectid#",archiveId="#url.archiveid#",typename=typename)>
<cfoutput>
<script type="text/javascript">
	if(parent['sidebar'].frames['sideTree'])
		parent['sidebar'].frames['sideTree'].location= parent['sidebar'].frames['sideTree'].location;

	location.href = "#finish_url#";
</script></cfoutput>
		<cfabort>
	</cfif>
	
	<!--- get archives --->
	<cfinvoke component="#application.packagepath#.farcry.versioning" method="getArchives" returnvariable="getArchivesRet">
		<cfinvokeargument name="objectID" value="#url.objectid#"/>
	</cfinvoke>

	<table cellspacing="0">
	<cfif getArchivesRet.recordcount gt 0>
		<!--- setup table --->
		<cfoutput>
		<tr>
			<th>#application.adminBundle[session.dmProfile.locale].Date#</th>
			<th>#application.adminBundle[session.dmProfile.locale].Label#</th>
			<th>#application.adminBundle[session.dmProfile.locale].User#</th>
			<!--- <th>&nbsp;</th> --->
			<th>&nbsp;</th>
			<th>&nbsp;</th>
		</tr>
		</cfoutput>
		<!--- loop over archives --->
		<cfoutput query="getArchivesRet">
		<tr>
			<td>
			#application.thisCalendar.i18nDateFormat(DATETIMELASTUPDATED,session.dmProfile.locale,application.longF)# 
			#application.thisCalendar.i18nTimeFormat(DATETIMELASTUPDATED,session.dmProfile.locale,application.shortF)#
			</td>
			<td>#label#</td>
			<td>#lastupdatedby#</td>
			<!--- <td><a href="edittabArchiveDetail.cfm?archiveid=#objectid#">#application.adminBundle[session.dmProfile.locale].moreDetail#</a></td> --->
			<td><a href="#application.url.conjurer#?archiveid=#objectid#" target="_blank">#application.adminBundle[session.dmProfile.locale].archivePreview#</a></td>
			<td>
				<a href="archive.cfm?objectid=#url.objectid#&archiveid=#objectid#&finish_url=#cgi.http_referer#" onclick="return confirm('Are you sure you want to rollback to this version?')">Rollback</a>
				<!--- check if archive has been rolled back successfully --->
				<cfif isdefined("url.archiveid") and stRollback.result and url.archiveId eq objectid>
					<span style="color:Red">#application.adminBundle[session.dmProfile.locale].rolledBackOK#</span>
				</cfif>
			</td>
		</tr>
		</cfoutput>
	<cfelse>
		<tr>
			<td colspan="6"><cfoutput>#application.adminBundle[session.dmProfile.locale].noArchiveRecorded#</cfoutput></td>
		</tr>
	</cfif>
	</table><cfoutput>
	<a href="#finish_url#">[Cancel]</a></cfoutput>
<cfelse>
	<admin:permissionError>
</cfif>

<!--- setup footer --->
<admin:footer>