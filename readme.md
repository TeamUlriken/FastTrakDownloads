Data flow
=========
Every protocol folder (NDV,GBD,ENDO etc.) is updated locally by the developers.
The changes are committed to master.  A nightly build copies data from repositories
to the binaries server.  A weekly build creates zip-files and notifies the customer.

The zip-files are downloadable by customers from https://binaries.dips.no.

Lookup folder
=============
The lookup folder can be populated in two ways:

  * Using the build script for zip-packages.  It uses http get.
  * Using FastTrakUpdate.exe.  It will "prettify" the xml, so it will be slightly different from a http get.

