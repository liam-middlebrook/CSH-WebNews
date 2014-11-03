class PostIndexer
  include ActiveAttr::Model
  include ActiveModel::ForbiddenAttributesProtection

  DEF_LIMIT = 10
  MAX_LIMIT = 20

  attribute :as_threads, type: Boolean, default: false
  attribute :authors, type: String, default: ''
  attribute :keywords, type: String, default: ''
  attribute :keywords_match_subject, type: Boolean, default: true
  attribute :keywords_match_body, type: Boolean, default: true
  attribute :limit, type: Integer, default: DEF_LIMIT
  # TODO: Implement this once there's a good way of getting it from the database
  #attribute :minimum_personal_level, type: Integer, default: 0
  attribute :newsgroup_ids, type: String, default: ''
  attribute :offset, type: Integer, default: 0
  attribute :only_roots, type: Boolean, default: false
  attribute :only_starred, type: Boolean, default: false
  attribute :only_sticky, type: Boolean, default: false
  attribute :only_unread, type: Boolean, default: false
  attribute :reverse_order, type: Boolean, default: false
  attribute :since, type: String, default: ''
  attribute :until, type: String, default: ''
  attribute :user, type: Object

  validates! :user, presence: true
  validates :limit, numericality: {
    greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_LIMIT
  }
  validates :offset, numericality: { greater_than_or_equal_to: 0 }
  # validates :minimum_personal_level, numericality: {
  #   greater_than_or_equal_to: 0, less_than: PERSONAL_CODES.size
  # }
  validate :keywords_must_have_balanced_quotes
  validate :keywords_must_match_at_least_one_field
  validate :newsgroups_must_exist
  validate :until_must_be_after_since

  def meta
    return nil unless valid?
    {
      results: matched_posts.count,
      total: unpaged_matched_posts.count,
      matched_ids: matched_ids
    }
  end

  def results
    return nil unless valid?

    if as_threads && !only_roots
      ancestor_ids = matched_posts.pluck(:ancestry)
        .compact.map{ |a| a.split('/') }.flatten.map(&:to_i)
      threads_scope = Post.where(id: matched_ids + ancestor_ids)

      if parsed_newsgroup_ids.any?
        threads_scope
          .with_postings_in_newsgroups(parsed_newsgroup_ids)
          .with_top_level_postings
      else
        threads_scope.roots
      end
    else
      matched_posts
    end
  end

  private

  def matched_posts
    unpaged_matched_posts.limit(limit).offset(offset)
  end

  def unpaged_matched_posts
    scope = Post.order(created_at: (reverse_order ? :asc : :desc))

    if parsed_newsgroup_ids.any?
      scope = scope.with_postings_in_newsgroups(parsed_newsgroup_ids)
      scope = scope.with_top_level_postings if only_roots
    else
      scope = scope.roots if only_roots
    end

    scope = scope.sticky if only_sticky
    scope = scope.unread_for_user(user) if only_unread
    scope = scope.starred_by_user(user) if only_starred
    scope = scope.where(keywords_sql) if parsed_keywords.any?
    scope = scope.where(authors_sql) if parsed_authors.any?
    scope = scope.where('posts.created_at >= ?', parsed_since) if parsed_since.present?
    scope = scope.where('posts.created_at <= ?', parsed_until) if parsed_until.present?
    scope
  end

  def matched_ids
    @matched_ids ||= matched_posts.pluck(:id)
  end

  def parsed_keywords
    @parsed_keywords ||= Shellwords.split(keywords) rescue []
  end

  def positive_keywords
    @positive_keywords ||= parsed_keywords.reject{ |kw| kw[0] == '-' }
  end

  def negative_keywords
    @negative_keywords ||= parsed_keywords.select{ |kw| kw[0] == '-' }.map{ |kw| kw[1..-1] }
  end

  def keywords_sql
    positive_conditions = keyword_conditions(positive_keywords).join(' AND ')
    negative_conditions = keyword_conditions(negative_keywords).join(' OR ')
    [
      ("(#{positive_conditions})" if positive_keywords.any?),
      ("NOT (#{negative_conditions})" if negative_keywords.any?)
    ].compact.join(' AND ')
  end

  def keyword_conditions(keywords)
    keywords.map do |keyword|
      [
        (sanitize_conditions('posts.body ILIKE ?', "%#{keyword}%") if keywords_match_body),
        (sanitize_conditions('posts.subject ILIKE ?', "%#{keyword}%") if keywords_match_subject)
      ].compact.join(' OR ')
    end.map{ |condition| "(#{condition})" }
  end

  def parsed_authors
    @parsed_authors ||= authors.split(',').map(&:strip)
  end

  def inexact_authors
    @inexact_authors ||= parsed_authors.reject{ |a| a[0] == '+' }
  end

  def exact_authors
    @exact_authors ||= parsed_authors.select{ |a| a[0] == '+' }.map{ |a| a[1..-1] }
  end

  def authors_sql
    [
      inexact_author_conditions.presence,
      exact_author_conditions.presence
    ].compact.join(' OR ')
  end

  def inexact_author_conditions
    inexact_authors.map do |author|
      sanitize_conditions('posts.author_raw ILIKE ?', "%#{author}%")
    end.join(' OR ')
  end

  def exact_author_conditions
    exact_authors.map do |author|
      sanitize_conditions('posts.author_name = ? OR posts.author_email = ?', author, author)
    end.join(' OR ')
  end

  def sanitize_conditions(*args)
    # FIXME: Non-protected alternative to this? Why is it protected anyway?
    ActiveRecord::Base.send(:sanitize_sql_array, args)
  end

  def parsed_newsgroup_ids
    @parsed_newsgroup_ids ||= newsgroup_ids.split(',').map(&:to_i)
  end

  def parsed_since
    # A 4-digit year alone is interpreted as 01/01 of that year
    @parsed_since ||= Chronic.parse(
      (since =~ /^\d{4}$/ ? "Jan 1, #{since}" : since), guess: :begin
    )
  end

  def parsed_until
    # A 4-digit year alone is interpreted as 12/31 of that year
    @parsed_until ||= Chronic.parse(
      (self.until =~ /^\d{4}$/ ? "Dec 31, #{self.until.to_i}" : self.until), guess: :end
    )
  end

  def keywords_must_have_balanced_quotes
    Shellwords.split(keywords)
  rescue ArgumentError
    errors.add(:keywords, 'has unbalanced quotes')
  end

  def keywords_must_match_at_least_one_field
    if keywords.present? && !keywords_match_subject && !keywords_match_body
      errors.add(:keywords_match_subject, 'cannot be false if keywords match body is false')
    end
  end

  def newsgroups_must_exist
    if newsgroup_ids.present? && Newsgroup.where(id: parsed_newsgroup_ids).size != parsed_newsgroup_ids.size
      errors.add(:newsgroup_ids, 'specifies nonexistent newsgroups')
    end
  end

  def until_must_be_after_since
    if since.present? && self.until.present? && parsed_since > parsed_until
      errors.add(:until, 'specifies an invalid date range')
    end
  end
end
