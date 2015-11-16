# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

author = Author.create(name: Faker::Name.name)

5.times do
  Article.create(title: Faker::Book.title, body: Faker::Lorem.paragraphs.join("\n\n"), author: author)
end
