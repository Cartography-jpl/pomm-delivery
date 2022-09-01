POMM Delivery
=============

This is a small repository for deliverying the POMM software.

There are 3 pieces that need to be deliveryed:

#. ISIS software
#. ISIS data
#. AFIS/POMM software

There is a top level Makefile that handles installing everything.

Note that each piece here can go to a separate location is desired.
In particular the ISIS data may fit better in a different location than
the software.

The Makefile takes a PREFIX argument, and by default installs everything
under that directory. But you can optionally specify ISISROOT and/or 
ISISDATA to change the location of things.

