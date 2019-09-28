# ![logo][] PowerShell
[logo]: https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg?sanitize=true

This is a collection of scripts that I use on a day to day basis as a ConfigMgr Admin/Endpoint Engineer.  I've just recently begun working my way back through all of them and sanitizing for public consumption.  Removing hard coded entries for servers/locations/etc and replacing with variables to make them more portable.  As I get time, I will continue to add to the repository.

Currently I have broken these out by general usage, and SCCM specific.  I will likely further break down the SCCM scripts into some that I use in task sequences, like:

* To create Distribution Points on the fly during OSD
* To communicate with the excellent [ConfigMgr Webservice](https://www.scconfigmgr.com/configmgr-webservice/)
* Although it's not powershell, I will likely include my [UI++ Frontend](http://uiplusplus.configmgrftw.com/) config as well

Versus scripts that I use for administration tasks like:

* Resolving PackageIDs to Names
* Getting collection memberships for computers
* Triggering machines to pull policy
* Redistributing content to distribution points
