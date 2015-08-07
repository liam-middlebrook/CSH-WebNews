class UnreadCleaner
  def self.clean
    Unread.where(user_id: User.inactive.ids).delete_all
  end
end
