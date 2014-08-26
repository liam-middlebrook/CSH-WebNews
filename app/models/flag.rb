class Flag < ActiveRecord::Base
  MAINTENANCE = 1

  serialize :data, JSON

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
end
