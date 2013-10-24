<cfcomponent displayname="Nested Tree Objects" extends="schema" hint="Definition of tree reference table" output="false">
	<cfproperty name="objectid" type="uuid" dbNullable="false" />
	<cfproperty name="parentid" type="uuid" dbNullable="true" dbIndex="true" />
	<cfproperty name="objectname" type="string" dbNullable="false" />
	<cfproperty name="typename" type="string" dbNullable="false" />
	<cfproperty name="nleft" type="integer" dbNullable="false" dbIndex="" />
	<cfproperty name="nright" type="integer" dbNullable="false" dbIndex="" />
	<cfproperty name="nlevel" type="integer" dbNullable="false" />
	
</cfcomponent>