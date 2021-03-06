<cfcomponent name="objectBroker" displayname="objectBroker" access="public" hint="Stores and manages cache of objects to enable faster access">

	<cffunction name="init" access="public" output="false" returntype="struct">
		<cfargument name="bFlush" default="false" type="boolean" hint="Allows the application to force a total flush of the objectbroker." />
		
		<cfset var typename = "" />
		<cfset var bSuccess = true />
		
		<cfif arguments.bFlush OR NOT structKeyExists(application, "objectBroker") OR NOT structKeyExists(application, "objectrecycler")>
			<cfset application.objectbroker =  structNew() />
			
			<!--- This Java object gathers objects that were put in the broker but marked for garbage collection --->
			<cfset application.objectrecycler =  createObject("java", "java.lang.ref.ReferenceQueue") />
			
			<cfif structkeyexists(application,"stCOAPI")>
				<cfloop list="#structKeyList(application.stcoapi)#" index="typename">
					<cfif application.stcoapi[typename].bObjectBroker>
						<cfset bSuccess = configureType(typename=typename, MaxObjects=application.stcoapi[typename].ObjectBrokerMaxObjects) />
					</cfif>
				</cfloop>
			</cfif>
		</cfif>	

		<cfif not isdefined("application.fcstats.objectbroker") or not isobject(application.fcstats.objectbroker)>
			<cfparam name="application.fcstats" default="#structnew()#" />
			<cfset application.fcstats.objectbroker = createObject("component","farcry.core.packages.lib.objectBrokerStats").init() />
		</cfif>

		<cfreturn this />
	</cffunction>
	
	<cffunction name="trackObjectEvent" output="false" returntype="void">
		<cfargument name="eventname" type="string" required="true" />
		<cfargument name="typename" type="string" required="true" />
		<cfargument name="objectid" type="string" required="true" />
		
		<!---<cflog file="broker" type="information" text="Event:#arguments.eventname# Type:#arguments.typename# OID:#arguments.objectid#" />--->		
		<cfset application.fcstats.objectbroker.trackObjectEvent(argumentCollection=arguments) />
	</cffunction>
	
	<cffunction name="configureType" access="public" output="false" returntype="boolean">
		<cfargument name="typename" required="yes" type="string">
		<cfargument name="MaxObjects" required="no" type="numeric" default="100">
		<cfargument name="MaxWebskins" required="no" type="numeric" default="10">
		
		<cfset var bResult = "true" />
		
		<cflock name="objectBroker-#application.applicationname#-#arguments.typename#" type="exclusive" timeout="2" throwontimeout="true">			
			<cfset application.objectbroker[arguments.typename]=structnew() />
			<cfset application.objectbroker[arguments.typename].aobjects=arraynew(1) />
			<cfset application.objectbroker[arguments.typename].maxobjects=arguments.MaxObjects />		
		</cflock>
		
		<cfreturn bResult />
	</cffunction>
	
	<cffunction name="GetObjectCacheEntry" access="public" output="false" returntype="struct" hint="Get an object's cache entry in the object broker">
		<cfargument name="ObjectID" required="yes" type="UUID">
		<cfargument name="typename" required="true" type="string">
		
		<!---
			This method returns one of three different kinds of structures:
				- On a live entry cache hit, it returns a reference to the cache entry struct with "stobj" and "stWebskins" keys
				- On a dead entry cache hit, it returns a new struct with a "bDead" key  
				- On a cache miss, it returns a new empty struct  
		 --->
		
		<cfset var objRef = structNew()>
		<cfset var stCacheEntry = structNew()>
		
		<!--- If the type is stored in the objectBroker and the Object is currently in the ObjectBroker --->
		<cfif structkeyexists(application.objectbroker, arguments.typename)
			 	AND structkeyexists(application.objectbroker[arguments.typename], arguments.objectid)>
			<!--- Try to dereference the soft object reference in the broker --->
			<cftry>
				<cfset objRef = application.objectbroker[arguments.typename][arguments.objectid] />
				<cfset stCacheEntry = objRef.get() />
				<cfcatch />
			</cftry>
			<cfif not isDefined("stCacheEntry")>
				<!--- Soft reference is empty: cache entry must have been recycled --->
				<cfset stCacheEntry.bDead = true />
				<cfset trackObjectEvent(eventname="nullhit",typename=arguments.typename,objectid=arguments.objectid) /> 
				<!--- <cftrace type="warning" category="coapi" var="arguments.typename" text="Broker recycled reference hit."> --->
			<cfelseif structKeyExists(stCacheEntry,"stobj")>
				<!--- Cache hit --->
				<cfset trackObjectEvent(eventname="hit",typename=arguments.typename,objectid=arguments.objectid) />
				<!--- <cftrace type="information" category="coapi" var="stobj.typename" text="Broker object cache hit."> --->
			<cfelse>
				<!--- Cache miss: entry was snatched from right under our nose!--->
				<cfset trackObjectEvent(eventname="miss",typename=arguments.typename,objectid=arguments.objectid) />
			</cfif>
		<cfelse>
			<!--- Cache miss --->
			<cfset trackObjectEvent(eventname="miss",typename=arguments.typename,objectid=arguments.objectid) />
		</cfif>
		<cfreturn stCacheEntry>
	</cffunction>
		
	<cffunction name="GetFromObjectBroker" access="public" output="false" returntype="struct">
		<cfargument name="ObjectID" required="yes" type="UUID">
		<cfargument name="typename" required="true" type="string">
		
		<cfset var stobj = structNew()>
		<cfset var stCacheEntry = structNew()>
		
		<cfif application.bObjectBroker>
			<cfset stCacheEntry = GetObjectCacheEntry(objectId=arguments.objectId,typename=arguments.typename)>
			<cfif StructKeyExists(stCacheEntry,"stobj")>
				<cfset stObj = duplicate(stCacheEntry.stobj) />
			<cfelseif StructKeyExists(stCacheEntry,"bDead")>
				<!--- "Bring out your dead!" --->
				<cfset reapDeadEntriesFromBroker() />
			</cfif>
		</cfif>
		
		<cfreturn stobj>
	</cffunction>
		
	<cffunction name="getWebskin" access="public" output="true" returntype="struct" hint="Searches the object broker in an attempt to locate the requested webskin template. Returns a struct containing the webskinCacheID and the html.">
		<cfargument name="ObjectID" required="false" type="UUID">
		<cfargument name="typename" required="true" type="string">
		<cfargument name="template" required="true" type="string">
		<cfargument name="hashKey" required="true" type="string">
		
		<cfset var stResult = structNew() />
		<cfset var i = "" />
		<cfset var j = "" />
		<cfset var k = "" />
		<cfset var bFlushCache = 0 />
		<cfset var bForceFlush = false />
		<cfset var stCacheWebskin = structNew() />
		<cfset var webskinTypename = arguments.typename /><!--- Default to the typename passed in --->
		<cfset var stCoapi = structNew() />
		<cfset var hashRolesString = "" />
		<cfset var bCacheByURL = false />
		<cfset var bCacheByForm = false />
		<cfset var bCacheByRoles = false />
		<cfset var lCcacheByVars= "" />
		<cfset var hashString = "" />
		<cfset var iViewState = "" />
		<cfset var stCacheEntry = structNew() />
		
		
		<cfset stResult.webskinCacheID = "" />
		<cfset stResult.webskinHTML = "" />

		<cfif arguments.typename EQ "farCoapi">
			<!--- This means its a type webskin and we need to look for the timeout value on the related type. --->			
			<cfset stCoapi = application.fc.factory['farCoapi'].getData(typename="farCoapi", objectid="#arguments.objectid#") />
			<cfset webskinTypename = stCoapi.name />
		</cfif>

		
		
		<cfif application.bObjectBroker>
			
			<!--------------------------------------------------------------------------------------------------- 
			IF WE HAVE A FORM POST AND THE WEBSKIN IS SUPPOSED TO FLUSH ON FORM POST THEN FORCE A FLUSH CACHE
			 --------------------------------------------------------------------------------------------------->
			<cfif isDefined("form") AND not structIsEmpty(form)>
				<cfif application.coapi.coapiadmin.getWebskinCacheFlushOnFormPost(typename=webskinTypename, template=arguments.template)>
					<cfset bForceFlush = true />
				</cfif>
			</cfif>
			
			<cfif bForceFlush OR (structKeyExists(request,"mode") AND request.mode.flushcache EQ 1 AND structKeyExists(arguments, "objectid"))>
				<cfset bFlushCache = removeWebskin(objectid=arguments.objectid, typename=arguments.typename, template=template) />
			</cfif>
		
			<cfif structKeyExists(request,"mode") AND (request.mode.flushcache EQ 1 OR request.mode.showdraft EQ 1 OR request.mode.tracewebskins eq 1 OR request.mode.design eq 1 OR request.mode.lvalidstatus NEQ "approved" OR (structKeyExists(url, "updateapp") AND url.updateapp EQ 1))>
				<!--- DO NOT USE CACHE IF IN DESIGN MODE or SHOWING MORE THAN APPROVED OBJECTS or UPDATING APP --->
			<cfelse>
					<cfif structKeyExists(application.stcoapi[webskinTypename].stWebskins, arguments.template)>
						<cfif application.stcoapi[webskinTypename].stWebskins[arguments.template].cacheStatus EQ 1>
							<cfif structkeyexists(arguments,"objectid")>
								<cfset stCacheEntry = GetObjectCacheEntry(objectID=arguments.objectID,typename=arguments.typename)>
								<cfif structKeyExists(stCacheEntry,"stWebskins")
									AND 	structKeyExists(stCacheEntry.stWebskins, arguments.template)>
								
									<cfset stResult.webskinCacheID = generateWebskinCacheID(
											typename="#webskinTypename#", 
											template="#arguments.template#",
											hashKey="#arguments.hashKey#"
									) />
									
	
									<cfif structKeyExists(stCacheEntry.stWebskins[arguments.template], hash("#stResult.webskinCacheID#"))>
										<cfset stCacheWebskin = stCacheEntry.stWebskins[arguments.template]["#hash('#stResult.webskinCacheID#')#"] />
									</cfif>								
									
								</cfif>
							</cfif>
								
	
							<cfif not structisempty(stCacheWebskin)>
									
								<cfif structKeyExists(stCacheWebskin, "datetimecreated")
									AND structKeyExists(stCacheWebskin, "webskinHTML") >
									
									<cfif DateDiff('n', stCacheWebskin.datetimecreated, now()) LT stCacheWebskin.cacheTimeout >
										<cfset stResult.webskinHTML = stCacheWebskin.webskinHTML />
										
										<!--- Update request browser timeout --->
										<cfif stCacheWebskin.browserCacheTimeout neq -1 and (not structkeyexists(request.fc,"browserCacheTimeout") or stCacheWebskin.browserCacheTimeout lt request.fc.browserCacheTimeout)>
											<cfset request.fc.browserCacheTimeout = stCacheWebskin.browserCacheTimeout />
										</cfif>
										
										<!--- Update request proxy timeout --->
										<cfif stCacheWebskin.proxyCacheTimeout neq -1 and (not structkeyexists(request.fc,"proxyCacheTimeout") or stCacheWebskin.proxyCacheTimeout lt request.fc.proxyCacheTimeout)>
											<cfset request.fc.proxyCacheTimeout = stCacheWebskin.proxyCacheTimeout />
										</cfif>
										
										<!--- Place any request.inHead variables back into the request scope from which it came. --->
										<cfparam name="request.inHead" default="#structNew()#" />
										<cfparam name="request.inhead.stCustom" default="#structNew()#" />
										<cfparam name="request.inhead.aCustomIDs" default="#arrayNew(1)#" />
										<cfparam name="request.inhead.stOnReady" default="#structNew()#" />
										<cfparam name="request.inhead.aOnReadyIDs" default="#arrayNew(1)#" />
										
										<!--- CSS --->
										<cfparam name="request.inhead.stCSSLibraries" default="#structNew()#" />
										<cfparam name="request.inhead.aCSSLibraries" default="#arrayNew(1)#" />
										
										<!--- JS --->
										<cfparam name="request.inhead.stJSLibraries" default="#structNew()#" />
										<cfparam name="request.inhead.aJSLibraries" default="#arrayNew(1)#" />
										
										<cfloop list="#structKeyList(stCacheWebskin.inHead)#" index="i">
											<cfswitch expression="#i#">
												<cfcase value="stCustom">
													<cfloop list="#structKeyList(stCacheWebskin.inHead.stCustom)#" index="j">
														<cfif not structKeyExists(request.inHead.stCustom, j)>
															<cfset request.inHead.stCustom[j] = stCacheWebskin.inHead.stCustom[j] />
														</cfif>
														
														<cfset addhtmlHeadToWebskins(id="#j#", text="#stCacheWebskin.inHead.stCustom[j]#") />
			
													</cfloop>
												</cfcase>
												<cfcase value="aCustomIDs">
													<cfloop from="1" to="#arrayLen(stCacheWebskin.inHead.aCustomIDs)#" index="k">
														<cfif NOT listFindNoCase(arrayToList(request.inHead.aCustomIDs), stCacheWebskin.inHead.aCustomIDs[k])>
															<cfset arrayAppend(request.inHead.aCustomIDs,stCacheWebskin.inHead.aCustomIDs[k]) />
														</cfif>
													</cfloop>
												</cfcase>
												<cfcase value="stOnReady">
													<cfloop list="#structKeyList(stCacheWebskin.inHead.stOnReady)#" index="j">
														<cfif not structKeyExists(request.inHead.stOnReady, j)>
															<cfset request.inHead.stOnReady[j] = stCacheWebskin.inHead.stOnReady[j] />
														</cfif>
														
														<cfset addhtmlHeadToWebskins(id="#j#", onReady="#stCacheWebskin.inHead.stOnReady[j]#") />
			
													</cfloop>
												</cfcase>
												<cfcase value="aOnReadyIDs">
													<cfloop from="1" to="#arrayLen(stCacheWebskin.inHead.aOnReadyIDs)#" index="k">
														<cfif NOT listFindNoCase(arrayToList(request.inHead.aOnReadyIDs), stCacheWebskin.inHead.aOnReadyIDs[k])>
															<cfset arrayAppend(request.inHead.aOnReadyIDs,stCacheWebskin.inHead.aOnReadyIDs[k]) />
														</cfif>
													</cfloop>
												</cfcase>
												
												<!--- CSS LIBRARIES --->
												
												<cfcase value="stCSSLibraries">
													<cfloop list="#structKeyList(stCacheWebskin.inHead.stCSSLibraries)#" index="j">
														<cfif not structKeyExists(request.inHead.stCSSLibraries, j)>
															<cfset request.inHead.stCSSLibraries[j] = stCacheWebskin.inHead.stCSSLibraries[j] />
														</cfif>			
													</cfloop>
												</cfcase>
												<cfcase value="aCSSLibraries">
													<cfloop from="1" to="#arrayLen(stCacheWebskin.inHead.aCSSLibraries)#" index="k">
														<cfif NOT listFindNoCase(arrayToList(request.inHead.aCSSLibraries), stCacheWebskin.inHead.aCSSLibraries[k])>
															<cfset arrayAppend(request.inHead.aCSSLibraries,stCacheWebskin.inHead.aCSSLibraries[k]) />
														</cfif>														
														<cfset addCSSHeadToWebskins(stCacheWebskin.inHead.stCSSLibraries[stCacheWebskin.inHead.aCSSLibraries[k]]) />
													</cfloop>
												</cfcase>
												
	
												<!--- JS LIBRARIES --->
												
												<cfcase value="stJSLibraries">
													<cfloop list="#structKeyList(stCacheWebskin.inHead.stJSLibraries)#" index="j">
														<cfif not structKeyExists(request.inHead.stJSLibraries, j)>
															<cfset request.inHead.stJSLibraries[j] = stCacheWebskin.inHead.stJSLibraries[j] />
														</cfif>																	
													</cfloop>
												</cfcase>
												<cfcase value="aJSLibraries">
													<cfloop from="1" to="#arrayLen(stCacheWebskin.inHead.aJSLibraries)#" index="k">
														<cfif NOT listFindNoCase(arrayToList(request.inHead.aJSLibraries), stCacheWebskin.inHead.aJSLibraries[k])>
															<cfset arrayAppend(request.inHead.aJSLibraries,stCacheWebskin.inHead.aJSLibraries[k]) />
														</cfif>														
														<cfset addJSHeadToWebskins(stCacheWebskin.inHead.stJSLibraries[stCacheWebskin.inHead.aJSLibraries[k]]) />
													</cfloop>
												</cfcase>
																							
												<cfdefaultcase>
													<cfset addhtmlHeadToWebskins(library=i) />
													<cfset request.inHead[i] = stCacheWebskin.inHead[i] />
												</cfdefaultcase>
											</cfswitch>
								
										</cfloop>
		
									</cfif>	
									
								</cfif>	
							</cfif>
						</cfif>
					</cfif>
			
			</cfif>
			
		</cfif>
		
		<cfreturn stResult />
	</cffunction>
		
	<cffunction name="generateWebskinCacheID" access="public" output="false" returntype="string" hint="Generates a webskin Cache ID that can be hashed to store a specific version of a webskin cache.">
		<cfargument name="typename" required="true" />
		<cfargument name="template" required="true" />
		<cfargument name="hashKey" required="false" default="" />
		<cfargument name="bCacheByURL" required="false" default="#application.coapi.coapiadmin.getWebskincacheByURL(typename=arguments.typename, template=arguments.template)#" />
		<cfargument name="bCacheByForm" required="false" default="#application.coapi.coapiadmin.getWebskincacheByForm(typename=arguments.typename, template=arguments.template)#" />
		<cfargument name="bCacheByRoles" required="false" default="#application.coapi.coapiadmin.getWebskincacheByRoles(typename=arguments.typename, template=arguments.template)#" />
		<cfargument name="lcacheByVars" required="false" default="#application.coapi.coapiadmin.getWebskincacheByVars(typename=arguments.typename, template=arguments.template)#" />

		<cfset var WebskinCacheID = "" />
		<cfset var iFormField = "" />
		<cfset var iViewState = "" />
		<cfset var varname = "" />
	
		
		<!--- Always prefixed with the hash key. This can be overridden in the webskin call. It will include any cfparam attributes. --->
		<cfif len(arguments.hashKey)>
			<cfset WebskinCacheID = listAppend(WebskinCacheID, "#arguments.hashKey#") />
		</cfif>
		
		<cfif arguments.bCacheByURL>
			<cfset WebskinCacheID = listAppend(WebskinCacheID,"script_name:#cgi.script_name#,query_string:#cgi.query_string#") />
		</cfif>
		
		<cfif arguments.bCacheByForm AND isDefined("form")>
			<cfif structIsEmpty(form)>
				<cfset WebskinCacheID = listAppend(WebskinCacheID, "form:empty") />
			<cfelse>
				<cfloop list="#listSort(structKeyList(form),'text')#" index="iFormField">
					<cfif isSimpleValue(form[iFormField])>
						<cfset WebskinCacheID = listAppend(WebskinCacheID, "form[#iFormField#]:#form[iFormField]#") />
					<cfelse>
						<cfset WebskinCacheID = listAppend(WebskinCacheID, "form[#iFormField#]:{complex}") />
					</cfif>
				</cfloop>
			</cfif>					
		</cfif>
		
		<cfif arguments.bCacheByRoles>
			<cfif application.security.isLoggedIn()>
				<cfset WebskinCacheID = listAppend(WebskinCacheID,"roles:#listSort(session.security.roles,'text')#") />
			<cfelse>
				<cfset WebskinCacheID = listAppend(WebskinCacheID, "roles:anonymous") />
			</cfif>									
		</cfif>

		<cfif listLen(arguments.lcacheByVars)>
			<cfloop list="#listSort(arguments.lcacheByVars, 'text')#" index="iViewState">
				<cfset varname = trim(listfirst(iViewState,":")) />
				
				<cftry>
					<cfif isvalid("variablename",varname) and isdefined(varname)>
						<cfset WebskinCacheID = listAppend(WebskinCacheID, "#varname#:#evaluate(varname)#") />
					<cfelseif find("(",varname) and isdefined(listfirst(varname,"("))>
						<cfset WebskinCacheID = listAppend(WebskinCacheID, "#varname#:#evaluate(varname)#") />
					<cfelse>
						<!--- If the var is defined with a default (e.g. @@cacheByVars: url.page:1), the default is incorporated into the hash --->
						<!--- If the var does not define a default (e.g. @@cacheByVars: url.error), that valueless string indicates the null --->
						<cfset WebskinCacheID = listAppend(WebskinCacheID, "#iViewState#") />
					</cfif>		
					
					<cfcatch type="any">
						<cfset WebskinCacheID = listAppend(WebskinCacheID, "#varname#:invalidVarName") />
					</cfcatch>
				</cftry>
			</cfloop>								
		</cfif>

		<cfreturn WebskinCacheID />
	</cffunction>	
			
	<cffunction name="addhtmlHeadToWebskins" access="public" output="true" returntype="void" hint="Adds the result of a skin:htmlHead to all relevent webskin caches">
		<cfargument name="id" type="string" required="false" default="#application.fc.utils.createJavaUUID()#" />
		<cfargument name="text" type="string" required="false" default="" />
		<cfargument name="library" type="string" required="false" default="" />
		<cfargument name="libraryState" type="boolean" required="false" default="true" />
		<cfargument name="onReady" type="string" required="false" default="" />
		
		<cfset var iWebskin = "">
		<cfset var iLibrary = "">

		<cfif len(arguments.id) or listlen(arguments.library)>
			<cfif structKeyExists(request, "aAncestorWebskins") AND arrayLen(request.aAncestorWebskins)>
				<cfloop from="1" to="#arrayLen(request.aAncestorWebskins)#" index="iWebskin">
					<cfif listlen(arguments.library)>
						<cfloop list="#arguments.library#" index="iLibrary">
							<cfset request.aAncestorWebskins[iWebskin].inHead[iLibrary] = arguments.libraryState />
						</cfloop>
					<cfelseif len(arguments.onReady)>
						<!--- If we are currently inside of a webskin we need to add this id to the current webskin --->					
						<cfif NOT structKeyExists(request.aAncestorWebskins[iWebskin].inhead.stOnReady, arguments.id)>
							<cfset request.aAncestorWebskins[iWebskin].inHead.stOnReady[arguments.id] = arguments.onReady />
							<cfset arrayAppend(request.aAncestorWebskins[iWebskin].inHead.aOnReadyIDs, arguments.id) />
						</cfif>
					<cfelse>
						<!--- If we are currently inside of a webskin we need to add this id to the current webskin --->					
						<cfif NOT structKeyExists(request.aAncestorWebskins[iWebskin].inhead.stCustom, arguments.id)>
							<cfset request.aAncestorWebskins[iWebskin].inHead.stCustom[arguments.id] = arguments.text />
							<cfset arrayAppend(request.aAncestorWebskins[iWebskin].inHead.aCustomIDs, arguments.id) />
						</cfif>
					</cfif>
				</cfloop>
			</cfif>	
		</cfif>
		
	</cffunction>		
			
	<cffunction name="addCSSHeadToWebskins" access="public" output="true" returntype="void" hint="Adds the result of a skin:loadCSS to all relevent webskin caches">
		<cfargument name="stCSS" type="struct" required="true" />
		
		<cfset var iWebskin = "">

		<cfif structKeyExists(request, "aAncestorWebskins") AND arrayLen(request.aAncestorWebskins)>
			<cfloop from="1" to="#arrayLen(request.aAncestorWebskins)#" index="iWebskin">
				<!--- If we are currently inside of a webskin we need to add this id to the current webskin --->					
				<cfif NOT structKeyExists(request.aAncestorWebskins[iWebskin].inhead.stCSSLibraries, arguments.stCSS.id)>
					
					<!--- Add the id to the array to make sure we keep track of the order in which these libraries need to appear. --->
					<cfset arrayAppend(request.aAncestorWebskins[iWebskin].inHead.aCSSLibraries, arguments.stCSS.id) />
					
					<!--- Add the css information to the struct so we will be able to load it all correctly into the header at the end of the request. --->
					<cfset request.aAncestorWebskins[iWebskin].inHead.stCSSLibraries[stCSS.id] = arguments.stCSS />
					
				</cfif>
			</cfloop>
		</cfif>	
	</cffunction>
	<cffunction name="addJSHeadToWebskins" access="public" output="true" returntype="void" hint="Adds the result of a skin:loadJS to all relevent webskin caches">
		<cfargument name="stJS" type="struct" required="true" />
		
		<cfset var iWebskin = "">

		<cfif structKeyExists(request, "aAncestorWebskins") AND arrayLen(request.aAncestorWebskins)>
			<cfloop from="1" to="#arrayLen(request.aAncestorWebskins)#" index="iWebskin">
				<!--- If we are currently inside of a webskin we need to add this id to the current webskin --->					
				<cfif NOT structKeyExists(request.aAncestorWebskins[iWebskin].inhead.stJSLibraries, arguments.stJS.id)>
					
					<!--- Add the id to the array to make sure we keep track of the order in which these libraries need to appear. --->
					<cfset arrayAppend(request.aAncestorWebskins[iWebskin].inHead.aJSLibraries, arguments.stJS.id) />
					
					<!--- Add the JS information to the struct so we will be able to load it all correctly into the header at the end of the request. --->
					<cfset request.aAncestorWebskins[iWebskin].inHead.stJSLibraries[stJS.id] = arguments.stJS />
					
				</cfif>
			</cfloop>
		</cfif>	
	</cffunction>
	
	<cffunction name="addWebskin" access="public" output="true" returntype="boolean" hint="Adds webskin to object broker if all conditions are met">
		<cfargument name="ObjectID" required="false" type="UUID">
		<cfargument name="typename" required="true" type="string">
		<cfargument name="template" required="true" type="string">
		<cfargument name="webskinCacheID" required="true" type="string">
		<cfargument name="HTML" required="true" type="string">
		<cfargument name="stCurrentView" required="true" type="struct">
		
		<cfset var webskinHTML = "" />
		<cfset var stCacheEntry = structNew() />
		<cfset var bAdded = "false" />
		<cfset var stCacheWebskin = structNew() />
		<cfset var hashString = "" />
		<cfset var webskinTypename = arguments.typename /><!--- Default to the typename passed in --->
		<cfset var stCoapi = structNew() />
		<cfset var iViewState = "" />
		<cfset var bForceFlush = false />
		
		<cfif arguments.typename EQ "farCoapi">
			<!--- This means its a type webskin and we need to look for the timeout value on the related type. --->		
			<cfset stCoapi = application.fc.factory['farCoapi'].getData(typename="farCoapi", objectid="#arguments.objectid#") />
			<cfset webskinTypename = stCoapi.name />
		</cfif>
		
		<cfif application.bObjectBroker>
			
			<cfif isDefined("form") AND not structIsEmpty(form)>
				<cfif application.coapi.coapiadmin.getWebskinCacheFlushOnFormPost(typename=webskinTypename, template=arguments.template)>
					<cfset bForceFlush = true />
				</cfif>
			</cfif>
			
		
			<cfif bForceFlush OR (structKeyExists(request,"mode") AND (request.mode.showdraft EQ 1 OR request.mode.tracewebskins eq 1 OR request.mode.design eq 1 OR request.mode.lvalidstatus NEQ "approved" OR (structKeyExists(url, "updateapp") AND url.updateapp EQ 1)))>
				<!--- DO NOT ADD TO CACHE IF IN DESIGN MODE or SHOWING MORE THAN APPROVED OBJECTS or UPDATING APP --->
			<cfelseif len(arguments.HTML)>
				<cfif structKeyExists(application.stcoapi[webskinTypename].stWebskins, arguments.template) >
					<cfif application.stcoapi[webskinTypename].bObjectBroker AND application.stcoapi[webskinTypename].stWebskins[arguments.template].cacheStatus EQ 1>
						<cfset stCacheEntry = GetObjectCacheEntry(ObjectID=arguments.objectid,typename=arguments.typename)>
						<cfif structKeyExists(stCacheEntry, "stobj")>
							<!--- Cache hit --->
								<cfif not structKeyExists(stCacheEntry, "stWebskins")>
									<cfset stCacheEntry.stWebskins = structNew() />
								</cfif>			
								
								<!--- Add the current State of the request.inHead scope into the broker --->
								<cfparam name="request.inHead" default="#structNew()#">
								
								<cfset stCacheWebskin.datetimecreated = now() />
								<cfset stCacheWebskin.webskinHTML = trim(arguments.HTML) />	
								<cfset stCacheWebskin.inHead = duplicate(arguments.stCurrentView.inHead) />
								<cfset stCacheWebskin.cacheStatus = arguments.stCurrentView.cacheStatus />
								<cfset stCacheWebskin.cacheTimeout = arguments.stCurrentView.cacheTimeout />
								<cfset stCacheWebskin.browserCacheTimeout = arguments.stCurrentView.browserCacheTimeout />
								<cfset stCacheWebskin.proxyCacheTimeout = arguments.stCurrentView.proxyCacheTimeout />
	
								<cfset stCacheWebskin.webskinCacheID = generateWebskinCacheID(
																		typename="#webskinTypename#", 
																		template="#arguments.template#",
																		hashKey="#arguments.stCurrentView.hashKey#"
															) />
								
																
								<cfset stCacheEntry.stWebskins[arguments.template][hash("#stCacheWebskin.webskinCacheID#")] = stCacheWebskin />

																
								<cfset bAdded = true />
						</cfif>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
		
		<cfreturn bAdded />
		
	</cffunction>
	
	<cffunction name="removeWebskin" access="public" output="false" returntype="boolean" hint="Searches the object broker in an attempt to locate the requested webskin template">
		<cfargument name="ObjectID" required="false" type="UUID">
		<cfargument name="typename" required="true" type="string">
		<cfargument name="template" required="true" type="string">
		
		<cfset var bSuccess = "true" />
		<cfset var stCacheEntry = structNew() />
		
		
		<cfif application.bObjectBroker>
		
			<cfif len(arguments.typename) AND structKeyExists(application.objectbroker, arguments.typename)>
				<cfif structKeyExists(application.objectbroker[arguments.typename], arguments.objectid)>
					<cfset stCacheEntry = GetObjectCacheEntry(ObjectID=arguments.objectid,typename=arguments.typename)>
					<cfif structKeyExists(stCacheEntry, "stWebskins")>
						<cflock name="objectBroker-#application.applicationname#-#arguments.typename#" type="exclusive" timeout="2" throwontimeout="true">
							<cfset structDelete(stCacheEntry.stWebskins, arguments.template) />
						</cflock>
					</cfif>
				</cfif>
			</cfif>
		</cfif>
	
		
		<cfreturn bSuccess />
		
	</cffunction>
	
	<cffunction name="putObjectCacheEntry" access="public" output="true" returntype="boolean">
		<cfargument name="stCacheEntry" required="true" type="struct">
		<cfargument name="objectid" required="true" type="UUID">
		<cfargument name="typename" required="true" type="string">
				
		<cfif structkeyexists(application.objectbroker, arguments.typename)>	
			<!--- Create a soft reference to the cache entry and put it in the object broker --->
			<cftry>
				<cfset application.objectbroker[arguments.typename][arguments.objectid] =
						createObject("java", "java.lang.ref.SoftReference").init(arguments.stCacheEntry, application.objectrecycler) />
				<cfreturn true />
				<!--- An expression error likely a race condition (ie. not structkeyexists(application.objectbroker, arguments.typename)) --->
				<cfcatch type="expression" />
			</cftry>
		</cfif>
		<cfreturn false />
	</cffunction>
	
	
	<cffunction name="AddToObjectBroker" access="public" output="true" returntype="boolean">
		<cfargument name="stObj" required="yes" type="struct">
		<cfargument name="typename" required="true" type="string">
		
		<cfset var bSuccess = false />
		<cfset var stCacheEntry = structNew() />
		<cfset var aObjectIds = arrayNew(1) />
		<cfset var oCaster	= '' />
		
		<cfif application.bObjectBroker>
			<!--- if the type is to be stored in the objectBroker --->
			<cfif structkeyexists(arguments.stObj, "objectid") AND structkeyexists(application.objectbroker, arguments.typename)>
				<!--- Prepare a cache entry --->
				<cfset stCacheEntry.stObj = duplicate(arguments.stObj) /> 
				<cfset stCacheEntry.stWebskins = structNew() />
				
				<cflock name="objectBroker-#application.applicationname#-#arguments.typename#" type="exclusive" timeout="2" throwontimeout="true">
					<cfif putObjectCacheEntry(stCacheEntry=stCacheEntry, objectid=arguments.stObj.objectid, typename=arguments.typename)>
						
						<!--- Remove it first in case we are here because of a missing soft reference object --->
						<cfset aObjectIds = ListToArray(arguments.stObj.ObjectID)>				
						
						<cfswitch expression="#server.coldfusion.productname#">
							<cfcase value="Railo">
								<cfset oCaster = createObject('java','railo.runtime.op.Caster') />
								<cfset application.objectBroker[arguments.typename].aObjects.removeAll(oCaster.toList(aObjectIds)) />
							</cfcase>
							<cfdefaultcase>
								<cfset application.objectBroker[arguments.typename].aObjects.removeAll(aObjectIds) >
							</cfdefaultcase>
						</cfswitch>		
						
						<!--- Add the objectid to the end of the FIFO array so we know its the latest to be added --->						
						<cfset arrayappend(application.objectbroker[arguments.typename].aObjects,arguments.stObj.ObjectID)>
						<cfset bSuccess = true />
					</cfif>
				</cflock>
				
				<cfif bSuccess>
					<cfset trackObjectEvent(eventname="add",typename=arguments.typename,objectid=arguments.stObj.objectid) />
					<!--- Cleanup the object broker just in case we have reached our limit of objects as defined by the metadata. --->
					<cfset cleanupObjectBroker(typename=arguments.typename)>
				</cfif>
			</cfif>
		</cfif>
		<cfreturn bSuccess />
	</cffunction>
	
	<cffunction name="reapDeadEntriesFromBroker" access="public" output="false" returntype="void" hint="Cleans out soft references to recycled objects in the object broker.">
		
		<cfset var objRef = StructNew() />
		<cfset var stCacheEntry = StructNew() />
		
		<cfif application.bObjectBroker>
			<!--- Poll the object recycler for a soft reference to an object recycled by the garbage collector --->
			<cfset objRef = application.objectrecycler.poll() />
			
			<cfloop condition="#isDefined("objRef")#">
				<!--- We got a soft reference: try to grab the contained object --->
				<cfset stCacheEntry = objRef.get() />
				<!--- Is the inner object still available with objectid and typename values? --->
				<cfif IsDefined("stCacheEntry") and StructKeyExists(stCacheEntry,"stobj")
						and StructKeyExists(stCacheEntry.stobj,"objectid") and StructKeyExists(stCacheEntry.stObj,"typename")>
					<!--- Delete any references to the object in the broker --->
					<cfset RemoveFromObjectBroker(lObjectIDs=stObj.objectID, typename=stObj.typename, eventName="reap") />
				</cfif>
				
				<!--- Poll the object recycler for another soft reference --->
				<cfset objRef = application.objectrecycler.poll() />
			</cfloop>
		</cfif>
	</cffunction>
	
	<cffunction name="CleanupObjectBroker" access="public" output="false" returntype="void" hint="Removes 10% of the items in the object broker if it is full.">
		<cfargument name="typename" required="yes" type="string">
		
		<cfset var numberToRemove = 0 />
		<cfset var lRemoveObjectIDs = "" />
		<cfset var i = "" />
		<cfset var objectToDelete = "" />
		
		<cfif application.bObjectBroker>
			<!--- Reap any recycled entries first. If we're lucky we might not need to evict any objects still present in the cache. --->
			<cfset reapDeadEntriesFromBroker() />
			
			<cfif arraylen(application.objectbroker[arguments.typename].aObjects) GT application.objectbroker[arguments.typename].maxObjects>
				
				<cfset numberToRemove =  Round(application.objectbroker[arguments.typename].maxObjects / 10) />
				<cfif numberToRemove GT 0>
					<cfloop from="1" to="#numberToRemove#" index="i">		
						<cfset lRemoveObjectIDs = listAppend(lRemoveObjectIDs, application.objectbroker[arguments.typename].aObjects[i]) />			
					</cfloop>
					
					<cfset removeFromObjectBroker(lObjectIDs=lRemoveObjectIDs, typename=arguments.typename, eventName="evict") />
				</cfif>
				
				
				<!--- <cftrace type="information" category="coapi" text="ObjectBroker Removed #numberToRemove# objects from FIFO #arguments.typename# stack."> --->
			</cfif>
		</cfif>
	</cffunction>
	
	<cffunction name="RemoveFromObjectBroker" access="public" output="true" returntype="void">
		<cfargument name="lObjectIDs" required="true" type="string">
		<cfargument name="typename" required="true" type="string">
		<cfargument name="eventName" required="false" type="string" default="flush" hint="Name of event that triggered the removal {flush,reap,evict}">
			
		<cfset var aObjectIds = arrayNew(1) />
		<cfset var oWebskinAncestor = application.fapi.getContentType("dmWebskinAncestor") />						
		<cfset var qWebskinAncestors = queryNew("blah") />
		<cfset var i = "" />
		<cfset var bSuccess = "" />
		<cfset var stResult = structNew() />
		<cfset var pos = "" />
		<cfset var arrayList = "" />
		<cfset var deleted = "" />
		<cfset var oCaster = "" />

		<cfif application.bObjectBroker and len(arguments.typename)>
			
			<!--- Remove any ancestor webskins that include a fragment of this object --->
			<cfloop list="#arguments.lObjectIDs#" index="i">				
			
				<!--- Find any ancestor webskins and delete them as well --->
				<cfset qWebskinAncestors = oWebskinAncestor.getAncestorWebskins(webskinObjectID=i, webskinTypename=arguments.typename) />
				
				<cfif qWebskinAncestors.recordCount>
					<cfloop query="qWebskinAncestors">
						<cfset bSuccess = removeWebskin(objectid=qWebskinAncestors.ancestorID,typename=qWebskinAncestors.ancestorRefTypename,template=qWebskinAncestors.ancestorTemplate) />
					</cfloop>
				</cfif>
				
			</cfloop>
			
			<cfif structkeyexists(application.objectbroker, arguments.typename)>	
				<!--- Remove all references to these objects --->
				<cflock name="objectBroker-#application.applicationname#-#arguments.typename#" type="exclusive" timeout="2" throwontimeout="true">
					
					<cfloop list="#arguments.lObjectIDs#" index="i">
						<cfset StructDelete(application.objectbroker[arguments.typename], i)>
					</cfloop>
					
					<cfset aObjectIds = ListToArray(arguments.lObjectIDs)>				
					
					<cfswitch expression="#server.coldfusion.productname#">
						<cfcase value="Railo">
							<cfset oCaster = createObject('java','railo.runtime.op.Caster') />
							<cfset application.objectBroker[arguments.typename].aObjects.removeAll(oCaster.toList(aObjectIds)) />
						</cfcase>
						<cfdefaultcase>
							<cfset application.objectBroker[arguments.typename].aObjects.removeAll(aObjectIds) >
						</cfdefaultcase>
					</cfswitch>					
				</cflock>
				
				<!--- Track the trigger event for each object ID passed in --->
				<cfloop list="#arguments.lObjectIDs#" index="i">
					<cfset trackObjectEvent(eventname=arguments.eventName,typename=arguments.typename,objectid=i) />	
				</cfloop>
			</cfif>
		</cfif>
	</cffunction>
	
	<cffunction name="flushTypeWatchWebskins" access="public" output="false" returntype="boolean" hint="Finds all webskins watching this type for any CRUD functions and flushes them from the cache">
	 	<cfargument name="objectID" required="false" hint="The typename that the CRUD function was performed on." />
	 	<cfargument name="typename" required="false" hint="" />
	 	<cfargument name="stObject" required="false" hint="Alternative to objectID+typename">
		
		<cfset var stTypeWatchWebskins = "" />
		<cfset var iType = "" />
		<cfset var iWebskin = "" />
		<cfset var oCoapi = application.fapi.getContentType("farCoapi") />
		<cfset var coapiObjectID = "" />
		<cfset var qCachedAncestors = "" />
		<cfset var bSuccess = "" />
		<cfset var qWebskinAncestors = "" />
		
		<cfif structkeyexists(arguments,"stObject")>
			<cfset arguments.typename = arguments.stObject.typename />
			<cfset arguments.objectid = arguments.stObject.objectid />
		<cfelse>
			<cfset arguments.stObject = application.fapi.getContentObject(objectid=arguments.objectid,typename=arguments.typename)>
		</cfif>
		
		<cfset stTypeWatchWebskins = application.stCoapi[arguments.typename].stTypeWatchWebskins />
		
		<cfif not structKeyExists(arguments.stObject, "status") OR arguments.stObject.status EQ "approved">
			<cfif not structIsEmpty(stTypeWatchWebskins)>
				<cfloop collection="#stTypeWatchWebskins#" item="iType">
					
					<cfset coapiObjectID = oCoapi.getCoapiObjectID(iType) />
						

					<cfif not structKeyExists(application.fc.webskinAncestors, iType)>
						<cfset application.fc.webskinAncestors[iType] = queryNew( 'webskinObjectID,webskinTypename,webskinRefTypename,webskinTemplate,ancestorID,ancestorTypename,ancestorTemplate,ancestorRefTypename', 'VarChar,VarChar,VarChar,VarChar,VarChar,VarChar,VarChar,VarChar' ) />
					</cfif>
					<cfset qWebskinAncestors = application.fc.webskinAncestors[iType] />
										
					<cfloop from="1" to="#arrayLen(stTypeWatchWebskins[iType])#" index="iWebskin">
					
						
						<cfquery dbtype="query" name="qCachedAncestors">
							SELECT * 
							FROM qWebskinAncestors
							WHERE (
									webskinTypename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#iType#" />
									OR webskinObjectID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#coapiObjectID#" />
							)
							AND webskinTemplate = <cfqueryparam cfsqltype="cf_sql_varchar" value="#stTypeWatchWebskins[iType][iWebskin]#" />
						</cfquery>
						
						<cfloop query="qCachedAncestors">
							<cfset bSuccess = removeWebskin(	objectID=qCachedAncestors.ancestorID,
																typename=qCachedAncestors.ancestorTypename,
																template=qCachedAncestors.ancestorTemplate ) />
							
							<cfset bSuccess = removeWebskin(	objectID=qCachedAncestors.webskinObjectID,
																typename=qCachedAncestors.webskinRefTypename,
																template=qCachedAncestors.webskinTemplate ) />
							
						</cfloop>
						
					</cfloop>
					
				</cfloop>
			</cfif>
		</cfif>
		<cfreturn true />
	 </cffunction>
	 
</cfcomponent>