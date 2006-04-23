<!--- 
|| LEGAL ||
$Copyright: Daemon Pty Limited 1995-2003, http://www.daemon.com.au $
$License: Released Under the "Common Public License 1.0", http://www.opensource.org/licenses/cpl.php$ 

|| VERSION CONTROL ||
$Header: /cvs/farcry/farcry_core/tags/container/containerControl.cfm,v 1.14 2005/08/15 04:46:03 pottery Exp $
$Author: pottery $
$Date: 2005/08/15 04:46:03 $
$Name: milestone_3-0-0 $
$Revision: 1.14 $

|| DESCRIPTION || 
$Description: Edit widget for containers $


|| DEVELOPER ||
$Developer: Paul Harrison (harrisonp@cbs.curtin.edu.au)$

|| ATTRIBUTES ||
$in: $
$out:$
--->

<cfparam name="attributes.objectID" default="">

<cfoutput>
<script>
var popUpWin=0;
function popUpWindow(URLStr, left, top, width, height)
{
  if(popUpWin)
  {
    if(!popUpWin.closed) popUpWin.close();
  }
  popUpWin = open(URLStr, 'popUpWin', 'toolbar=no,location=no,directories=no,status=no,scrollbars=yes,resizable=yes,copyhistory=yes,width='+width+',height='+height+',left='+left+', top='+top+',screenX='+left+',screenY='+top+'');
  popUpWin.focus();
}
	
</script>

<style type="text/css">
.container-edit {font: 95% arial,helvetica,sans-serif;width:auto;height:auto;clear:both;position: relative;margin: 15px 5px 15px 0}
.container-edit a, .container-edit a:link, .container-edit a:visited, .container-edit a:hover, .container-edit a:active {display:block;text-decoration:none;color:##333;display:block;padding: 17px 0 14px;background: transparent url("#application.url.farcry#/css/images/container_edit_2.gif") repeat-x 0 0}
.container-edit a:hover {color:##715200;background: transparent url("#application.url.farcry#/css/images/container_edit_2.gif") repeat-x 0 -50px}
.container-edit strong {margin-left: 50px}
.container-edit .spanner {position:absolute;top:3px;left:0;display:block;width:40px;height:40px;background: url("#application.url.farcry#/css/images/container_edit_icon.png");_background-image: none;-filter: progid:DXImageTransform.Microsoft.AlphaImageLoader(enabled=true, sizingMethod=scale, src='#application.url.farcry#/css/images/container_edit_icon.png')}
</style>

</cfoutput>
<cfoutput>
<cfset Attributes.label = reReplaceNoCase(attributes.label,"$*.*_","")>
<div class="container-edit">
	<a href="##" onclick="popUpWindow('#application.url.farcry#/navajo/container_index.cfm?containerID=#attributes.objectID#',100,200,620,550);return false;"><strong>EDIT:</strong> #attributes.label#<span class="spanner"></span></a>
</div>	
</cfoutput>	