require 'faker'
require 'fabrication'

class TentApiDoc
  TentD::Model::ProfileInfo.create!(:type => TentD::Model::ProfileInfo::TENT_PROFILE_TYPE_URI,
                                    :public => true,
                                    :content => {
                                      :licenses => ['http://creativecommons.org/licenses/by/3.0/'],
                                      :entity => 'https://example.org',
                                      :servers => ['https://tent.example.org', 'http://eqt5g4fuenphqinx.onion/']
                                    })

  example(:create_follower) do |clients|
    clients[:base].follower.create(:entity => 'https://example.org',
                                   :types => ['https://tent.io/types/post/status/v0.1.0#full'],
                                   :licenses => ['http://creativecommons.org/licenses/by/3.0/'])
  end

  example(:get_follower) do |clients|
    clients[:follower].follower.get(TentD::Model::Follower.first.public_id)
  end

  example(:update_follower) do |clients|
    follower = TentD::Model::Follower.first
    clients[:follower].follower.update(follower.public_id, follower.attributes.slice(:entity, :licenses).merge(:types => ['https://tent.io/types/post/essay/v0.1.0#full']))
  end

  example(:delete_follower) do |clients|
    follower = TentD::Model::Follower.last
    client = TentClient.new('https://example.com', follower.auth_details.merge(:faraday_adapter => TentD.faraday_adapter))
    client.follower.delete(follower.public_id)
  end

  example(:get_profile) do |clients|
    clients[:base].http.get('/profile')
  end
end
