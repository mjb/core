<cfsetting enablecfoutputonly="true" requesttimeout="1000" />
<!--- @@displayname: COAPI Overview --->
<!--- @@description: Overview of DB persistent types and any existing conflicts --->

<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />
<cfimport taglib="/farcry/core/tags/misc" prefix="misc" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />
<cfimport taglib="/farcry/core/tags/formtools" prefix="ft" />

<cfset aChanges = arraynew(1) />
<cfset changedTypes = "" />

<cfif isdefined("url.logchanges")>
	<cfset application.config.general.logDBChanges = url.logchanges />
	<cfset qConfig = application.fapi.getContentObjects(typename="farConfig",configkey_eq="general") />
	<cfset stConfig = application.fapi.getContentObject(typename="farConfig",objectid=qConfig.objectid) />
	<cfwddx action="cfml2wddx" input="#application.config.general#" output="stConfig.configdata" />
	<cfset application.fapi.setData(stProperties=stConfig) />
	<cfoutput>true</cfoutput>
	<cfabort>
</cfif>

<ft:processform action="Apply Default Resolutions">
	<cfparam name="form.deploydefaults" default="" />
	<cfloop list="#form.deploydefaults#" index="thistype">
		<cfset stDiff = application.fc.lib.db.diffSchema(typename=thistype,dsn=application.dsn) />
		<cfloop collection="#stDiff.tables#" item="thistable">
			<cfset aChanges = application.fc.lib.db.mergeChanges(aChanges,application.fc.lib.db.getDefaultChanges(stDiff=stDiff.tables[thistable])) />
		</cfloop>
		<cfset changedTypes = listappend(changedTypes,thistype) />
	</cfloop>
</ft:processform>

<ft:processform action="Deploy Changes">
	<cfset stDiff = application.fc.lib.db.diffSchema(typename=form.typename,dsn=application.dsn) />
	<cfloop collection="#stDiff.tables#" item="thistable">
		<cfswitch expression="#stDiff.tables[thistable].resolution#">
			<cfcase value="x">
				<cfloop collection="#stDiff.tables[thistable].fields#" item="thisfield">
					<cfswitch expression="#stDiff.tables[thistable].fields[thisfield].resolution#">
						<cfcase value="x">
							<cfif form["field_#thistable#_#thisfield#"] eq "repair">
								<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="repairColumn",schema=stDiff.tables[thistable].newmetadata,propertyname=thisfield)) />
							</cfif>
						</cfcase>
						<cfcase value="+">
							<cfif form["field_#thistable#_#thisfield#"] eq "deploy">
								<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="addColumn",schema=stDiff.tables[thistable].newmetadata,propertyname=thisfield)) />
							</cfif>
						</cfcase>
						<cfcase value="-">
							<cfif form["field_#thistable#_#thisfield#"] eq "drop">
								<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="dropColumn",schema=stDiff.tables[thistable].newmetadata,propertyname=thisfield)) />
							<cfelseif form["field_#thistable#_#thisfield#"] eq "rename" and len(form["field_#thistable#_#thisfield#_rename_new"])>
								<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="repairColumn",schema=stDiff.tables[thistable].newmetadata,propertyname=form["field_#thistable#_#thisfield#_rename_new"],oldpropertyname=thisfield)) />
							</cfif>
						</cfcase>
					</cfswitch>
				</cfloop>
				
				<cfloop collection="#stDiff.tables[thistable].indexes#" item="thisindex">
					<cfswitch expression="#stDiff.tables[thistable].indexes[thisindex].resolution#">
						<cfcase value="x">
							<cfif form["index_#thistable#_#thisindex#"] eq "repair">
								<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="repairIndex",schema=stDiff.tables[thistable].newmetadata,indexname=thisindex)) />
							</cfif>
						</cfcase>
						<cfcase value="+">
							<cfif form["index_#thistable#_#thisindex#"] eq "deploy">
								<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="addIndex",schema=stDiff.tables[thistable].newmetadata,indexname=thisindex)) />
							</cfif>
						</cfcase>
						<cfcase value="-">
							<cfif form["index_#thistable#_#thisindex#"] eq "drop">
								<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="dropIndex",schema=stDiff.tables[thistable].newmetadata,indexname=thisindex)) />
							</cfif>
						</cfcase>
					</cfswitch>
				</cfloop>
			</cfcase>
			<cfcase value="+">
				<cfif form["table_#thistable#"] eq "deploy">
					<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="deploySchema",schema=stDiff.tables[thistable].newmetadata,bDropTable=true)) />
				</cfif>
			</cfcase>
			<cfcase value="-">
				<cfif form["table_#thistable#"] eq "drop">
					<cfset arrayappend(aChanges,application.fc.lib.db.createChange(action="dropSchema",schema=stDiff.tables[thistable].oldmetadata)) />
				</cfif>
			</cfcase>
		</cfswitch>
		
		<cfif structkeyexists(application.stCOAPI,thistable)>
			<cfset changedTypes = listappend(changedTypes,thistable) />
		</cfif>
	</cfloop>
</ft:processform>

<cfset aResults = arraynew(1) />
<cfset aResults = application.fc.lib.db.deployChanges(aChanges,application.dsn) />
<cfif arraylen(aResults)>
	<cfloop from="1" to="#arraylen(aResults)#" index="i">
		<cfif structkeyexists(aResults[i],"message") and aResults[i].bSuccess>
			<skin:bubble message="#aResults[i].message#" tags="coapichange,success" />
		<cfelseif structkeyexists(aResults[i],"message")>
			<skin:bubble message="#aResults[i].message#" tags="coapichange,error" />
		</cfif>
	</cfloop>
	
	<cfset application.fc.lib.objectbroker.init(true) />
	<skin:bubble message="Application cache has been flushed" tags="coapichange,success" />
	
	<cfquery datasource="#application.dsn#" name="qDeleteWizards">delete from dmWizard where ReferenceID in (select objectid from refObjects where typename in (<cfqueryparam cfsqltype="cf_sql_varchar" list="true" value="#changedTypes#">))</cfquery>
	<skin:bubble message="Wizard data has been deleted for updated types" tags="coapichange,success" />
</cfif>

<skin:loadCSS id="farcry-form" />
<cfoutput><div class="uniForm"></cfoutput>
<skin:pop tags="error" start="<div class='alert alert-error'>" end="</div>">
	<cfoutput>
		<cfif len(trim(message.title))><strong>#message.title#</strong></cfif><cfif len(trim(message.title)) and len(trim(message.message))>: </cfif>
		<cfif len(trim(message.message))>#message.message#</cfif>
		<br>
	</cfoutput>
</skin:pop>
<skin:pop tags="coapichange" start="<div class='alert alert-success'>" end="</div>">
	<cfoutput>
		<cfif len(trim(message.title))><strong>#message.title#</strong></cfif><cfif len(trim(message.title)) and len(trim(message.message))>: </cfif>
		<cfif len(trim(message.message))>#message.message#</cfif>
		<br>
	</cfoutput>
</skin:pop>
<cfoutput></div></cfoutput>

<cfif structkeyexists(form,"sql") and form.sql>
	<cfset sqlOut = "" />
	<cfloop from="1" to="#arraylen(aResults)#" index="i">
		<cfif aResults[i].bSuccess>
			<cfset sqlOut = sqlOut & "## SUCCESS :: #aResults[i].message##chr(13)##chr(10)#" />
		<cfelse>
			<cfset sqlOut = sqlOut & "## FAILURE :: #aResults[i].message##chr(13)##chr(10)#" />
		</cfif>
		<cfloop from="1" to="#arraylen(aResults[i].results)#" index="j">
			<cfset sqlOut = sqlOut & "#trim(rereplace(aResults[i].results[j].sql,'\n\s+','','all'))#;#chr(13)##chr(10)##chr(13)##chr(10)#" />
		</cfloop>
		<cfset sqlOut = sqlOut & "#chr(13)##chr(10)#" />
	</cfloop>
	<cfoutput><textarea cols="80" rows="10">#sqlOut#</textarea></cfoutput>
</cfif>
<cfif structkeyexists(form,"debug") and form.debug>
	<cfdump var="#aResults#">
</cfif>

<cffunction name="getIcon" output="false" returntype="string" hint="Returns icon for typename or default for others.">
	<cfargument name="typename" type="string" required="true" />

	<!--- set default of table for non-types; eg. schema --->
	<cfset var icon = "icon-table">

	<cfif structKeyExists(application.stcoapi, arguments.typename)>
		<cfset icon = application.stcoapi[arguments.typename].icon>
	</cfif>

	<cfif NOT len(icon)>
		<cfset icon = "icon-question-sign">
	</cfif>

	<cfreturn icon />
</cffunction>

<cffunction name="summariseConflicts" output="false" returntype="string" hint="Returns a string summarising the conflicts passed in">
	<cfargument name="stConflicts" type="struct" required="true" />
	
	<cfset var summary = "" />
	<cfset var thistable = "" />
	<cfset var thisfield = "" />
	<cfset var thisindex = "" />
	
	<cfset var changes = arraynew(1) />
	
	<cfloop collection="#arguments.stConflicts.tables#" item="thistable">
		<cfswitch expression="#arguments.stConflicts.tables[thistable].resolution#">
			<cfcase value="x">
				<cfset changes = arraynew(1) />
				<cfloop collection="#arguments.stConflicts.tables[thistable].fields#" item="thisfield">
					<cfswitch expression="#arguments.stConflicts.tables[thistable].fields[thisfield].resolution#">
						<cfcase value="+">
							<cfset arrayappend(changes,"<div class='undeployed field'><i class='icon-fixed-width'></i><i class='icon-plus-sign icon-fixed-width'></i> #thisfield#</div>") />
						</cfcase>
						<cfcase value="x">
							<cfset arrayappend(changes,"<div class='altered field'><i class='icon-fixed-width'></i><i class='icon-question-sign icon-fixed-width'></i> #thisfield#</div>") />
						</cfcase>
						<cfcase value="-">
							<cfset arrayappend(changes,"<div class='deleted field'><i class='icon-fixed-width'></i><i class='icon-remove-sign icon-fixed-width'></i> #thisfield#</div>") />
						</cfcase>
					</cfswitch>
				</cfloop>
				<cfloop collection="#arguments.stConflicts.tables[thistable].indexes#" item="thisindex">
					<cfswitch expression="#arguments.stConflicts.tables[thistable].indexes[thisindex].resolution#">
						<cfcase value="+">
							<cfset arrayappend(changes,"<div class='undeployed field'><i class='icon-fixed-width'></i><i class='icon-plus-sign icon-fixed-width'></i> #thisindex#</div>") />
						</cfcase>
						<cfcase value="x">
							<cfset arrayappend(changes,"<div class='altered field'><i class='icon-fixed-width'></i><i class='icon-question-sign icon-fixed-width'></i> #thisindex#</div>") />
						</cfcase>
						<cfcase value="-">
							<cfset arrayappend(changes,"<div class='deleted field'><i class='icon-fixed-width'></i><i class='icon-remove-sign icon-fixed-width'></i> #thisindex#</div>") />
						</cfcase>
					</cfswitch>
				</cfloop>
					
				<cfset summary = listappend(summary,"<p class='altered coapitable'><i class='icon-question-sign icon-fixed-width'></i> #thistable#</p> <div>#arrayToList(changes,"")#</div>"," ") />
			</cfcase>
			<cfcase value="+">
				<cfset summary = listappend(summary,"<p class='undeployed coapitable'><i class='icon-plus-sign icon-fixed-width'></i> #thistable#</p>"," ") />
			</cfcase>
			<cfcase value="-">
				<cfset summary = listappend(summary,"<p class='deleted coapitable'><i class='icon-remove-sign icon-fixed-width'></i> #thistable#</p>"," ") />
			</cfcase>
		</cfswitch>
	</cfloop>
	
	<cfreturn summary />
</cffunction>

<cfset stConflicts = structnew() />

<!--- Location labels --->
<cfset stLocations = structnew() />
<misc:map values="#application.plugins#" resulttype="struct" result="stLocations">
	<!--- Try to get plugin name from manifest --->
	<cfif fileexists("#application.path.plugins#/#value#/install/manifest.cfc")>
		<cfset oManifest = createobject("component","farcry.plugins.#value#.install.manifest") />
		<cfif structkeyexists(oManifest,"name")>
			<cfset sendback[value] = oManifest.name />
		<cfelse>
			<cfset sendback[value] = value />
		</cfif>
	<cfelse>
		<cfset sendback[value] = value />
	</cfif>
</misc:map>
<cfset stLocations.core = "Core" />
<cfset stLocations.project = "Project" />

<!--- Create query of COAPI types --->
<misc:map values1="#application.stCOAPI#" values2="#application.schema#" resulttype="querynew('class,label,typename,packagepath,locations,locationids,conflicts')" result="qTypes">
	<cfif listcontains("type,rule,schema",value.class) and not refindnocase("^(#structkeylist(application.stCOAPI,'|')#)_\w+",index)>
		<cfset sendback[1].class = value.class />
		<cfset sendback[1].typename = index />
		<cfset sendback[1].packagepath = value.packagepath />
		
		<!--- Figure out the type label --->
		<cfif structkeyexists(value,"displayname")>
			<cfset sendback[1].label = value.displayname />
		<cfelse>
			<cfset sendback[1].label = sendback.typename />
		</cfif>
		
		<!--- Figure out the various locations of the type --->
		<cfset stMD = getMetadata(createobject("component",value.packagepath)) />
		<cfset sendback[1].locations = "" /><div></div>
		<cfset sendback[1].locationids = "" />
		<cfloop condition="not structisempty(stMD)">
			<cfif refindnocase("\.core\.packages\.",stMD.fullname)>
				<cfset sendback[1].locations = listappend(sendback[1].locations,"Core:#stMD.fullname#") />
				<cfset sendback[1].locationids = listappend(sendback[1].locationids,"core") />
			<cfelseif refindnocase("\.plugins\.\w+\.packages",stMD.fullname)>
				<cfset plugin = rereplacenocase(stMD.fullname,".*\.plugins\.(\w+)\.packages.*","\1") />
				<cfif structkeyexists(stLocations,plugin)>
					<cfset sendback[1].locations = listappend(sendback[1].locations,"#stLocations[plugin]#:#stMD.fullname#") />
				<cfelse>
					<cfset sendback[1].locations = listappend(sendback[1].locations,"#plugin#:#stMD.fullname#") />
				</cfif>
				<cfset sendback[1].locationids = listappend(sendback[1].locationids,plugin) />
			<cfelseif refindnocase("\.projects\.\w+\.packages\.",stMD.fullname)>
				<cfset sendback[1].locations = listappend(sendback[1].locations,"Project:#stMD.fullname#") />
				<cfset sendback[1].locationids = listappend(sendback[1].locationids,"project") />
			</cfif>
			
			<!--- Get next ancestor --->
			<cfif structkeyexists(stMD,"extends")>
				<cfset stMD = stMD.extends />
				<cfif refindnocase("\.schema$",stMD.fullname) or refindnocase("\.fourq$",stMD.fullname) or refindnocase("\.types$",stMD.fullname) or refindnocase("\.versions$",stMD.fullname) or refindnocase("\.rules$",stMD.fullname) or refindnocase("\.category$",stMD.fullname)>
					<cfset stMD = structnew() />
				</cfif>
			<cfelse>
				<cfset stMD = structnew() />
			</cfif>
		</cfloop>
		
		<!--- Find conflicts --->
		<cfset application.fc.lib.db.initialiseTableMetadata(value.packagepath) />
		<cfset stConflicts[index] = application.fc.lib.db.diffSchema(typename=value.packagepath,dsn=application.dsn) />
		<cfset sendback[1].conflicts = summariseConflicts(stConflicts[index]) />
	</cfif>
</misc:map>

<cfquery dbtype="query" name="qTypes">
	select		*
	from		qTypes
	order by	label
</cfquery>

<cfset lLogChangeFlags = application.fc.lib.db.getLogChangeFlags() />

<skin:loadJS id="fc-jquery" />
<skin:loadJS id="farcry-form" />
<skin:loadJS id="fc-jquery-ui" />
<skin:loadCSS id="jquery-ui" />


<skin:htmlHead><cfoutput>
	<style type="text/css">
		.undeployed { color:##23d729; }
		.deleted { color:##ff0000; }
		.altered { color:##d78b23; }
		
		a.titleonly { color:##000000; }
			
		td.class, th.class { width:8em; }
		td.name, th.name {  }
		td.location, th.location { width:12em; }
		td.conflicts, th.conflicts { width:12em; }
		td.actions, th.actions { width:12em; }
		td.logchanges, th.logchanges { width:1.5em; }
	</style>
</cfoutput></skin:htmlHead>

<skin:onReady><cfoutput>
	$j(document).on("click","a.openindialog",function(){
		$fc.openDialogIFrame($j(this).data("title"),this.href,700,600);
		return false;
	});
	
	var logBuffer = 0;
	function updateLogChanges(){
		if (logBuffer)
			clearTimeout(logBuffer);
		
		logBuffer = setTimeout(function(){
			var logchanges = $j.map($j("td.logchanges input:checked").toArray(),function(value){
				return value.value;
			}).join();
			
			$j.get("#application.fapi.fixURL(addvalues='logchanges=abcdef')#".replace("abcdef",logchanges));
			
			logBuffer = 0;
		},1500);
	};
	$j(document).on("click","input[name=logallchanges]",function(){
		$j("th.logchanges input, td.logchanges input").not(this).attr("checked",$j(this).attr("checked")=="checked"?true:false);
		updateLogChanges();
	});
	$j(document).on("click","input[name=logchanges]",updateLogChanges);
</cfoutput></skin:onReady>

<cfset conflictCount = 0 />
<cfloop query="qTypes">
	<cfif len(qTypes.conflicts)>
		<cfset conflictCount = conflictCount + 1 />
	</cfif>
</cfloop>

<cfoutput><h1>COAPI Overview</h1></cfoutput>

<cfif conflictCount>
	<ft:form>
		<cfoutput>
			<h2>Conflicts</h2>
			<table style="width:100%;table-layout:fixed;" class="farcry-objectadmin table table-striped table-hover">
				<thead>
					<tr>
						<th class="class">Class</th>
						<th class="name">Name</th>
						<th class="conflicts">Conflict</th>
						<th class="actions"><label><input type="checkbox" name="selectall" value="" onclick="$j('input[name=deploydefaults]').attr('checked',(this.checked?'checked':''));" /> Apply Defaults</label></th>
					</tr>
				</thead>
				<tbody>
		</cfoutput>
		<cfloop query="qTypes">
			<cfif len(qTypes.conflicts)>
				<cfoutput>
					<tr class="#qTypes.class#">
						<td class="class">#ucase(left(qTypes.class,1))##mid(qTypes.class,2,10)#</td>
						<td class="name"><i class="#getIcon(qtypes.typename)# icon-fixed-width" style="font-size:16px;color:##777"></i> #qTypes.label#</td>
						<td class="conflicts">
							<skin:buildLink type="farCOAPI" view="webtopPageModal" bodyview="webtopBodyConflicts" urlParameters="typepath=#qTypes.packagepath#" class="openindialog" data-title="#qTypes.label# Conflicts" id="#qTypes.typename#_conflicts">Resolve conflicts</skin:buildLink>
							<skin:tooltip id="#qTypes.typename#_conflicts" selector="###qTypes.typename#_conflicts" position="bottom" message="#qTypes.conflicts#" />
						</td>
						<td class="actions"><input type="checkbox" name="deploydefaults" value="#qTypes.packagepath#" /></td>
					</tr>
				</cfoutput>
			</cfif>
		</cfloop>
		<cfoutput>
				</tbody>
			</table>
		</cfoutput>
		<ft:buttonPanel>
			<cfoutput>
				<div class="pull-right">
					<label>Show debug output <input type="checkbox" name="debug" value="1"<cfif (structkeyexists(form,"debug") and form.debug) or (structkeyexists(url,"debug") and url.debug)> checked</cfif>></label>&nbsp;
					<label>Show SQL <input type="checkbox" name="sql" value="1"<cfif (structkeyexists(form,"sql") and form.sql) or (structkeyexists(url,"sql") and url.sql)> checked</cfif>></label>&nbsp;
			</cfoutput>
			<ft:button value="Apply Default Resolutions" />
			<cfoutput>
				</div>
			</cfoutput>
		</ft:buttonPanel>
	</ft:form>
<cfelse>
	<cfoutput><div class="alert alert-success">No schema conflicts</div></cfoutput>
</cfif>

<cfloop list="project,#application.fapi.listReverse(application.plugins)#,core" index="thislocation">
	<cfoutput>
		<h2>#stLocations[thislocation]#</h2>
		<table style="width:100%;table-layout:fixed;" class="farcry-objectadmin table table-striped table-hover">
			<thead>
				<tr>
					<th class="class">Class</th>
					<th class="name">Name</th>
					<th class="location">Location</th>
					<th class="actions">Info</th>
					<th class="logchanges"><input type="checkbox" name="logallchanges" value="" title="Log changes on ALL types" /></th>
				</tr>
			</thead>
			<tbody>
	</cfoutput>
	<cfset count = 0 />
	<cfloop query="qTypes">
		<cfif listcontains(qTypes.locationids,thislocation)>
			<cfset count = count+1 />
			<cfoutput>
				<tr class="#qTypes.class#">
					<td class="class">#ucase(left(qTypes.class,1))##mid(qTypes.class,2,10)#</td>
					<td class="name"><i class="#getIcon(qtypes.typename)# icon-fixed-width" style="font-size:16px;color:##777"></i> #qTypes.label#</td>
					<td class="location">
						<cfloop list="#qTypes.locations#" index="thispath">
							<span title="#listlast(thispath,':')#">#listfirst(thispath,':')#</span><cfif thispath neq listlast(qTypes.locations)>, </cfif>
						</cfloop>
					</td>
					<td class="actions">
						<cfif listcontains(application.plugins,"farcrydoc") and listcontains("rule,type",qTypes.class)>
							<a href="#application.fapi.getLink(type=qTypes.typename,view='webtopPageModal',bodyview='docAll',urlParameters='ajaxmode=1')#" class="openindialog" data-title="FarCry Documentation">Docs</a>
						<cfelse>
							<a href="/CFIDE/componentutils/componentdetail.cfm?COMPONENT=#packagepath#" class="openindialog" data-title="ColdFusion Documentation">Docs</a>
						</cfif>
						<cfif listcontains("rule,type",qTypes.class)>
							&middot;
							<a href="#application.fapi.getLink(type='farCOAPI',view='webtopPageModal',bodyview='webtopBodyScaffold',urlParameters='typename=#qTypes.typename#')#" class="openindialog" data-title="Scaffold">Scaffold</a>
						</cfif>
					</td>
					<td class="logchanges"><input type="checkbox" name="logchanges" value="#qTypes.typename#" title="Log changes on THIS type" <cfif listfindnocase(lLogChangeFlags,qTypes.typename)>checked</cfif> /></td>
				</tr>
			</cfoutput>
		</cfif>
	</cfloop>
	<cfif not count>
		<cfoutput><tr class="none"><td colspan="5">No COAPI types</td></tr></cfoutput>
	</cfif>
	<cfoutput>
			<tbody>
		</table>
	</cfoutput>
</cfloop>

<cfsetting enablecfoutputonly="false" />