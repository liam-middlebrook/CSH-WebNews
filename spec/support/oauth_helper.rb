module OauthHelper
  %w(head get post put patch delete).each do |method_name|
    define_method(method_name) do |path, params = nil, headers = {}|
      super(path, params.to_json, default_headers.merge(headers))
    end
  end

  def default_headers
    {
      'CONTENT_TYPE' => 'application/json',
      accept: 'application/vnd.csh.webnews.v1+json',
      authorization: "Bearer #{access_token.token}"
    }
  end

  def access_token
    @access_token ||= create(:oauth_access_token)
  end

  def oauth_user
    @oauth_user ||= User.find(access_token.resource_owner_id)
  end

  def response_json
    @response_json ||= JSON.parse(response.body).deep_symbolize_keys
  end
end
