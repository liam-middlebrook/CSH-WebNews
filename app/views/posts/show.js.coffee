<% if @not_found %>

$('#post_view').html '<%= j render("not_found") %>'
document.title = '<%= abbrev_newsgroup(@newsgroup.name) %> \u00bb Post not found!'
if window.loaded_location != '<%= @newsgroup.name %>'
  $.getScript '<%= posts_path(@newsgroup.name) %>?not_found=true'
else
  $('#posts_list .selected').removeClass('selected')

<% else %>

<% posting = @post.postings.find_by(newsgroup_id: @newsgroup.id) %>

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
  scroll_to_selected_post()

$('#post_view').html '<%= j render(@post) %>'

<% if not @search_mode %>
document.title = '<%= abbrev_newsgroup(@newsgroup.name) %> \u00bb <%= raw j(@post.subject) %>'
<% end %>

if $('#posts_list tr[data-id="<%= @post.id %>"]').length == 0
  $('#group_view').empty().activity(spinner_large)
  $.getScript '<%= posts_path(@newsgroup.name) %>?from_number=<%= posting.number %>', -> select_post(true)
  $('#post_view .content').focus()
else
  select_post(false)
  $('#posts_list .selected').removeClass('unread')
  if document.activeElement != $('#posts_list')[0] then $('#post_view .content').focus()

<% if @post_was_unread %>
reset_check_timeout()
<% @post.newsgroups.each do |group| %>
group_li = $('#groups_list li[data-name="<%= group.name %>"]')
selected = group_li.hasClass('selected')
read_only = group_li.hasClass('read_only')
group_li.removeClass()
unread = <%= raw group.unread_for_user(@current_user).to_json %>

if unread.count > 0
  group_li.addClass('unread').addClass(unread.personal_class)
  group_li.find('.unread_count').text(' (' + unread.count + ')')
else
  group_li.find('.unread_count').remove()

group_li.addClass('selected') if selected
group_li.addClass('read_only') if read_only
<% end %>
<% end %>

$('#next_unread').attr('href', '<%= next_unread_href %>')

<% end %>
