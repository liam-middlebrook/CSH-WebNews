$('#overlay').append('<%= j render(controller.action_name) %>')
switch '<%= j raw(controller.controller_name + '/' + controller.action_name) %>'
  when 'posts/search_entry'
    $('input[name="keywords"]').focus()
  when 'posts/new'
    $('#post_body').putCursorAtEnd() if $('#post_body').val() != ''
    set_draft_interval()
