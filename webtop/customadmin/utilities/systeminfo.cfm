<cfsetting enablecfoutputonly="true" />
<!--- @@displayname: System Information --->

<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />

<admin:header />

<cfoutput>
	<h1>System Information</h2>
</cfoutput>

<ft:form>
	<ft:fieldset legend="UpdateApp">
		<cfif isdefined("application.fcstats.updateapp")>
			<ft:field label="Most Recent" bMultiField="true" hint="The time of the most recent UpdateApp">
				<cfoutput>#timeformat(application.fcstats.updateapp.when[application.fcstats.updateapp.recordcount],"h:mm tt")#, #dateformat(application.fcstats.updateapp.when[application.fcstats.updateapp.recordcount],"dddd d mmmm yyyy")#</cfoutput>
			</ft:field>
		</cfif>
		<ft:field label="Count" bMultiField="true" hint="The number of times this app has been restarted since the last ColdFusion reset">
			<cfif isdefined("application.fcstats.updateapp")><cfoutput>#application.fcstats.updateapp.recordcount#</cfoutput><cfelse>0</cfif>
		</ft:field>
		<cfif isdefined("application.fcstats.updateapp")>
			<ft:field label="Speed" bMultiField="true" hint="How long each updateapp took">
				<cfchart format="png" xaxistitle="Date" yaxistitle="Tick Count" chartwidth="500">
					<cfchartseries type="line" query="application.fcstats.updateapp" itemcolumn="when" valuecolumn="howlong">
					</cfchartseries>
				</cfchart>
			</ft:field>
		</cfif>
	</ft:fieldset>
</ft:form>



<skin:loadCSS>
	<cfoutput>
	tr.used {
		background-color:green;
	}
	tr.unused {
		background-color:red;
		display:none;
	}
	</cfoutput>
</skin:loadCSS>

<cfoutput><hr></cfoutput>
<skin:buildLink href="##" onClick="$j('tr.used').toggle();return false;" linkText="Show/Hide Used" />
<skin:buildLink href="##" onClick="$j('tr.unused').toggle();return false;" linkText="Show/Hide Un-Used" />

<cfloop collection="#application.stCoapi#" item="table">
	<cfset qWebskins = application.stCoapi[table].qWebskins>



	<cfif structKeyExists(application.fc.webskinLog, table)>


		<cfoutput>
		<h3>#table#</h3>
		
		<table class="objectAdmin">
		</cfoutput>
		
		<cfoutput query="qWebskins">
			<cfif listLast(qWebskins.DIRECTORY, "/") EQ table>
				<cfif structKeyExists(application.fc.webskinLog, table) AND structKeyExists(application.fc.webskinLog[table], qWebskins.methodName)>
					<cfset bUsed = application.fc.webskinLog[table][qWebskins.methodName]>
					<cfset usedClass = "used">
				<cfelse>
					<cfset bUsed = 0>
					<cfset usedClass = "unused">
				</cfif>
				
				
				<tr class="#usedClass#">
					<td>#qWebskins.methodName#</td>
					<td>
						#bUsed#
					</td>
				</tr>
			</cfif>
		</cfoutput>
		
		<cfoutput>
		</table>
		</cfoutput>
	
	</cfif>
</cfloop>


<admin:footer />

<cfsetting enablecfoutputonly="false" />