class ArticleResource < JSONAPI::Resource
  attributes :title, :body
  has_one :author
end
