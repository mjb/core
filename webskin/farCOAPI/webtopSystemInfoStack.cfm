<cfsetting enablecfoutputonly="true">
<!--- @@displayname: Stack --->
<!--- @@seq: 900 --->

<cfdbinfo type="version" datasource="#application.dsn#" name="dbinfo">
<cfset stJava = CreateObject("java", "java.lang.System").getProperties()>

<cfoutput>
	<table class="table">
		<thead>
			<tr>
				<th style="width:220px;">Component</th>
				<th>Value</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td>Operating System</td>
				<td>#stJava['os.name']# #stJava['os.version']# (#stJava['os.arch']#)</td>
			</tr>
			<tr>
				<td>Java Version</td>
				<td>#stJava['java.runtime.version']#</td>
			</tr>
			<tr>
				<td>CFML Engine</td>
				<td>#server.coldfusion.productname# #server.coldfusion.productversion#</td>
			</tr>
			<tr>
				<td>Database</td>
				<td>#dbinfo.DATABASE_PRODUCTNAME# #dbinfo.DATABASE_VERSION#</td>
			</tr>
			<tr>
				<td>Database Driver</td>
				<td>#dbinfo.DRIVER_VERSION#</td>
			</tr>
			<tr>
				<td>Timezone</td>
				<td>#stJava['user.timezone']#</td>
			</tr>
		</tbody>
	</table>
</cfoutput>


<cfsetting enablecfoutputonly="false">