<!--- @@Copyright: Daemon Pty Limited 2002-2008, http://www.daemon.com.au --->
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
<cfcomponent 	
	displayname="Nav Permission" 
	extends="types" 
	output="false" 
	hint="Each permission corresponds to a right to access a section of the site or webtop." 
	bsystem="true"
	bObjectBroker="false"
	bRefObjects="false">

	<!---------------------------------------------- 
		type properties
		----------------------------------------------->
	<cfproperty 
		name="type" type="string" default="" hint="The type of navigation permission" 
		ftSeq="1" ftFieldset="General Details" 
		ftLabel="Type"
		fthint="The type of navigation permission."
		ftType="list"
		ftList="site,webtop" />
		
		
	<cfproperty 
		name="roleid" type="uuid" default="" hint="The role this barnacle is attached to" 
		ftSeq="1" ftFieldset="General Details" 
		ftLabel="Role" 
		ftType="uuid" 
		ftJoin="farRole" />
	
			
		
	<cfproperty 
		name="refID" type="string" default="" hint="The reference to the object for which this permission is set" 
		ftSeq="1" ftFieldset="General Details" 
		ftLabel="Reference ID"
		fthint="The reference to the object for which this permission is set"
		ftType="string" />
		
	<cfproperty
		name="permValue" 
		type="numeric" 
		default="0" 
		hint="Deny: -1, Selected Only: 0, Grant: 1. Absence of a barnacle implies inherit. If the object can't inherit that is equivilent to deny." 
		ftLabel="Right" 
		ftType="list" 
		ftList="-1:Deny,0:Selected Only,1:Grant" />
		
	<!---------------------------------------------- 
		library data methods; used by formtools
		----------------------------------------------->
	<!--- <cffunction name="setGrant" access="public" output="false" returntype="boolean" hint="Returns the new value of permValue">
		<cfargument name="type" type="string" required="true" hint="The type of navigation permission">
		<cfargument name="refID" type="string" required="true" hint="The reference to the object for which this permission is set">
		
		<cfset var newPermValue = 0 />
		
		<cfswitch expression="#arguments.type#">
			<cfcase value="site">
				
				<cfset stNav = application.fapi.getContentObject(typename="dmNavigation", objectid="#arguments.refID#") />
				<cfset qNode = application.factory.oTree.getNode(objectid=arguments.refID)>
				<cfset qAncestors = application.factory.oTree.getAncestors(objectid=arguments.refID)>
				
				<cfquery datasource="#application.dsn#" name="qDescendants">
				DELETE
				FROM farNavPermission
				WHERE refID IN (
					SELECT perm.refID
					FROM nested_tree_objects as ntm
					INNER JOIN farNavPermission as perm ON ntm.objectid = perm.refID 
					WHERE ntm.nleft	> <cfqueryparam cfsqltype="cf_sql_integer" value="#qNode.nLeft#">
					AND ntm.nleft < <cfqueryparam cfsqltype="cf_sql_integer" value="#qNode.nRight#">
					AND ntm.typename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qNode.typename#">
				)
				</cfquery>
				
				
				<cfquery datasource="#application.dsn#" name="qPerm">
				SELECT *
				FROM farNavPermission
				WHERE refID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.refID#">
				</cfquery>
				<cfif qPerm.recordCount>
					<cfset application.fapi.setData(typename="farNavPermission", objectid="#qPerm.objectid#", permValue="1")>
				<cfelse>
					<cfset application.fapi.setData(typename="farNavPermission", objectid="#application.fapi.getUUID()#", refID="#arguments.refID#", permValue="1")>
				</cfif>
				
				
				<cfif qAncestors.recordCount>
				
					<cfquery datasource="#application.dsn#" name="qAncestorPermissions">
					SELECT *
					FROM farNavPermission
					WHERE refID IN ( <cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valuelist(qAncestors.objectid)#"> )
					</cfquery>
					
					<cfloop query="qAncestorPermissions">
						
						<cfset qNode = application.factory.oTree.getNode(objectid=qAncestorPermissions.refID)>
						
						<cfquery datasource="#application.dsn#" name="qDeny">
						SELECT objectid
						FROM farNavPermission
						WHERE refID IN (
							SELECT perm.refID
							FROM nested_tree_objects as ntm
							INNER JOIN farNavPermission as perm ON ntm.objectid = perm.refID 
							WHERE ntm.nleft	> <cfqueryparam cfsqltype="cf_sql_integer" value="#qNode.nLeft#">
							AND ntm.nleft < <cfqueryparam cfsqltype="cf_sql_integer" value="#qNode.nRight#">
							AND ntm.typename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qNode.typename#">
						)
						AND permValue = <cfqueryparam cfsqltype="cf_sql_numeric" value="-1">
						</cfquery>
						
						<cfif not qDeny.recordcount>
							<cfset setGrant(type="#arguments.type#", refID="#qAncestorPermissions.refID#")>
						</cfif>
					
					</cfloop>
				</cfif>
				
			</cfcase>
			<cfcase value="webtop">
				<!--- todo --->
				<cfreturn arguments.permValue>
			</cfcase>
			<cfdefaultcase>
				<cfabort showerror="setGrant type must be 'site' or 'webtop'">
			</cfdefaultcase>
		</cfswitch>
		
		<cfreturn 1>
	</cffunction>
	
	<cffunction name="setDeny" access="public" output="false" returntype="boolean" hint="Returns the new value of permValue">
		<cfargument name="type" type="string" required="true" hint="The type of navigation permission">
		<cfargument name="refID" type="string" required="true" hint="The reference to the object for which this permission is set">
		
		<cfset var newPermValue = 0 />
		
		<cfswitch expression="#arguments.type#">
			<cfcase value="site">
				
				<cfset stNav = application.fapi.getContentObject(typename="dmNavigation", objectid="#arguments.refID#") />
				<cfset qNode = application.factory.oTree.getNode(objectid=arguments.refID)>
				<cfset qAncestors = application.factory.oTree.getAncestors(objectid=arguments.refID)>
				
				<cfquery datasource="#application.dsn#" name="qDescendants">
				DELETE
				FROM farNavPermission
				WHERE refID IN (
					SELECT perm.refID
					FROM nested_tree_objects as ntm
					INNER JOIN farNavPermission as perm ON ntm.objectid = perm.refID 
					WHERE ntm.nleft	> <cfqueryparam cfsqltype="cf_sql_integer" value="#qNode.nLeft#">
					AND ntm.nleft < <cfqueryparam cfsqltype="cf_sql_integer" value="#qNode.nRight#">
					AND ntm.typename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qNode.typename#">
				)
				</cfquery>
				
				
				<cfquery datasource="#application.dsn#" name="qPerm">
				SELECT *
				FROM farNavPermission
				WHERE refID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.refID#">
				</cfquery>
				<cfif qPerm.recordCount>
					<cfset application.fapi.setData(typename="farNavPermission", objectid="#qPerm.objectid#", permValue="-1")>
				<cfelse>
					<cfset application.fapi.setData(typename="farNavPermission", objectid="#application.fapi.getUUID()#", refID="#arguments.refID#", permValue="-1")>
				</cfif>
				
				
				<cfif qAncestors.recordCount>
				
					<cfquery datasource="#application.dsn#" name="qAncestorPermissions">
					SELECT *
					FROM farNavPermission
					WHERE refID IN ( <cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#valuelist(qAncestors.objectid)#"> )
					</cfquery>
					
					<cfloop query="qAncestorPermissions">
						
						<cfset qNode = application.factory.oTree.getNode(objectid=qAncestorPermissions.refID)>
						
						<cfquery datasource="#application.dsn#" name="qGrant">
						SELECT objectid
						FROM farNavPermission
						WHERE refID IN (
							SELECT perm.refID
							FROM nested_tree_objects as ntm
							INNER JOIN farNavPermission as perm ON ntm.objectid = perm.refID 
							WHERE ntm.nleft	> <cfqueryparam cfsqltype="cf_sql_integer" value="#qNode.nLeft#">
							AND ntm.nleft < <cfqueryparam cfsqltype="cf_sql_integer" value="#qNode.nRight#">
							AND ntm.typename = <cfqueryparam cfsqltype="cf_sql_varchar" value="#qNode.typename#">
						)
						AND permValue = <cfqueryparam cfsqltype="cf_sql_numeric" value="-1">
						</cfquery>
						
						<cfif qGrant.recordcount>
							<cfset setSome(type="#arguments.type#", refID="#qAncestorPermissions.refID#")>
						<cfelse>
							<cfset setDeny(type="#arguments.type#", refID="#qAncestorPermissions.refID#")>
						</cfif>
					
					</cfloop>
				</cfif>
				
			</cfcase>
			<cfcase value="webtop">
				<!--- todo --->
				<cfreturn arguments.permValue>
			</cfcase>
			<cfdefaultcase>
				<cfabort showerror="setGrant type must be 'site' or 'webtop'">
			</cfdefaultcase>
		</cfswitch>
		
		<cfreturn 1>
	</cffunction>
		
	
	<cffunction name="setSome" access="public" output="false" returntype="boolean" hint="Returns the new value of permValue">
		<cfargument name="type" type="string" required="true" hint="The type of navigation permission">
		<cfargument name="refID" type="string" required="true" hint="The reference to the object for which this permission is set">
		
		<cfset var newPermValue = 0 />

		<cfquery datasource="#application.dsn#" name="qPerm">
		SELECT *
		FROM farNavPermission
		WHERE refID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.refID#">
		</cfquery>
		
		<cfif qPerm.recordCount>
			<cfset application.fapi.setData(typename="farNavPermission", objectid="#qPerm.objectid#", permValue="0")>
		<cfelse>
			<cfset application.fapi.setData(typename="farNavPermission", objectid="#application.fapi.getUUID()#", refID="#arguments.refID#", permValue="0")>
		</cfif>
		
		<cfreturn 0>
	</cffunction> --->
	
	<cffunction name="setGrant" access="public" output="false" returntype="boolean" hint="Returns the new value of permValue">
		<cfargument name="type" type="string" required="true" hint="The type of navigation permission">
		<cfargument name="refID" type="string" required="true" hint="The reference to the object for which this permission is set">
		
		<cfquery datasource="#application.dsn#" name="qPerm">
		SELECT *
		FROM farNavPermission
		WHERE refID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.refID#">
		</cfquery>
		
		<cfif qPerm.recordCount>
			<cfset application.fapi.setData(typename="farNavPermission", objectid="#qPerm.objectid#", permValue="1")>
		<cfelse>
			<cfset application.fapi.setData(typename="farNavPermission", objectid="#application.fapi.getUUID()#", refID="#arguments.refID#", permValue="1")>
		</cfif>
		
		<cfreturn 1>
	</cffunction>
	
	<cffunction name="setDeny" access="public" output="false" returntype="boolean" hint="Returns the new value of permValue">
		<cfargument name="type" type="string" required="true" hint="The type of navigation permission">
		<cfargument name="refID" type="string" required="true" hint="The reference to the object for which this permission is set">
		
		<cfquery datasource="#application.dsn#" name="qPerm">
		SELECT *
		FROM farNavPermission
		WHERE refID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.refID#">
		</cfquery>
		
		<cfif qPerm.recordCount>
			<cfset application.fapi.setData(typename="farNavPermission", objectid="#qPerm.objectid#", permValue="0")>
		<cfelse>
			<cfset application.fapi.setData(typename="farNavPermission", objectid="#application.fapi.getUUID()#", refID="#arguments.refID#", permValue="0")>
		</cfif>
		
		<cfreturn 0>
	</cffunction> 
				
	
	<cffunction name="setInherit" access="public" output="false" returntype="boolean" hint="Returns the new value of permValue">
		<cfargument name="type" type="string" required="true" hint="The type of navigation permission">
		<cfargument name="refID" type="string" required="true" hint="The reference to the object for which this permission is set">
		
		<cfquery datasource="#application.dsn#" name="qPerm">
		SELECT *
		FROM farNavPermission
		WHERE refID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.refID#">
		</cfquery>
		
		<cfif qPerm.recordCount>
			<cfset application.fapi.getContentType("farNavPermission").delete(qPerm.objectid) >
		</cfif>
		
		<cfreturn 0>
	</cffunction> 
				
</cfcomponent>
