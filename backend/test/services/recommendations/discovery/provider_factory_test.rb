require "test_helper"

class Recommendations::Discovery::ProviderFactoryTest < ActiveSupport::TestCase
  test "auto activity discovery combines global place and trail sources" do
    providers = Recommendations::Discovery::ProviderFactory.activities("auto")

    assert_equal %w[wikipedia openstreetmap], providers.map(&:name)
  end

  test "explicit activity discovery accepts a comma-separated provider list" do
    providers = Recommendations::Discovery::ProviderFactory.activities("overpass,wikipedia,overpass")

    assert_equal %w[openstreetmap wikipedia], providers.map(&:name)
  end

  test "auto event discovery stays offline without provider credentials" do
    with_event_credentials(ticketmaster: nil, predicthq: nil) do
      providers = Recommendations::Discovery::ProviderFactory.events("auto")

      assert_equal 1, providers.length
      assert_instance_of Recommendations::Discovery::NullProvider, providers.first
    end
  end

  test "auto event discovery activates every configured source" do
    with_event_credentials(ticketmaster: "server-key", predicthq: "global-token") do
      providers = Recommendations::Discovery::ProviderFactory.events("auto")

      assert_equal %w[ticketmaster predicthq], providers.map(&:name)
    end
  end

  test "explicit event discovery accepts a comma-separated provider list" do
    providers = Recommendations::Discovery::ProviderFactory.events("predicthq,ticketmaster,predicthq")

    assert_equal %w[predicthq ticketmaster], providers.map(&:name)
  end

  private

  def with_event_credentials(ticketmaster:, predicthq:)
    previous_ticketmaster = ENV["TICKETMASTER_API_KEY"]
    previous_predicthq = ENV["PREDICTHQ_ACCESS_TOKEN"]
    ticketmaster.nil? ? ENV.delete("TICKETMASTER_API_KEY") : ENV["TICKETMASTER_API_KEY"] = ticketmaster
    predicthq.nil? ? ENV.delete("PREDICTHQ_ACCESS_TOKEN") : ENV["PREDICTHQ_ACCESS_TOKEN"] = predicthq
    yield
  ensure
    previous_ticketmaster.nil? ? ENV.delete("TICKETMASTER_API_KEY") : ENV["TICKETMASTER_API_KEY"] = previous_ticketmaster
    previous_predicthq.nil? ? ENV.delete("PREDICTHQ_ACCESS_TOKEN") : ENV["PREDICTHQ_ACCESS_TOKEN"] = previous_predicthq
  end
end
