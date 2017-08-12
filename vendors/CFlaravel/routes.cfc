component {   
/*
    NOTES: we create a set of "verb functions": get(), post(), etc... and we set them to empty functions. On init() we 
    determine the request method, match it to one of the verb functions, and alias that funtion to any() which is the
    function that does the actual work. In this way we prevent extrainous pocessing from Route declarations that have 
    no chance of matching. ie... A GET /v1/dogs  request to the server could never match a Route.post() route so why 
    attempt to process it.
*/
    variables.target_verb = ""; //I'm a local copy of the actual request method passed to the server in the request.
    variables.target_route = ""; //I'm a local copy of the actual route passed to the server in the request.
    variables.filters = {}; //I will hold all of the global filters defined via Route.filter().
    variables.when_filters = {}; //I will hold the filters passed in on the when() function until they are matched and ready to go into the variables.route.filtes object.
    variables.route = {
        is_matched = false, //becomes True when we match a route.
        path: "", //I will hold the concatinated path once a match has been made.
        prefix: "", //I'm a concatination of prefixes and route paths (helps Route.group>prefix actually work)
        action: "", //this will be a controller reference: MyController@SomeMethod  or a Closure.
        slugs: {}, //I will hold all the slug values for the matched route.
        filters: {before: [], after: [], auth: "", value: ""} //I will hold all the requested filters for the matched route to be executed in process()
    }

    this.input = variables.route.slugs; //I will be an object of slugs

    public function init(string verb, string route){
        variables.target_verb = arguments.verb;
        variables.target_route = arguments.route;
        this[variables.target_verb] = this.any; //alias the appropriate "verb" function.
        return this;
    }

    /*** ROUTING FUNCTIONS ***/
        public function get(){} //will get aliased to any() from init() on appropriate requests.
        public function post(){} //will get aliased to any() from init() on appropriate requests.
        public function put(){} //will get aliased to any() from init() on appropriate requests.
        public function patch(){} //will get aliased to any() from init() on appropriate requests.
        public function delete(){} //will get aliased to any() from init() on appropriate requests.
        public function resource(string path, any controller, struct filter={}){
            var ctrlr = listFirst(arguments.controller, '@');
            var actions = ['index', 'store', 'show', 'update', 'destroy'];

            if(structKeyExists(arguments.filter, 'only') AND isArray(arguments.filter.only)){
                actions = arguments.filter.only;
            } 

            if(structKeyExists(arguments.filter, 'except') AND isArray(arguments.filter.except)){
                for(var filter_index in arguments.filter.except){
                    var action_index = ArrayFindNoCase( actions, filter_index );
                    if(action_index){
                        arrayDeleteAt(actions, action_index);
                    }
                }
            }
            if(ArrayFindNoCase( actions, 'index' )){
                this.get(arguments.path, ctrlr&"@index");
            }
            if(ArrayFindNoCase( actions, 'store' )){
                this.post(arguments.path, ctrlr&"@store");
            }
            if(ArrayFindNoCase( actions, 'show' )){
                this.get(arguments.path&"/{resource}", ctrlr&"@show");
            }
            if(ArrayFindNoCase( actions, 'update' )){
                this.put(arguments.path&"/{resource}", ctrlr&"@update"); 
                this.patch(arguments.path&"/{resource}", ctrlr&"@update");
            }
            if(ArrayFindNoCase( actions, 'destroy' )){
                this.delete(arguments.path&"/{resource}", ctrlr&"@destroy");
            }
        }
        public function any(string path, any controller){
            
            

            if(listLen(arguments.path, '/')+listLen(variables.route.prefix, '/') EQ listLen(variables.target_route, '/')){
                variables.route.is_matched = appendRegexRoute(arguments.path);
                if(variables.route.is_matched){
                    variables.route.action = arguments.controller;
                    variables.route.path = variables.route.prefix;
                    this.input = variables.route.slugs;
                    
                    //once we get a match, set these back to empty functions to stop extra processing
                    this[variables.target_verb] = function(){};
                    this.group = function(){};
                } 
            }
        }
    /*** /ROUTING FUNCTIONS ***/

    /*** GROUPING AND FILTER FUNCTIONS ***/
        public function filter(string key, function cb){ //I add filters to the variables.filte object when a filter is envoked via the Route.filter() function.
            variables.filters[arguments.key] = arguments.cb;
        }
        public function when(string path, string filter, array except=[]){ //I add filters to the variables.when_filtes object when a filter is envoked via the Route.when() function. when we process the route, this filtes will become Before:filters
            if(NOT arrayFindNoCase(arguments.except, variables.target_verb)){
                variables.when_filters[arguments.path] = arguments.filter;
            }
        }
        public function group(struct actions, function cb){ //I add prefixes and before/after filtes to the variables.route object when Route.group() is called.
            var success = false;
            var filter_name = "";
            for(var action in arguments.actions){
                switch(action){
                    case "prefix":
                        if(appendRegexRoute(actions[action])){
                            arguments.cb(argumentCollection = variables.route.slugs);
                            variables.route.prefix = "";
                        }
                    break;

                    case "before":
                    case "after":
                        filter_name = listFirst(arguments.actions[action],":");
                        arrayPrepend(variables.route.filters[action], filter_name);

                        if(listLen(arguments.actions[action],":") EQ 2){
                            variables.route.filters.value = listLast(arguments.actions[action],":");
                        }

                        arguments.cb(argumentCollection = variables.route.slugs);
                        if(NOT variables.route.is_matched){
                            variables.route.filters = {before: [], after: [], auth: "", value: ""};
                        }
                    break;
                }
            }
        }
    /*** /GROUPING AND FILTER FUNCTIONS ***/
    
    /*** MAIN FUNCTION: this is called from within the framework index.cfm file. It makes all the magic happen ***/
        public function process(){
            appendWhenFilters();
            var result = "";
            if(variables.route.is_matched){
                // PROCESS BEFORE FILTERS
                var filter_result = false;
                var filter_args = {};
                for(var before in variables.route.filters.before){
                    filter_args = {
                        $route: variables.target_route,
                        $request: request,
                        $value: variables.route.filters.value
                    };
                  filter_result = variables.filters[before](argumentCollection=filter_args);
                  bypass_route = NOT (isNull(filter_result) OR (isBoolean(filter_result) AND NOT filter_result));
                  if( bypass_route ){
                   return formatResponse(filter_result);
                  }
                }

                // PROCESS THE ROUTE
                if( isSimpleValue(variables.route.action)) {
                    result = invoke(
                        "/controllers/#ListFirst(variables.route.action, "@")#", 
                        ListLast(variables.route.action, "@"), 
                        {argumentCollection=variables.route.slugs}
                    );
                }else if( isClosure(variables.route.action) ){
                    result = variables.route.action(argumentCollection=variables.route.slugs);
                }

                // PROCESS AFTER FILTERS
                var filter_args = {};
                for(var after in variables.route.filters.after){
                    filter_args = {
                        $route: variables.target_route,
                        $request: request,
                        $response: result
                    };
                  filter_result = variables.filters[after](argumentCollection=filter_args);
                  if(NOT isNull(filter_result)){
                    result = filter_result;
                  }
                  
                }
            }
            if(NOT variables.route.is_matched){
                result = 'nil';
            }
            return formatResponse(result);
        }
    /*** /MAIN FUNCTION ***/

    /*** PRIVATE FUNCTIONS ***/
        private function appendRegexRoute(string str){ 
            var result = false;
            var prefix = variables.route.prefix;
                if(arguments.str NEQ "/"){ //to prevent "base routes" adding an extra "/" to our path we will pretend they don't exist by only concatinating the path to the prefix when it isn't a base route.
                    prefix = listAppend(prefix, arguments.str, "/");
                }
            var prefix_len = listLen(prefix, '/');

            if(prefix_len <= listLen(variables.target_route, '/')){
                var regex = '^' & REreplaceNoCase(prefix, '({[a-z0-9-_ ]+})', '[a-z0-9-_ ]+', "all") & '$';
                var target_segment = "";
                for(var i=1;i<=prefix_len;i++){
                    target_segment = listAppend(target_segment, listGetAt(variables.target_route, i, '/'), '/');
                }
                
                if((prefix EQ variables.target_route) OR REFindNoCase(regex, target_segment) ){ //exact match or pattern match
                    result = true;
                    variables.route.prefix = prefix;

                    listMap(prefix, function(string key, number idx){ //put the slugs into a global variable for later use
                        if(REFind("^{[^}]*}$", arguments.key)){
                            variables.route.slugs[REReplace(arguments.key, "{|}", "", "all")] = listGetAt(target_segment, idx, '/');
                        }
                    }, '/');
                }
            }
            return result;
        }
        private any function formatResponse(any result){
            var responseObj = getPageContext().getResponse();   
            if( NOT isSimpleValue(result)) {
                responseObj.setcontenttype('application/json; charset=utf-8');
                result = serializeJSON(result);
            }else if(isXML(result)){
                responseObj.setcontenttype('application/xml; charset=utf-8');
            }
            return result;
        }
        private function appendWhenFilters(){
            for(var key in variables.when_filters){
                if(REFind("^"&listFirst(key,"*"), variables.route.path)){
                    arrayPrepend(variables.route.filters.before,variables.when_filters[key]);
                }
            }
        }
    /*** /PRIVATE FUNCTIONS ***/
}