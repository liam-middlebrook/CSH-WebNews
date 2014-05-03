@delayClickTime = 300
@delayClickTimeout = null

click = (elem, extraData = null) ->
  if $(elem).is(':visible')
    $(elem).trigger('click', extraData)
    if (href = $(elem).attr('href')) and href[0..1] == '#!'
      location.hash = href[1..-1]

delayClickGroup = (groupElem) ->
  clearTimeout(@delayClickTimeout)
  $('#groups_list .selected').removeClass('selected')
  $(groupElem).addClass('selected')
  @delayClickTimeout = setTimeout (->
    click $(groupElem).find('a'), false
  ), @delayClickTime

delayClickPost = (postRow) ->
  clearTimeout(@delayClickTimeout)
  $('#posts_list .selected').removeClass('selected')
  $(postRow).addClass('selected')
  scroll_to_selected_post()
  @delayClickTimeout = setTimeout (->
    click postRow, false
  ), @delayClickTime

selectPreviousPost = ->
  prevPostRow = $('#posts_list .selected').prevAll('tr:visible')[0]
  if prevPostRow
    delayClickPost prevPostRow
  else if $('#posts_list .selected').length == 0
    delayClickPost $('#posts_list tbody tr:visible').last()

selectNextPost = ->
  nextPostRow = $('#posts_list .selected').nextAll('tr:visible')[0]
  if nextPostRow
    delayClickPost nextPostRow
  else if $('#posts_list .selected').length == 0
    delayClickPost $('#posts_list tbody tr:visible').first()

selectPreviousThread = ->
  prevThreadRow = $('#posts_list .selected').prevAll('tr[data-level="1"]')[0]
  if prevThreadRow
    delayClickPost prevThreadRow
  else if $('#posts_list .selected').length == 0
    delayClickPost $('#posts_list tr[data-level="1"]').last()

selectNextThread = ->
  nextThreadRow = $('#posts_list .selected').nextAll('tr[data-level="1"]')[0]
  if nextThreadRow
    delayClickPost nextThreadRow
  else if $('#posts_list .selected').length == 0
    delayClickPost $('#posts_list tr[data-level="1"]').first()

selectPreviousGroup = ->
  prevGroupElem = $('#groups_list .selected').prev('li')[0]
  if prevGroupElem
    delayClickGroup $(prevGroupElem)
  else
    prevGroupElem = $('#groups_list .selected').parent('ul').prev('ul').children('li').last()[0]
    if prevGroupElem
      delayClickGroup $(prevGroupElem)
    else
      delayClickGroup $('#groups_list li').last()

selectNextGroup = ->
  nextGroupElem = $('#groups_list .selected').next('li')[0]
  if nextGroupElem
    delayClickGroup $(nextGroupElem)
  else
    nextGroupElem = $('#groups_list .selected').parent('ul').next('ul').children('li').first()[0]
    if nextGroupElem
      delayClickGroup $(nextGroupElem)
    else
      delayClickGroup $('#groups_list li').first()

toggleCurrentPost = ->
  toggle_thread_expand($('#posts_list .selected'))

toggleCurrentThread = ->
  selectedPostRow = $('#posts_list .selected')
  if selectedPostRow.attr('data-level') == '1'
    toggle_thread_expand($(selectedPostRow))
  else
    currentThreadRow = selectedPostRow.prevAll('tr[data-level="1"]')[0]
    click currentThreadRow, false
    toggle_thread_expand($(currentThreadRow))

clickMostSpecificSearch = ->
  for searchButton in ['#revise_search_button', '#newsgroup_search_button', '#search_button']
    if $(searchButton).length > 0
      click $(searchButton)
      return false # to prevent activating page search in Firefox

closeDialogOrMinimizeDraft = ->
  if $('.buttons .minimize_draft').length > 0
    click $('.buttons .minimize_draft')
  else
    click $('.dialog_cancel')

focusOnThreadView = ->
  $('#posts_list').focus()
  $('#group_view').css('background-color', '#ffc')
  setTimeout (-> $('#group_view').css('background-color', '')), 150

focusOnPostView = ->
  $('#post_view .content').focus()
  $('#post_view').css('background-color', '#ffc')
  setTimeout (-> $('#post_view').css('background-color', '')), 150

@setHotkeyModeNormal = ->
  Mousetrap.reset()
  Mousetrap.bind
    'k': selectPreviousPost
    'j': selectNextPost
    'shift+k': selectPreviousThread
    'shift+j': selectNextThread
    'alt+k': selectPreviousGroup
    'alt+j': selectNextGroup
    'e': toggleCurrentPost
    'shift+e': toggleCurrentThread
    'alt+shift+i': -> click $('#mark_all_read_button')
    'alt+i': -> click $('#mark_group_read_button')
    'shift+i': -> click $('#mark_thread_read_button')
    'esc': -> click $('#home_button')
    'n': -> click $('#next_unread')
    'shift+s': -> click $('#starred_button')
    '~': -> click $('#settings_button')
    '?': -> click $('#about_button')
    '/': clickMostSpecificSearch
    'c': -> click $('#group_view .new_draft')
    'r': -> click $('#post_view .new_draft')
    'h': -> click $('#show_headers_button')
    'u': -> click $('#mark_unread_button')
    't': -> click $('#sticky_post_button')
    '#': -> click $('#cancel_post_button')
    's': -> click $('#star_post_button')
    'q': -> click $('#show_quote_button')
    'd': -> click $('#reading_mode_button')
    'v': -> click $('#view_in_newsgroup_button')
    'alt+m': -> click $('.resume_draft')
    'alt+up': focusOnThreadView
    'alt+down': focusOnPostView

@setHotkeyModeDialog = ->
  Mousetrap.reset()
  Mousetrap.bindGlobal 'alt+s', -> click $('#dialog input[type="submit"]')
  Mousetrap.bindGlobal 'alt+m', -> click $('.buttons .minimize_draft')
  Mousetrap.bindGlobal 'alt+q', -> click $('.dialog_cancel.clear_draft')
  Mousetrap.bindGlobal 'esc', closeDialogOrMinimizeDraft
