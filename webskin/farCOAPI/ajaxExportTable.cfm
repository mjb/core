<cftry>
	<cfset stTable = session.stSkeletonExport.aTables[url.position]>


	<cfloop from="1" to="#arrayLen(stTable.aDeploySQL)#" index="iType">
		<cffile action="write" file="#application.path.project#/install/sql/DEPLOY-#stTable.aDeploySQL[iType].dbType#_#stTable.name#.sql" output="#stTable.aDeploySQL[iType].sql#">
	</cfloop>
	
	<cfloop from="1" to="#arrayLen(stTable.aInsertSQL)#" index="iPage">
		
		
		<cfset insertSQL = stTable.aInsertSQL[iPage]>
		<cfquery datasource="#application.dsn#" name="qryTemp">
		#preserveSingleQuotes(insertSQL)#
		</cfquery>
		
		<cfsavecontent variable="insertSQL">
		<cfloop query="qryTemp">
			<cfset formattedValues = replaceNoCase(qryTemp.insertValues,'|???|','null','all')>
			<cfset formattedValues = replaceNoCase(formattedValues,"'","''","all")>
			<cfset formattedValues = replaceNoCase(formattedValues,"|---|","'","all")>
			<cfset formattedValues = rereplace(formattedValues,'\{ts ([^}]*)\}','\1','all')>
			<cfset formattedValues = replaceNoCase(formattedValues,"'NULL'","NULL","all")>
			<cfoutput>INSERT INTO #stTable.name# (#stTable.insertFieldnames#) VALUES ( #formattedValues# );
</cfoutput>
		</cfloop>
		</cfsavecontent>
		
					   													
		<cffile action="write" file="#application.path.project#/install/sql/INSERT-#stTable.name#-#iPage#.sql" output="#insertSQL#">
			
	</cfloop>
		
	
	<cfset stTable.bComplete = 1>
	
	<cfoutput>#arrayLen(stTable.aInsertSQL)# pages generated.</cfoutput>
	
	<cfcatch type="any">
		<cfdump var="#cfcatch#"><cfabort>

		<cfheader statuscode="500" statustext="#cfcatch.Message#" />
	</cfcatch>
</cftry>