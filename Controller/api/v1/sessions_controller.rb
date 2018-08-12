class Api::V1::SessionsController < DeviseTokenAuth::SessionsController
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  def render_create_success
    render json: {
        status: 'success',
        data: resource_data(resource_json: @resource.token_validation_response)
    }
  end
end
