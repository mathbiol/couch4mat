# couch4mat
resuscitated from https://code.google.com/archive/p/couch4mat/

Matlab / FreeMat toolbox to interoperate with CouchDB

This Matlab toolbox supports interoperation with CouchDB. This toolbox relies on JSON4MAT to parse the data structures and on cURL to make HTTP calls to CouchDB.
___
## Full Manual

https://mathbiol.github.io/couch4mat/html/couch_pub.html
https://mathbiol.github.io/couch4mat/html/couch_pub.pdf
___


###Summary

The couch4mat toolbox itself consists of a single m-file couch() where all sub-functions are embedded. Since the JSON4MAT parsers may be useful by themselves two additional functions were also included, [json2mat](https://github.com/mathbiol/couch4mat/blob/gh-pages/json2mat.m) and [mat2json](https://github.com/mathbiol/couch4mat/blob/gh-pages/mat2json.m), as was a MS Windows cURL executable borrowed from http://curl.haxx.se:

A tutorial / user manual was also produced produced using cell programming, which corresponds to the coucdb_[pub.m](https://github.com/mathbiol/couch4mat/blob/gh-pages/pub.m) file. [html](https://mathbiol.github.io/couch4mat/html/couch_pub.html) and [pdf](https://mathbiol.github.io/couch4mat/html/couch_pub.pdf) versions were published.
