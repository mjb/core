<cfsetting enablecfoutputonly="true">
<!--- @@displayname: Repositories JSON API Method --->
<!--- @@viewstack: page --->

<cfparam name="url.nested" type="boolean" default="false">

<cfset oRepo = application.fapi.getContentType(typename="configRepositories")>
<cfset stRepoData = structNew()>

<cfif isDefined("url.key") AND url.key eq application.updateappkey>
	<!--- get repository data --->
	<cfset aPaths = oRepo.getAllRepositoryPaths()>
	<cfset stRepoData = oRepo.processRepositoryPaths(aPaths, url.nested)>
</cfif>

<!--- output json response --->
<cfset request.mode.ajax = 1>
<cfcontent type="application/json" reset="true">
<cfoutput>#serializeJSON(stRepoData)#</cfoutput>

<cfsetting enablecfoutputonly="false">