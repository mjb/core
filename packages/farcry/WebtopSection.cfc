<!--- {{{ jEdit Modes
:mode=coldfusion:
:collapseFolds=1:
:noTabs=true:
:tabSize=4:
:indentSize=4:
}}} --->
<!--- {{{
|| LEGAL ||
$Copyright: (C) 2005 The University of Texas at Austin, http://www.utexas.edu $
$License: Released Under the "Common Public License 1.0", http://www.opensource.com/licenses/cpl.php$

|| DESCRIPTION ||
$Description: Represents a webtop configuration, can merge with other webtop roots, and translate to and from xml. $

|| DEVELOPER ||
$Developer: Tyler Ham (tylerh@austin.utexas.edu)$
}}} --->

<cfcomponent displayname="Webtop Section"
  hint="Represents a webtop section, can merge with another section,
  and translate to and from xml.">
  
  <cfset this.isInitialized = "false">
  <cfset this.stAttributes = StructNew()>
  <cfset this.aSubsections = ArrayNew(1)>
  
  <!--- default mergeType of a section is 'merge' --->
  <!--- other possible values: 'mergeNoReplace', 'replace', 'none' --->
  <!--- see WebtopRoot.cfc for more info on mergeTypes --->
  <cfset this.stAttributes.mergeType = "merge">
  
<!--- {{{ PACKAGE functions --->


<!--- {{{ package init(SectionXmlElement) --->
<cffunction name="init" access="package" output="no" returnType="WebtopSection"
  hint="initializes this WebtopSection with data from the given section XmlElement
  from a webtop xml file.">
  
  <cfargument name="SectionXmlElement" required="true"
    hint="webtop section XmlElement">
  
  <cfset var i = "">
  <cfset var attrib = "">
  <cfset var newChild = "">
  
  <!--- if anything is bad, simply return this --->
  <!--- isInitialized is still false, so getXml will --->
  <!--- just return empty string --->
  
  <!--- make sure the argument is an xml element --->
  <cfif not isXmlElem(arguments.SectionXmlElement)>
    <cfreturn this>
  </cfif>
  
  <!--- make sure XmlName is 'section' --->
  <cfif not arguments.SectionXmlElement.XmlName is "section">
    <cfreturn this>
  </cfif>
  
  <!--- ok, everything SEEMS ok, lets get the attributes --->
  <cfloop index="attrib" list="#StructKeyList(arguments.SectionXmlElement.XmlAttributes)#">
    <cfset this.stAttributes[attrib] = arguments.SectionXmlElement.XmlAttributes[attrib]>
  </cfloop>
  
  <!--- get the xml children --->
  <cfloop index="i" from="1" to="#ArrayLen(arguments.SectionXmlElement.XmlChildren)#">
    <cfinvoke component="WebtopSubsection" method="init" returnVariable="newChild">
      <cfinvokeargument name="SubsectionXmlElement" value="#arguments.SectionXmlElement.XmlChildren[i]#">
    </cfinvoke>
    <cfset ArrayAppend(this.aSubsections, newChild)>
  </cfloop>
  
  <!--- we are officially initialized, now getXml will work --->
  <cfset this.isInitialized = "true">
  
  <cfreturn this>
</cffunction>
<!--- }}} package init(SectionXmlElement) --->


<!--- {{{ package mergeSection(WebtopSection section2) --->
<cffunction name="mergeSection" access="package" output="no" returnType="void"
  hint="merges the given section2 onto this section, following any specified
  mergeType rules.  See WebtopRoot.cfc for more information about mergeType.
  Assuming section1 and section2 match (have same id).">
  
  <cfargument name="section2" type="WebtopSection" required="true"
    hint="section to merge into this one">
  
  <!--- comment note: section1 means THIS --->
  
  <!--- if mergeType='none' on section1, it cannot be replaced or merged --->
  <cfif this.stAttributes.mergeType is "none">
    <cfreturn>
  </cfif>
  
  <cfswitch expression="#arguments.section2.stAttributes.mergeType#">
    <cfcase value="replace">
      <!--- replace ALL data about section1 with that of section2 --->
      <!--- ?? should we maintain the same mergeType, though?? -TH --->
      <cfset this.stAttributes = arguments.section2.stAttributes>
      <cfset this.aSubsections = arguments.section2.aSubsections>
    </cfcase>
    
    <cfcase value="merge">
      <!--- append section2.stAttributes to section1.stAttributes --->
      <!--- replace if duplicate keys --->
      <!--- normal merge/replace operation on children --->
      <cfset StructAppend(this.stAttributes, arguments.section2.stAttributes, "yes")>
      <cfset mergeChildren(arguments.section2)>
    </cfcase>
    
    <cfcase value="mergeNoReplace">
      <!--- append section2.stAttributes to section1.stAttributes --->
      <!--- do not replace duplicate keys --->
      <!--- normal merge/replace operation on children --->
      <cfset StructAppend(this.stAttributes, arguments.section2.stAttributes, "no")>
      <cfset mergeChildren(arguments.section2)>
    </cfcase>
    
    <cfdefaultcase> <!--- this will catch "none" values --->
      <!--- what should we do with strange mergeTypes? or "none"s? --->
      <!--- (remember, section1.id = section2.id - we assume this in here) --->
      <!--- How about "merge" as default for sections? -TH --->
      <cfset StructAppend(this.stAttributes, arguments.section2.stAttributes, "yes")>
      <cfset mergeChildren(arguments.section2)>
    </cfdefaultcase>
  </cfswitch>
  
</cffunction>
<!--- }}} package mergeSection(WebtopSection section2) --->


<!--- {{{ package getXml() --->
<cffunction name="getXml" access="package" output="no" returnType="string"
  hint="returns xml of this webtop element as a string">
  
  <cfset var sOutput = "">
  <cfset var i = "">
  
  <!--- if we were not initialized with a proper SectionXmlElement, --->
  <!--- just return empty string--->
  <!--- this ought to do the least amount of harm --->
  <cfif not this.isInitialized>
    <cfreturn sOutput>
  </cfif>
  
  <!--- this call takes the struct and returns a string that looks like --->
  <!--- 'key="value" key="value" ...' --->
  <cfinvoke component="WebtopRoot" method="toAttributeString" returnVariable="sOutput" stAttributes="#this.stAttributes#">
  <cfset sOutput = "<section " & sOutput & " >">
  
  <!--- add the children --->
  <cfloop index="i" from="1" to="#ArrayLen(this.aSubsections)#">
    <cfset sOutput = sOutput & " " & this.aSubsections[i].getXml()>
  </cfloop>
  
  <!--- add the close tag --->
  <cfset sOutput = sOutput & " </section>">
  
  <cfreturn sOutput>
</cffunction>
<!--- }}} package getXml() --->


<!--- }}} PACKAGE functions --->


<!--- {{{ PRIVATE functions --->

<!--- {{{ private mergeChildren(WebtopSection section2) --->
<cffunction name="mergeChildren" access="private" output="no" returnType="void"
  hint="merges the children of section2 into the children of this section,
  following any specified mergeType rules.  See WebtopRoot.cfc for more information
  about mergeType.">
  
  <cfargument name="section2" type="WebtopSection" required="true"
    hint="section whose children to merge with this one">
  
  <cfset var i = "">
  
  <!--- comment note: section1 means THIS --->
  
  <!--- loop through and merge each child (passing the buck again!) --->
  <cfloop index="i" from="1" to="#ArrayLen(arguments.section2.aSubsections)#">
    <cfset mergeChild(arguments.section2.aSubsections[i])>
  </cfloop>
  
</cffunction>
<!--- }}} private mergeChildren(WebtopSection section2) --->


<!--- {{{ private mergeChild(WebtopSubsection child) --->
<cffunction name="mergeChild" access="private" output="no" returnType="void"
  hint="merges the child into aSubsections">
  
  <cfargument name="child" type="WebtopSubsection" required="true"
    hint="subsection to merge into this sections's children">
  
  <cfset var i = "">
  <cfset var matchFound = "false">
  
  <!--- we must have an id to match, otherwise, no point in looking --->
  <cfif StructKeyExists(arguments.child.stAttributes, "id")>
    <!--- does the same child exist in this menu? --->
    <!--- ID will match, if so --->
    <cfloop index="i" from="1" to="#ArrayLen(this.aSubsections)#">
      <!--- id attribute must be present and must match --->
      <cfif StructKeyExists(this.aSubsections[i].stAttributes, "id")
        and this.aSubsections[i].stAttributes.id is arguments.child.stAttributes.id>
        
        <!--- set matchFound=true so we don't append the child later --->
        <cfset matchFound = "true">
        
        <!--- they match, so merge them --->
        <cfset this.aSubsections[i].mergeSubsection(arguments.child)>
        
        <!--- no need to keep looping --->
        <cfbreak>
      </cfif>
    </cfloop>
    
  </cfif>
  
  <cfif not matchFound>
    <!--- a match was not found, so we should append the menuitem --->
    <cfset ArrayAppend(this.aSubsections, arguments.child)>
  </cfif>
  
</cffunction>
<!--- }}} private mergeChild(WebtopSubsection child) --->


<!--- }}} PRIVATE functions --->


</cfcomponent>
