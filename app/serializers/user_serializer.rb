class UserSerializer < ActiveModel::Serializer
  attributes :username, :display_name, :created_at, :is_admin

  def display_name
    object.real_name
  end

  def is_admin
    object.admin?
  end
end
