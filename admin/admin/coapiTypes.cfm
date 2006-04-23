<cfsetting enablecfoutputonly="Yes">
<cfprocessingDirective pageencoding="utf-8">
<!--- 
|| LEGAL ||
$Copyright: Daemon Pty Limited 1995-2003, http://www.daemon.com.au $
$License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php$ 

|| VERSION CONTROL ||
$Header: /cvs/farcry/farcry_core/admin/admin/coapiTypes.cfm,v 1.26 2005/10/13 09:14:53 geoff Exp $
$Author: geoff $
$Date: 2005/10/13 09:14:53 $

$Name: milestone_3-0-0 $
$Revision: 1.26 $

|| DESCRIPTION || 
$Description: Management interface for COAPI types. 
	Legacy display is nasty as.  Need to rebuild this reporting tool 
	at some point. No time just now GB $

|| DEVELOPER ||
$Developer: Geoff Bowers (modius@daemon.com.au)$
--->

<!--- import tag libraries --->
<cfimport taglib="/farcry/farcry_core/tags/admin/" prefix="admin">

<!--- check permissions --->
<cfif NOT request.dmSec.oAuthorisation.checkPermission(reference="policyGroup",permissionName="AdminCOAPITab")>	
	<admin:permissionError>
	<cfabort>
</cfif>

<!--- environment variables --->
<cfparam name="FORM.action" default="" type="string">

<!--- component documentation url... --->
<cfif structKeyExists(application.config.general,"componentDocURL") AND len(application.config.general.componentDocURL)>
	<cfset documentURL=application.config.general.componentDocURL>
<cfelse>
	<cfset documentURL="/CFIDE/componentutils/componentdetail.cfm">
</cfif>

<cfscript>
/* COAPI Evolution Actions */
	alterType = createObject("component","#application.packagepath#.farcry.alterType");
	alterType.refreshAllCFCAppData();
	if (isDefined("URL.deploy"))
		alterType.deployCFC(typename=url.deploy);
	switch(form.action){
		case "deleteproperty":
		 {
			alterType.deleteProperty(typename=form.typename,srcColumn=form.property);
			alterType.refreshCFCAppData(typename=form.typename);
			break;
		 }
		 case "droparraytable":
		 {
		 	alterType.dropArrayTable(typename=form.typename,property=form.property);
			alterType.refreshCFCAppData(typename=form.typename);
			break;
		 }
		 case "deployproperty":
		 {
		 	propMetadata = application.types[form.typename].stProps[form.property].metadata;
			//is the property nullable
			isNullable = false;
			if( isDefined('propMetadata.required') AND NOT propMetadata.required)
				isNullable = true;
			//do we have a default value
			defaultVal = "";
			if ( isDefined('propMetadata.default'))
				defaultVal = propMetadata.default;				
			alterType.addProperty(typename=form.typename,srcColumn=form.property,srcColumnType=alterType.getDataType(application.types[form.typename].stProps[form.property].metadata.type),bNull=isNullable,stDefault=defaultVal);
		 	alterType.refreshCFCAppData(typename=form.typename);
			break;
		 }	
		 case "deployarrayproperty":
		 {
		 	alterType.deployArrayProperty(typename=form.typename,property=form.property);
			alterType.refreshCFCAppData(typename=form.typename);
			break;
		 }	
		 case "renameproperty":
		 {
		 	alterType.alterPropertyName(typename=form.typename,srcColumn=form.property,destColumn=form.renameto,colType=form.colType,colLength=form.colLength);
			alterType.refreshCFCAppData(typename=form.typename);
			break;
		 }
		  case "repairproperty":
		 {
		 	alterType.repairProperty(typename=form.typename,srcColumn=form.property,srcColumnType=alterType.getDataType(application.types[form.typename].stProps[form.property].metadata.type,true));
			alterType.refreshCFCAppData(typename=form.typename);
			break;
		 }
		 default:
		 {	//do nothing
		 
		 }
	 }
	//if (NOT application.dbType is "ora") //temp mess until oracle compatability introduced
		stTypes = alterType.buildDBStructure();
</cfscript>

<!--- build page output --->
<admin:header title="COAPI Types" writingDir="#session.writingDir#" userLanguage="#session.userLanguage#">	

<cfoutput>
	<!--- TODO: i18n --->
	<h3>Custom Content Types</h3>
	<table class="table-5" cellspacing="0">
	<tr>
		<th>#application.adminBundle[session.dmProfile.locale].integrity#</th>
		<th>#application.adminBundle[session.dmProfile.locale].component#</th>
		<th>#application.adminBundle[session.dmProfile.locale].component#</th>
		<!--- TODO: i18n remove property label --->
		<!--- <th>#application.adminBundle[session.dmProfile.locale].deployed#</th> --->
		<th>#application.adminBundle[session.dmProfile.locale].deploy#</th>
		<!--- TODO: i18n --->
		<!--- <th style="border-right:none">Permission Set</th> --->
		<!--- TODO: i18n --->
		<th style="border-right:none">Doc</th>
	</tr>
</cfoutput>
	
<cfloop collection="#application.types#" item="componentName">
<cfif application.types[componentname].bcustomtype>
	<cfscript>
		if (structKeyExists(stTypes,componentname))
			stConflicts = alterType.compareDBToCFCMetadata(typename=componentname,stDB=stTypes['#componentname#']);
		else
			stConflicts['#componentname#'] = structNew();
	</cfscript>
	<cfoutput>
		<tr <cfif alterType.isCFCConflict(stConflicts=stConflicts,typename=componentName)>style='color:##000;'</cfif>>
			<td>
				<cfif alterType.isCFCConflict(stConflicts=stConflicts,typename=componentName)>
					<img src="#application.url.farcry#/images/no.gif" /> #application.adminBundle[session.dmProfile.locale].seeBelow#
				<cfelse>
					<img src="#application.url.farcry#/images/yes.gif" />
				</cfif>
			</td>
			<cfif structkeyexists(application.types[componentname], "hint")>
			<td><span title="#application.types[componentname].hint#">
				<cfif structkeyexists(application.types[componentname],"displayName")>
					#application.types[componentname].displayname#
				<cfelse>
					#componentName#
				</cfif>	
				</span>
			</td>
			<cfelse>
			<td>
				<cfif structkeyexists(application.types[componentname],"displayName")>
					#application.types[componentname].displayname#
				<cfelse>
					#componentName#
				</cfif>	
			</td>
			</cfif>
			<td>#componentName#</td>
			<td>
				<cfif NOT alterType.isCFCDeployed(typename=componentName)>
					<a href="#CGI.SCRIPT_NAME#?deploy=#componentName#">#application.adminBundle[session.dmProfile.locale].deploy#</a>
				<cfelse>
					#application.adminBundle[session.dmProfile.locale].notAvailable#
				</cfif>
			</td>
			<!--- <td><em>Create Permissions</em>
			check application.types[componentname].permissionset exists
			if not assume typename* --->
			</td>
			<td style="border-right:none">
			<a href="#variables.documentURL#?component=#application.types[componentname].name#">Doc</a>
			</td>
		</tr>
	</cfoutput>
	<cfscript>
	// output dreadful interface for COAPI evolution
		if (structKeyExists(stConflicts,'cfc') AND structKeyExists(stConflicts['cfc'],componentName))
			{
			writeoutput("<tr><td colspan='4' style='background-color:##F9E6D4;border-right:none'><div id='#componentname#_report'>");
			alterType.renderCFCReport(typename=componentname,stCFC=stConflicts['cfc'][componentname]);
			writeoutput("</div></td></tr>");		
			}
		if (structKeyExists(stConflicts,'database') AND structKeyExists(stConflicts['database'],componentName))
			{
			writeoutput("<tr><td colspan='4' style='background-color:##F9E6D4;border-right:none'><div id='#componentname#_report'>");
			alterType.renderDBReport(typename=componentname,stDB=stConflicts['database'][componentname]);
			writeoutput("</div></td></tr>");		
			}
	</cfscript>
</cfif>
</cfloop>
<cfoutput></table></cfoutput>

<cfoutput>
	<h3>#application.adminBundle[session.dmProfile.locale].typeClasses#</h3>
	<table class="table-5" cellspacing="0">
	<tr>
		<th>#application.adminBundle[session.dmProfile.locale].integrity#</th>
		<th>#application.adminBundle[session.dmProfile.locale].component#</th>
		<th>#application.adminBundle[session.dmProfile.locale].component#</th>
		<!--- TODO: i18n remove property label --->
		<!--- <th>#application.adminBundle[session.dmProfile.locale].deployed#</th> --->
		<th>#application.adminBundle[session.dmProfile.locale].deploy#</th>
		<!--- TODO: i18n --->
		<th style="border-right:none">Doc</th>
	</tr>
</cfoutput>
	
<!--- output core types --->
<cfloop collection="#application.types#" item="componentName">
<cfif NOT application.types[componentname].bcustomtype>
	<cfscript>
		if (structKeyExists(stTypes,componentname))
			stConflicts = alterType.compareDBToCFCMetadata(typename=componentname,stDB=stTypes['#componentname#']);
		else
			stConflicts['#componentname#'] = structNew();
	</cfscript>
	<cfoutput>
		<tr <cfif alterType.isCFCConflict(stConflicts=stConflicts,typename=componentName)>style='color:##000;'</cfif>>
			<td>
				<cfif alterType.isCFCConflict(stConflicts=stConflicts,typename=componentName)>
					<img src="#application.url.farcry#/images/no.gif" /> #application.adminBundle[session.dmProfile.locale].seeBelow#
				<cfelse>
					<img src="#application.url.farcry#/images/yes.gif" />
				</cfif>
			</td>
			<td><span title="<cfif structKeyExists(application.types[componentname], 'hint')>#application.types[componentname].hint#<cfelse>#application.types[componentname].displayname#</cfif>">#application.types[componentname].displayname#</span></td>
			<td>#componentName#</td>
			<td>
				<cfif NOT alterType.isCFCDeployed(typename=componentName)>
					<a href="#CGI.SCRIPT_NAME#?deploy=#componentName#">#application.adminBundle[session.dmProfile.locale].deploy#</a>
				<cfelse>
					#application.adminBundle[session.dmProfile.locale].notAvailable#
				</cfif>
			</td>
			<td style="border-right:none">
			<a href="#variables.documentURL#?component=#application.types[componentname].name#">Doc</a>
			</td>
		</tr>
	</cfoutput>
	<cfscript>
	// output dreadful interface for COAPI evolution
		if (structKeyExists(stConflicts,'cfc') AND structKeyExists(stConflicts['cfc'],componentName))
			{
			writeoutput("<tr><td colspan='4' style='background-color:##F9E6D4;border-right:none'><div id='#componentname#_report'>");
			alterType.renderCFCReport(typename=componentname,stCFC=stConflicts['cfc'][componentname]);
			writeoutput("</div></td></tr>");		
			}
		if (structKeyExists(stConflicts,'database') AND structKeyExists(stConflicts['database'],componentName))
			{
			writeoutput("<tr><td colspan='4' style='background-color:##F9E6D4;border-right:none'><div id='#componentname#_report'>");
			alterType.renderDBReport(typename=componentname,stDB=stConflicts['database'][componentname]);
			writeoutput("</div></td></tr>");		
			}
	</cfscript>
</cfif>
</cfloop>
<cfoutput></table></cfoutput>

<admin:footer>

<!--- <cfdump var="#application.types.dmarchive#"> --->
<cfsetting enablecfoutputonly="No">
