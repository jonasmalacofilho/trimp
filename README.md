TrImp
=====

_Cross-platform map matching based on incremental path finding_


Introduction
------------

TrImp solves off-line map matching problems with iterative open – as in
unspecified – source breadth-first searches, essentially by computing what
resembles an incremental shortest path on the network.

The network vertices are labeled not only with the smallest know distance from
the starting point, but are also penalized at each processed input point with
the distance from it to them.

The algorithm is built on extending the single source shortest path
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

TrImp is cross-platform and developed in Haxe, running on the Neko VM and
manipulating [INRO Emme][Emme] networks using the EmmeKit library for Haxe.


### Shrimp

A simplified version of TrImp – called [Shrimp] – was developed for testing
purposes as part of an experiment on map-matching algorithm development and
comparison.  Unlike its parent, it was developed on top of a generic network
model and has no dependencies on target software or libraries.

Shrimp does solve easy instances of map-matching problems and is much more
readable than TrImp, but doesn't yet handle loops all that well.


Building
--------

For the time being there are no pre-built versions of TrImp.  However,
compiling it is simple and fast on any major desktop platform – Windows, Mac or
Linux.

To build TrImp, recent versions of [Haxe][Haxe] (3.2+) and the [Neko VM][Neko]
(2.0+) are required, alongside the [EmmeKit] and [Vehjo] Haxe libraries.

The required Haxe libraries can be installed with the `haxelib` client that
ships with any Haxe installation:

```sh
haxelib git vehjo https://github.com/jonasmalacofilho/vehjo.hx
haxelib git emmekit https://github.com/jonasmalacofilho/emmekit.hx
```

To compile, simply execute `haxe build.hxml` in the current directory.  This will
compile the unit tests and both debug and release versions of TrImp, finishing
by running the unit tests.


Running
-------

TrImp map-matches paths – defined as sequences of coordinates – to a target
network, generating suitable routes on it.  It uses a simple command line
interface, suitable for easy batch processing of large set of inputs.

The target network and several parameters are supplied as options on the
command line, and it's expected that the network – nodes and links – has
already been exported Emme in one or more Emme Free Format (EFF) files.

Input data is read from the standard input and in the [Text/Geography]
format; each record contains a path that will be map-matched.

TrImp will then compute a suitable route on the network for each read path and
output a EFF route file to standard output suitable for importing in Emme.

The essential command line options are:

 - `--net <path>`: read a EFF file with nodes and/or links
 - `--mode <mode>`: mode for the created lines
 - `--veh <number>`: vehicle type for the created lines
 - `--hdw <minutes>`: headway for the created lines
 - `--speed <km/h>`: default speed for the created lines
 - `--names <path>`: *optional* CSV with names for the input sequences (format:
   id,name)
 - `--kml-output <path>`: *optional* create an auxiliary Google Earth KML
   output

The full list of available options can be seen by executing `trimp` with no
arguments.


### Example

```
./trimp --net net.in --mode b --veh 1 --hdw 3 --speed 20 < gps.geo > lines.out
```

 - the executable name varies depending on the operating system used:
   `trimp.exe` (Windows), `trimp` (Linux) or `trimp.app` (Mac)
 - the network is read from an Emme Free Format file: `net.in`
 - all created lines will have mode `b`, vehicle number `1`, headway `3` and a
   default speed of `20` km/h
 - `< gps.geo` overrides the standard input to read from the `gps.geo` file,
   instead of the keyboard
 - `> lines.out` redirects the standard output to write to the `lines.out`
   file, instead of the screen


## Copyright and license

Copyright is retained by the commit authors and the code is licensed under a
BSD 2-clause license.  More details can be found on [LICENSE.txt].


[EmmeKit]: https://github.com/jonasmalacofilho/emmekit.hx
[Emme]: http://www.inrosoftware.com/en/products/emme
[Haxe]: http://haxe.org
[Neko]: http://nekovm.org
[Shrimp]: https://github.com/jonasmalacofilho/map-matching-lab/blob/master/lab/mapMatching/Shrimp.hx
[Text/Geography]: formats.md#textgeography-for-lines
[Vehjo]: https://github.com/jonasmalacofilho/vehjo.hx
[experiment]: https://github.com/jonasmalacofilho/map-matching-lab
[LICENSE.txt]: LICENSE.txt

