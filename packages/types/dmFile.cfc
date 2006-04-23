<!--- 
|| LEGAL ||
$Copyright: Daemon Pty Limited 1995-2003, http://www.daemon.com.au $
$License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php$

|| VERSION CONTROL ||
$Header: /cvs/farcry/farcry_core/packages/types/dmFile.cfc,v 1.24 2005/10/17 07:28:23 guy Exp $
$Author: guy $
$Date: 2005/10/17 07:28:23 $
$Name: milestone_3-0-0 $
$Revision: 1.24 $

|| DESCRIPTION || 
$Description: dmFile type $


|| DEVELOPER ||
$Developer: Brendan Sisson (brendan@daemon.com.au) $

|| ATTRIBUTES ||
$in: $
$out:$
--->

<cfcomponent extends="types" displayname="File"  hint="File objects" bUseInTree="1">
<!------------------------------------------------------------------------
type properties
------------------------------------------------------------------------->
<cfproperty name="title" type="nstring" hint="Meaningful reference title for file" required="no" default=""> 
<cfproperty name="filename" type="string" hint="The name of the file to be uploaded" required="no" default="">  
<cfproperty name="filepath" type="string" hint="The location of the file on the webserver" required="no" default="">  
<cfproperty name="fileSize" type="numeric" hint="The size of the file on the webserver (in bytes)" required="no" default="0">  
<cfproperty name="fileType" type="string" hint="MIME content type of the saved file" required="no" default="">
<cfproperty name="fileSubType" type="string" hint="MIME content subtype of the saved file" required="no" default="">
<cfproperty name="fileExt" type="string" hint="The extension of the file on the webserver (without the period)" required="no" default="">
<cfproperty name="documentDate" type="date" hint="The date of a file object" required="no" default="">
<cfproperty name="bLibrary" type="numeric" hint="Flag to indictae if in file library or not" required="no" default="1">
<cfproperty name="description" type="longchar" hint="A description of the file to be uploaded" required="No" default=""> 
<cfproperty name="status" type="string" hint="Status of the node (draft, pending, approved)." required="yes" default="draft">
<!--- Object Methods --->

<cffunction name="edit" access="public">
	<cfargument name="objectid" required="yes" type="UUID">
	
	<!--- getData for object edit --->
	<cfset var stObj = this.getData(arguments.objectid)>
	<!--- check if datePublished has been set --->
	<cfif not isDate(stObj.documentDate)>
		<cfset stObj.documentDate = stObj.dateTimeCreated>
	</cfif>
	<!--- include edit handler --->	
	<cfinclude template="_dmFile/edit.cfm">
</cffunction>

<cffunction name="display" access="public" output="true">
	<cfargument name="objectid" required="yes" type="UUID">
	
	<!--- getData for object edit --->
	<cfset var stObj = this.getData(arguments.objectid)>
	<cfinclude template="_dmFile/display.cfm">
</cffunction>

<cffunction name="delete" access="public" hint="Specific delete method for dmFile. Removes physical files from ther server." returntype="struct">
	<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of the object being deleted">
	
	<cfset var stLocal = StructNew()>
	<cfset var stReturn = StructNew()>
	<!--- get object details --->
	<cfset var stObj = getData(arguments.objectid)>

	<cfset stReturn.bSuccess = true>
	<cfset stReturn.message = "#stObj.label# (#stObj.typename#) deleted.">
		
	<cfset stLocal.errormessage = "">
	<!--- check if image is associated with any content items --->
	<cfset stLocal.lrelatedContentTypes = "dmNews,dmNavigation,dmHtml,dmEvent">

	<cfloop index="stLocal.relatedContentType" list="#stLocal.lrelatedContentTypes#">
		<cfquery name="stLocal.qCheck" datasource="#application.dsn#">
		SELECT	objectid
		FROM	#application.dbowner##stLocal.relatedContentType#_aobjectids
		WHERE	data = '#arguments.objectid#'
		</cfquery>
		<cfif stLocal.qCheck.recordcount GTE 1>
			<cfset stLocal.errormessage = stLocal.errormessage & "Sorry this image cannot be delete because it is associated to <strong>#stLocal.qCheck.recordcount# #stLocal.relatedContentType#</strong> item(s).<br />">
		</cfif>
	</cfloop>

	<cfif stLocal.errormessage NEQ "">
		<cfoutput>#stLocal.errormessage#</cfoutput>
	<cfelse>
		<cfinclude template="_dmFile/delete.cfm">
	</cfif>
	<cfreturn stReturn>
</cffunction>	

<cffunction name="archiveObject" access="public" hint="Archive a file object">
	<cfargument name="objectid" required="yes" type="UUID" hint="Object ID of the object to be archived">
	
	<!--- get object details --->
	<cfset var stObj = getData(arguments.objectid)>
	<cfset var stProps = structNew()>
	<cfset var oArchive = createobject("component",application.types.dmArchive.typepath)>
	<cfset var archiveObjectId= createUUID()>
	<cfset var stLiveWDDX = "">
	
	<!--- rename current live file --->
	<cfif fileExists("#application.path.project#/www/files/#stObj.fileName#")>
		<cffile action="RENAME" source="#application.path.project#/www/files/#stObj.fileName#" destination="#application.path.project#/www/files/#archiveObjectId#_#stObj.fileName#">
		<cfset stObj.fileName = "#archiveObjectId#_#stObj.fileName#">
	</cfif>
	<!--- Convert current live object to WDDX for archive --->
	<cfwddx input="#stObj#" output="stLiveWDDX"  action="cfml2wddx">

	<!--- archive file object --->
	<cfscript>
		stProps.objectID = archiveObjectId;
		stProps.archiveID = stObj.objectID;
		stProps.objectWDDX = stLiveWDDX;
		stProps.label = stObj.title;		
		oArchive.createData(stProperties=stProps);
	</cfscript>
</cffunction>

<cffunction name="archiveRollback" access="public" returntype="struct" hint="Sends a archived object live and archives current version">
	<cfargument name="objectID" type="uuid" required="true">
	<cfargument name="archiveID"  type="uuid" required="true" hint="the archived object to be sent back live">
	<cfargument name="typename" type="string" default="" required="false">
	
	<cfset var stResult = structNew()>
	<cfset var stArchiveDetail = "">
	<cfset var stArchive = "">
	<cfset var oArchive = createObject("component",application.types.dmArchive.typepath)>
	
	<cflock name="archive_#arguments.archiveID#" timeout="50" type="exclusive">
		<!--- archive current object --->
		<cfset archiveObject(objectid)>
		
		<!--- rollback archived version --->	
		<cfset stArchive = oArchive.getData(objectid=arguments.archiveID)>
		
		<!--- Convert wddx archive object --->
		<cfwddx input="#stArchive.objectwddx#" output="stArchiveDetail"  action="wddx2cfml">
		<cfset stArchiveDetail.objectid = arguments.objectID>
		<cfset stArchiveDetail.locked = 0>
		<cfset stArchiveDetail.lockedBy = "">
		
		<!--- copy physical file (remove uuid)--->
		<cfif fileExists("#application.path.project#/www/files/#stArchiveDetail.fileName#")>
			<cffile action="COPY" source="#application.path.project#/www/files/#stArchiveDetail.fileName#" destination="#application.path.project#/www/files/#right(stArchiveDetail.fileName,len(stArchiveDetail.fileName)-36)#">
			<cfset stArchiveDetail.fileName = right(stArchiveDetail.fileName,len(stArchiveDetail.fileName)-36)>
		</cfif>
		
		<!--- Update current live object with archive property values	 --->
		<cfset setData(stProperties=stArchiveDetail,auditNote='Archive rolled back')>
			
		<!--- update tree --->
		<nj:getNavigation objectId="#arguments.objectID#" bInclusive="1" r_stObject="stNav" r_ObjectId="objectId">	
		<nj:updateTree ObjectId="#stNav.objectId#">
		
		<cfset stResult.result = false>
		<cfset stRestult.message = 'No update has taken place'>
	</cflock>
	
	<cfreturn stResult>
</cffunction>

<cffunction name="setFriendlyURL" access="public" returntype="struct" hint="the default set friendly url for an object." output="true">
	<cfargument name="stProperties" required="true" type="struct">
	
	<cfset var stLocal = structnew()>
	<cfset stLocal.returnstruct = StructNew()>
	<cfset stLocal.returnstruct.bSuccess = 1>
	<cfset stLocal.returnstruct.message = "">
	
	<cfset stLocal.stFriendlyURL = StructNew()>
	<cfset stLocal.stFriendlyURL.objectid = arguments.stProperties.objectid>
	<cfset stLocal.stFriendlyURL.friendlyURL = "">
	<cfset stLocal.stFriendlyURL.querystring = "">
	<!--- 
			<cfset stLocal.objFU = CreateObject("component","#Application.packagepath#.farcry.fu")>
			<!--- used to retrieve default of where item is in tree --->
			<cfset stLocal.objNavigation = CreateObject("component","#Application.packagepath#.types.dmnavigation")>
	
			<!--- This determines the friendly url by where it sits in the navigation node  --->
			<cfset stLocal.qNavigation = stLocal.objNavigation.getParent(arguments.stProperties.objectid)>
	
			<cfif stLocal.qNavigation.recordcount>
				<cfset stLocal.stFriendlyURL.friendlyURL = stLocal.objFU.createFUAlias(stLocal.qNavigation.objectid)>
			<cfelse> <!--- generate friendly url based on content type --->
				<cfif StructkeyExists(application.types[arguments.stProperties.typename],"displayName")>
					<cfset stLocal.stFriendlyURL.friendlyURL = "/#application.types[arguments.stProperties.typename].displayName#">
				<cfelse>
					<cfset stLocal.stFriendlyURL.friendlyURL = "/#ListLast(application.types[arguments.stProperties.typename].name,'.')#">
				</cfif>
			</cfif>
	
			<cfset stLocal.stFriendlyURL.friendlyURL = stLocal.stFriendlyURL.friendlyURL & "/#arguments.stProperties.label#">
			<cfset stLocal.objFU.setFU(stLocal.stFriendlyURL.objectid, stLocal.stFriendlyURL.friendlyURL, stLocal.stFriendlyURL.querystring)>
	 --->
	<cfreturn stLocal.returnstruct>
</cffunction>
</cfcomponent>