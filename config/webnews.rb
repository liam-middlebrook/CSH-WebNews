# The FQDN of the web server
SERVER_NAME = if Rails.env.production?
  'webnews.csh.rit.edu'
else
  "webnews-#{Rails.env}.csh.rit.edu"
end

# The base URL for legacy web client links
LEGACY_URL_BASE = 'https://webnews.csh.rit.edu'

# The domain part of email addresses for authenticated users
LOCAL_DOMAIN = 'csh.rit.edu'

# URL prefixes for the Profile and Wiki links
PROFILES_URL = 'https://profiles.csh.rit.edu/user/'
WIKI_URL = 'https://wiki.csh.rit.edu/wiki/'
WIKI_USER_URL = WIKI_URL + 'User:'

# Server variables that provide the user's username and display name
ENV_USERNAME = 'WEBAUTH_USER'
ENV_DISPLAY_NAME = 'WEBAUTH_LDAP_CN'

# Default time zone for new users, from `rake time:zones:all`
DEFAULT_TIME_ZONE = 'Eastern Time (US & Canada)'

# Date formats
DATE_FORMAT = '%-m/%-d/%Y %-I:%M%P'
SHORT_DATE_FORMAT = '%-m/%-d %-I:%M%P'
DATE_ONLY_FORMAT = '%-m/%-d/%Y'
MONTH_ONLY_FORMAT = '%B %Y'

# Newsgroups whose names match this SIMILAR TO pattern are excluded from the
# activity feed and "all newsgroups" search
DEFAULT_NEWSGROUP_FILTER = 'control%|%.?test'

# Default subscriptions that are copied to new users on creation
# (must include one newsgroup-less "default" setting with all options set)
NEW_USER_SUBSCRIPTIONS = [
  { unread_level: 0, email_level: 3, digest_type: 'none' },
  { newsgroup_name: 'control.cancel', unread_level: 3, email_level: 3, digest_type: 'none' },
  { newsgroup_name: 'csh.test', unread_level: 3, email_level: 3, digest_type: 'none' }
]
