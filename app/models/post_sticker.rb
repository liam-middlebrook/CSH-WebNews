class PostSticker
  include ActiveAttr::Model
  include ActiveModel::ForbiddenAttributesProtection

  attribute :expires_at, type: DateTime
  attribute :post, type: Object
  attribute :user, type: Object

  validates! :post, :user, presence: true
  validates :expires_at,
    presence: { message: 'must be a valid datetime' },
    date: {
      after_or_equal_to: proc{ Time.now },
      allow_blank: true,
      message: "can't be in the past"
    }
  validate :post_must_be_root
  validate :user_must_be_admin

  def stick
    return unless valid?
    post.update!(sticky_user: user, sticky_expires_at: expires_at)
  end

  def expires_at=(value)
    super Chronic.parse(value, guess: :begin)
  end

  private

  def post_must_be_root
    if !post.root?
      errors.add(:post, 'must be a root post to be sticky')
    end
  end

  def user_must_be_admin
    if !user.admin?
      errors.add(:post, 'requires admin privileges to sticky')
    end
  end
end
