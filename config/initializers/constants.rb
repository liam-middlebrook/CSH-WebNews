PERSONAL_CODES = { nil => 0, :mine_in_thread => 1, :mine_reply => 2, :mine => 3 }.freeze
PERSONAL_CLASSES = PERSONAL_CODES.keys.freeze

# Randomly generate a short string unlikely to be found in post content
MARK_STRING = (1..12).map{ ('A'..'Z').to_a[rand(26)] }.join.gsub(/[AEIOU]/, 'x')
