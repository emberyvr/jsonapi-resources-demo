# config/initializers/jsonapi_resources.rb
JSONAPI.configure do |config|
  # built in paginators are :none, :offset, :paged
  config.default_paginator = :paged

  config.default_page_size = 2
  config.maximum_page_size = 20
end
