require 'faker'
require 'fabrication'

class TentApiDoc
  example(:get_profile) do |clients|
    TentD::Model::ProfileInfo.create!(:type => TentD::Model::ProfileInfo::TENT_PROFILE_TYPE_URI,
                                      :public => true,
                                      :content => {
                                        :licenses => ['http://creativecommons.org/licenses/by/3.0/'],
                                        :entity => 'https://example.org',
                                        :servers => ['https://tent.example.org', 'http://eqt5g4fuenphqinx.onion/']
                                      })
    clients[:app].http.get('/profile')
  end
end
