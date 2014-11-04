module NNTPHelper
  def allow_nntp_server
    allow_any_instance_of(NNTP::Server)
  end
end
