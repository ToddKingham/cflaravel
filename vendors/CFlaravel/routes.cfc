component {
	/* SET UP SOME VARIABLES */
	VARIABLES.filters = {};

	VARIABLES.matched_filters = {
		before = [],
		after = [],
		auth = [],
		value = ""
	};

	VARIABLES.route_prefix = "";

	VARIABLES.matched_route = "I will become a struct when a route is matched";

	/* PUBLIC ROUTE METHODS */
	public void function get(string path, any controller){
		setRoute('get',ARGUMENTS.path,ARGUMENTS.controller);
	}
	
	public void function post(string path, any controller){
		setRoute('post',ARGUMENTS.path,ARGUMENTS.controller);
	}
	
	public void function put(string path, any controller){
		setRoute('put',ARGUMENTS.path,ARGUMENTS.controller);
	}
	
	public void function patch(string path, any controller){
		setRoute('patch',ARGUMENTS.path,ARGUMENTS.controller);
	}
	
	public void function delete(string path, any controller){
		setRoute('delete',ARGUMENTS.path,ARGUMENTS.controller);
	}
	
	public void function any(string path, any controller){
		setRoute(REQUEST.data.method,ARGUMENTS.path,ARGUMENTS.controller);
		
	}

	public void function group(struct actions, function cb){
		for(var key in ARGUMENTS.actions){
			switch(key) {
			    case "prefix":
			    	VARIABLES.route_prefix = listAppend(VARIABLES.route_prefix,ARGUMENTS.actions[key],"/");
		    	break;

			    case "before":
			    	var the_filter = listFirst(ARGUMENTS.actions[key],":");
			     	if(structKeyExists(VARIABLES.filters,the_filter)){
			    		 arrayAppend(VARIABLES.matched_filters.before,VARIABLES.filters[the_filter]);
			    		 if(listLen(ARGUMENTS.actions[key],":") GT 1){
			    		 	VARIABLES.matched_filters.value = listLast(ARGUMENTS.actions[key],":");
			    		 }
			       	}
			    break;  

			    case "after":
			     	var the_filter = listFirst(ARGUMENTS.actions[key],":");
			     	if(structKeyExists(VARIABLES.filters,the_filter)){
			    		 arrayAppend(VARIABLES.matched_filters.after,VARIABLES.filters[the_filter]);
			       	}
			    break;   
			}	
		}
		ARGUMENTS.cb();
		for(var x in VARIABLES.matched_filters){
			if(isArray(VARIABLES.matched_filters[x])){
				VARIABLES.matched_filters[x] = [];
			} else {
				VARIABLES.matched_filters[x] = "";
			}
		}
		VARIABLES.route_prefix = "";
	}

	public void function filter(string key, function action){
		VARIABLES.filters[ARGUMENTS.key] = ARGUMENTS.action;
	}

	/* PRIVATE HELPER FUNCTIONS */
	private void function setRoute(string verb, string path, any controller){
		var current_route = listAppend(VARIABLES.route_prefix,ARGUMENTS.path,"/");
		var regex = '^' & REREPLACENOCASE(current_route,'({[a-z0-9-_ ]+})','[a-z0-9-_ ]+',"all") & '$';

		if((REQUEST.data.method EQ ARGUMENTS.verb) AND (ReFindNoCase(regex,REQUEST.route))){

			//set the matched route
			VARIABLES.matched_route = {
				controller = ARGUMENTS.controller,
				filters = duplicate(VARIABLES.matched_filters),
				match = current_route
			};

			//process any slugs
			var route_array = listToArray(current_route,'/');
			var url_array = listToArray(REQUEST.route,'/');
			for(var key in REmatch('{[^}]*}',current_route)){
				REQUEST.parameters[rereplace(key,'[{}]','','all')] = url_array[arrayFindNoCase(route_array,key)];
			}
		}
	}

	private any function formatResponse(result){
		if( NOT isSimpleValue(result)) {
			getpagecontext().getresponse().setcontenttype('application/json; charset=utf-8');
			result = serializeJSON(result);
		}else if(isXML(result)){
			getpagecontext().getresponse().setcontenttype('application/xml; charset=utf-8');
		}
		return result;
	};

	/* THE MAIN DADDY! GET'S CALLED ONCE FROM WITHIN THE FRAMEWORK */
	public any function process(string verb, string path){  
		var result = false;

		if( isStruct(VARIABLES.matched_route) ) {

			//PROCESS ANY BEFORE FILTERS
			var filter_result = false;
			var the_filter = '';
			for(var i=1;i LTE arrayLen(VARIABLES.matched_route.filters.before) ;i++){
				the_filter = VARIABLES.matched_route.filters.before[i];
				filter_result = the_filter(REQUEST.route,REQUEST,VARIABLES.matched_route.filters.value);
		 		if( isDefined('filter_result') AND NOT isBoolean(filter_result) ){
		 			return formatResponse(filter_result);
	    			//location(url="/#filter_result#", addtoken="false");
	    		}
			}

			//PROCESS THE ROUTE
			var theController = VARIABLES.matched_route.controller;
			if( isSimpleValue(theController)) {
				result = invoke(
					"/controllers/#ListFirst(theController,"@")#",
					ListLast(theController,"@"),
					{argumentCollection=Request.all()}
				);
			}else if( isClosure(theController) ){
				result = theController(argumentCollection=Request.all());
			}

			//PROCESS ANY AFTER FILTERS
			var filter_result = false;
			var the_filter = '';
			for(var i=1;i LTE arrayLen(VARIABLES.matched_route.filters.after) ;i++){
				the_filter = VARIABLES.matched_route.filters.after[i];
				result = the_filter(REQUEST.route,REQUEST,result);
		 	}

			//RETURN THE RESPONSE
			if( NOT isSimpleValue(result)) {
				getpagecontext().getresponse().setcontenttype('application/json; charset=utf-8');
				result = serializeJSON(result);
			}else if(isXML(result)){
				getpagecontext().getresponse().setcontenttype('application/xml; charset=utf-8');
			}
			
			return formatResponse(result);
		
		}
	}
}