(function(){tinymce.PluginManager.requireLangPack('fct');tinymce.create('tinymce.plugins.fctPlugin',{init:function(ed,url){ed.addCommand('mceFCT',function(){ed.windowManager.open({file:url+'/popup.cfm?objectid',width:500+parseInt(ed.getLang('fct.delta_width',0)),height:400+parseInt(ed.getLang('fct.delta_height',0)),inline:1},{plugin_url:url,some_custom_arg:'custom arg'})});ed.addButton('fct',{title:'fct.desc',cmd:'mceFCT',image:url+'/img/fct.gif'});ed.onNodeChange.add(function(ed,cm,n){cm.setActive('fct',n.nodeName=='IMG')})},createControl:function(n,cm){return null},getInfo:function(){return{longname:'FCT plugin',author:'Some author',authorurl:'http://tinymce.moxiecode.com',infourl:'http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/fct',version:"1.0"}}});tinymce.PluginManager.add('fct',tinymce.plugins.fctPlugin)})();