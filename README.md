# eqntott: convert boolean logic equation to truth table.

I have converted the code from K&R style function syntax to ANSI to
please the modern C compilers.

Grab latest Zig compiler and run:

```
$ zig build
```

### Original README by Peter Scott

See the man page for more information. There are some example input
files in the examples/ directory. To install, do the usual:

./configure
make
make install

This is old code written for an ancient C compiler, but I've made some
modifications so it compiles with a modern gcc. The program is very
mature -- it was used as part of the SPEC92 benchmarks -- but it
hasn't been actively updated since 1981.

In the conversion to modernity, I've done the following:

* Restructured the code. Now there are src/ and doc/ and examples/
  directories.

* Converted it to use automake and autoconf. I don't really check for
  portability with autoconf, so most of the configure script's effort
  goes to waste, but it does provide some compatibility and a lot of
  usability.

* Moved the whole thing into Darcs version control.

* Fixed the code so that it will compile.

* Discontinued use of the yacc sources for the parser. I just ran
  Bison on them and called the resulting files part of the source. The
  output from Bison is already littered with ridiculous amounts of
  compatibility code anyway, so I figure it's about a million times
  more portable than any other part of the code.


Peter Scott
pjscott@iastate.edu
June 2008
