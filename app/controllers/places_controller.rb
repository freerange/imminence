ActionController::Renderers.add :csv do |places, options|
  if places.first.is_a?(Place)
    filename = "#{places.first.data_set.service.slug}.csv"

    headers['Cache-Control']             = 'must-revalidate, post-check=0, pre-check=0'
    headers['Content-Disposition']       = "attachment; filename=#{filename}"
    headers['Content-Type']              = 'text/csv'
    headers['Content-Transfer-Encoding'] = 'binary'

    self.response_body = DataSetCsvPresenter.new(places.first.data_set).to_csv
  end
end

require 'gds_api/mapit'

class GdsApi::Mapit < GdsApi::Base
  def area_for_id(area_id)
    puts "#{base_url}area/#{area_id}.geojson"
    get_json("#{base_url}area/#{area_id}.geojson")
  end
end

class PlacesController < ApplicationController
  respond_to :json, :kml, :csv

  def show
    # Show a set of places in relation to a service
    # Parameters:
    #   id: the slug for the service
    #   _and_
    #   lat, lng: latitude/longitude in decimal degrees to limit the set of
    #             places displayed
    #   max_distance: maximum distance in miles from the lat/long given
    #   limit: maximum number of places to show
    #   _or_
    #   mapit_area_id: the mapit ID for an area (an alternative to lat, lng)
    @service = Service.where(slug: params[:id]).first
    head 404 and return if @service.nil?

    data_set = select_data_set(@service, params[:version])
    head 404 and return if data_set.nil?

    if params[:mapit_area_id]
      mapit_api = GdsApi::Mapit.new( ENV['MAPIT_ENDPOINT'] || 'http://mapit.mysociety.org/')
      response = mapit_api.area_for_id(params[:mapit_area_id]).to_hash
      @places = data_set.places_within(response)
    else
      if params[:max_distance].present?
        max_distance = Distance.new(Float(params[:max_distance]), :miles)
      else
        max_distance = nil
      end

      if params[:lat].present? && params[:lng].present?
        # TODO: should we handle parsing errors here?
        location = Point.new(latitude: params[:lat], longitude: params[:lng])
        @places = data_set.places_near(location, max_distance, params[:limit])
      else
        @places = data_set.places
      end
    end

    # For some reason, Rails isn't picking up that we want to use the CSV
    # renderer to render CSV files.
    respond_with(@places) do |format|
      format.csv { render csv: @places }
    end
  end

  protected
  def select_data_set(service, version = nil)
    if user_signed_in? and version.present?
      service.data_sets.find(version)
    else
      service.active_data_set
    end
  end
end
