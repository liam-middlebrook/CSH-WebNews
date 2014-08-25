module NNTP
  class BasicMessage
    include ActiveModel::Model

    attr_accessor :api_user_agent, :api_posting_host, :posting_host, :user

    validates! :posting_host, :user, presence: true

    def to_s
      to_mail.to_s
    end

    private

    def to_mail
      valid?

      mail = Mail.new(from: from_line)

      mail.header['X-WebNews-Posting-Host'] = posting_host
      if api_posting_host.present?
        mail.header['X-WebNews-API-Posting-Host'] = api_posting_host
      end

      if api_user_agent.present?
        mail.header['User-Agent'] = 'CSH-WebNews-API'
        mail.header['X-WebNews-API-Agent'] = api_user_agent
      else
        mail.header['User-Agent'] = 'CSH-WebNews'
      end

      mail
    end

    def from_line
      address = Mail::Address.new
      address.display_name = user.real_name
      address.address = user.email
      address.to_s
    end
  end
end
