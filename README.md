
pk2-piculear-conversion-tools
=============================

This project aims to produce a workflow to retrieve scripts and device
information intended for use with the Microchip PICkit 2 development programmer
and automate or facilitate its reworking for use with other programmers.

The programs here operate by dissecting an available device file
(`PK2DeviceFile.dat`). The intellectual property rights for that file, as
produced by Microchip, are likely to be restricted and such a restriction would
tend to apply to derivative works. Therefore, this project shall not host
consequential portions of encumbered device files nor outputs generated from
such.

The device file is widely available and not difficult to find.


Decoding
--------

A modified version of amx's fine `pk2dft` tool is used to unpack the distinct
logical structures from the device file. For this project, the output
mechanisms were modified to produce valid JSON as output. (The input mechanisms
have *not* been changed, so this output cannot be fed back in to produce a new
device file.)

A combine-and-associate program reads in the JSON from each script and performs
rudimentary identification of the opcode and operand values from the script
array. The associated part of the `Makefile` combines the results into a single
JSON array.


Decompilation
-------------

TODO. The scripts are made up of what are essentially instructions for a very
simple machine architecture. To facilitate their use on other platforms, it
would be desirable to be able to work backward from the instructions (in
particular the looping and branching instructions) to produce something more
similar to C or pseudocode.


Dependencies
------------

The modified `pk2dft`, like the original, depends on `libconfuse` dev files
being installed on your system. Naturally, `gcc` is also required.

The Perl scripts require the `JSON` CPAN module.


Instructions
------------

If the device file `PK2DeviceFile.dat` is in this directory (e.g. via copying
or symlinking), you can just do

	make

If the device file is elsewhere, specify `DEVICEFILE` when running `make`. For
example, if the file is `~/Downloads/PK2DeviceFile.dat`, do

	make DEVICEFILE=~/Downloads/PK2DeviceFile.dat

The resulting products are placed in the `build` directory.
