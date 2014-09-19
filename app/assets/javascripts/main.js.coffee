@chunks = {}
@check_new_interval = 15000
@check_new_retry_interval = 5000
@draft_save_interval = 2000
@spinner_large = {
  segments: 17,
  length: 0,
  width: 6,
  space: 6,
  padding: 0
}
@spinner_small = {
  segments: 17,
  length: 0,
  width: 2,
  space: 2,
  padding: 4,
  align: 'left'
}

window.loaded_location = false
window.first_load = true
window.active_navigation = false
window.active_scroll_load = false
window.active_check_new = false
window.check_new_timeout = false
window.draft_save_timer = false

@fix_post_header = ->
  if $('#post_header').length > 0
    $('#post_view .content').css('top', $('#post_header').outerHeight() + 'px');

@fix_dialog_height = ->
  dialog = $('#dialog')
  shrinkable = $('.shrinkable')
  if dialog.length > 0 and shrinkable.length > 0
    if not dialog.attr('data-original-height')
      shrinkable.height(shrinkable.height() + 1)
      dialog.attr('data-original-height', dialog.height())
      shrinkable.attr('data-original-height', shrinkable.height())
    dialog_original_height = parseInt(dialog.attr('data-original-height'))
    shrinkable_original_height = parseInt(shrinkable.attr('data-original-height'))
    if dialog.outerHeight() > $(window).height()
      shrinkable.height(shrinkable.height() - (dialog.outerHeight() - $(window).height()))
    else if dialog.outerHeight() < $(window).height() and dialog.height() < dialog_original_height
      shrinkable.height(shrinkable.height() + ($(window).height() - dialog.outerHeight()))
    if dialog.height() > dialog_original_height
      shrinkable.height(shrinkable_original_height)

@adjust_dialog_original_height = (adjustment) ->
  adjust_original_height($('#dialog'), adjustment)
  fix_dialog_height()

@adjust_shrinkable_original_height = (adjustment) ->
  adjust_dialog_original_height(adjustment)
  adjust_original_height($('.shrinkable'), adjustment)
  fix_dialog_height()

@adjust_original_height = (element, adjustment) ->
  original_height = parseInt(element.attr('data-original-height'))
  element.attr('data-original-height', original_height + adjustment)

@set_reading_mode = (enable) ->
  if enable
    $('#post_view').css('top', $('#group_view').css('top'))
    $('#post_view').css('margin-top', $('#group_view').css('margin-top'))
    $('#post_view .body').css('font-size', '120%')
    $('#group_view').hide()
    $('#reading_mode_button').addClass('enabled')
  else
    $('#post_view').css('top', '').css('margin-top', '')
    $('#post_view .body').css('font-size', '')
    $('#group_view').show()
    $('#reading_mode_button').removeClass('enabled')
    scroll_to_selected_post()

@target_external_links = ->
  $('a[href^="http"]:not([href*="' + window.location.host + '"])').attr('target', '_blank')

@init_toggle = (elem, pretoggle = true) ->
  elem = $(elem)
  if not elem.is('[data-toggle-initialized]')
    elem.attr('data-toggle-initialized', '')
    if pretoggle
      toggle_content(elem)
      elem.prepend('<i class="fa fa-chevron-down"></i> ')
    else
      elem.prepend('<i class="fa fa-chevron-up"></i> ')

@toggle_content = (elem) ->
  elem = $(elem)
  $(elem.attr('data-selector')).toggle()
  if elem.find('i').length > 0
    elem.find('i').toggleClass('fa-chevron-up fa-chevron-down')

@set_loaded_location = ->
  window.loaded_location = location.hash.split('/')[1]

@clear_loaded_location = ->
  window.loaded_location = false

@refresh_loaded_location = ->
  clear_loaded_location()
  window.onhashchange()

@set_check_timeout = (delay = check_new_interval) ->
  window.check_new_timeout = setTimeout (->
    current_newsgroup = $('#groups_list .selected').attr('data-name')
    current_number = $('#posts_list .selected').attr('data-number')
    check_new_path = '/check_new?location=' + encodeURIComponent(location.hash)
    check_new_path += '&newsgroup=' + encodeURIComponent(current_newsgroup) if current_newsgroup?
    check_new_path += '&number=' + encodeURIComponent(current_number) if current_number?
    window.active_check_new = $.getScript check_new_path
  ), delay

@clear_check_timeout = ->
  clearTimeout(window.check_new_timeout)

@abort_active_check = ->
  if window.active_check_new
    window.active_check_new.abort()
    window.active_check_new = false

@reset_check_timeout = (delay = check_new_interval) ->
  clear_check_timeout()
  abort_active_check()
  set_check_timeout(delay)

@abort_active_scroll = ->
  if window.active_scroll_load
    window.active_scroll_load.abort()
    window.active_scroll_load = false

@set_draft_interval = ->
  $('a.resume_draft').show()
  window.draft_save_timer = setInterval save_draft, draft_save_interval

@save_draft = ->
  localStorage['draft_html'] = $('#dialog').outerHTML()
  localStorage['draft_form'] = JSON.stringify($('#dialog form').serializeArray())

@clear_draft_interval = ->
  clearInterval(window.draft_save_timer)

@init_dialog = ->
  $('body').append(chunks.overlay.clone())
  $('#overlay').focus()

@open_dialog = (content) ->
  $('#overlay').append(content)
  setHotkeyModeDialog()
  # Must be delayed, otherwise outerHeight returns nonsensical values
  setTimeout (-> fix_dialog_height()), 1

@close_dialog = ->
  $('#overlay').remove()
  setHotkeyModeNormal()
  if $('#dashboard').length > 0
    $('#dashboard').focus()
  else
    $('#posts_list').focus()

@scroll_to_selected_post = ->
  if $('#posts_list .selected').length > 0
    view_height = $('#posts_list').height()
    scroll_top = $('#posts_list').scrollTop()
    post_top = $('#posts_list .selected').first().position().top + scroll_top

    if post_top + 20 > scroll_top + view_height or post_top < scroll_top
      $('#posts_list').scrollTop(post_top - (view_height / 2))

# Calls expand_thread or collapse_thread depending on the current state
@toggle_thread_expand = (tr, check_selected = false) ->
  if tr.find('.expandable').length > 0
    return expand_thread(tr)
  else if tr.find('.expanded').length > 0 and (tr.hasClass('selected') or not check_selected)
    return collapse_thread(tr)

# Returns number of rows shown
@expand_thread = (tr) ->
  rows_changed = 0
  tr.find('.expandable').removeClass('expandable').addClass('expanded')
  for child in tr.nextUntil('[data-level=' + tr.attr('data-level') + ']')
    break if parseInt($(child).attr('data-level')) < parseInt(tr.attr('data-level'))
    if $(child).is(':hidden')
      $(child).show()
      rows_changed += 1
    $(child).find('.expandable').removeClass('expandable').addClass('expanded')
  return rows_changed

# Returns number of rows hidden
@collapse_thread = (tr) ->
  rows_changed = 0
  tr.find('.expanded').removeClass('expanded').addClass('expandable')
  for child in tr.nextUntil('[data-level=' + tr.attr('data-level') + ']')
    break if parseInt($(child).attr('data-level')) < parseInt(tr.attr('data-level'))
    if $(child).is(':visible')
      $(child).hide()
      rows_changed += 1
    $(child).find('.expanded').removeClass('expanded').addClass('expandable')
  return rows_changed


window.onhashchange = ->
  if location.hash.substring(0, 3) == '#!/'
    set_reading_mode(false)
    window.active_navigation.abort() if window.active_navigation
    window.active_navigation = $.getScript location.hash.replace('#!/', '')
    new_location = location.hash.split('/')[1]

    if new_location != window.loaded_location
      abort_active_scroll()
      clear_loaded_location()

      $('#post_view').empty()
      $('#groups_list .selected').removeClass('selected')
      $('#groups_list [data-name="' + new_location + '"]').addClass('selected')

      if new_location == 'home'
        $('#group_view').css('bottom', '0')
        $('#group_view').css('border-bottom', '0')
        $('#post_view').hide()
      else
        $('#group_view').css('bottom', '')
        $('#group_view').css('border-bottom', '')
        $('#post_view').show()

      if new_location == 'home' and window.first_load == true
        $('#group_view .loading').activity(spinner_small)
      else
        $('#group_view').empty().activity(spinner_large)
      window.first_load = false

$ ->
  setHotkeyModeNormal()

  chunks.overlay = $('#loader #overlay').clone()
  chunks.ajax_error = $('#loader #ajax_error').clone()
  $('#loader').remove()

  target_external_links()
  $('a.resume_draft').hide() if not localStorage['draft_form']

  if $('#startup_msg').length > 0
    init_dialog()
    $.getScript $('#startup_msg').attr('data-action')

  if location.hash == '' or location.hash.substring(0, 3) != '#!/'
    location.hash = '#!/home'
  else
    window.onhashchange()

  set_check_timeout()

$(document).on 'click', 'a[href="#"]', ->
  return false

$(document).on 'click', '.toggle', ->
  toggle_content(this)

$(document).on 'click', '#crosspost_toggle', ->
  toggled = $($(this).attr('data-selector'))
  if toggled.is(':visible')
    adjust_dialog_original_height(toggled.height())
  else
    adjust_dialog_original_height(0 - toggled.height())

$(document).on 'click', '.add_nested_fields[data-association="subscriptions"]', ->
  adjust_shrinkable_original_height($('#subscription_rows tr').first().height())

$(document).on 'click', '.remove_nested_fields[data-association="subscriptions"]', ->
  adjust_shrinkable_original_height(0 - $('#subscription_rows tr').first().height())

$(document).on 'click', 'a.new_draft', (e) ->
  if localStorage['draft_form'] and not confirm('Really discard your saved draft and start a new post?')
    e.stopImmediatePropagation()
    return false

$(document).on 'click', 'a.post_reply', (e) ->
  added_text = $('#added_post_text').detach()
  selected_text = window.getSelection().toString().replace(/\r\n/g, "\n").replace(/\r/g, "\n")
  selected_index = $('.content .body').text().indexOf(selected_text)
  if selected_index >= 0 and selected_text.length > 0
    $(this).attr('data-href-append', '&quote_start=' + selected_index + '&quote_length=' + selected_text.length)
  added_text.insertBefore('.fullquote')

$(document).on 'click', 'a[href^="#?/"]', ->
  Mousetrap.reset()
  init_dialog()
  request_path = @href.replace('#?/', '')
  if $(this).attr('data-href-append')
    request_path += $(this).attr('data-href-append')
    $(this).removeAttr('data-href-append')
  $.getScript request_path
  return false

$(document).on 'click', 'a.mark_read', ->
  reset_check_timeout()
  $('#next_unread').attr('href', '#')

  path = 'mark_read'
  after_func = null
  scope = $(this).attr('data-scope')
  newsgroup = $('#groups_list .selected').attr('data-name') || $(this).attr('data-newsgroup')
  number = $('#posts_list .selected').attr('data-number') || $(this).attr('data-number')
  thread_id = $('#posts_list .selected').attr('data-thread')

  if scope == 'thread'
    path += '?in_thread=true'
    path += '&newsgroup=' + encodeURIComponent(newsgroup) + '&number=' + number
    if window.loaded_location == 'home'
      row = $(this).parents('tr')
      row.find('.counter.unread').remove()
      link = row.find('.subject a')
      link.removeClass('unread mine_reply mine_in_thread').addClass(link.attr('data-personal-class'))
      $(this).remove()
      after_func = ->
        reset_check_timeout(1500)
    else
      abort_active_scroll()
      after_func = ->
        reset_check_timeout(0)
        $('#posts_list').scroll()
      $('#posts_list tr[data-thread="' + thread_id + '"]').removeClass('unread')
  else if scope == 'newsgroup'
    path += '?newsgroup=' + encodeURIComponent(newsgroup)
    group_item = $('#groups_list [data-name="' + newsgroup + '"]')
    group_item.removeClass('unread mine_reply mine_in_thread').find('.unread_count').remove()
    $('#next_unread').attr('href', '#') if $('#groups_list .unread_count').length == 0
    abort_active_scroll()
    after_func = -> $('#posts_list').scroll()
    $('#posts_list tbody tr').removeClass('unread')
  else if scope == 'all'
    path += '?all_posts=true'
    $('#groups_list li').removeClass('unread mine_reply mine_in_thread').find('.unread_count').remove()
    $('#next_unread').attr('href', '#')
    if window.loaded_location == 'home'
      document.title = 'WebNews'
      $('#unread_line').text('You have no unread posts.')
      $('.activity a').removeClass('unread')
      $('.activity .counter.unread').remove()
      $('#mark_read_toggle').addClass('invisible')
    else
      abort_active_scroll()
      $('#posts_list tbody tr').removeClass('unread')
      after_func = -> $('#posts_list').scroll()

  $.ajaxScript 'PUT', path, after_func
  return false

$(document).on 'click', 'a.mark_unread', ->
  clear_check_timeout()
  abort_active_check()
  $('#posts_list .selected').addClass('unread')
  $.ajaxScript 'PUT', @href.replace('#~/', ''), -> set_check_timeout(0)
  return false

$(document).on 'click', '#star_post_button', ->
  $.ajaxScript 'PUT', @href.replace('#~/', '')
  return false

$(document).on 'click', '#reading_mode_button', ->
  set_reading_mode(!$('#reading_mode_button').hasClass('enabled'))

$(document).on 'click', 'a.update_api_settings', ->
  $('#update_api_buttons').text('Working...')
  $.ajaxScript 'PUT', @href.replace('#~/', '')
  return false

$(document).on 'click', '.change_theme', ->
  $('link[rel="stylesheet"]').first().attr('href', $(this).attr('data-path'))

$(document).on 'click', '#do_sticky', ->
  if $(this).is(':checked')
    $('#sticky_until').prop('disabled', false).focus()
  else
    $('#sticky_until').val('').prop('disabled', true)

$(document).on 'click', '#crosspost_toggle', ->
  $('#crosspost_to').val('')
  $('.crosspost_options input').val([])

$(document).on 'click', 'a.minimize_draft', ->
  save_draft()

$(document).on 'click', 'a.dialog_cancel', ->
  clear_draft_interval()
  close_dialog()

$(document).on 'click', 'a.clear_draft', ->
  localStorage.removeItem('draft_html')
  localStorage.removeItem('draft_form')
  $('a.resume_draft').hide()

$(document).on 'click', 'a.resume_draft', ->
  init_dialog()
  open_dialog(localStorage['draft_html'])
  for elem in JSON.parse(localStorage['draft_form'])
    $('#dialog form [name="' + elem.name + '"]').val(elem.value)
  $('#post_body').focusAtEnd() if $('#post_body').val() != ''
  set_draft_interval()

$(document).on 'click', '#new_post [type="submit"]', (e) ->
  body = $('#new_post #post_body').first().val()
  if $.trim(body).length == 0 and not confirm('Really submit this post with no content?')
    e.stopImmediatePropagation()
    return false

$(document).on 'click', '[type="submit"]', ->
  $('#dialog .buttons').hide()
  $('#dialog .loading').text('Working...')
  $('#dialog .errors').text('')

$(document).on 'click', 'a.refresh', ->
  refresh_loaded_location()

$(document).on 'click', '#posts_list .expander', (e) ->
  toggle_thread_expand($(this).closest('tr'))
  e.stopImmediatePropagation()

$(document).on 'click', '#posts_list tbody tr', (e, do_toggle = true) ->
  tr = $(this)

  href = tr.find('a').attr('href')
  if href.substring(0, 3) == '#~/'
    $.getScript href.replace('#~/', '')
  else
    location.hash = href

  toggle_thread_expand(tr, true) if do_toggle

  $('#posts_list .selected').removeClass('selected')
  tr.addClass('selected')
  return false

$(document).on 'mousedown', 'a, button, input', -> this.style.outlineStyle = 'none'
$(document).on 'blur', 'a, button, input', -> this.style.outlineStyle = ''

$(document).on 'focus', 'a, input, select, textarea, button', ->
  if $('#dialog').length > 0 and $(this).parents('#dialog').length == 0
    $('#dialog').find('a[href], input, select, textarea, button').
      filter(':visible').not(':disabled').first().focus()
    return false
  else if $('#overlay').length > 0 and $('#dialog').length == 0
    $('#overlay').focus()
    return false

$(window).resize ->
  fix_post_header()
  fix_dialog_height()

$(document).ajaxComplete ->
  fix_post_header()
  target_external_links()
  for link in $('.toggle')
    init_toggle(link)

$(document).ajaxError (event, jqxhr, settings, exception) ->
  if jqxhr.readyState != 0
    if settings.url.match 'check_new'
      $('body').append(chunks.ajax_error.clone()) if $('#ajax_error').length == 0
      window.active_check_new = false
      set_check_timeout(check_new_retry_interval)
    else
      alert("\"#{exception}\" occurred while requesting #{settings.url}\n\nThis error could indicate a network issue or a bug in WebNews. Check your connection and refresh the page. If the error persists, please file a bug report with the steps needed to reproduce it and the full text of the error message above.")
