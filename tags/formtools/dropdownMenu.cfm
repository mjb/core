<cfsetting enablecfoutputonly="true">
<!--- @@Copyright: Daemon Pty Limited 1995-2007, http://www.daemon.com.au --->
<!--- @@License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php --->
<!--- @@displayname: dropdownMenu --->
<!--- @@Description: Wrapper for farcry dropdownMenu. --->
<!--- @@Developer: Matthew Bryant (mbryant@daemon.com.au) --->


<!--- Import tag libraries --->
<cfimport taglib="/farcry/core/tags/formtools/" prefix="ft" >
<cfimport taglib="/farcry/core/tags/webskin/" prefix="skin" >

<cfif not thistag.HasEndTag>
	<cfabort showerror="Does not have an end tag...">
</cfif>




<cfparam  name="attributes.class" default="">
<cfparam  name="attributes.style" default="">


<cfif thistag.ExecutionMode EQ "Start">
	<cfoutput><ul class="dropdown-menu #attributes.class#" style="#attributes.style#"></cfoutput>
</cfif>

<cfif thistag.ExecutionMode EQ "End">
	<cfoutput></ul></cfoutput>
</cfif>


<cfsetting enablecfoutputonly="false">
