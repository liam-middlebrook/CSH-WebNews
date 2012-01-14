NEWS_SERVER = 'news.csh.rit.edu'
PROFILES_URL = 'https://members.csh.rit.edu/profiles/members/'
WIKI_URL = 'https://wiki.csh.rit.edu/wiki/'
WIKI_USER_URL = WIKI_URL + 'User:'
LOCAL_EMAIL_DOMAIN = '@csh.rit.edu'

ENV_USERNAME = 'WEBAUTH_USER'
ENV_REALNAME = 'WEBAUTH_LDAP_CN'

DATE_FORMAT = '%-m/%-d/%Y %-I:%M%P'
SHORT_DATE_FORMAT = '%-m/%-d %-I:%M%P'

RECENT_EXCLUDE = /^(control|csh\.lists|csh\.test)/

# Randomly generate a short string unlikely to be found in post content
MARK_STRING = (1..12).map{ ('A'..'Z').to_a[rand(26)] }.join.gsub(/[AEIOU]/, 'x')

PERSONAL_CODES = { nil => 0, :mine_in_thread => 1, :mine_reply => 2, :mine => 3 }.freeze
PERSONAL_CLASSES = PERSONAL_CODES.keys.map(&:to_s).freeze
