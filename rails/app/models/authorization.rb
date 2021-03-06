class Authorization < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id, :uid, :provider
  validates_uniqueness_of :uid, :scope => :provider

  def self.find_with_omniauth(auth)
    find_by_provider_and_uid(auth['provider'], auth['uid'])
  end

  def self.create_with_omniauth(auth)
    info = {}
    case auth['provider']
    when 'ravelry'
      info = {
        'name' => auth['uid'],
        'profile_url' => "http://www.ravelry.com/people/#{auth['uid']}"
      }
    when 'google_oauth2'
      info = {
        'name' => auth['info']['name'],
        'profile_url' => auth['info']['urls']['Google']
      }
    when 'facebook'
      info = {
        'name' => auth['info']['name'],
        'profile_url' => auth['info']['urls']['Facebook']
      }
    end

    create(uid: auth['uid'], provider: auth['provider'], info: info)
  end

  # (possibly) provider-dependent attributes
  def name
    info['name']
  end

  def profile_url
    info['profile_url']
  end
end