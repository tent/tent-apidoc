require 'faker'
require 'fabrication'

class TentApiDoc
  TentD::Model::ProfileInfo.create(:type => TentD::Model::ProfileInfo::TENT_PROFILE_TYPE_URI,
                                   :public => true,
                                   :content => {
                                     :licenses => ['http://creativecommons.org/licenses/by/3.0/'],
                                     :entity => 'https://example.org',
                                     :servers => ['https://tent.example.org', 'http://eqt5g4fuenphqinx.onion/']
                                   })
  TentD::Model::ProfileInfo.create(:type => 'https://tent.io/types/info/basic/v0.1.0',
                                   :public => true,
                                   :content => {
                                     :name => 'The Tentity',
                                     :avatar_url => 'http://example.org/avatar.jpg',
                                     :birthdate => '2012-08-23',
                                     :location => 'The Internet',
                                     :gender => 'Unknown',
                                     :bio => Faker::Lorem.sentence
                                   })

  example(:create_follower) do
    clients[:base].follower.create(
      :entity => 'https://example.org',
      :types => ['all'],
      :licenses => ['http://creativecommons.org/licenses/by/3.0/']
    ).tap {
      clients[:follower] = TentClient.new('https://example.com', TentD::Model::Follower.last.auth_details.merge(:faraday_adapter => TentD.faraday_adapter))
    }
  end

  example(:get_follower) do
    clients[:follower].follower.get(TentD::Model::Follower.first.public_id)
  end

  example(:update_follower) do
    follower = TentD::Model::Follower.first
    clients[:follower].follower.update(follower.public_id, follower.attributes.slice(:entity, :licenses).merge(:types => ['https://tent.io/types/post/essay/v0.1.0#full']))
  end

  example(:get_profile) do
    clients[:base].profile.get
  end

  example(:create_app) do
    clients[:base].app.create(
      :name => "FooApp",
      :description => "Does amazing foos with your data",
      :url => "http://example.com",
      :icon => "http://example.com/icon.png",
      :redirect_uris => ["https://app.example.com/tent/callback"],
      :scopes => {
        :write_profile => "Uses an app profile section to describe foos",
        :read_followings => "Calculates foos based on your followings"
      }).tap {
        clients[:app] = TentClient.new('https://example.com', TentD::Model::App.last.auth_details.merge(:faraday_adapter => TentD.faraday_adapter))
      }
  end

  example(:app_auth) do
    app = TentD::Model::App.first
    auth = app.authorizations.create(
      :scopes => ['read_posts', 'read_profile'],
      :profile_info_types => ['https://tent.io/types/info/music/v0.1.0'],
      :post_types => ['https://tent.io/types/posts/status/v0.1.0', 'https://tent.io/types/posts/photo/v0.2.0']
    )
    variables[:app_code] = auth.token_code
    variables[:app_id] = app.public_id
    clients[:app].app.authorization.create(app.public_id, :code => auth.token_code, :token_type => 'mac')
  end

  example(:delete_follower) do
    follower = TentD::Model::Follower.last
    client = TentClient.new('https://example.com', follower.auth_details.merge(:faraday_adapter => TentD.faraday_adapter))
    client.follower.delete(follower.public_id)
  end
end
