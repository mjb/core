<!--- 
|| LEGAL ||
$Copyright: Daemon Pty Limited 1995-2003, http://www.daemon.com.au $
$License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php$ 

|| VERSION CONTROL ||
$Header: /cvs/farcry/farcry_core/admin/reporting/auditUser.cfm,v 1.8 2005/08/17 03:28:39 pottery Exp $
$Author: pottery $
$Date: 2005/08/17 03:28:39 $
$Name: milestone_3-0-0 $
$Revision: 1.8 $

|| DESCRIPTION || 
$Description: Audit for user activity $

|| DEVELOPER ||
$Developer: Brendan Sisson (brendan@daemon.com.au)$

|| ATTRIBUTES ||
$in: $
$out:$
--->

<cfprocessingDirective pageencoding="utf-8">

<!--- check permissions --->
<cfscript>
	iAuditTab = request.dmSec.oAuthorisation.checkPermission(reference="policyGroup",permissionName="ReportingAuditTab");
</cfscript>

<!--- set up page header --->
<cfimport taglib="/farcry/farcry_core/tags/admin/" prefix="admin">
<admin:header writingDir="#session.writingDir#" userLanguage="#session.userLanguage#">

<cfif iAuditTab eq 1>
	<h3>
	<cfif isdefined("url.view")>
		<cfoutput>#application.adminBundle[session.dmProfile.locale].allUserActivity#</cfoutput>
	<cfelse>
		<cfoutput>#application.adminBundle[session.dmProfile.locale].recentUserActivity#</cfoutput>
	</cfif>
	</h3>
	
	<cfparam name="form.username" default="all">
	<cfparam name="form.auditType" default="all">
	<cfparam name="form.maxRows" default="10">
	
	<cfscript>
		// hack for max rows, unlikely they'll want more than this
		if (form.maxrows eq "all") {
			form.maxrows = 999999;
		}	
		
		qActivity = application.factory.oAudit.getAuditLog(maxrows=form.maxRows,username=form.username,auditType=form.auditType);
		qUsers = application.factory.oAudit.getAuditUsers(maxrows=maxrows);
		qActivitites = application.factory.oAudit.getAuditActivities(maxrows=maxrows);
	</cfscript>	
	<cfoutput>

			<form method="post" class="f-wrap-1 f-bg-short" action="#application.url.farcry#/reporting/auditUser.cfm">
			<fieldset>
			
				<label for="userName">
				<b>#application.adminBundle[session.dmProfile.locale].userLabel#</b>
				<select name="userName" id="userName">
					<option value="all">#application.adminBundle[session.dmProfile.locale].allUsers#</option>
					<cfloop query="qUsers">
						<option value="#username#" <cfif form.username eq username>selected="selected"</cfif>>#username#</option>
					</cfloop>
				</select><br />
				</label>
				
				<label for="auditType">
				<b>#application.adminBundle[session.dmProfile.locale].activityLabel#</b>
				<select name="auditType" id="auditType">
					<option value="all">#application.adminBundle[session.dmProfile.locale].allTypes#</option>
					<cfloop query="qActivitites">
						<option value="#auditType#" <cfif form.auditType eq auditType>selected="selected"</cfif>>#auditType#</option>
					</cfloop>
				</select><br />
				</label>
				
				<label for="maxRows">
				<b>#application.adminBundle[session.dmProfile.locale].rowsReturned#</b>
				<select name="maxRows" id="maxRows">
					<option value="all" <cfif form.maxRows eq "all">selected="selected"</cfif>>#application.adminBundle[session.dmProfile.locale].allRows#</option>
					<cfloop from="10" to="200" step=10 index="rows">
						<option value="#rows#" <cfif rows eq form.maxRows>selected="selected"</cfif>>#rows#</option>
					</cfloop>				
				</select>
				</label>
				
				<div class="f-submit-wrap">
				<input type="submit" value="#application.adminBundle[session.dmProfile.locale].submit#" class="f-submit" />
				</div>
				
			</fieldset>
			</form>

	</cfoutput>
				<hr />
				
				<table cellspacing="0">
	<cfoutput>
	<tr>
		<th>#application.adminBundle[session.dmProfile.locale].date#</th>	
		<th>#application.adminBundle[session.dmProfile.locale].activity#</th>
		<th>#application.adminBundle[session.dmProfile.locale].objectLC#</th>
		<th>#application.adminBundle[session.dmProfile.locale].note#</th>
		<th>#application.adminBundle[session.dmProfile.locale].user#</th>
		<th>#application.adminBundle[session.dmProfile.locale].location#</th>
	</tr>
	</cfoutput>
	<cfoutput query="qActivity">
		<tr class="#IIF(currentrow MOD 2, de(""), de("alt"))#">
			<td>
			#application.thisCalendar.i18nDateFormat(Datetimestamp,session.dmProfile.locale,application.fullF)# 
			#application.thisCalendar.i18nTimeFormat(Datetimestamp,session.dmProfile.locale,application.shortF)#
			</td>
			<td>#auditType#</td>
			<td><cfif len(trim(objectid))><a href="#application.url.conjurer#?objectid=#objectid#" target="_blank">#objectid#</a><cfelse>#application.adminBundle[session.dmProfile.locale].notAvailable#</cfif></td>
			<td>#Note#</td>
			<td><cfif username neq "">#Username#<cfelse><i>#application.adminBundle[session.dmProfile.locale].unknown#</i></cfif></td>		
			<td>#Location#</td>
		</tr>	
	</cfoutput>
	</table>
<cfelse>
	<admin:permissionError>
</cfif>

<!--- setup footer --->
<admin:footer>