class ThreadSerializer < PostSerializer
  self.root = :post
  attributes :child_ids
  has_many :descendants, embed: :ids, embed_in_root: true, serializer: self

  def filter(keys)
    keys.delete(:descendants) unless object.root?
    keys
  end

  def child_ids
    object.children.order(:date).ids
  end

  def descendants
    object.descendants.order(:date)
  end
end
