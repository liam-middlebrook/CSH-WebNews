class UnreadCleaner
  def self.clean
    UnreadPostEntry.where(user_id: User.inactive.ids).delete_all
  end
end
