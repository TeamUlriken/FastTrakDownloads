Data flow
=========
Every protocol folder (NDV,GBD,ENDO etc.) is updated locally by the developers.
The changes are committed to master.  This will trigger a build on the build
server. The build creates zip-files, and adds them to the repository.

The zip-files are downloadable by customers from http://downloads.fasttrak.no.

Lookup folder
=============
The lookup folder can be populated in two ways:

  * Using the build script for zip-packages.  It uses http get.
  * Using FastTrakUpdate.exe.  It will "prettify" the xml, so it will be slightly different from a http get.

Todo
====
Every protocol should have its own repository.  For now, only GBD has a separate repo.

