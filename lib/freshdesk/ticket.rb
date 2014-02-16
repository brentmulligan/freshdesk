module Freshdesk
  class Ticket < APIResource
    include Freshdesk::APIOperations::List
    include Freshdesk::APIOperations::Create
    include Freshdesk::APIOperations::Update


    def create_note(note_body, is_private=nil)
      is_private ||= true
      params = { :helpdesk_note => { :body => note_body, :source => '2', :private => is_private } }

      response, api_key = Freshdesk.request(:post, create_note_url, @api_key, params)
      refresh_from(response, api_key)
      self
    end

    def create_tag(tag)
      params = { :name => tag }
      response, api_key = Freshdesk.request(:post, create_tag_url, @api_key, params)
      refresh_from(response, api_key)
      self
    end

    def remove_tag(tag, params={})
      tag_id = get_tag_id(tag)
      if tag_id
        response, api_key = Freshdesk.request(:delete, remove_tag_url(tag_id), @api_key, params)
        refresh_from(response, api_key)
      else
        false
      end
    end

    private

    def create_note_url
      url + '/notes'
    end

    def create_tag_url
      url + '/tag_uses'
    end

    #TODO This is non functional unless the Tag to be removed id/name are mapped below

    def remove_tag_url(tag_id)
      url + '/tag_uses/' + tag_id
    end


    # There does not appear to be a way to retrieve a list of tags set on a ticket
    # and the only way to remove a tag is a delete request using it's ID...
    # For now tag IDs must be mapped to tag names below. I have an inquiry in to Freshdesk about this.

    def get_tag_id(tag_name)
      case tag_name.gsub(/\s+/, '_').downcase.to_sym
      when :pending_art_proof
        '1000019458'
      else
        false
      end
    end

  end
end
