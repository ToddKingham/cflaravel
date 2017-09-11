<cfscript>
	

	Route.filter('must_be_logged_in',function($route, $request, $value){
		writeDump(Route.Input);
		if(!$value){
			return redirect('login');
		};

		// return redirect('login');

	});

	


</cfscript>
