$ ->
  key.setScope('main')
  
  # Select the next/previous post
  key 'j', 'main', ->
    prev_post = $('#posts_list .selected').prevAll('tr:visible')[0]
    if prev_post
      click prev_post, false
    else
      click $('#posts_list tbody tr:visible').last()
  key 'k', 'main', ->
    next_post = $('#posts_list .selected').nextAll('tr:visible')[0]
    if next_post
      click next_post, false
    else
      click $('#posts_list tbody tr:visible').first()
  
  # Select the next/previous thread
  key 'shift+j', 'main', ->
    prev_thread = $('#posts_list .selected').prevAll('tr[data-level="1"]')[0]
    if prev_thread
      click prev_thread, false
    else
      click $('#posts_list tr[data-level="1"]').last()
  key 'shift+k', 'main', ->
    next_thread = $('#posts_list .selected').nextAll('tr[data-level="1"]')[0]
    if next_thread
      click next_thread, false
    else
      click $('#posts_list tr[data-level="1"]').first()
  
  # Select the next/previous newsgroup
  key 'alt+j', 'main', ->
    prev_group = $('#groups_list .selected').prev('li')[0]
    if prev_group
      click $(prev_group).find('a')
    else
      prev_group = $('#groups_list .selected').parent('ul').prev('ul').children('li').last()[0]
      if prev_group
        click $(prev_group).find('a')
      else
        click $('#groups_list li a').last()
  key 'alt+k', 'main', ->
    next_group = $('#groups_list .selected').next('li')[0]
    if next_group
      click $(next_group).find('a')
    else
      next_group = $('#groups_list .selected').parent('ul').next('ul').children('li').first()[0]
      if next_group
        click $(next_group).find('a')
      else
        click $('#groups_list li a').first()
  
  # Expand or collapse the current post/thread
  key 'e', 'main', -> toggle_thread_expand($('#posts_list .selected'))
  key 'shift+e', 'main', ->
    selected = $('#posts_list .selected')
    if selected.attr('data-level') != '1'
      selected = selected.prevAll('tr[data-level="1"]')[0]
      click selected, false
    toggle_thread_expand($(selected))
  
  # Mark all read, mark all in group read
  key 'alt+r', 'main', -> click $('#toolbar .mark_read')
  key 'shift+r', 'main', -> click $('#group_view .mark_read')
  
  # Toolbar functions
  key 'h', 'main', -> click $('#home_button')
  key 'n', 'main', -> click $('#next_unread')
  key 'shift+s', 'main', -> click $('#search_button')
  key 's', 'main', ->
    for button in ['#revise_search_button', '#newsgroup_search_button', '#search_button']
      if $(button).length > 0
        click $(button)
        return
  key 'p', 'main', -> click $('#group_view .new_draft')
  key 'r', 'main', -> click $('#post_view .new_draft')
  
  # Dialog functions
  key 'esc', 'dialog', ->
    if $('.dialog_cancel.clear_draft').length > 0
      click $('.dialog_cancel.clear_draft')
    else
      click $('.dialog_cancel')
  key 'alt+m', 'dialog', ->
    click $('.minimize_draft')
  key 'alt+m', 'main', ->
    if $('.resume_draft').is(':visible')
      click $('.resume_draft')
  key 'alt+s', 'dialog', ->
    click $('#dialog form input[type="submit"]')


@click = (elem, extra_data = null) ->
  $(elem).trigger('click', extra_data)
  if (hash = $(elem).attr('href')) && hash[0..1] == '#!'
    location.hash = hash[1..-1]
