<cfsetting enablecfoutputonly="true">
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
<!--- @@displayname: jQuery tools: Tool Tip --->
<!--- @@description: Displays a tool tip on hover.  --->
<!--- @@author: Matthew Bryant (mbryant@daemon.com.au) --->


<!------------------ 
FARCRY IMPORT FILES
 ------------------>
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfparam name="attributes.id" default="" /><!--- id used to ensure the tooltip is only loaded once per id. --->
<cfparam name="attributes.selector" type="string" /><!--- The id of the dom element that you wish to have the tooltip display on hover. --->
<cfparam name="attributes.message" default="" /><!--- The actual message. This can be replaced with generatedContent --->
<cfparam name="attributes.class" default="tooltip" /><!--- The css class to be assigned to the tooltip div --->
<cfparam name="attributes.style" default="" /><!--- The css style to be assigned to the tooltip div --->
<cfparam name="attributes.configuration" default="predelay:100" /><!--- Specifies the configuration of the tooltip. --->


<cfif thistag.executionMode eq "Start">
	<!--- Do Nothing --->
</cfif>

<cfif thistag.executionMode eq "End">

	<skin:loadJS id="jquery-tooltip" />
	<skin:loadCSS id="jquery-tooltip" />

	<cfif not len(attributes.message)>
		<cfset attributes.message = thisTag.generatedContent />
	</cfif>
	<cfset thisTag.generatedContent = "" />
		
	<cfif not len(attributes.id)>
		<cfset attributes.id = hash(attributes.selector) /><!--- Replace non alphanumeric --->
	</cfif>
	
	
	<!--- 
		This crazy code checking is because of a bug in the tooltip when rendering tips with multiple nodes matching the selector when rendered via ajax.
		We are basically checking to see if a tooltip has already been rendered and if so, do not initialize it again.
	--->
	<skin:onReady id="tooltip-#attributes.id#">
	<cfoutput>
		$j('#attributes.selector#').tooltip({ 
		    delay: 0, 
		    showURL: false, 
		    bodyHandler: function() { 
		        return '#jsStringFormat(attributes.message)#'; 
		    } 
		});
	</cfoutput>
	</skin:onReady>
	
</cfif>



<cfsetting enablecfoutputonly="false">