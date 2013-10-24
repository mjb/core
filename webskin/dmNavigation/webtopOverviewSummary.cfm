<!--- @@Copyright: Daemon Pty Limited 2002-2009, http://www.daemon.com.au --->
<!--- @@License:
    This file is part of FarCry.

    FarCry is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    FarCry is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with FarCry.  If not, see <http://www.gnu.org/licenses/>.
--->
<!--- @@displayname: Webtop Overview --->
<!--- @@description: The dmNavigation specific webskin to use to render the object's summary in the webtop overview screen  --->

<!--- import tag libraries --->
<cfimport taglib="/farcry/core/tags/navajo" prefix="nj" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/security" prefix="sec" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />
<cfimport taglib="/farcry/core/tags/grid" prefix="grid" />
<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />


<ft:processForm action="Manage">
	
	<!--- get parent to update tree --->
	<nj:treeGetRelations typename="#stObj.typename#" objectId="#stObj.ObjectID#" get="parents" r_lObjectIds="ParentID" bInclusive="1">
	
	<!--- update tree --->
	<nj:updateTree objectId="#parentID#">
		
	<cfif structKeyExists(form, "selectedObjectID")>
		<skin:location url="#application.url.webtop#/edittabOverview.cfm?objectid=#form.selectedObjectID#" />
	</cfif>
</ft:processForm>




<cfoutput>
	<div class="developer-actions">
		<div class="objectid" style="display:none;">#stObj.objectid#</div>
		<a onclick="var oid = $j(this).siblings('.objectid').toggle();selectText(oid[0]);return false;" title="See objectid"><i class="icon-tag"></i></a>
		<a onclick="$fc.openDialog('Property Dump', '#application.url.farcry#/object_dump.cfm?objectid=#stobj.objectid#&typename=#stobj.typename#');return false;" title="Open a window containing all the raw data of this content item"><i class="icon-list-alt"></i></a>
	</div>
</cfoutput>

	
	<ft:fieldset legend="Navigation Details">
		
		<!--- Using getNavID() just in case developer has added versions to dmNavigation --->
		<cfset qDescendents = createObject("component", "#application.packagepath#.farcry.tree").getDescendants(objectid=getNavID(stobj.objectid), depth=1, bIncludeSelf=0) />
		<ft:field label="Breadcrumb" bMultiField="true">
		
			<nj:getNavigation objectId="#stobj.objectid#" r_objectID="parentID" bInclusive="1">
			
			<cfif len(parentID)>
				<cfif stobj.typename EQ "dmNavigation">
					<cfset qAncestors = application.factory.oTree.getAncestors(objectid=parentID,bIncludeSelf=false) />
				<cfelse>
					<cfset qAncestors = application.factory.oTree.getAncestors(objectid=parentID,bIncludeSelf=true) />
				</cfif>
				
				<cfif qAncestors.recordCount>
					<cfloop query="qAncestors">
						<skin:buildLink href="#application.url.webtop#/edittabOverview.cfm" urlParameters="typename=dmNavigation&objectID=#qAncestors.objectid#" linktext="#qAncestors.objectName#" />
						<cfoutput>&nbsp;&raquo;&nbsp;</cfoutput>
					</cfloop>
					<cfoutput>#stobj.label#</cfoutput>
				<cfelse>
					<cfoutput>#stobj.label#</cfoutput>
				</cfif>
			</cfif>
			
			
			<ft:fieldHint>
				<cfoutput>
				This shows you the selected navigation item in the context of your site. 
				You can <ft:button value="create a child" renderType="link" url="#application.url.farcry#/conjuror/evocation.cfm?parenttype=dmNavigation&objectId=#stobj.objectid#&typename=dmNavigation&ref=#url.ref#" /> navigation item under this.
				</cfoutput>
			</ft:fieldHint>
		</ft:field>
		
		
		
		<cfif stObj.navType eq "externalLink" or (len(stObj.navType) eq "" and len(stObj.externalLink))>
			<ft:field label="Content Mirror" bMultiField="true" hint="When a visitor to your site browses to this navigation item, they will be shown the content above instead of the children of this item.">
				<cfoutput>
					<table class="objectAdmin" style="width:100%;">	
						<cfset contentTypename = application.fapi.findType(objectid="#stobj.externalLink#") />
						
						<tr>
							<td>
								<cfif structKeyExists(application.stCOAPI,contentTypename)>
									<cfif len(application.stCOAPI[contentTypename].icon)>
										<i class="icon-#application.stCOAPI[contentTypename].icon#"></i>
									<cfelse>
										<i class="icon-file"></i>
									</cfif>
									<skin:view typename="#contentTypename#" objectid="#stobj.externalLink#" webskin="displayLabel" />
								</cfif>
							</td>	
							<td style="width:50px;"><ft:button value="Manage" renderType="link" selectedObjectID="#stobj.externalLink#" /></td>	
						</tr>	
					</table>
				</cfoutput>
			</ft:field>
		<cfelseif stObj.navType eq "aObjectIDs" or (len(stObj.navType) eq "" and len(stObj.aObjectIDs))>
			<cfif arrayLen(stobj.aObjectIDs)>
				<cfsavecontent variable="contentHint">
					<cfoutput>When a visitor to your site browses to this navigation item, they will be displayed the content above. Unless instructed otherwise, you should only require a single content item here.</cfoutput>
				</cfsavecontent>
			<cfelse>
				<cfsavecontent variable="contentHint">
					<cfoutput>Select the type of content that a visitor to your site will see when they browse to this navigation item.</cfoutput>
				</cfsavecontent>
			</cfif>
			<ft:field label="Content" bMultiField="true" hint="#contentHint#">
				<cfoutput>
					
					<cfif arrayLen(stobj.aObjectIDs)>
						<table class="objectAdmin" style="width:100%;">	
						<cfloop from="1" to="#arrayLen(stobj.aObjectIDs)#" index="i">
							<cfset contentTypename = application.fapi.findType(objectid="#stobj.aObjectIDs[i]#") />
							
							<tr>
								<td>
									<cfif len(application.stCOAPI[contentTypename].icon)>
										<i class="icon-#application.stCOAPI[contentTypename].icon#"></i>
									<cfelse>
										<i class="icon-file"></i>
									</cfif>
									<skin:view typename="#contentTypename#" objectid="#stobj.aObjectIDs[i]#" webskin="displayLabel" />
								</td>	
								<td style="width:50px;"><ft:button value="Manage" renderType="link" selectedObjectID="#stobj.aObjectIDs[i]#" /></td>	
							</tr>
								
						</cfloop>	
						</table>
						
					</cfif>
		
					<nj:getNavigation objectId="#stobj.objectid#" r_objectID="parentID" bInclusive="1">
					
					<cfif application.fapi.checkObjectPermission(objectID=parentID, permission="Create")>
						<cfset objType = application.fapi.getContentType(stobj.typename) />
						<cfset lPreferredTypeSeq = "dmNavigation,dmHTML"> <!--- this list will determine preffered order of objects in create menu - maybe this should be configurable. --->
						<!--- <cfset aTypesUseInTree = objType.buildTreeCreateTypes(lPreferredTypeSeq)> --->
						<cfset lAllTypes = structKeyList(application.types)>
						<!--- remove preffered types from *all* list --->
						<cfset aPreferredTypeSeq = listToArray(lPreferredTypeSeq)>
						<cfloop index="i" from="1" to="#arrayLen(aPreferredTypeSeq)#">
							<cfset lAlltypes = listDeleteAt(lAllTypes,listFindNoCase(lAllTypes,aPreferredTypeSeq[i]))>
						</cfloop>
						<cfset lAlltypes = ListAppend(lPreferredTypeSeq,lAlltypes)>
						<cfset aTypesUseInTree = objType.buildTreeCreateTypes(lAllTypes)>
						<cfif ArrayLen(aTypesUseInTree)>
					
							<!--- <skin:loadJS id="fc-jquery" />
							<skin:loadJS id="msdropdown" baseHREF="#application.url.webtop#/thirdparty" lFiles="/msdropdown/js/uncompressed.jquery.dd.js" />
								<skin:loadCSS id="msdropdown" baseHREF="#application.url.webtop#/thirdparty" lFiles="/msdropdown/dd.css" />
							
							<skin:onReady>
								<cfoutput>
									$j("##createContent").msDropDown();
								</cfoutput>
							</skin:onReady> --->
							
									<select id="createContent" name="createContent" style="width:100%;" onChange="location = '#application.url.farcry#/conjuror/evocation.cfm?parenttype=dmNavigation&objectId=#stobj.objectid#&typename=' + $j('##createContent').val() + '&ref=#url.ref#';">
										<cfif arrayLen(stobj.aObjectIDs)>
											<option value="">-- Attach More Content --</option>
										<cfelse>
											<option value="">-- Attach Content --</option>
										</cfif>
										<optgroup label="-------------------Content Item---------------------"></optgroup>
										
										<cfset lTreeTypes = "">
										<cfloop collection="#application.stcoapi#" item="iType">
											<cfif application.fapi.getContentTypeMetadata(typename="#iType#", md="bUseInTree", default="false")>
												<cfset lTreeTypes = listAppend(lTreeTypes, iType) />
											</cfif>
										</cfloop>
										
										<cfloop list="#lTreeTypes#" index="iType">
											<cfif iType NEQ "dmNavigation" AND  iType NEQ "dmInclude">
												<option value="#iType#">#application.fapi.getContentTypeMetadata(typename="#iType#", md="displayName", default="#iType#")#</option>
											</cfif>
										</cfloop>
										
										<optgroup label="-------------------Type Views---------------------"></optgroup>
										
										<cfloop collection="#application.stcoapi#" item="iType">
											<cfset qWebskins = application.coapi.coapiAdmin.getWebskins(typename="#iType#", viewBinding="type", viewStack="body") />
											
											<cfloop query="qWebskins">
												<cfif len(qWebskins.displayname)>
													<cfset optionLabel = qWebskins.displayname>
												<cfelse>
													<cfset optionLabel = "#application.fapi.getContentTypeMetadata(typename='#iType#', md='displayName', default='#iType#')#:#qWebskins.methodname#">
												</cfif>
												<option value="#qWebskins.typename#:#qWebskins.methodname#">#optionLabel#</option>
											</cfloop>
										</cfloop>
										
									</select>
							
						</cfif>
					</cfif>
					
				</cfoutput>	
			</ft:field>
		<cfelseif stObj.navType eq "internalRedirectID">
			
			<ft:field label="Internal Redirect" bMultiField="true" hint="This navigation item redirects to another page in the website.">
				<cfoutput>
					<table class="objectAdmin" style="width:100%;">	
						<cfset contentTypename = application.fapi.findType(objectid="#stobj.internalRedirectID#") />
						
						<tr>
							<td>
								<cfif structKeyExists(application.stCOAPI,contentTypename)>
									<cfif len(application.stCOAPI[contentTypename].icon)>
										<i class="icon-#application.stCOAPI[contentTypename].icon#"></i>
									<cfelse>
										<i class="icon-file"></i>
									</cfif>
									<skin:view typename="#contentTypename#" objectid="#stobj.internalRedirectID#" webskin="displayLabel" />
								</cfif>
							</td>	
							<td style="width:50px;"><ft:button value="Manage" renderType="link" selectedObjectID="#stobj.internalRedirectID#" /></td>	
						</tr>	
					</table>
				</cfoutput>
			</ft:field>

		<cfelseif stObj.navType eq "externalRedirectURL">
			
			<ft:field label="External Redirect" bMultiField="true" hint="This navigation item redirects to a page on another website.">
				<cfoutput><a href="#stObj.externalRedirectURL#" target="_blank">#stObj.externalRedirectURL#</a></cfoutput>
			</ft:field>

		</cfif>
		
		
		<ft:field label="Alias" hint="The alias is used by the programmers to refer to this navigation item in their code.">
			<cfif len(stobj.lNavIDAlias)>
				<cfoutput>#stobj.lNavIDAlias#</cfoutput>
			<cfelse>
				<cfoutput>-- No Alias Provided --</cfoutput>
			</cfif>
		</ft:field>
		
		
	</ft:fieldset>

	

