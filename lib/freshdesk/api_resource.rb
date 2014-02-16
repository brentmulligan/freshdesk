module Freshdesk
  class APIResource < FreshObject
    def self.class_name
      self.name.split('::')[-1]
    end

    def self.url()
      if self == APIResource
        raise NotImplementedError.new('APIResource is an abstract class.  You should perform actions on its subclasses (Charge, Customer, etc.)')
      end
      "/#{CGI.escape(class_name.downcase)}s"
    end

    def url
      unless id = self['id'] || self['helpdesk_ticket']['display_id'].to_s
        raise InvalidRequestError.new("Could not determine which URL to request: #{self.class} instance has invalid ID: #{id.inspect}", 'id')
      end
      id = id.to_s
      "#{self.class.url}/#{CGI.escape(id)}"
    end

    def refresh
      response, api_key = Freshdesk.request(:get, url, @api_key, @retrieve_options)
      refresh_from(response, api_key)
      self
    end

    def self.retrieve(id, api_key=nil)
      instance = self.new(id, api_key)
      instance.refresh
      instance
    end
  end
end