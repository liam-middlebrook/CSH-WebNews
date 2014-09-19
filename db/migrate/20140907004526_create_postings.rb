class CreatePostings < ActiveRecord::Migration
  def change
    create_table :postings do |t|
      t.references :newsgroup, index: true
      t.references :post, index: true
      t.integer :number
      t.boolean :followup
    end
  end
end
