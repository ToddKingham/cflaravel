<cfsilent>
	<cfparam name="layout" default="Main Page !">
</cfsilent>
<!doctype html>
<html>
<head>
	<title>Welcome to CFLaravel</title>
	<style>
		ul#main-nav {
		    list-style-type: none;
		    margin: 0;
		    padding: 0;
		    background-color:lightgrey;
		    color:white;
		    display:inline-block;
		    float:right;

		}
		ul#main-nav li {
			display:inline-block;
			padding:5px
		}
		ul#main-nav li a {text-decoration: none;
			color:gray;
		}

		#content {clear:both;}
	</style>
</head>
<body>
	<section id="header">
		<ul id="main-nav">
			<li><a href="/">Home</a></li>
			<li><a href="/about">About Us</a></li>
			<li><a href="/contact">Contact Us</a></li>
			<li><a href="/faqs">FAQ's</a></li>
			<li><a href="/login">Login</a></li>
		</ul>
	</section>
	<section id="content">
		<h1>Welcome to CFLaravel!</h1>
		<div><cfoutput>#layout#</cfoutput></div>
	</section>





</body>
</html>