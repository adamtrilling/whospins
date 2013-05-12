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
      info = {'name' => auth['uid']}
    when 'google_oauth2'
      info = auth[:info]
    end

    create(uid: auth['uid'], provider: auth['provider'], info: info)
  end

  # provider-dependent attributes
  def self.provider_names
    {
      'ravelry' => 'ravelry',
      'google' => 'google_oauth2',
      'facebook' => 'facebook'
    }
  end

  def name
    info['name']
  end

  def profile_url
    'http://placeholder'
  end
end