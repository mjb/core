<cfsetting enablecfoutputonly="yes" />

<cfif not thisTag.HasEndTag>
	<cfabort showerror="skin:loadCSS requires an end tag." />
</cfif>

<cfif thistag.executionMode eq "Start">
	<!--- Do Nothing --->
</cfif>

<cfif thistag.executionMode eq "End">
	<cfparam name="attributes.id" default=""><!--- The id of the library that has been registered with the application --->
	<cfparam name="attributes.lCombineIDs" default=""><!--- A list of registered CSS ids, to be included in this library --->
	<cfparam name="attributes.baseHREF" default=""><!--- The url baseHREF to the css files--->
	<cfparam name="attributes.lFiles" default=""><!--- The files to include in that baseHREF --->
	<cfparam name="attributes.media" default=""><!--- the media type to use in the style tag --->
	<cfparam name="attributes.condition" default=""><!--- the condition to wrap around the style tag --->
	<cfparam name="attributes.prepend" default=""><!--- any CSS to prepend to the beginning of the script block --->
	<cfparam name="attributes.append" default=""><!--- any CSS to append to the end of the script block --->
	<cfparam name="attributes.bCombine" default=""><!--- Should the files be combined into a single cached css file. Passing true/false will override how it was registered. --->
	
	<!--- 
	<cfif attributes.id EQ "fc-jquery-ui">
		<cfset attributes.id = 'jquery-ui'>
	</cfif>
	<cfif attributes.id EQ "fc-bootstrap">
		<cfset attributes.id = 'bootstrap'>
	</cfif> --->
	
	
	<cfif len(trim(thisTag.generatedContent))>
		<cfset attributes.append = "#attributes.append##thisTag.generatedContent#" />
		<cfset thisTag.generatedContent = "" />
	</cfif>
	
	<cfset stCSS = duplicate(attributes) />
	
	<!--- Generate our id based on the baseHREF and files passed in. --->
	<cfif not len(stCSS.id)>
		<cfset stCSS.id = hash("#stCSS.baseHREF##stCSS.lFiles##stCSS.lCombineIDs#") />
	</cfif>
	
	
	<cfparam name="request.inHead.aCSSLibraries" default="#arrayNew(1)#" />
	<cfparam name="request.inHead.stCSSLibraries" default="#structNew()#" />
	
	
	<cfif NOT structKeyExists(request.inhead.stCSSLibraries, stCSS.id) or not listcontainsnocase(arraytolist(request.inHead.aCSSLibraries),stCSS.id)>
		
		<cfif structKeyExists(application.fc.stCSSLibraries, stCSS.id)>
			<cfif not len(stCSS.lCombineIDs)>
				<cfset stCSS.lCombineIDs = application.fc.stCSSLibraries[stCSS.id].lCombineIDs />
			</cfif>
			<cfif not len(stCSS.baseHREF)>
				<cfset stCSS.baseHREF = application.fc.stCSSLibraries[stCSS.id].baseHREF />
			</cfif>
			<cfif not len(stCSS.lFiles)>
				<cfset stCSS.lFiles = application.fc.stCSSLibraries[stCSS.id].lFiles />
			</cfif>
			<cfif not len(stCSS.media)>
				<cfset stCSS.media = application.fc.stCSSLibraries[stCSS.id].media />
			</cfif>
			<cfif not len(stCSS.condition)>
				<cfset stCSS.condition = application.fc.stCSSLibraries[stCSS.id].condition />
			</cfif>
			<cfif not len(stCSS.prepend)>
				<cfset stCSS.prepend = application.fc.stCSSLibraries[stCSS.id].prepend />
			</cfif>
			<cfif not len(stCSS.append)>
				<cfset stCSS.append = application.fc.stCSSLibraries[stCSS.id].append />
			</cfif>
			<cfif not isBoolean(stCSS.bCombine)>
				<cfset stCSS.bCombine = application.fc.stCSSLibraries[stCSS.id].bCombine />
			</cfif>
		<cfelse>
			<cfif not isBoolean(stCSS.bCombine)>
				<cfset stCSS.bCombine = true />
			</cfif>
			<cfif not len(stCSS.media)>
				<cfset stCSS.media = "all" />
			</cfif>
		</cfif>
		
		<!--- Normalise files --->
		<cfif len(stCSS.lFiles)>
			<cfset stCSS.lFullFilebaseHREFs = application.fc.utils.normaliseFileList(stCSS.baseHREF,stCSS.lFiles) />
		<cfelse>
			<cfset stCSS.lFullFilebaseHREFs = "" />
		</cfif>
		
		<!--- Identify external files --->
		<cfif refindnocase("(^|,)(http[s]?\:)?//",stCSS.lFiles)>
			<cfset stCSS.bCombine = false />
			<cfset stCSS.bExternal = true />
		<cfelse>
			<cfset stCSS.bExternal = false />
		</cfif>
		
		<!--- Add the id to the array to make sure we keep track of the order in which these libraries need to appear. --->
		<cfset arrayAppend(request.inHead.aCSSLibraries, stCSS.id) />
		
		<!--- Add the css information to the struct so we will be able to load it all correctly into the header at the end of the request. --->
		<cfset request.inHead.stCSSLibraries[stCSS.id] = stCSS />
	
	<cfelse>
	
		<cfset stCSS = request.inHead.stCSSLibraries[stCSS.id] />
	</cfif>
	
	
	<!--- SAVE THIS INFORMATION INTO THE RELEVENT WEBSKINS FOR CACHING --->
	<cfset application.fc.lib.objectbroker.addCSSHeadToWebskins(stCSS="#stCSS#") />
	
	
</cfif>

<cfsetting enablecfoutputonly="no" />