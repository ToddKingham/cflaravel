<cfcomponent>
	
	<CFFUNCTION name="make" access="public" returntype="string">
		<cfargument name="template" type="string" required="true">
		<cfargument name="params" type="struct" required="false" default="#structNew()#">
		<cfset var theTemplate = "/Views/#replace(arguments.template,'.','/')#.cfm">
		<cfset var html = "">
		<cfset var key = "">
		<cfif fileExists(expandPath(theTemplate))>
			<cfsavecontent variable="html">
				<cfloop collection="#arguments.params#" item="key">
					<cfset variables[key] = arguments.params[key]>
				</cfloop>
				<cfinclude template="#theTemplate#">
			</cfsavecontent>
		</cfif>
		<cfreturn html>
	</CFFUNCTION>

</cfcomponent>