component {
	/* SET UP SOME variables */
	variables.filters = {};
	variables.matched_filters = {
		before = [],
		after = [],
		auth = [],
		value = ""
	};
	variables.route_prefix = "";
	variables.matched_route = "I will become a struct when a route is matched";
	variables.response = getPageContext().getResponse();
		

	/* PUBLIC ROUTE METHODS */
	public void function get(string path, any controller){
		setRoute('get',arguments.path,arguments.controller);
	}
	
	public void function post(string path, any controller){
		setRoute('post',arguments.path,arguments.controller);
	}
	
	public void function put(string path, any controller){
		setRoute('put',arguments.path,arguments.controller);
	}
	
	public void function patch(string path, any controller){
		setRoute('patch',arguments.path,arguments.controller);
	}
	
	public void function delete(string path, any controller){
		setRoute('delete',arguments.path,arguments.controller);
	}
	
	public void function any(string path, any controller){
		setRoute(request.data.method,arguments.path,arguments.controller);
	}

	public void function resource(string path, string controller, struct filter={}){
		var contr = listFirst(arguments.controller,'@');
		var actions = ['index','store','show','update','destroy'];

		if(structKeyExists(arguments.filter, 'except') AND isArray(arguments.filter.except)){
			for(var filter_index in arguments.filter.except){
				var action_index = ArrayFindNoCase( actions, filter_index );
				if(action_index){
					arrayDeleteAt(actions,action_index);
				}
			}
		}

		if(structKeyExists(arguments.filter, 'only') AND isArray(arguments.filter.only)){
			actions = arguments.filter.only;
		}

		if(ArrayFindNoCase( actions, 'index' )){
			setRoute("get",arguments.path,contr&"@index");
		}
		if(ArrayFindNoCase( actions, 'store' )){
			setRoute("post",arguments.path,contr&"@store");
		}
		if(ArrayFindNoCase( actions, 'show' )){
			setRoute("get",arguments.path&"/{resource}",contr&"@show");
		}
		if(ArrayFindNoCase( actions, 'update' )){
			setRoute("put",arguments.path&"/{resource}",contr&"@update"); 
			setRoute("patch",arguments.path&"/{resource}",contr&"@update");
		}
		if(ArrayFindNoCase( actions, 'destroy' )){
			setRoute("delete",arguments.path&"/{resource}",contr&"@destroy");
		}
	}

	public void function group(struct actions, function cb){
		var isPrefix = false;
		for(var key in arguments.actions){
			switch(key) {
			    case "prefix":
			    	variables.route_prefix = listAppend(variables.route_prefix,arguments.actions[key],"/");
			    	isPrefix = true;
			    break;

			    case "before":
			    	var the_filter = listFirst(arguments.actions[key],":");
			     	if(structKeyExists(variables.filters,the_filter)){
			    		 arrayAppend(variables.matched_filters.before,variables.filters[the_filter]);
			    		 if(listLen(arguments.actions[key],":") GT 1){
			    		 	variables.matched_filters.value = listLast(arguments.actions[key],":");
			    		 }
			       	}
			    break;  

			    case "after":
			     	var the_filter = listFirst(arguments.actions[key],":");
			     	if(structKeyExists(variables.filters,the_filter)){
			    		 arrayAppend(variables.matched_filters.after,variables.filters[the_filter]);
			       	}
			    break;   
			}	
		}

		arguments.cb();

		for(var x in variables.matched_filters){
			if(isArray(variables.matched_filters[x])){
				variables.matched_filters[x] = [];
			} else {
				variables.matched_filters[x] = "";
			}
		}

		if(isPrefix){
			var chunk_len = len(variables.route_prefix) - len(arguments.actions.prefix);
			if(chunk_len){
				variables.route_prefix = left(variables.route_prefix, chunk_len-1);
			} else {
				variables.route_prefix = '';
			}
		}
	}

	public void function filter(string key, function action){
		variables.filters[arguments.key] = arguments.action;
	}

	/* THE MAIN DADDY! GET'S CALLED ONCE FROM WITHIN THE FRAMEWORK */
	public any function process(string verb, string path){  
		var result = false;


		if( isStruct(variables.matched_route) ) {

			//PROCESS ANY BEFORE FILTERS
			var filter_result = false;
			var the_filter = '';
			for(var i=1;i LTE arrayLen(variables.matched_route.filters.before) ;i++){
				the_filter = variables.matched_route.filters.before[i];
				filter_result = the_filter(request.route,request,variables.matched_route.filters.value);
		 		if( isDefined('filter_result') AND NOT isBoolean(filter_result) ){
		 			return formatResponse(filter_result);
	    			//location(url="/#filter_result#", addtoken="false");
	    		}
			}

			//PROCESS THE ROUTE
			var theController = variables.matched_route.controller;
			var controllerArgs = {};
			var requestBody = request.json();

			if(isStruct(requestBody)){
				structAppend(controllerArgs,requestBody);
			}structAppend(controllerArgs,request.all());
			
				
			if( isSimpleValue(theController)) {
				result = invoke(
					"/controllers/#ListFirst(theController,"@")#",
					ListLast(theController,"@"),
					{argumentCollection=controllerArgs}
				);
			}else if( isClosure(theController) ){
				result = theController(argumentCollection=controllerArgs);
			}

			param name="result" default="";

			//PROCESS ANY AFTER FILTERS
			var filter_result = false;
			var the_filter = '';
			for(var i=1;i LTE arrayLen(variables.matched_route.filters.after) ;i++){
				the_filter = variables.matched_route.filters.after[i];
				result = the_filter(request.route,request,result);
		 	}

			//RETURN THE RESPONSE
			return formatResponse(result);
		
		}
	}

	private void function setRoute(string verb, string path, any controller){
		var current_route = variables.route_prefix;
		if( (arguments.path NEQ '/') OR (!len(variables.route_prefix) )){
			current_route = listAppend(variables.route_prefix,arguments.path,"/");
		}

		var regex = '^' & REREPLACENOCASE(current_route,'({[a-z0-9-_ ]+})','[a-z0-9-_ ]+',"all") & '$';
		if((request.data.method EQ arguments.verb) AND (ReFindNoCase(regex,request.route))){

			//set the matched route
			variables.matched_route = {
				controller = arguments.controller,
				filters = duplicate(variables.matched_filters),
				match = current_route
			};

			//process any slugs
			var route_array = listToArray(current_route,'/');
			var url_array = listToArray(request.route,'/');
			for(var key in REmatch('{[^}]*}',current_route)){
				request.parameters[rereplace(key,'[{}]','','all')] = url_array[arrayFindNoCase(route_array,key)];
			}
		}
	}

	private any function formatResponse(result){
		if( NOT isSimpleValue(result)) {
			variables.response.setcontenttype('application/json; charset=utf-8');
			result = serializeJSON(result);
		}else if(isXML(result)){
			variables.response.setcontenttype('application/xml; charset=utf-8');
		}
		return result;
	};
}