TrImp v3
========

_Map matching based on incremental path finding_

TrImp v3 solves off-line map matching problems by computing an incremental
shortest path on the network between starting and ending positions.  The
network is reweighted for each input point, penalizing network vertices
according to their distance to the current position.

The algorithm is built on top of extending the single source shortest path
(SSSP) concept in two ways:

 - SSSP algorithms pick the best eligible source for any destination, and may
   be initialized with a set containing more than one starting vertices;

 - by replacing the single parent by a stack of parents, SSSP algorithms can be
   extended to handle loops and follow waypoints.

From this, TrImp balances the incremental cost on the network with the distance
to the input points to compute a path that should both make sense and resemble
the input.

Even though the penalty and cost functions remain quite simple, there is a huge
gain in both optimality and performance by delaying any decisions to the very
last moment, when all input points have been processed and will be taken into
consideration.

TrImp v3 is development on [Haxe] and manipulates [Emme] networks using the
[EmmeKit] library.


Shrimp
------

A simplified version of TrImp v3 called [Shrimp] was developed for testing
purposes, as part of an [experiment] on map-matching algorithm development and
comparison.  Unlike its parent, it was developed on top of a generic network model
and has no dependencies on target software or libraries.

Shrimp does solve easy instances of map-matching problems and is much more
readable than TrImp, but doesn't yet handle loops all that well.


Building
--------

To build a recent (3.2+) version of [Haxe] is required, alongside the [EmmeKit]
and [Vehjo] libraries and the [Neko VM].

To compile, simply run `haxe build.hxml` in the current directory.  This will
compile the unit tests and both the debug and release versions of TrImp, and
will end by running the unit tests.


Running
-------

TrImp uses a simple command line interface, so that running it in batch for a
large set of inputs remains easy.

Input should be supplied in the process standard input in the Text/Geography
format, and output Emme Free Format (EFF) line file will be generated in the
standard output.

The essential options are:

 - `--net <path>`: read a EFF file with nodes and/or links
 - `--mode <mode>`: mode for the created lines
 - `--veh <number>`: vehicle type for the created lines
 - `--hdw <minutes>`: headway for the created lines
 - `--speed <km/h>`: default speed for the created lines
 - `--names <path>`: *optional* CSV with names for the input sequences (format: id,name)
 - `--kml-output <path>`: *optional* create an auxiliary Google Earth KML output

A full list of options is available by executing `trimp` with no arguments.

Example:

```
./trimp --net net.in --mode b --veh 1 --hdw 3 --speed 20 < gps.geo > lines.out
```

 - the executable name varies depending on the operating system used: `trimp.exe` (Windows), `trimp` (Linux) or `trimp.app` (Mac)
 - the network is read from an Emme Free Format file: `net.in`
 - all created lines will have mode `b`, vehicle number `1`, headway `3` and a default speed of `20` km/h
 - `< gps.geo` overrides the standard input to read from the `gps.geo` file, instead of the keyboard
 - `> lines.out` redirects the standard output to write to the `lines.out` file, instead of the screen

[EmmeKit]: https://github.com/jonasmalacofilho/emmekit.hx
[Emme]: http://www.inrosoftware.com/en/products/emme
[Haxe]: http://haxe.org
[Neko VM]: http://nekovm.org
[Shrimp]: https://github.com/jonasmalacofilho/map-matching-lab/blob/master/lab/mapMatching/Shrimp.hx
[Vehjo]: https://github.com/jonasmalacofilho/vehjo.hx
[experiment]: https://github.com/jonasmalacofilho/map-matching-lab

