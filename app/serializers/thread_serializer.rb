class ThreadSerializer < PostSerializer
  self.root = :post
  attributes :child_ids
  has_many :descendants, embed: :ids, embed_in_root: true, serializer: self, except: :descendants

  def child_ids
    object.children.order(:created_at).ids
  end

  def descendants
    object.descendants.order(:created_at)
  end
end
