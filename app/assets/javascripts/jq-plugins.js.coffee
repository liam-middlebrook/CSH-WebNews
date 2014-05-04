jQuery.ajaxScript = (method, url, success = null) ->
  $.ajax {
    url: url,
    type: method,
    dataType: 'script',
    success: success
  }

jQuery.fn.outerHTML = ->
  $('<div>').append(this.first().clone()).html()

jQuery.fn.focusAtEnd = ->
  target = this.get(0)
  endIndex = target.value.length
  $(target).focus()
  target.setSelectionRange(endIndex, endIndex)
