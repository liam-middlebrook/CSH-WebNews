<% if @not_found %>

$('#post_view').html '<%= j render("not_found") %>'
document.title = '<%= @newsgroup.name %> \u00bb Post not found!'
if window.loaded_location != '<%= @newsgroup.name %>'
  $.getScript '<%= posts_path(@newsgroup.name) %>?not_found=true'
else
  $('#posts_list .selected').removeClass('selected')

<% else %>

select_post = (showing) ->
  post_tr = $('#posts_list tr[data-id="<%= @post.id %>"]')
  
  if post_tr.is(':hidden') or (showing and post_tr.attr('data-parent') == 'false')
    parent = if post_tr.is(':hidden') then post_tr.prevAll('[data-level="1"]:first') else post_tr
    parent.find('.expandable').removeClass('expandable').addClass('expanded')
    for child in parent.nextUntil('[data-level="1"]')
      $(child).show()
      $(child).find('.expandable').removeClass('expandable').addClass('expanded')
  
  $('#posts_list .selected').removeClass('selected')
  post_tr.addClass('selected')
  
  view_height = $('#posts_list').height()
  scroll_top = $('#posts_list').scrollTop()
  post_top = post_tr.position().top + scroll_top
  
  if post_top + 20 > scroll_top + view_height or post_top < scroll_top
    $('#posts_list').scrollTop(post_top - (view_height / 2))

$('#post_view').html '<%= j render(@post) %>'

<% if not @search_mode %>
document.title = '<%= @newsgroup.name %> \u00bb <%= raw j(@post.subject) %>'
<% end %>

if $('#posts_list tr[data-id="<%= @post.id %>"]').length == 0
  $('#group_view').empty().append(chunks.spinner.clone())
  $.getScript '<%= posts_path(@newsgroup.name) %>?showing=<%= @post.number %>', -> select_post(true)
  $('#post_view .content').focus()
else
  select_post(false)
  $('#posts_list .selected').removeClass('unread')

<% if @post_was_unread %>
reset_check_timeout()
<% @post.all_newsgroups.each do |group| %>
group_li = $('#groups_list li[data-name="<%= group.name %>"]')
selected = group_li.hasClass('selected')
group_li.removeClass()
unread = <%= raw group.unread_for_user(@current_user).to_json %>

if unread.count > 0
  group_li.addClass('unread').addClass(unread.hclass)
  group_li.find('.unread_count').text(' (' + unread.count + ')')
else
  group_li.find('.unread_count').remove()

group_li.addClass('selected') if selected
<% end %>
<% end %>

$('#next_unread').attr('href', '<%= next_unread_href %>')
$(window).resize()

<% end %>
