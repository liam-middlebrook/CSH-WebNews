class KeywordsMatcher < Matcher
  VALID_FIELDS = %w(subject body headers)
  DEFAULT_FIELDS = %w(subject body)

  def initialize(keywords_string, match_fields = DEFAULT_FIELDS)
    # Ensure balanced quotes in the keywords string for Shellwords parsing
    @keywords_string = keywords_string.to_s
    @keywords_string += '"' if @keywords_string.count('"').odd?
    @match_fields = VALID_FIELDS & match_fields
  end

  private

  def where_clause
    positive_conditions = keyword_conditions(positive_keywords).join(' AND ')
    negative_conditions = keyword_conditions(negative_keywords).join(' OR ')
    [
      ("(#{positive_conditions})" if positive_conditions.present?),
      ("NOT (#{negative_conditions})" if negative_conditions.present?)
    ].compact.join(' AND ')
  end

  def keyword_conditions(words)
    words.map do |word|
      @match_fields.map do |field|
        sanitize_conditions("posts.#{field} ILIKE ?", "%#{word}%")
      end.compact.join(' OR ')
    end.map{ |condition| "(#{condition})" if condition.present? }
  end

  def keywords
    @keywords ||= Shellwords.split(@keywords_string)
  end

  def positive_keywords
    @positive_keywords ||= keywords.reject{ |kw| kw[0] == '-' }
  end

  def negative_keywords
    @negative_keywords ||= keywords.select{ |kw| kw[0] == '-' }.map{ |kw| kw[1..-1] }
  end
end
