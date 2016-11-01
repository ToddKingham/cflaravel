<cfscript>
	

	Route.filter('must_be_logged_in',function(){
		var isLoggedIn = true;

		if(isLoggedIn){
			return false;
		};

		return redirect('login');

	});

	


</cfscript>
