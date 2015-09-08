Summary of used file formats
============================


Text/Geography
--------------

The Text/Geography format is built on top of [Comma Separated Values
(CSV)][CSV] files and is used to encode simple geography features such as
points or lines.

Each Text/Geography file can contain either points or lines, but not a mixture
of the two.  The files should not have any human readable header.


### Text/Geography for lines

Records in line files have a variable number of fields:

 - the feature id,
 - the number of points described;
 - and the latitudes and longitudes of each point.

```csv
15,3,44.2394,20.2345,44.2932,20.0123,44.3901,19.9234
```

In case there is more than one record for the same feature, the behavior is
unspecified.


### Text/Geography for points

Records in point files have 3 fields:

 - the feature numerical id,
 - its latitude,
 - its longitude.

```csv
4,44.2394,20.2345
8,44.3901,19.9234
```

In case there is more than one record for the same feature, the behavior is
unspecified.


### About the Text/Geography format

The Text/Geography format is the simplest geography format that can be used to
interact with Calliper TransCad.  It's used extensively by those manipulating
TransCad networks outside GISDK and is suitable for any exchange of simple
geography data, but has never been formally specified.

In fact, TransCad's documentation isn't even compatible with the files it
generates, and this has in the past caused software written by the author of
this small document to break in unexpected ways.

Something in the lines of Well Known Text (WKT) – or even Well Known
Binary (WKB) – may be a suitable replacement for future applications that will
never interface with TransCad, mainly for being a public and well-defined
format.


Emme Free Format
----------------

Documentation of Emme Free Format (EFF) files can be found on the Emme manual.


[CSV]: https://tools.ietf.org/html/rfc4180
[WKT]: https://en.wikipedia.org/wiki/Well-known_text

