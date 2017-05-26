# combining
[![Build Status](https://travis-ci.org/elidoran/node-combining.svg?branch=master)](https://travis-ci.org/elidoran/node-combining)
[![Dependency Status](https://gemnasium.com/elidoran/node-combining.png)](https://gemnasium.com/elidoran/node-combining)
[![npm version](https://badge.fury.io/js/combining.svg)](http://badge.fury.io/js/combining)
[![Coverage Status](https://coveralls.io/repos/github/elidoran/node-combining/badge.svg?branch=master)](https://coveralls.io/github/elidoran/node-combining?branch=master)

Combine streams in a pipeline.

Behaviors:

1. Piping to it pipes to its first stream.
2. Piping from it pipes from its last stream.
3. adding 'close' event listener will add it to its **first stream**
4. adding listeners: *end, finish, data, readable* will add it to its **last stream**
5. adding other listeners, including *error*, will be added to **all** its streams
6. error events emitted on any of its streams are automatically forwarded and emitted on it

## Install

```sh
npm install --save combining
```

## Usage

```javascript
// get the module
var buildCombine = require('combining')

// build the combine function for use
var combine = buildCombine() // no options provided

// some input stream where you'd have data coming from
var input = getSomeInputStream()

// some output stream where you'd like to send results
var output = getSomeOutputStream()

// create some sample streams to combine
var stream1 = someStream()
var stream2 = anotherStream()
var stream3 = soManyStreams()

// combine the three streams together
var combo = combine(stream1, stream2, stream3)

// Or,
// provide an array of streams:
var combo = combine([stream1, stream2, stream3])

// Or,
// provide streams and arrays of streams
// because it'll be flattened into a single array.
var combo = combine([
  stream1,
  [stream2, stream3],
  [stream4, [stream5, stream6], stream7]
])

// now use the combined streams as if they were one stream
input.pipe(combo).pipe(output)

// adds end listener to the first stream:
combo.on('end', function() {})

// adds finish listener to the last stream:
combo.on('finish', function() {})

// adds custom listeners to all streams in the `combo`:
combo.on('some event', function() {})

// Note:
// We could have pipe'd each one to the next ourselves.
// But, I've found I'm rarely the one controlling all parts involved.
// This shows how things work together. In development, I find it's
// helpful to create a single stream combined from other streams to
// supply to some library or function to use.
//
// Also, I'm aware of the module `stream-combiner`. I wasn't able to add event
// listeners to it and have them added on the internal streams I knew to be
// combined in a stream I had. My implementation allows that.
```


# [MIT License](LICENSE)
