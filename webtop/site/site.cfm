
<cfimport taglib="/farcry/core/tags/webskin" prefix="skin" />

<cfoutput>
<div class="row">

	<div class="span3">
		<div id="sidebar">
			<iframe src="/webtop/site/sidebar.cfm?__allowredirect=true&amp;SUB=tree&amp;updateapp=false&amp;sec=site" 
					name="sidebar" 
					scrolling="auto" 
					frameborder="0"
					style="width:100%;"
					id="iframe-sidebar"></iframe>
		</div>
	</div>
	
	<div class="span9">
		<div id="content">
			<iframe src="/webtop/inc/content_overview.html?__allowredirect=true&amp;SUB=tree&amp;updateapp=false&amp;sec=site" 
					name="content" 
					scrolling="auto" 
					frameborder="0" 
					style="width:100%;"
					id="iframe-content"></iframe>
		</div>
	</div>
</div>
</cfoutput>


<skin:onReady>
<cfoutput>
	$('##iframe-sidebar').css('height', $(window).height() - 210);
	$('##iframe-content').css('height', $(window).height() - 210);
</cfoutput>
</skin:onReady>