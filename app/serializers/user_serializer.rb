class UserSerializer < ActiveModel::Serializer
  include Avatar
  attributes :username, :display_name, :avatar_url, :created_at, :is_admin

  def is_admin
    object.admin?
  end

  def avatar_url
    avatar_url_for(object.email)
  end
end
