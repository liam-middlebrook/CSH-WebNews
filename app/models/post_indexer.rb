class PostIndexer
  include ActiveAttr::Model
  include ActiveModel::ForbiddenAttributesProtection

  MAX_IDS_PER_QUERY = 50
  MAX_POSTS_PER_QUERY = 20

  attribute :as_meta, type: Boolean, default: false
  attribute :as_threads, type: Boolean, default: false
  attribute :authors, type: String
  attribute :keywords, type: String
  attribute :keywords_match_subject, type: Boolean, default: true
  attribute :keywords_match_body, type: Boolean, default: true
  attribute :limit, type: Integer, default: ->{ maximum_limit }
  # TODO: Implement this once there's a good way of getting it from the database
  #attribute :minimum_personal_level, type: Integer, default: 0
  attribute :newsgroup_ids, type: Object, default: []
  attribute :offset, type: Integer, default: 0
  attribute :only_roots, type: Boolean, default: false
  attribute :only_starred, type: Boolean, default: false
  attribute :only_sticky, type: Boolean, default: false
  attribute :only_unread, type: Boolean, default: false
  attribute :reverse_order, type: Boolean, default: false
  attribute :since, type: DateTime
  attribute :until, type: DateTime
  attribute :user, type: Object

  validates! :user, presence: true
  validates :limit, numericality: { greater_than_or_equal_to: 0 }
  validates :offset, numericality: { greater_than_or_equal_to: 0 }
  # validates :minimum_personal_level, numericality: {
  #   greater_than_or_equal_to: 0, less_than: PERSONAL_CODES.size
  # }
  validate :newsgroups_must_exist
  validate :until_must_be_after_since

  def meta
    return unless valid?
    {
      matched_ids: matched_ids,
      total: unpaged_matched_posts.count
    }
  end

  def results
    return unless valid?

    if as_threads && !only_roots
      ancestor_ids = matched_posts.pluck(:ancestry)
        .compact.map{ |a| a.split('/') }.flatten.map(&:to_i)
      threads_scope = Post.where(id: matched_ids + ancestor_ids)

      if newsgroup_ids.any?
        threads_scope
          .with_postings_in_newsgroups(newsgroup_ids)
          .with_top_level_postings
      else
        threads_scope.roots
      end
    else
      matched_posts
    end
  end

  def limit
    [super, maximum_limit].min
  end

  def newsgroup_ids=(value)
    super value.split(',').map(&:to_i)
  end

  def since=(value)
    # A 4-digit year alone is interpreted as start-of-day on 01/01 of that year
    super Chronic.parse((value =~ /^\d{4}$/ ? "Jan 1, #{value}" : value), guess: :begin)
  end

  def until=(value)
    # A 4-digit year alone is interpreted as end-of-day on 12/31 of that year
    super Chronic.parse((value =~ /^\d{4}$/ ? "Dec 31, #{value}" : value), guess: :end)
  end

  private

  def matched_posts
    unpaged_matched_posts.limit(limit).offset(offset)
  end

  def unpaged_matched_posts
    scope = Post.order(created_at: (reverse_order ? :asc : :desc))

    if newsgroup_ids.any?
      scope = scope.with_postings_in_newsgroups(newsgroup_ids)
      scope = scope.with_top_level_postings if only_roots
    else
      scope = scope.roots if only_roots
    end

    scope = scope.sticky if only_sticky
    scope = scope.unread_for_user(user) if only_unread
    scope = scope.starred_by_user(user) if only_starred
    scope = authors_matcher.apply(scope) if authors.present?
    scope = keywords_matcher.apply(scope) if keywords.present?
    scope = scope.where('posts.created_at >= ?', since) if since.present?
    scope = scope.where('posts.created_at <= ?', self.until) if self.until.present?
    scope
  end

  def matched_ids
    @matched_ids ||= matched_posts.pluck(:id)
  end

  def keywords_matcher
    KeywordsMatcher.new(keywords, keywords_match_subject, keywords_match_body)
  end

  def authors_matcher
    AuthorsMatcher.new(authors)
  end

  def maximum_limit
    as_meta ? MAX_IDS_PER_QUERY : MAX_POSTS_PER_QUERY
  end

  def newsgroups_must_exist
    if newsgroup_ids.any? && Newsgroup.where(id: newsgroup_ids).size != newsgroup_ids.size
      errors.add(:newsgroup_ids, 'specifies one or more nonexistent newsgroups')
    end
  end

  def until_must_be_after_since
    if since.present? && self.until.present? && since > self.until
      errors.add(:until, 'specifies an invalid date range')
    end
  end
end
