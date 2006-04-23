<cfsetting enablecfoutputonly="Yes">
<cfprocessingDirective pageencoding="utf-8">

<cfparam name="url.lObjectIds" default="#attributes.lObjectIDs#">

<cfimport taglib="/farcry/fourq/tags/" prefix="q4">
<cfimport taglib="/farcry/farcry_core/tags/admin/" prefix="admin">


<!--- setup page header --->
<admin:header writingDir="#session.writingDir#" userLanguage="#session.userLanguage#">

<q4:contentobjectGet objectId="#url.lObjectIds#" r_stObject="stObj" />
<cfdump var="#stObj#" label="#stObj.label# Properties">	

<!--- setup page footer --->
<admin:footer>
<cfsetting enablecfoutputonly="No">