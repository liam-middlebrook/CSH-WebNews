class DigestScheduler
  def self.send
    User.find_each do |user|
      Time.use_zone(user.time_zone) do
        now = Time.now

        if now.between?(now.beginning_of_day + 30.minutes, now.beginning_of_day + 90.minutes)
          Mailer.posts_digest(
            user,
            now.beginning_of_day - 1.day,
            now.end_of_day - 1.day,
            'daily'
          ).deliver_now
        end

        if now.between?(now.beginning_of_week + 30.minutes, now.beginning_of_week + 90.minutes)
          Mailer.posts_digest(
            user,
            now.beginning_of_week - 1.week,
            now.end_of_week - 1.week,
            'weekly'
          ).deliver_now
        end

        if now.between?(now.beginning_of_month + 30.minutes, now.beginning_of_month + 90.minutes)
          Mailer.posts_digest(
            user,
            now.beginning_of_month - 1.month,
            now.end_of_month - 1.month,
            'monthly'
          ).deliver_now
        end
      end
    end
  end
end
