<% if @star_error %>
alert('<%= @star_error %>')
<% else %>

<% if @starred %>
$('#star_post_button').addClass('starred')
<% else %>
$('#star_post_button').removeClass('starred')
<% end %>

<% end %>
