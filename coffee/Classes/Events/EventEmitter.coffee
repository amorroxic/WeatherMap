((exports) ->

  EventEmitter = ->

  indexOfListener = (listener, listeners) ->
    return listeners.indexOf(listener)  if nativeIndexOf
    i = listeners.length
    return i  if listeners[i] is listener  while i--

  proto = EventEmitter::
  nativeIndexOf = (if Array::indexOf then true else false)

  proto.getListeners = (evt) ->
    events = @_events or (@_events = {})
    events[evt] or (events[evt] = [])

  proto.addListener = (evt, listener) ->
    listeners = @getListeners(evt)
    listeners.push listener  if indexOfListener(listener, listeners) is -1
    @

  proto.removeListener = (evt, listener) ->
    listeners = @getListeners(evt)
    index = indexOfListener(listener, listeners)

    if index isnt -1
      listeners.splice index, 1
      @_events[evt] = null  if listeners.length is 0
    @

  proto.addListeners = (evt, listeners) ->
    @manipulateListeners false, evt, listeners

  proto.removeListeners = (evt, listeners) ->
    @manipulateListeners true, evt, listeners

  proto.manipulateListeners = (remove, evt, listeners) ->
    i = undefined
    value = undefined
    single = (if remove then @removeListener else @addListener)
    multiple = (if remove then @removeListeners else @addListeners)

    if typeof evt is "object"
      for i of evt
        if evt.hasOwnProperty(i) and (value = evt[i])
          if typeof value is "function"
            single.call this, i, value
          else
            multiple.call this, i, value
    else
      i = listeners.length
      single.call this, evt, listeners[i]  while i--

    @

  proto.removeEvent = (evt) ->
    if evt
      @_events[evt] = null
    else
      @_events = null
    @

  proto.emitEvent = (evt, args) ->
    listeners = @getListeners(evt)
    i = listeners.length
    response = undefined

    while i--
      response = (if args then listeners[i].apply(null, args) else listeners[i]())
      @removeListener evt, listeners[i]  if response is true
    @

  exports.EventEmitter = EventEmitter

) @
