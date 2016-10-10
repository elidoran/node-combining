fs = require 'fs'
corepath = require 'path'
assert = require 'assert'
{Transform,PassThrough} = require 'stream'

strung = require 'strung'
buildEach = require 'each-part'

buildCombine = require '../../lib'
combine = buildCombine()

uppercase = ->
  new Transform
    transform: (data, _, next) -> next undefined, data.toString().toUpperCase()

echoer = ->
  new Transform
    transform: (data, __, next) ->
      string = data.toString()
      console.log 'ECHO:',string
      next undefined, string

describe 'test combining', ->

  describe 'with: file -> transform -> strung', ->

    # create path to the test file
    inputPath = corepath.join(__dirname, '..', 'helpers', 'input.txt')

    # also read the file content
    inputContent = fs.readFileSync(inputPath, 'utf8')

    # split it on newlines so we can get rid of them because they won't exist
    # in the final result either.
    # also, we want the parts to compare to what's emitted by eachLine
    # to ensure the right parts were passed to the `part` event we added to
    # the `combined` instance
    inputParts = inputContent.split '\n'

    # join content back together without the newlines and capitalize it.
    # then we can compare to what the pipeline did
    inputContent = inputParts.join('').toUpperCase()

    # create a Readable of the file
    input = fs.createReadStream inputPath

    # create a PassThrough just to have something else as the first stream
    passthru = new PassThrough

    # create a transfirn whuch splits on newlines
    # NOTE: the readableObjectMode setting is so eachLine passes a string instead
    # of the info object it otherwise would push
    eachLine = buildEach delim:'\n', readableObjectMode:false

    # a transform which does something so some work is done
    transform = uppercase()

    # gathers the output so we can test it
    output = strung()

    # had it echo content to help with debugging
    # echo = echoer()

    # for debugging it's handy to output which stream is doing what :)
    # input.id = 'input'
    # eachLine.id = 'eachLine'
    # transform.id = 'uppercase'
    # echo.id = 'echo'
    # output.id = 'output'

    # store info from listeners called
    called = data:[], parts:[]

    # watch for the file read stream to end
    input.on 'end', -> called.inputEnded = true
    # watch for the `strung` target stream to have it all
    output.on 'finish', -> called.outputFinished = true

    # what we're testing: combine these three streams in sequence
    combined = combine passthru, eachLine, transform

    # add these listeners and record if they are run
    for name in [ 'end', 'finish', 'readable' ]
      do (name) ->
        combined.on name, -> called[name] = true

    # what we're testing: pipe into the combo and pipe from the combo
    input.pipe(combined).pipe output

    # what we're testing: add some listeners to the combo
    # the `part` isn't known, so, it is added to all the substreams.
    combined.on 'part', (part) -> called.parts.push part
    # the `data` event gets special attention and is only added to
    # the last stream (transform)
    combined.on 'data', (data) -> called.data.push data.toString()

    before 'wait for input end', (done) ->
      if called.inputEnded is true then return done()
      input.on 'end', done

    before 'wait for output finish', (done) ->
      if called.outputFinished is true then return done()
      output.on 'finish', done

    it 'should become readable', -> assert called.readable

    it 'should end', -> assert called.end

    it 'should finish', -> assert called.finish

    it 'should emit 3 parts', -> assert.equal called.parts.length, 3

    it 'should emit first part', -> assert.equal called.parts[0], inputParts[0]

    it 'should emit second part', -> assert.equal called.parts[1], inputParts[1]

    it 'should emit third part', -> assert.equal called.parts[2], inputParts[2]

    it 'should emit 3 data from combo (last=transform)', -> assert.equal called.parts.length, 3

    it 'should emit first data', -> assert.equal called.data[0], inputParts[0].toUpperCase()

    it 'should emit second data', -> assert.equal called.data[1], inputParts[1].toUpperCase()

    it 'should emit third data', -> assert.equal called.data[2], inputParts[2].toUpperCase()

    it 'should produce capitalized input file content', ->

      assert.equal output.string, inputContent
