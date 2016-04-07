<cfscript>

	//main nav routes: passing the reqest to a Controller and method
	Route.get('/','SampleController@main');
	Route.get('about','SampleController@aboutus');
	Route.get('contact','SampleController@contactus');
	Route.get('faqs','SampleController@faqs');
	Route.get('login','SampleController@login');

	//Route Groups let you prefix paths. so this will match reports/sales for get and post
	Route.group({ "prefix" = "reports"}, function(){
		Route.get('sales','SampleController@reports_display');
		Route.post('sales','SampleController@reports_insert');
	});

	//Route Groups can have a "before action" so we process this filter before we match the routes
	Route.group({'before'='must_be_logged_in'},function(){
		//this route uses a closer instead of calling the controller.
		Route.any('customers/{id}/name/{name}',function(id,name){
			return "The customer #ARGUMENTS.name# has an ID of #ARGUMENTS.id#";
		});
	});

	Route.post('blogs',function(){
		//If you post a message body you can get to it using the Request.json() method
		return Request.json();
	});
</cfscript>