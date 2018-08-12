class Api::V1::SchoolRequestController < Api::V1::ApplicationController
  def subdomain_redirect
    subdomain = params[:subdomain].downcase
    school = School.find_by_subdomain!(subdomain)
    json_response(school)
  end
end
