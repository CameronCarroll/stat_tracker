stat-tracker.rb
-----------------

(Alpha Development)
====================

Followed https://github.com/sklise/sinatra-warden-example to implement authentication.

So now we have a (albeit shitty) frontpage and login form. To lower friction I was thinking that the front login form should maybe double as the account creation form but then I was just thinking that it would be shitty to mistype your username and get taken to account creation.

03/14/15 ---

So yeah, pretty much decided to nuke the login page and create a separate account creation page. The root page is only available to people who are logged out, and the dash is only available to people who are logged in. Obviously. But yeah if you're logged in already there's no reason to show you the frontpage.
