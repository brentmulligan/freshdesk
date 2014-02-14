module Freshdesk
  module APIOperations
    module Delete
      def delete(params = {})
        response, api_key = Freshdesk.request(:delete, url, @api_key, params)
        refresh_from(response, api_key)
        self
      end
    end
  end
end
