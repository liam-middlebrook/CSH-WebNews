$ ->
  key.setScope('main')
  
  # Select the next/previous post
  key 'j', 'main', -> click $('#posts_list .selected').prevAll('tr:visible')[0], false
  key 'k', 'main', -> click $('#posts_list .selected').nextAll('tr:visible')[0], false
  
  # Select the next/previous thread
  key 'h', 'main', -> click $('#posts_list .selected').prevAll('tr[data-level="1"]')[0], false
  key 'l', 'main', -> click $('#posts_list .selected').nextAll('tr[data-level="1"]')[0], false
  
  # Select the next/previous newsgroup
  key 'shift+h', 'main', -> click $('#groups_list .selected').prev('li').find('a')
  key 'shift+l', 'main', -> click $('#groups_list .selected').next('li').find('a')
  
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
  key 'o', 'main', -> click $('#home_button')
  key 'n', 'main', -> click $('#next_unread')
  key 'shift+s', 'main', -> click $('#search_button')
  key 's', 'main', ->
    for button in ['#revise_search_button', '#newsgroup_search_button', '#search_button']
      if $(button).length > 0
        click $(button)
        return
  
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


@click = (elem, extra_data = null) ->
  $(elem).trigger('click', extra_data)
  if (hash = $(elem).attr('href')) && hash[0..1] == '#!'
    location.hash = hash[1..-1]
