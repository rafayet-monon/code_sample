module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
    rescue_from ActiveRecord::InvalidForeignKey, with: :not_found
    rescue_from ActiveRecord::StatementInvalid, with: :unprocessable_entity
    rescue_from ActiveRecord::RecordNotUnique, with: :not_acceptable
    rescue_from ActiveModel::ForbiddenAttributesError, with: :unprocessable_entity
    rescue_from ActionController::BadRequest, with: :unprocessable_entity
    rescue_from NoMethodError, with: :not_implemented
    rescue_from NameError, with: :unprocessable_entity
    rescue_from ArgumentError, with: :not_implemented
    rescue_from RangeError, with: :unprocessable_entity
    rescue_from PG::InvalidTextRepresentation, with: :unprocessable_entity
    rescue_from PG::ForeignKeyViolation, with: :unprocessable_entity
  end

  private

  def not_found(e)
    json_response({ message: e.message }, :not_found)
  end

  def unprocessable_entity(e)
    json_response({ message: e.message }, :unprocessable_entity)
  end

  def not_acceptable(e)
    json_response({ message: e.message }, :not_acceptable)
  end

  def not_implemented(e)
    json_response({ message: e.message }, :not_implemented)
  end
end