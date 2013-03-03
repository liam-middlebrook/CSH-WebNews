previous_height = $('#api_settings').height()
$('#api_settings').html('<%= j render("api_settings") %>')
adjust_shrinkable_original_height($('#api_settings').height() - previous_height)
