class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.text :data
      t.timestamps
    end
  end
end
