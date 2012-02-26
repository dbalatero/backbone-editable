if not Function::mixin
  Function::mixin = (module) ->
    for name, method of module::
      this::[name] = method
    return this
if not Backbone.Mixin
  Backbone.Mixin = {}

class Backbone.Mixin.Editable
  _editable_events:
    'click  .editable'      : '_editable'
    'blur   .editable input': '_setKey'
    'keyup  .editable input': '_setKeyEnter'

  initEditable: (options = {}) ->
    @_setSilent(options)
    _.extend @events, @_editable_events
    @delegateEvents()
      

  _editable: (e) ->
    $el = $(e.currentTarget)
    if !$el.hasClass('editing')
      # Gather data
      width = $el.width()
      value = Backbone.Mixin.Editable._GetValue
        model: @model,
        el: $el
      # Set up the field
      $el.addClass('editing').html('<input />').
        find('input').val(value).
        width(width).
        focus()

  _setKey: (e) ->
    $el = $(e.currentTarget).parent()
    if $el.hasClass('editing')
      console.log 'setting...'
      # Make sure the event is triggered twice
      # Store the value in the model
      [key, value] = Backbone.Mixin.Editable._NewAttributes
        model: @model,
        value: $el.find('input').val(),
        el: $el
      @model.save key, value,
        wait: true, silent: @_getSilent($el),
        success: => @_removeInput($el)

  _removeInput: ($el) =>
    # Get rid of the text box, and set the new
    # (or old) value.
    value = Backbone.Mixin.Editable._GetValue
      model: @model,
      el: $el
    $el.removeClass('editing').html(value)
 
  _setKeyEnter: (e) ->
    if e.keyCode is 13
      # Trigger the blur event
      $(e.currentTarget).blur()

  _getSilent: ($el) ->
    el_silent = $el.data 'silent'
    if (el_silent is @silent) or (el_silent is undefined)
      @silent
    else
      el_silent

  _setSilent: (options) ->
    if options['silent_events'] or options['silent_events'] is undefined
      @silent = true
    else
      @silent = false


  @_GetValue = (options = {}) ->
    model   = options['model']
    $el     = options['el']
    object  = $el.data('object')
    index   = $el.data('index')
    key     = $el.data('key')
    value = null
    # Full complexity
    if object and (index != undefined) and key
      value = _.escape model.get(object)[index][key]
    # Object with a key
    else if object and key
      value = _.escape model.get(object)[key]
    # Object that is an array
    else if object and (index != undefined)
      value = _.escape model.get(object)[index]
    # Just accessing by a key
    else
      value = model.escape key
    return value

  @_NewAttributes = (options = {}) ->
    model   = options['model']
    value   = options['value']
    silent  = false
    silent  = true if options['silent']
    $el     = options['el']
    object  = $el.data('object')
    index   = $el.data('index')
    key     = $el.data('key')
    # Full complexity
    if object and (index != undefined) and key
      new_object  = _.clone model.get(object)
      new_index   = _.clone new_object[index]
      new_index[key] = value
      new_object[index] = new_index
      [object, new_object]
    # Object with a key
    else if object and key
      new_object = _.clone model.get(object)
      new_object[key] = value
      [object, new_object]
    # Object that is an array
    else if object and (index != undefined)
      new_object = _.clone model.get(object)
      new_object[index] = value
      [object, new_object]
    # Just accessing by a key
    else
      [key, value]
