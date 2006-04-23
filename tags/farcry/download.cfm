<!---
|| LEGAL ||
$Copyright: Daemon Pty Limited 1995-2003, http://www.daemon.com.au $
$License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php$

|| VERSION CONTROL ||
$Header: /cvs/farcry/farcry_core/tags/farcry/download.cfm,v 1.17 2005/10/07 05:44:58 daniela Exp $
$Author: daniela $
$Date: 2005/10/07 05:44:58 $
$Name: milestone_3-0-0 $
$Revision: 1.17 $

|| DESCRIPTION ||
$Description: Downloads a dmFile object$


|| DEVELOPER ||
$Developer: Brendan Sisson (brendan@daemon.com.au)$

|| ATTRIBUTES ||
$in: $
$out:$
--->

<cfsetting enablecfoutputonly="Yes">
<cfimport taglib="/farcry/fourq/tags/" prefix="q4">

<cfif isdefined("attributes.downloadfile")>
	<cfset url.downloadfile = attributes.downloadfile>
</cfif>


<!--- should not be able to get object unless authorised. --->
<cfif isDefined("url.DownloadFile") and len(trim(url.DownloadFile))>

	<q4:contentobjectget objectid="#url.DownloadFile#" r_stobject="stFile">

    <!--- work out file type --->
    <cfif stFile.typeName eq "dmImage">
        <cfset pos = find(".", stFile.imageFile)>
        <cfset suffix = removeChars(stFile.imageFile, 1, pos)>
    <cfelse>
		<cfset pos = find(".", stFile.filename)>
        <cfset suffix = removeChars(stFile.filename, 1, pos)>
    </cfif>

	<!--- pick a mime type (if required) --->
	<cfswitch expression="#lCase(suffix)#">

		<cfcase value="mpg,mpeg">
			<cfset mimeType = "video/mpeg">
		</cfcase>

		<cfcase value="avi">
			<cfset mimeType = "video/x-msvideo">
		</cfcase>

        <cfcase value="gif">
            <cfset mime = "image/gif">
        </cfcase>

        <cfcase value="jpg">
            <cfset mime = "image/jpg">
        </cfcase>

        <cfcase value="jpeg">
            <cfset mime = "image/jpeg">
        </cfcase>

		<cfcase value="pdf">
			<cfset mime = "application/pdf">
		</cfcase>

		<cfdefaultcase>
			<cfset mime = "application/unknown">
		</cfdefaultcase>

	</cfswitch>

	<!--- log download --->
	<cfinvoke component="#application.packagepath#.farcry.stats" method="logEntry">
		<cfinvokeargument name="pageId" value="#url.DownloadFile#"/>
		<cfinvokeargument name="navId" value="#url.DownloadFile#"/>
		<cfinvokeargument name="remoteIP" value="#cgi.REMOTE_ADDR#"/>
		<cfinvokeargument name="sessionId" value="#trim(session.sessionId)#"/>
		<cftry>
			<cfinvokeargument name="browser" value="#trim(cgi.HTTP_USER_AGENT)#"/>
			<cfcatch><cfinvokeargument name="browser" value="Unknown"/></cfcatch>
		</cftry>
		<!--- check is a user is logged in --->
		<cfif request.LoggedIn>
			<cfinvokeargument name="userid" value="#session.dmSec.authentication.userlogin#"/>
		<cfelse>
			<cfinvokeargument name="userid" value="Anonymous"/>
		</cfif>
	</cfinvoke>

	<!--- download --->
    <cftry>
	    <cfif stFile.typeName eq "dmImage">
	 		<cfheader name="content-disposition" VALUE="inline; filename=#stFile.imageFile#">
			<cfheader name="cache-control" value="">
			<cfheader name="pragma" value="">
	        <cfcontent type="#mime#" file="#stFile.originalImagePath#/#stFile.imageFile#" deletefile="No" reset="Yes">
	    <cfelse>
			<cfheader name="Content-Disposition" VALUE="attachment;filename=#stFile.filename#">
			<cfheader name="cache-control" value="">
			<cfheader name="pragma" value="">
			<cfcontent type="#mime#" file="#application.path.defaultfilepath#/#stFile.filename#" deletefile="No" reset="Yes">
	    </cfif>
    <cfcatch><!--- prevent unnecessary log entries when user cancels download whilst it is in progress ---></cfcatch>
    </cftry>
	<cfabort>

<!--- ext file --->
<cfelseif isdefined("url.extFile") and isDefined("application.config.verity.contentType.extFiles.aProps.uncpath")>

	<!--- get filename --->
	<cfset filename = replace(url.extFile,"\","/","all")>
	<cfset fileName = listLast(filename,"/")>

	<!--- work out file type --->
 	<cfset pos = find(".", url.extFile)>
    <cfset suffix = removeChars(url.extFile, 1, pos)>

	<!--- pick a mime type (if required) --->
	<cfswitch expression="#lCase(suffix)#">

		<cfcase value="mpg,mpeg">
			<cfset mimeType = "video/mpeg">
		</cfcase>

		<cfcase value="avi">
			<cfset mimeType = "video/x-msvideo">
		</cfcase>

        <cfcase value="gif">
            <cfset mime = "image/gif">
        </cfcase>

        <cfcase value="jpg">
            <cfset mime = "image/jpg">
        </cfcase>

        <cfcase value="jpeg">
            <cfset mime = "image/jpeg">
        </cfcase>

		<cfcase value="pdf">
			<cfset mime = "application/pdf">
		</cfcase>

		<cfdefaultcase>
			<cfset mime = "application/unknown">
		</cfdefaultcase>

	</cfswitch>

	<!--- download file via unc path specified for external files --->
	<cfheader name="content-disposition" value="attachment; filename=#fileName#" />
	<cfheader name="cache-control" value="">
	<cfheader name="pragma" value="">

    <cftry>
	<cfcontent type="#mime#" file="#application.config.verity.contentType.extFiles.aProps.uncpath#/#fileName#" deletefile="No" reset="Yes">
    <cfcatch><!--- prevent unnecessary log entries when user cancels download whilst it is in progress ---></cfcatch>
    </cftry>
    <cfabort>

</cfif>

<cfsetting enablecfoutputonly="No">