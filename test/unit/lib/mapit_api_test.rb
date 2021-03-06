require 'test_helper'
require 'mapit_api'

class MockResponse
  attr_reader :code, :to_hash
  def initialize(code, data)
    @code = code
    @to_hash = data
  end
end

class MapitApiTest < ActiveSupport::TestCase

  context "district_snac_for_postcode" do
    should "return the snac for a district council(DIS)" do
      stub_mapit_postcode_response_from_fixture("EX39 1QS")

      assert_equal "18UK", MapitApi.district_snac_for_postcode("EX39 1QS")
    end

    should "return the snac for a london borough(LBO)" do
      stub_mapit_postcode_response_from_fixture("WC2B 6NH")

      assert_equal "00AG", MapitApi.district_snac_for_postcode("WC2B 6NH")
    end

    should "return the snac for a metropolitan district(MTD)" do
      stub_mapit_postcode_response_from_fixture("M2 5DB")

      assert_equal "00BN", MapitApi.district_snac_for_postcode("M2 5DB")
    end

    should "return the snac for a unitary authority(UTA)" do
      stub_mapit_postcode_response_from_fixture("EH15 1AF")

      assert_equal "00QP", MapitApi.district_snac_for_postcode("EH15 1AF")
    end

    should "return the snac for a Isles of Scilly parish(COP)" do
      stub_mapit_postcode_response_from_fixture("TR21 0LW")

      assert_equal "00HF", MapitApi.district_snac_for_postcode("TR21 0LW")
    end

    should "return nil if mapit doesn't return a district area type" do
      stub_mapit_postcode_response_from_fixture("BT1 5GS")

      assert_nil MapitApi.district_snac_for_postcode("BT1 5GS")
    end

    should "raise InvalidPostcodeError for an invalid postcode" do
      GdsApi::Mapit.any_instance.expects(:location_for_postcode).returns(nil)

      assert_raise MapitApi::InvalidPostcodeError do
        MapitApi.district_snac_for_postcode("AB1 2CD")
      end
    end
  end

  context "payload" do
    setup do
      @areas = {
        123 => { "id" => 123, "name" => "Westminster City Council", "country_name" => "England", "type" => "LBO" },
        234 => { "id" => 234, "name" => "London", "country_name" => "England", "type" => "EUR" }
      }
    end
    context "for an AreasByTypeResponse" do
      should "return code and areas attributes in a hash" do
        api_response = MockResponse.new(200, @areas)
        response = MapitApi::AreasByTypeResponse.new(api_response)

        assert_equal 200, response.payload[:code]
        assert_equal 123, response.payload[:areas].first["id"]
        assert_equal "Westminster City Council", response.payload[:areas].first["name"]
        assert_equal 234, response.payload[:areas].last["id"]
        assert_equal "London", response.payload[:areas].last["name"]
      end
    end
    context "for a RegionsResponse" do
      should "prepend England as a region" do
        api_response = MockResponse.new(200, @areas)
        response = MapitApi::RegionsResponse.new(api_response)

        assert_equal 200, response.payload[:code]
        assert_equal "England", response.payload[:areas].first["name"]
        assert_equal "Westminster City Council", response.payload[:areas].second["name"]
        assert_equal "London", response.payload[:areas].last["name"]
      end
    end
    context "payload for an AreasByPostcodeResponse" do
      should "return code and areas attributes in a hash" do
        location = OpenStruct.new(:response => MockResponse.new(200, { "areas" => @areas }))
        response = MapitApi::AreasByPostcodeResponse.new(location)

        assert_equal 200, response.payload[:code]
        assert_equal 123, response.payload[:areas].first["id"]
        assert_equal "Westminster City Council", response.payload[:areas].first["name"]
        assert_equal 234, response.payload[:areas].last["id"]
        assert_equal "London", response.payload[:areas].last["name"]
      end
      should "return a 404 code and no areas if no location is found" do
        location = nil
        response = MapitApi::AreasByPostcodeResponse.new(location)

        assert_equal 404, response.payload[:code]
        assert_equal [], response.payload[:areas]
      end

    end
  end
end
