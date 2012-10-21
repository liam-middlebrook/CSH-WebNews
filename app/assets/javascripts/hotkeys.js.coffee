# FIXME: Characters requiring a Shift modifier on US keyboards must actually
# be assigned as Shift+<unshifted_character>. Assigning to e.g. '?' or '#' in
# keymaster does not work. See https://github.com/madrobby/keymaster/issues/29

$ ->
  key.filter = (event) ->
    event.preventDefault() if event.keyCode == 27
    # https://github.com/grantovich/CSH-WebNews/issues/54
    # https://github.com/madrobby/keymaster/issues/36
    return !event.ctrlKey
  
  key.setScope('main')
  
  # Select the next/previous post
  key 'k', 'main', ->
    prev_post = $('#posts_list .selected').prevAll('tr:visible')[0]
    if prev_post
      delay_click_post prev_post
    else if $('#posts_list .selected').length == 0
      delay_click_post $('#posts_list tbody tr:visible').last()
  key 'j', 'main', ->
    next_post = $('#posts_list .selected').nextAll('tr:visible')[0]
    if next_post
      delay_click_post next_post
    else if $('#posts_list .selected').length == 0
      delay_click_post $('#posts_list tbody tr:visible').first()
  
  # Select the next/previous thread
  key 'shift+k', 'main', ->
    prev_thread = $('#posts_list .selected').prevAll('tr[data-level="1"]')[0]
    if prev_thread
      delay_click_post prev_thread
    else if $('#posts_list .selected').length == 0
      delay_click_post $('#posts_list tr[data-level="1"]').last()
  key 'shift+j', 'main', ->
    next_thread = $('#posts_list .selected').nextAll('tr[data-level="1"]')[0]
    if next_thread
      delay_click_post next_thread
    else if $('#posts_list .selected').length == 0
      delay_click_post $('#posts_list tr[data-level="1"]').first()
  
  # Select the next/previous newsgroup
  key 'alt+k', 'main', ->
    prev_group = $('#groups_list .selected').prev('li')[0]
    if prev_group
      delay_click_group $(prev_group)
    else
      prev_group = $('#groups_list .selected').parent('ul').prev('ul').children('li').last()[0]
      if prev_group
        delay_click_group $(prev_group)
      else
        delay_click_group $('#groups_list li').last()
  key 'alt+j', 'main', ->
    next_group = $('#groups_list .selected').next('li')[0]
    if next_group
      delay_click_group $(next_group)
    else
      next_group = $('#groups_list .selected').parent('ul').next('ul').children('li').first()[0]
      if next_group
        delay_click_group $(next_group)
      else
        delay_click_group $('#groups_list li').first()
  
  # Expand or collapse the current post/thread
  key 'e', 'main', -> toggle_thread_expand($('#posts_list .selected'))
  key 'shift+e', 'main', ->
    selected = $('#posts_list .selected')
    if selected.attr('data-level') != '1'
      selected = selected.prevAll('tr[data-level="1"]')[0]
      click selected, false
    toggle_thread_expand($(selected))
  
  # Mark read buttons
  key 'alt+shift+i', 'main', -> click $('#mark_all_read_button')
  key 'alt+i', 'main', -> click $('#mark_group_read_button')
  key 'shift+i', 'main', -> click $('#mark_thread_read_button')
  
  # Toolbar functions
  key 'esc', 'main', -> click $('#home_button')
  key 'n', 'main', -> click $('#next_unread')
  key 'shift+s', 'main', -> click $('#starred_button')
  key 'shift+`', 'main', -> click $('#settings_button')
  key 'shift+/', 'main', -> click $('#about_button')
  key '/', 'main', ->
    for button in ['#revise_search_button', '#newsgroup_search_button', '#search_button']
      if $(button).length > 0
        click $(button)
        return
  key 'c', 'main', -> click $('#group_view .new_draft')
  key 'r', 'main', -> click $('#post_view .new_draft')
  key 'h', 'main', -> click $('#show_headers_button')
  key 'u', 'main', -> click $('#mark_unread_button')
  key 't', 'main', -> click $('#sticky_post_button')
  key 'shift+3', 'main', -> click $('#cancel_post_button')
  key 's', 'main', -> click $('#star_post_button')
  key 'q', 'main', -> click $('#show_quote_button')
  key 'v', 'main', -> click $('#view_in_newsgroup_button')
  
  # Dialog functions
  key 'esc, alt+q', 'dialog', ->
    if $('.dialog_cancel.clear_draft').length > 0
      click $('.dialog_cancel.clear_draft')
    else
      click $('.dialog_cancel')
  key 'alt+m', 'dialog', ->
    # Need this so it doesn't double-trigger... why only here?
    setTimeout (-> click $('.buttons .minimize_draft')), 1
  key 'alt+m', 'main', ->
    click $('.resume_draft')
  key 'alt+s', 'dialog', ->
    click $('#dialog form input[type="submit"]')
  
  # Change keyboard focus for scrolling
  key 'alt+up', 'main', ->
    $('#posts_list').focus()
    $('#group_view').css('background-color', '#ffc')
    setTimeout (-> $('#group_view').css('background-color', '')), 150
  key 'alt+down', 'main', ->
    $('#post_view .content').focus()
    $('#post_view').css('background-color', '#ffc')
    setTimeout (-> $('#post_view').css('background-color', '')), 150
