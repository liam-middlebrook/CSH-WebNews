# Decodes and encodes Mail::Message objects from or into the "flowed format"
# specified in RFC3676 (though without support for the "DelSp" parameter)

module NNTP
  module FlowedFormat
    def self.decode_message(message)
      if message.content_type_parameters.to_h['format'] == 'flowed'
        message = message.dup
        message.content_type_parameters.delete('format')

        new_body_lines = []
        message.body.to_s.each_line do |line|
          line.chomp!
          quotes = line[/^>+/]
          line.sub!(/^>+/, '')
          line.sub!(/^ /, '')
          if line != '-- ' and
              new_body_lines.length > 0 and
              !new_body_lines[-1][/^-- $/] and
              new_body_lines[-1][/ $/] and
              quotes == new_body_lines[-1][/^>+/]
            new_body_lines[-1] << line
          else
            new_body_lines << quotes.to_s + line
          end
        end

        message.body = new_body_lines.join("\n")
      end

      message
    end

    def self.encode_message(message)
      if (!message.has_content_type? || message.content_type == 'text/plain') &&
          message.content_type_parameters.to_h['format'] != 'flowed'
        message = message.dup
        message.content_type ||= 'text/plain'
        message.content_type_parameters[:format] = 'flowed'

        message.body = message.body.to_s.split("\n").map do |line|
          line.rstrip!
          quotes = ''
          if line[/^>/]
            quotes = line[/^([> ]*>)/, 1].gsub(' ', '')
            line.gsub!(/^[> ]*>/, '')
          end
          line = ' ' + line if line[/^ /]
          if line.length > 78
            line.gsub(/(.{1,#{72 - quotes.length}}|[^\s]+)(\s+|$)/, "#{quotes}\\1 \n").rstrip
          else
            quotes + line
          end
        end.join("\n")
      end

      message
    end
  end
end
