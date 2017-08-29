<cfscript>
	//SET RESPONSE
	RESPONSE = getPageContext().getResponse();

	//PREPARE THE REQUEST SCOPE
	REQUEST.route = "";
	REQUEST.routeprefix = "";
	REQUEST.body = "";
	REQUEST.data = getHttpRequestData();
	REQUEST.parameters = URL;
	structAppend(REQUEST.parameters,FORM);
	param name="REQUEST.data.Headers['Content-Type']" default="text/plain; charset=UTF-8";
	REQUEST.input = function(k,d=""){
		param name="REQUEST.parameters.#k#" default="#d#";
		return REQUEST.parameters[ARGUMENTS.k];
	};
	REQUEST.has = function(k){
		return StructKeyExists(REQUEST.parameters,ARGUMENTS.k);
	};
	REQUEST.all = function(){
		return REQUEST.parameters;
	};
	REQUEST.only = function(){
		var r = {};
		var list = ArgumentsArray(ARGUMENTS);
		for(var i=1;i LTE ArrayLen(list);i++){
			if(structKeyExists(REQUEST.parameters,list[i])){
				r[list[i]] = REQUEST.parameters[list[i]];
			}
		}
		return r;
	};
	REQUEST.except = function(){
		var r = duplicate(REQUEST.parameters);
		var list = ArgumentsArray(ARGUMENTS);
		for(var i=1;i LTE ArrayLen(list);i++){
			if(structKeyExists(REQUEST.parameters,list[i])){
				structDelete(r,list[i]);
			}
		}
		return r;
	};
	REQUEST.json = function(){
		return false;
	};
	REQUEST.header = function(header){
		var result = false;
		if(structKeyExists(REQUEST.data.headers, arguments.header)){
			result = REQUEST.data.headers[arguments.header];
		}
		return result;
	}

	private function ArgumentsArray(struct args){
		var r = [];
		if(structCount(args) GT 0 AND isArray(args[1])){
			r = args[1];
		}else{
			for(var x in args){
				arrayAppend(r,args[X]);
			}
		}
		return r;
	};
	
	//FOR CLIENTS THAT DON'T SUPPORT "PUT/PATCH/DELETE/etc..." (perhaps this is over reaching and should be moved into the RESOURCE route logic once implimented.
	if( structKeyExists(URL, "method") ){
		REQUEST.data.method = ucase(url.method);
	}

	//GET THE ORIGINAL URL (SOME SERVERS USE cgi.REDIRECT_URL others pass it as the request header X-Original-URL)
	if( structKeyExists(URL,'X-Original-URL') ){
		ORIGINAL_URL = URL['X-Original-URL'];
		structDelete(URL,'X-Original-URL');
	} else if( structKeyExists(REQUEST.data.headers, "X-Original-URL") ){
		ORIGINAL_URL = ListFirst(REQUEST.data.headers["X-Original-URL"],'?');
	}else{
		ORIGINAL_URL = cgi.REDIRECT_URL;
	}

	//FIND THE REQUEST ROUTE
	REQUEST.route = replace(ORIGINAL_URL,'/','');
	//REQUEST.route = replaceNoCase(ORIGINAL_URL,getDirectoryFromPath(cgi.SCRIPT_NAME),'');
	if( NOT len(trim(REQUEST.route)) ){
		REQUEST.route = "";
	}

	//PARSE THE REQUEST BODY
	if( REQUEST.data.method NEQ "GET" ){
		REQUEST.body = REQUEST.data.content;
	}

	if( findNoCase("application/json", REQUEST.data.Headers["Content-Type"]) ){
		if( isBinary(REQUEST.body) ){
			REQUEST.body = toString(REQUEST.body);
		}
		if( isJSON(REQUEST.body) ){
			REQUEST.json = function(){
				return deserializeJSON(REQUEST.body);
			};
		}else{
			RESPONSE.setStatus("400");
			writeOutput("ERROR! EXPECTED JSON");
			abort;
		}
	}

	//PROCESS THE REQUEST
	function redirect(r){
		if(request.route NEQ r){ //this prevents infinte loops
			location(url="/#r#", addtoken="false");
			result = {"type":"redirect","route:":r};
		}
	};

	Route = CreateObject("component","CFlaravel.routes").init(REQUEST.data.method,REQUEST.route);
	View = CreateObject("component","CFlaravel.views");
	include "../app/filters.cfm";
	include "../app/routes.cfm";
	result = Route.process(REQUEST.data.method,REQUEST.route);
	if( result EQ "nil" ){
		RESPONSE.setStatus("404");
		//TODO: MAKE THIS BETTER
		result = "404 Not Found";

	}

	//OUTPUT THE RESPONSE
	writeOutput(result);
</cfscript>