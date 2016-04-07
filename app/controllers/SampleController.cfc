component extends="CFlaravel/BaseController"{
	
	function main(){
		return View.make("Global_Layout");
	}

	function aboutus(){
		var nestedView = View.make("layouts.About_Us",{layout="About Us"});
		return View.make("Global_Layout",{layout=nestedView});
	}

	function contactus(){
		return View.make("Global_Layout",{layout=View.make("layouts.Contact_Us",{layout="Contact you"})});
	}

	function faqs(){
		return View.make("Global_Layout",{layout="FAQs"});
	}

	function login(){
		return View.make("Global_Layout",{layout="this is the login screen"});
	}

	
	function reports_display(){
		var result = "get the reports";
		return result;
	}

	function reports_insert(){
		var result = "insert report data";
		return result;
	}
	
}