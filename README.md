## What is it?

This is an attempt at describing the grammar for .itc files used by iTunes.  I based this on [ITC Extractor](http://www.sffjunkie.co.uk/python-itc.html) by Simon Kennedy, which does the job of
extracting image data from .itc files handily.

This is just a quick & dirty attempt to highlight the basic structure of itc files.  YMMV, as it's
not clear whether the format of these files will change over time.

##Working with it
You can apply this grammar to .itc files with [Synalyze It](http://www.synalysis.net).  Occasional
bugs aside, it's a good hex editor for working with & visualizing this sort of information.

## A word on ITC
I haven't found much information about this file format.

The grammar is fairly straightforward, aside from understanding the padding provided by some parts
of the data.  So this grammar might not be exhaustive, but it seems to be sufficient to get at
the image data.

This is part of a larger project for me, but the trickiest part of working with ITC files is in
dealing with ARGb data and converting it to a more useful format in native code.  Since I'm only
working with iTunes 11+ data and not concerned about backwards-compatibility, I haven't spent much
time worrying about non-ARGb image formats.