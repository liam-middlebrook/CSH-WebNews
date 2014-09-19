class TrimMessageIds < ActiveRecord::Migration
  def up
    say_with_time 'Trimming message IDs...' do
      Post.update_all("message_id = TRIM(BOTH '<>' FROM message_id)")
    end
  end

  def down
    say_with_time 'Un-trimming message IDs...' do
      Post.update_all("message_id = CONCAT('<', message_id, '>')")
    end
  end
end
