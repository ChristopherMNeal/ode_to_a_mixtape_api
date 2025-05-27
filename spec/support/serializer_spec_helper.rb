# frozen_string_literal: true

module SerializerSpecHelper
  def serialize(object, options = {})
    serializer_class = options.delete(:serializer) || "#{object.class.name}Serializer".constantize
    serializer = serializer_class.new(object)
    adapter = ActiveModelSerializers::Adapter.create(serializer, options)
    adapter.as_json
  end
end

RSpec.configure do |config|
  config.include SerializerSpecHelper
end
