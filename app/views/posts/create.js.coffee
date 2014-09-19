clear_draft_interval()
localStorage.removeItem('draft_html')
localStorage.removeItem('draft_form')
$('a.resume_draft').hide()

<% if @sync_error %>
close_dialog()
alert('<%= j @sync_error %>')
<% else %>
location.hash = '#!<%= post_path(@post.primary_newsgroup.name, @post.primary_posting.number) %>'
close_dialog()
<% end %>
