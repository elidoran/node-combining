
module.exports = (builderOptions) ->

  # return a function which builds the combined streams
  (streams...) ->

    # handle the streams arg, it may be an array in the array or be empty
    switch streams.length
      when 1
        if Array.isArray streams[0] then streams = streams[0]
        else return streams[0]
      when 0 then return new require('stream').PassThrough()

    # remember first/last cuz their the head+tail of the pipeline
    first = streams[0]
    last  = streams[streams.length - 1]
    # i'm going to use the first stream to represent the pipeline and alter
    # some of its functions.
    combined = first
    combined.substreams = streams

    # special behaviors for `first` as the representation of all combined streams

    # 1. handle onerror
    # bind the emit function with 'error' as its first arg for use on other streams
    onerror = combined.emit.bind combined, 'error'

    # create pipeline
    # start from the front and pipe each to the next one
    # until we reach the last one which doesn't pipe to anyone
    for stream,index in streams when stream isnt last

      # use index+1 to get the next one
      stream.pipe streams[index + 1]

      # also, let's setup the on-error while we're looping
      # NOTE: the `first` is `combined`, so, no need to forward from itself
      if stream isnt first then stream.on 'error', onerror

    # we didn't do the last one, so, do it now (cuz it doesn't pipe())
    last.on 'error', onerror

    # 2. when someone wants it to pipe() to another stream, it actually needs
    #    to have `last` pipe to it. so, let's override its pipe() function
    combined.pipe = (target) -> last.pipe target

    # 3. unpipe() should undo what's done in #1.
    combined.unpipe = (target) -> last.unpipe target

    # 4. when event listeners are added to `combined` then we may need to add them
    #    to only first, or maybe only to last, or maybe to all of them.
    addListeners = (which, event, listener) ->
      switch event

        # close listeners go on first as its the Writable (first one)
        # 'error' listeners also go on the first one (combined), cuz the
        # other streams forward their errors to it
        when 'close' or 'error' then first['_combined' + which] event, listener

        # end/finish/data go on last cuz it's the Readable point (at the end)
        when 'end', 'finish', 'data', 'readable' then last[which] event, listener

        # unknown events go on all listeners
        else
          for stream in streams
            # have to take special care for `combined` (first)
            # because I overrode its on/once functions
            combo = '_combined' + which
            if stream[combo]?
              stream[combo] event, listener
            else
              stream[which] event, listener

    # override its on/once functions for the special handling above
    combined._combinedon = combined.on
    combined._combinedonce = combined.once
    combined.on = addListeners.bind combined, 'on'
    combined.once = addListeners.bind combined, 'once'

    # 5. when certain substreams emit certain events, emit them on `first`
    #  Note: above we already setup forwarding error events
    # so far, we only care about `end` and `finish` on `last`
    last.on 'end', combined.emit.bind combined, 'end'
    last.on 'finish', combined.emit.bind combined, 'end'

    # 6. there are a few other things we may want to control, but, if we hold
    #    the assumption they're only wanting to pipe() to this pipeline and
    #    then pipe() out from it... and add event listeners, then we're good.

    # what am i returning...it's actually `first`
    return combined
