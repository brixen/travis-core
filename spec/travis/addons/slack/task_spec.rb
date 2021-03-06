require 'spec_helper'

describe Travis::Addons::Slack::Task do
  include Travis::Testing::Stubs

  let(:subject) { Travis::Addons::Slack::Task }
  let(:http)    { Faraday::Adapter::Test::Stubs.new }
  let(:client)  { Faraday.new { |f| f.request :url_encoded; f.adapter :test, http } }
  let(:payload) { Travis::Api.data(build, for: 'event', version: 'v0') }

  before do
    subject.any_instance.stubs(:http).returns(client)
    Travis::Features.stubs(:active?).returns(true)
  end

  def run(targets)
    subject.new(payload, targets: targets).run
  end

  it "sends slack notifications to the given targets" do
    targets = ['team-1:token-1#channel1', 'team-2:token-2#channel1']
    message = {
      channel: '#channel1',
      text: 'A build' 
    }.stringify_keys
    expect_slack('team-1', 'token-1', 'channel-1', message)
    expect_slack('team-2', 'token-2', 'channel-1', message)

    run(targets)
    http.verify_stubbed_calls
  end

  def expect_slack(account, token, channel, body)
    host = "#{account}.slack.com"
    path = "/services/hooks/incoming-webhook?token=#{token}"

    http.post(path) do |env|
      env[:url].host.should == host
      env[:url].request_uri.should == path
      MultiJson.decode(env[:body]).should == body
    end
  end

end
