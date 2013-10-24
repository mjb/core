<!--- @@cacheStatus: 1 --->


<cfif len(stobj.firstname) OR len(stobj.lastname)>
	<cfoutput>#stobj.firstname# #stobj.lastname#</cfoutput>
<cfelseif len(stobj.emailAddress)>
	<cfoutput>#stobj.emailAddress#</cfoutput>
<cfelse>
	<cfoutput>#stobj.userName#</cfoutput>
</cfif>

