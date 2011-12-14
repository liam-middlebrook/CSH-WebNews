$ ->
  # Select the previous or next post
  key 'j', -> click $('#posts_list .selected').prevAll('tr:visible')[0], false
  key 'k', -> click $('#posts_list .selected').nextAll('tr:visible')[0], false
  
  # Select the previous or next thread
  key 'h', -> click $('#posts_list .selected').prevAll('tr[data-level="1"]')[0], false
  key 'l', -> click $('#posts_list .selected').nextAll('tr[data-level="1"]')[0], false
  
  # Select the previous or next newsgroup
  key 'shift+h', -> click $('#groups_list .selected').prev('li').find('a')
  key 'shift+l', -> click $('#groups_list .selected').next('li').find('a')
  
  # Go to next unread post
  key 'n', -> click $('#next_unread')
  
  # Expand or collapse the current post
  key 'e', -> toggle_thread_expand($('#posts_list .selected'))
  
  # Expand or collapse the current thread
  key 'shift+e', ->
    selected = $('#posts_list .selected')
    if selected.attr('data-level') != '1'
      selected = selected.prevAll('tr[data-level="1"]')[0]
      click selected, false
    toggle_thread_expand($(selected))
  
  # Mark all read, mark all in group read
  key 'alt+r', -> click $('#toolbar .mark_read')
  key 'shift+r', -> click $('#group_view .mark_read')


@click = (elem, extra_data = null) ->
  $(elem).trigger('click', extra_data)
  if (hash = $(elem).attr('href')) && hash[0..1] == '#!'
    location.hash = hash[1..-1]
