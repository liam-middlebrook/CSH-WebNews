# == Schema Information
#
# Table name: flags
#
#  id         :integer          not null, primary key
#  data       :text
#  created_at :datetime
#  updated_at :datetime
#

class Flag < ActiveRecord::Base
  serialize :data, JSON

  MAINTENANCE = 1

  def self.maintenance_mode?
    where(id: MAINTENANCE).exists?
  end

  def self.maintenance_reason
    find_by(id: MAINTENANCE).try(:data)
  end

  def self.maintenance_mode_on!(reason)
    where(id: MAINTENANCE).first_or_initialize.update!(data: reason)
  end

  def self.maintenance_mode_off!
    find_by(id: MAINTENANCE).try(:destroy!)
  end

  NEWS_SYNC = 2

  def self.with_news_sync_lock(full_sync: false, &block)
    sync_flag = where(id: NEWS_SYNC).first_or_create!
    sync_flag.with_lock do
      yield
      sync_flag.touch if full_sync
    end
  end

  def self.last_full_news_sync_at
    find_by(id: NEWS_SYNC).try(:updated_at)
  end
end
