<cfsetting enablecfoutputonly="true">
<!--- @@Copyright: Daemon Pty Limited 1995-2007, http://www.daemon.com.au --->
<!--- @@License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php --->
<!--- @@displayname: farcryButtonPanel --->
<!--- @@Description: Wrapper for farcry buttons. --->
<!--- @@Developer: Matthew Bryant (mbryant@daemon.com.au) --->


<!--- Import tag libraries --->
<cfimport taglib="/farcry/core/tags/formtools/" prefix="ft" >

<cfif not thistag.HasEndTag>
	<cfabort showerror="Does not have an end tag...">
</cfif>

<cfif thistag.ExecutionMode EQ "Start">
	
	<cfparam  name="attributes.id" default="#application.fapi.getUUID()#">
	<cfparam  name="attributes.class" default="form-actions">
	<cfparam  name="attributes.style" default="">
	<cfparam  name="attributes.autoSetPriority" default="false">
	
	<cfif attributes.autoSetPriority>
		<cfset bPrimaryDefined = false />
	<cfelse>
		<cfset bPrimaryDefined = true />
	</cfif>
	

	<cfoutput>
		<div id="#attributes.id#" class="#attributes.class#" style="#attributes.style#">
	</cfoutput>
</cfif>

<cfif thistag.ExecutionMode EQ "End">

	<cfoutput>
		</div>
	</cfoutput>

</cfif>


<cfsetting enablecfoutputonly="false">
