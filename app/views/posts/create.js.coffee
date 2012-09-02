clear_draft_interval()

<% if @sync_error %>
alert('<%= j @sync_error %>')
$('#dialog .buttons').show()
$('#dialog .loading').text('')
save_draft()
<% else %>
localStorage.removeItem('draft_html')
localStorage.removeItem('draft_form')
$('a.resume_draft').hide()
location.hash = '#!<%= post_path(@new_post.newsgroup.name, @new_post.number) %>'
<% end %>

close_dialog()
