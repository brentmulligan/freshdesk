module Freshdesk
  class Ticket < APIResource
    include Freshdesk::APIOperations::List
    include Freshdesk::APIOperations::Create
    include Freshdesk::APIOperations::Update

    def refund(params={})
      response, api_key = Freshdesk.request(:post, refund_url, @api_key, params)
      refresh_from(response, api_key)
      self
    end

    def capture(params={})
      response, api_key = Freshdesk.request(:post, capture_url, @api_key, params)
      refresh_from(response, api_key)
      self
    end

    def update_dispute(params)
      response, api_key = Freshdesk.request(:post, dispute_url, @api_key, params)
      refresh_from({:dispute => response}, api_key, true)
      dispute
    end

    def close_dispute
      response, api_key = Freshdesk.request(:post, close_dispute_url, @api_key)
      refresh_from(response, api_key)
      self
    end

    private

    def refund_url
      url + '/refund'
    end

    def capture_url
      url + '/capture'
    end

    def dispute_url
      url + '/dispute'
    end

    def close_dispute_url
      url + '/dispute/close'
    end
  end
end
