POMM Delivery
=============

This is a small repository for deliverying the POMM software.

There are 3 pieces that need to be deliveried:

1. ISIS software
2. ISIS data
3. AFIS/POMM software

There is a top level Makefile that handles installing everything.

Note that each piece here can go to a separate location is desired.
In particular the ISIS data may fit better in a different location than
the software.

The Makefile takes a PREFIX argument, and by default installs everything
under that directory. But you can optionally specify ISISROOT and/or 
ISISDATA to change the location of things.

To install, simply run

    make PREFIX=<top directory for install> install
	
You can optionally add ISISROOT=<isis directory> and/or 
ISISDATA=<isis data directory> if you want to install in a different location.

Note that the pomm software automatically downloads SPICE kernels from
the ISIS repository. These files go by default into the directory
~/.spice_cache. If desired you can redirect this to a different
directory by setting the environment variable “SPICECACHE” to your
desired location.
