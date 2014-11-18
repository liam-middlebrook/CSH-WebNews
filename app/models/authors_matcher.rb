class AuthorsMatcher < Matcher
  def initialize(authors_string)
    @authors_string = authors_string.to_s
  end

  private

  def where_clause
    [
      exact_author_conditions.presence,
      inexact_author_conditions.presence
    ].compact.join(' OR ')
  end

  def exact_author_conditions
    exact_authors.map do |author|
      sanitize_conditions('posts.author_name = ? OR posts.author_email = ?', author, author)
    end.join(' OR ')
  end

  def inexact_author_conditions
    inexact_authors.map do |author|
      sanitize_conditions('posts.author_raw ILIKE ?', "%#{author}%")
    end.join(' OR ')
  end

  def authors
    @authors ||= authors.split(',').map(&:strip)
  end

  def exact_authors
    @exact_authors ||= authors.select{ |a| a[0] == '+' }.map{ |a| a[1..-1] }
  end

  def inexact_authors
    @inexact_authors ||= authors.reject{ |a| a[0] == '+' }
  end
end
