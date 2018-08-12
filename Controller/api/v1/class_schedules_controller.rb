class Api::V1::ClassSchedulesController < Api::V1::ApplicationController
  before_action :authenticate_current_user
  def routine
    class_routine = ClassSchedule.get_class_routine(params, current_shift)
    class_times = []
    weekdays = []
    daily_routine = []
    class_routine.first[1].each do |key, value |
      class_times << key
    end
    class_routine.each do |key, value|
      weekdays << Weekday.find(key).name
    end
    new_routine = weekdays.zip(class_routine.values).to_h
    new_routine.each do |key, value|
      per_day = [day: key]
      value.each_with_index do |(key_v, val), index|
        unless val[:message].present?
          per_day << {
              teacher: val[:teacher],
              subject: val[:subject],
              room: val[:room]
          }
        else
          per_day << {
              message: val[:message],
          }
        end
      end
      daily_routine << per_day
    end
    json_response(class_times: class_times, routine: daily_routine)
  end

  def deep_to_a(hash)
    hash.map do |v|
      if v.is_a?(Hash) or v.is_a?(Array) then
        deep_to_a(v)
      else
        v
      end
    end
  end

end