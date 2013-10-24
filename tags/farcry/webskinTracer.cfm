<cfsetting enablecfoutputonly="true" />
<!--- @@Copyright: Daemon Pty Limited 2003-2010, http://www.daemon.com.au --->
<!--- @@License:  --->
<!--- @@displayname: webskin tracer  --->
<!--- @@description:  --->
<!--- @@author: Matthew Bryant (mbryant@daemon.com.au) --->


<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfif thistag.executionMode eq "Start">

	<cfif structKeyExists(request,"mode") AND request.mode.traceWebskins EQ true AND not request.mode.ajax>		
		<cfif structKeyExists(request, "aAncestorWebskinsTrace") AND arrayLen(request.aAncestorWebskinsTrace)>
		
			<skin:loadJS id="fc-jquery" />
			<skin:loadJS id="fc-jquery-ui" />
			<skin:loadCSS id="jquery-ui" />
			
			<skin:htmlHead id="webskin-tracer">
				<cfoutput>
					<style type="text/css">
					.webskin-tracer-close {background:transparent url(#application.url.webtop#/thirdparty/jquery-tooltip/shadow.png) top no-repeat;height:26px;}
					.webskin-tracer-bubble {background:transparent url(#application.url.webtop#/thirdparty/jquery-tooltip/shadow-bottom.png) bottom no-repeat;width:369px;height:auto;display:block;}
					.webskin-tracer-bubble-inner {padding:0px 25px 25px 25px;font-size:10px;display:block;}
					.webskin-tracer-bubble-inner table.webskin-tracer-table {border:none;}
					.webskin-tracer-bubble-inner table.webskin-tracer-table th {font-size:10px;color:black;font-weight:bold;padding:1px;vertical-align:top;}
					.webskin-tracer-bubble-inner table.webskin-tracer-table td {font-size:10px;color:black;font-weight:normal;padding:1px;vertical-align:top;}
					.webskin-border {background:red;border:2px solid black;display:block;z-index:9998;position:absolute;opacity:0.1;}
					.webskin-tracer-close {cursor:pointer;text-decoration:underline;color:red;}
					.webskin-tracer-link {cursor:pointer;font-size:10px;}
					</style>
				</cfoutput>
			</skin:htmlHead>
			
			
			<cfoutput>
			<div id="tracer" style="display:none;">	
				<cfloop from="1" to="#arrayLen(request.aAncestorWebskinsTrace)#" index="i">
					<div class="webskin-tracer-link" traceid="#request.aAncestorWebskinsTrace[i].traceID#">
						<cfswitch expression="#request.aAncestorWebskinsTrace[i].cacheStatus#">
						<cfcase value="-1">
							<cfset color = "red" />
						</cfcase>
						<cfcase value="1">
							<!--- If the webskin is set to cache but not using objectbroker, then notify with purple flavour. --->
							<cfif structKeyExists(application.stcoapi, request.aAncestorWebskinsTrace[i].typename) AND application.stcoapi[request.aAncestorWebskinsTrace[i].typename].bObjectBroker>
								<cfset color = "green" />
							<cfelse>
								<cfset color = "purple" />
							</cfif>
						</cfcase>
						<cfdefaultcase>
							<cfset color = "black" />
						</cfdefaultcase>
						</cfswitch>
																	
						
						<div style="color:#color#;margin-left:#request.aAncestorWebskinsTrace[i].level * 6#px;">-#request.aAncestorWebskinsTrace[i].typename#: #request.aAncestorWebskinsTrace[i].template# <cfif structKeyExists(request.aAncestorWebskinsTrace[i], "totalTickCount")>(#request.aAncestorWebskinsTrace[i].totalTickCount#s)</cfif></div>
					</div>
				</cfloop>	
			</div>	
			</cfoutput>
			
			<skin:onReady>
			<cfoutput>
				$j('##tracer').dialog({ 
					autoOpen: true,
					width:320,
					height:500,
					title:'Webskin Tracer',
					bgiframe: true 
				}).dialog('option','position',['right','top']);				
				
				$j('div.webskin-tracer-link').click(function() {
						var $id = $j(this).attr('traceid');	
						var $width = 30;
						var $height = 30;
						var $position = {};
						var $positionNode = $j('webskin##' + $id + '-webskin').nextAll().not('webskin');				
						
						
						var $comments = $j('webskin').contents().filter(function() {
					        return this.nodeType == 8;
					    });
					  
						
						
						
						if ($positionNode.length === 0){
							$positionNode = $j('webskin##' + $id + '-webskin').prevAll().not('webskin');
						};					
						
						if ($positionNode.length === 0){
							$positionNode = $j('webskin##' + $id + '-webskin').parents().not('webskin');	
						};		
						if ($positionNode.length === 0){
							$positionNode = $j('body');		
						};
						$position = $positionNode.position();
						$width = $positionNode.width();
						$height = $positionNode.height();
						
						if ($width < 20){$width=120;};
						if ($height < 20){$height=20;};
							
						$j('div.webskin-tracer').each(function (i) {
							$j(this).css('display', 'none');							
						});
						$j('div.webskin-border').each(function (i) {
							$j(this).removeClass("webskin-border").css('display', 'none');
						});	
											
						$j('div##' + $id).css('left', $position.left);
						$j('div##' + $id).css('top', $position.top)	;
						$j('div##' + $id).css('position', 'absolute').css('z-index', '9998').css('display', 'block');		
						$j('div##' + $id + '-webskin-border').addClass("webskin-border").css('width', $width).css('height', $height).css('display', 'block').css('z-index', '9999');
				});	
			</cfoutput>
			</skin:onReady>
		</cfif>
	</cfif>
</cfif>

<cfsetting enablecfoutputonly="false" />