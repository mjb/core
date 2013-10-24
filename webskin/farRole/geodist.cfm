
<cfimport taglib="/farcry/core/tags/formtools/" prefix="ft" />
<cfimport taglib="/farcry/core/tags/grid/" prefix="grid" />
<cfimport taglib="/farcry/core/tags/webskin/" prefix="skin" />
<cfimport taglib="/farcry/core/tags/admin/" prefix="admin" />



<cfset setLock(stObj=stObj,locked=true) />



<!--- 
ENVIRONMENT VARIABLES
 --->
<cfquery datasource="#application.dsn#" name="qGenericPermissions">
select objectid from farPermission
where title like '%Generic%'
order by shortcut
</cfquery>
<cfset permissions = valueList(qGenericPermissions.objectid) />





<cfif isWDDX(stobj.typePermissions)>
	<cfwddx action="wddx2cfml" input="#stobj.typePermissions#" output="stTypePermissions" />
<cfelse>
	<cfparam name="stTypePermissions" default="#structNew()#" />
	
	<cfloop list="#permissions#" index="iPermission">
		<cfparam name="stTypePermissions['#iPermission#']" default="#structNew()#" />
	</cfloop>


	<cfquery datasource="#application.dsn#" name="qBarnacles">
	SELECT *
	FROM farBarnacle
	WHERE objecttype = <cfqueryparam cfsqltype="cf_sql_varchar" value="package">
	AND roleid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#stobj.objectid#">
	AND permissionID IN (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#permissions#">)
	</cfquery>
	
	<cfloop query="qBarnacles">
		<cfset stTypePermissions['#qBarnacles.permissionID#']['#qBarnacles.referenceID#'] = qBarnacles.barnaclevalue >
	</cfloop>
</cfif>



<!--- 


<ft:processForm action="Save,Change Permission">


	<cfloop collection="#form#" item="iField">
		<cfif left(iField,14) EQ "barnacleValue-">
			<cfset session.fc.stRolePermissions['#stobj.objectid#']['#form.permissionID#'][ mid(iField,15, len(iField)-14) ] = form[iField] />
		</cfif>
	</cfloop>
</ft:processForm>

<ft:processForm action="Change Permission">
	<skin:location type='farRole' objectid='#stobj.objectid#' view='editSitePermissions' urlParameters='permission=#form.selectPermission#' />
</ft:processForm>
 --->



<!--- 
<cfparam name="session.fc.stRolePermissions['#stobj.objectid#']['#form.objecttype#']['#form.permissionID#']" default="#structNew()#">
 --->
<ft:processForm action="Save">
	
	<cfwddx action="cfml2wddx" input="#stTypePermissions#" output="wddxTypePermissions" />
	<cfset application.fapi.setData(typename="farRole",
									objectid="#stobj.objectid#",
									typePermissions="#stTypePermissions#")>
	
	
	<cfset oBarnacle = application.fapi.getContentType("farBarnacle") />
	
	
	<cfloop list="#structKeyList(stTypePermissions)#" index="iPermission">
		<cfquery datasource="#application.dsn#" name="qPermissionBarnacles">
		SELECT *
		FROM farBarnacle
		WHERE objecttype = <cfqueryparam cfsqltype="cf_sql_varchar" value="package">
		AND farBarnacle.roleid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#stobj.objectid#">
		AND farBarnacle.permissionid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#iPermission#">
		</cfquery>
		
		<cfloop collection="#stTypePermissions['#iPermission#']#" item="iReferenceID">
			<cfquery dbtype="query" name="qBarnacleExists">
			SELECT *
			FROM qPermissionBarnacles
			WHERE referenceID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#iReferenceID#">
			</cfquery>
			
			<cfset newBarnacleValue = stTypePermissions[iPermission][iReferenceID] />
			
			<cfif qBarnacleExists.recordCount>
				<cfif newBarnacleValue EQ 0>
					<cfset oBarnacle.delete(qBarnacleExists.objectid)>
				<cfelse>
					<cfif qBarnacleExists.barnaclevalue NEQ newBarnacleValue>
						<cfset application.fapi.setData(typename="farBarnacle", objectID="#qBarnacleExists.objectid#", referenceID="#iReferenceID#", objecttype="#qBarnacleExists.objecttype#", barnaclevalue="#newBarnacleValue#") />
					</cfif>
				</cfif>
				
			<cfelse>
				<cfif newBarnacleValue NEQ 0>
					<cfset stResult = application.fapi.setData(
						typename="farBarnacle", 
						objectID="#application.fapi.getUUID()#", 
						roleid="#stobj.objectid#",
						permissionID="#iPermission#",
						referenceid="#iReferenceID#",
						objecttype="package",
						barnaclevalue="#newBarnacleValue#"
						) />
				</cfif>
			</cfif>
		</cfloop>
	</cfloop>
	
	
	<!--- SAVE BARNACLES --->
</ft:processForm>

<ft:processForm action="Save,Cancel" Exit="true" url="/webtop/edittabOverview.cfm?typename=farRole&method=edit&ref=iframe&module=customlists/farRole.cfm&objectid=#stobj.objectid#">
	<cfset setLock(objectid=stObj.objectid,locked=false) />
</ft:processForm>





<cfif isWDDX(stobj.typePermissions)>
	<cfwddx action="wddx2cfml" input="#stobj.typePermissions#" output="stTypePermissions" />
<cfelse>
	<cfparam name="stTypePermissions" default="#structNew()#" />
	
	<cfloop list="#permissions#" index="iPermission">
		<cfparam name="stTypePermissions['#iPermission#']" default="#structNew()#" />
	</cfloop>


	<cfquery datasource="#application.dsn#" name="qBarnacles">
	SELECT *
	FROM farBarnacle
	WHERE objecttype = <cfqueryparam cfsqltype="cf_sql_varchar" value="package">
	AND roleid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#stobj.objectid#">
	AND permissionID IN (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#permissions#">)
	</cfquery>
	
	<cfloop query="qBarnacles">
		<cfset stTypePermissions['#qBarnacles.permissionID#']['#qBarnacles.referenceID#'] = qBarnacles.barnaclevalue >
	</cfloop>
</cfif>



<skin:loadJS id="jquery" />
<skin:loadJS id="jquery-ui" />
<skin:loadCSS id="jquery-ui" />




<skin:htmlHead>
<cfoutput>
<style type="text/css">
.inherit {opacity:0.4;}

.ui-button.small.barnacleBox {
	width: 50px;
	height: 16px;
	float:right;
	margin:0px 0px 0px 5px;
}

.ui-button.small.barnacleBox .ui-icon {
	margin-top: -8px;
	margin-left: -8px;
}

##permissionTree li {
	font-size:10px;
}

.barnacleBox.ui-button {
	padding:0px 0px 5px 0px;	
	width: 50px;
	height: 16px;
	float:right;
}
</style>
</cfoutput>
</skin:htmlHead>


<cfset stTree = structNew() />

<cfloop collection="#application.stCoapi#" item="iType">
	<cfset stPointer = stTree>

	<cfloop from="#arrayLen(application.stCoapi[iType].aExtends)#" to="1" step="-1" index="i">
		<cfif not structKeyExists(stPointer, application.stCoapi[iType].aExtends[i])>
			<cfset stPointer[application.stCoapi[iType].aExtends[i]] = structNew() />
		</cfif>
		
		<cfset stPointer = stPointer[application.stCoapi[iType].aExtends[i]] />
	</cfloop>
	
	<cfif not structKeyExists(stPointer, iType)>
		<cfset stPointer[iType] = structNew() />
	</cfif>
	
	<cfset stPointer[iType].displayName = application.stCoapi[iType].displayName />
	<cfset stPointer[iType].packagePath = application.stCoapi[iType].packagePath />
</cfloop>

<cffunction name="renderNode" output="true">
	<cfargument name="stNode" />
	<cfargument name="treeID" default="" />
	<cfargument name="roleID" default="" />
	

	
	<cfset priority = "secondary">
	<cfset icon = "ui-icon-close">
	<cfset class="inherit" />
	<cfif len(treeID)>
		<cfset priority = "ui-priority-secondary">
		<cfset icon = "ui-icon-check">
		<cfset inherit="" />
		<cfset currentBarnacleValue = -1>
		<cfset currentInheritBarnacleValue = -1>
	<cfelse>
		<cfset priority = "ui-priority-secondary">
		<cfset icon = "ui-icon-check">
		<cfset inherit="inherit" />
		<cfset currentBarnacleValue = 0>
		<cfset currentInheritBarnacleValue = "">
	</cfif>	
	
	<cfif not structIsEmpty(stNode)>
		<cfoutput><ul <cfif len(arguments.treeID)>id="#arguments.treeID#"</cfif> ></cfoutput>
		
		<cfloop list="#ListSort( structKeyList(stNode) , 'textnocase')#" index="i">
			<cfif structKeyExists(stNode[i], "displayName")>
				
				<cfset barnacleID = hash(stNode[i].packagePath) />
				
				<cfoutput>
				<li title="#stNode[i].packagePath#">
					
					<cfloop list="#permissions#" index="iPermission">
						
						<cfif i EQ "fourq">
							<cfif structKeyExists(stTypePermissions['#iPermission#'], barnacleID)>
								<cfset currentBarnacleValue = stTypePermissions['#iPermission#'][barnacleID]>
							<cfelse>
								<cfset currentBarnacleValue = -1 />
							</cfif>
						<cfelse>
							<cfif structKeyExists(stTypePermissions['#iPermission#'], barnacleID)>
								<cfset currentBarnacleValue = stTypePermissions['#iPermission#'][barnacleID]>
							<cfelse>
								<cfset currentBarnacleValue = 0 />
							</cfif>
						</cfif>
						
						<cfset priority = "ui-priority-secondary">
						<cfset icon = "ui-icon-close">
						<cfset inherit="inherit" />
						<cfif currentBarnacleValue EQ 1>
							<cfset priority = "ui-priority-primary">
							<cfset inherit="" />
						<cfelseif currentBarnacleValue EQ -1>
							<cfset priority = "ui-priority-secondary">
							<cfset inherit="" />
						</cfif>
						
						<button id="#hash(stNode[i].packagePath)##iPermission#" class="permButton barnacleBox #priority# #inherit# #iPermission#" value="#currentBarnacleValue#" type="button" ftobjecttype="package" ftreferenceid="#barnacleID#" ftpermissionid="#iPermission#" ftbarnaclevalue="#numberformat(currentBarnacleValue)#" ftinheritbarnaclevalue="#currentInheritBarnacleValue#"></button>
						
						<!--- <input type="hidden" class="barnacleValue #iPermission#" id="barnacleValue-#barnacleID#" name="barnacleValue-#barnacleID#-#iPermission#" value="#currentBarnacleValue#" style="width:10px;">
						<input type="hidden" class="inheritBarnacleValue #iPermission#" id="inheritBarnacleValue-#barnacleID#" value="#currentInheritBarnacleValue#" style="width:10px;"> --->
					</cfloop>
					
						&nbsp;
						#i# (#stNode[i].displayName#)
					
				</li>
				</cfoutput>
			<cfelse>
				
				<cfset barnacleID = hash(i) />
				
				<cfoutput>
				<li>
					
					<cfloop list="#permissions#" index="iPermission">
						

						<cfif i EQ "fourq">
							<cfif structKeyExists(stTypePermissions['#iPermission#'], barnacleID)>
								<cfset currentBarnacleValue = stTypePermissions['#iPermission#'][barnacleID]>
							<cfelse>
								<cfset currentBarnacleValue = -1 />
							</cfif>
						<cfelse>
							<cfif structKeyExists(stTypePermissions['#iPermission#'], barnacleID)>
								<cfset currentBarnacleValue = stTypePermissions['#iPermission#'][barnacleID]>
							<cfelse>
								<cfset currentBarnacleValue = 0 />
							</cfif>
						</cfif>
						
						<cfset priority = "ui-priority-secondary">
						<cfset icon = "ui-icon-close">
						<cfset inherit="inherit" />
						<cfif currentBarnacleValue EQ 1>
							<cfset priority = "ui-priority-primary">
							<cfset inherit="" />
						<cfelseif currentBarnacleValue EQ -1>
							<cfset priority = "ui-priority-secondary">
							<cfset inherit="" />
						</cfif>
												
						<button  id="#hash(i)##iPermission#" class="permButton barnacleBox #priority# #inherit# #iPermission#" value="#currentBarnacleValue#" type="button" ftobjecttype="package" ftreferenceid="#barnacleID#" ftpermissionid="#iPermission#" ftbarnaclevalue="#numberformat(currentBarnacleValue)#" ftinheritbarnaclevalue="#currentInheritBarnacleValue#"></button>
						
						<!--- 
						<input type="hidden" class="barnacleValue #iPermission#" id="barnacleValue-#barnacleID#" name="barnacleValue-#barnacleID#-#iPermission#" value="#currentBarnacleValue#" style="width:10px;">
						<input type="hidden" class="inheritBarnacleValue #iPermission#" id="inheritBarnacleValue-#barnacleID#" value="#currentInheritBarnacleValue#" style="width:10px;">
						 --->
					</cfloop>	
					
					&nbsp;
					#i#
					#renderNode(stNode="#stNode[i]#", roleID="#arguments.roleID#" )#
					
				</li>
				</cfoutput>
			</cfif>
				
		</cfloop>
		
		<cfoutput></ul></cfoutput>
	</cfif>
</cffunction>

<admin:header title="Edit Site Permissions" />			
	<!--- WEBTOP PERMISSIONS --->
	
	
	<cfset stWebtop = application.factory.oWebtop.getItem(honoursecurity="false") />
	<cfset barnacleID = hash(stWebtop.rbKey)>
	
	<ft:form>
	
	
	<cfoutput>	
	
	<div style="float:left;">
		<table style="width:100%;table-layout:fixed;">
		<tr class="nowrap">
			<td>&nbsp;</td>
			<cfloop list="#permissions#" index="iPermission">
				<td style="width:6px;">&nbsp;</td>
				<td style="width:50px;font-size:9px;text-align:center;" title="#replaceNoCase(application.security.factory.permission.getLabel(iPermission) , "generic", "", "all")#">#replaceNoCase(application.security.factory.permission.getLabel(iPermission) , "generic", "", "all")#</td>
			</cfloop>
		</tr>
		</table>
		</cfoutput>
		
		<cfoutput>
		#renderNode(stNode="#stTree#", treeID="permissionTree", roleID="#stobj.objectid#")#
		</cfoutput>
	</div>
	<ft:buttonPanel style="margin-top:20px;">
		<ft:button value="Save" />
		<ft:button value="Cancel" validate="false" />
	</ft:buttonPanel>
	
	</ft:form>
	
<admin:footer />



<skin:onReady>
<cfoutput>

	$j('.barnacleBox').button({
         text: false,
		icons: {
            primary: "ui-icon-bullet"
        }
     });
       
	$fc.fixDescendants = function(elParent) {
		
		var permission = $j(elParent).attr('ftpermissionid');
		
		// loop over all descendants of clicked item and if they are inheriting, adjust inherited value if required
		$j(elParent).closest( 'div,li' ).find( 'button.permButton[ftpermissionid="' + permission + '"]' ).each(function (i) {
			
			elDescendant = $j(this);
			var descendantValue = $j(elDescendant).attr('ftbarnaclevalue');
			
			$j(elDescendant).find('.ui-icon').removeClass('ui-icon-bullet')
			
			if (descendantValue == -1 ){
				$j(elDescendant).find('.ui-icon').addClass('ui-icon-close');
			};
			if (descendantValue == 1 ){
				$j(elDescendant).find('.ui-icon').addClass('ui-icon-check');
			};
			
			if( $j(elDescendant).attr('id') != $j(elParent).attr('id')) {
				
				$j(this).parents( 'div,li' ).children( 'button.permButton[ftpermissionid="' + permission + '"]' ).each(function (i) {
				
					var elDescendantParent = $j(this);
					
					if( $j(elDescendantParent).attr('id') != $j(elDescendant).attr('id')) {
						
						var descendantParentValue = $j(elDescendantParent).attr('ftbarnaclevalue');
						
						
						if (descendantParentValue == 1) {
							$j(elDescendant).attr('ftinheritbarnaclevalue', '1');
							
							if (descendantValue == 0) { //only descendants that inherit
								$j(elDescendant).removeClass('ui-priority-secondary').addClass('ui-priority-primary');
								$j(elDescendant).find('.ui-icon').removeClass('ui-icon-close').addClass('ui-icon-check');
								
							}
							return false;
						};
						if (descendantParentValue == -1) {
							
							$j(elDescendant).attr('ftinheritbarnaclevalue', '-1');
							
							if (descendantValue == 0) { //only descendants that inherit
								$j(elDescendant).removeClass('ui-priority-primary').addClass('ui-priority-secondary');
								$j(elDescendant).find('.ui-icon').removeClass('ui-icon-check').addClass('ui-icon-close');
								
							}
							return false;
						};
					};
				});
			};
		});				
	};
	
	$j('.permButton').click(function() {
		var el = $j(this);
		var permission = $j(this).attr('ftpermissionid');
		var barnacleValue = $j(this).attr('ftbarnaclevalue');
		var inheritBarnacleValue = $j(this).attr('ftinheritbarnaclevalue');
		
		
		// Different rules for first item in tree. Can Not Inherit.
		if (  $j(this).parents( 'div,li' ).children( 'button.permButton[ftpermissionid="' + permission + '"]' ).length == 1 ) {
			if(barnacleValue == 1) {
				$j(this).attr('ftbarnaclevalue', '-1');
				$j(this).removeClass('ui-priority-primary').addClass('ui-priority-secondary');
				$j(this).find('.ui-icon').removeClass('ui-icon-check').addClass('ui-icon-close');
				$j(this).removeClass('inherit');
			} else {
				$j(this).attr('ftbarnaclevalue', '1');
				$j(this).removeClass('ui-priority-secondary').addClass('ui-priority-primary');
				$j(this).find('.ui-icon').removeClass('ui-icon-close').addClass('ui-icon-check');
				$j(this).removeClass('inherit');
			}
			
		} else {
		
			if(barnacleValue == 1) {
				if(inheritBarnacleValue == -1) {
					$j(this).attr('ftbarnaclevalue', '0');
					$j(this).removeClass('ui-priority-primary').addClass('ui-priority-secondary');
					$j(this).find('.ui-icon').removeClass('ui-icon-check').addClass('ui-icon-close');
					$j(this).addClass('inherit');
				} else {
					$j(this).attr('ftbarnaclevalue', '0');
					$j(this).removeClass('ui-priority-primarysecondary').addClass('ui-priority-primary');
					$j(this).find('.ui-icon').removeClass('ui-icon-close').addClass('ui-icon-check');
					$j(this).addClass('inherit');
				};
			};
			
			if(barnacleValue == -1) {
				if(inheritBarnacleValue == 1) {
					$j(this).attr('ftbarnaclevalue', '0');
					$j(this).removeClass('ui-priority-secondary').addClass('ui-priority-primary');
					$j(this).find('.ui-icon').removeClass('ui-icon-close').addClass('ui-icon-check');
					$j(this).addClass('inherit');
				} else {
					$j(this).attr('ftbarnaclevalue', '1');
					$j(this).removeClass('ui-priority-secondary').addClass('ui-priority-primary');
					$j(this).find('.ui-icon').removeClass('ui-icon-close').addClass('ui-icon-check');

					
												
				};
			};
			
			if(barnacleValue == 0) {
				if(inheritBarnacleValue == 1) {
					
					$j(this).attr('ftbarnaclevalue', '-1');
					$j(this).removeClass('ui-priority-primary').addClass('ui-priority-secondary');
					$j(this).find('.ui-icon').removeClass('ui-icon-check').addClass('ui-icon-close');
				} else {
					$j(this).attr('ftbarnaclevalue', '1');
					$j(this).removeClass('ui-priority-secondary').addClass('ui-priority-primary');
					$j(this).find('.ui-icon').removeClass('ui-icon-close').addClass('ui-icon-check');
					
				};
				$j(this).removeClass('inherit');
			};
		}
		
	
		$j.ajax({
		   type: "POST",
		   url: '/index.cfm?ajaxmode=1&type=farRole&objectid=#stobj.objectid#&view=editAjaxSavePermission',
		   dataType: "html",
		   cache: false,
		   context: $j(this),
		   timeout: 15000,
		   data: {
				referenceid: $j(this).attr('ftreferenceid'),
				permissionid: $j(this).attr('ftpermissionid'),
				objecttype: $j(this).attr('ftobjecttype'),
				barnaclevalue: $j(this).attr('ftbarnaclevalue')
			},
		   success: function(msg){
		   		$j(this).find('.ui-icon').removeClass('ui-icon-bullet');
				$fc.fixDescendants(el);			     	
		   },
		   error: function(data){	
				alert('change unsuccessful. The page will be refreshed.');
				location=location;
			},
			complete: function(){
				
			}
		 });
			 
			 
		
	});
	
	<cfloop list="#permissions#" index="iPermission">	
		$fc.fixDescendants ( $j('###hash('fourq')##iPermission#') );
	</cfloop>
		
	$j("##permissionTree button.permButton[ftbarnaclevalue='1'],##permissionTree button.permButton[ftbarnaclevalue='-1']").each(function (i) {
		$j(this).parents('li').removeClass("closed").addClass("open");
	});
	
	$j("##permissionTree").treeview({
		//animated: "fast",
		collapsed: true
	});
	
	$j( 'button.permButton["ftbarnaclevalue"="1"]' ).live('mouseenter ', function(event) {           
		
		$j(this).closest( 'li' ).css('background-color', '##E8E8E8');
	
     });
	$j( 'button.permButton["ftbarnaclevalue"="-1"]' ).live('mouseleave', function(event) {           
		
		$j(this).closest( 'li' ).css('background-color', 'transparent');
	
     });

	
</cfoutput>
</skin:onReady>


			