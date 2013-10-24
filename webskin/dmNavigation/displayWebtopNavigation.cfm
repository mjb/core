<!--- @@cacheStatus: 1 --->
<!--- @@cacheByRoles: 1 --->

<cfimport taglib="/farcry/core/tags/admin" prefix="admin" />
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<!--- 
<cfif structKeyExists(url, "clear")>
	<cfset structDelete(session, "stWebtop")>
</cfif>

<cfif not structKeyExists(session,"stWebtop")>
	<cfset session.stWebtop = application.factory.oWebtop.getItem() >
</cfif>
 --->

<cfset stWebtop = application.factory.oWebtop.getItem() >
<!--- <cfdump var="#stWebtop#" expand="false" label="stWebtop"> --->

<cfoutput><h1>Webtop #randRange(1,100)#</h1></cfoutput>
<cfoutput>
	
	<ul>
		<li><a href="##" target="content">#stWebtop.rbKey#</a></li>
	
	
		<cfif len(stWebtop.CHILDORDER)>
			<ul>
			<cfloop list="#stWebtop.CHILDORDER#" index="iSection">
				<cfset stSection = stWebtop.children[iSection]>
				<li>#stSection.rbKey#</li>
				
				<cfif len(stSection.CHILDORDER)>
					<ul>
					<cfloop list="#stSection.CHILDORDER#" index="iSubSection">
						<cfset stSubSection = stSection.children[iSubSection]>
						<li>#stSubSection.rbKey#</li>
					
						<cfif len(stSubSection.CHILDORDER)>
							<ul>
							<cfloop list="#stSubSection.CHILDORDER#" index="iMenu">
								<cfset stMenu = stSubSection.children[iMenu]>
								<li>#stMenu.rbKey#</li>
							
								<cfif len(stMenu.CHILDORDER)>
								<ul>
									<cfloop list="#stMenu.CHILDORDER#" index="iMenuItem">
										<cfset stMenuItem = stMenu.children[iMenuItem]>
										<li>#stMenuItem.rbKey#</li>
										
									</cfloop>
								</ul>
								</cfif>	
							</cfloop>
							</ul>	
						</cfif>	
					</cfloop>
					</ul>
				</cfif>
			</cfloop>
			</ul>
		</cfif>
	</ul>
</cfoutput>

