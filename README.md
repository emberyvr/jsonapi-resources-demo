# JSON API with Ember Data 2.1

When Ember 1.13 was released, the biggest change was a total overhaul of Ember Data's internal format and the Serializer API to follow the JSON API specification. The JSON API specification (seen [here](http://jsonapi.org/)) has been in the works for a few years, and recently 1.0 specification was released.

Ember's core team designed this change to operatate *mostly* transparently; in general, you didn't have to do much to update to Ember 1.13 unless you were doing some super custom serialization. 

With previous versions of Ember, if you were using Rails, you were probably using the [active_model_serializers](https://github.com/rails-api/active_model_serializers) gem and the output probably looked something like this:

    {
      "article": {
          "id": 1,
          "title": "JSON API with Ember Data 2.1",
          "author_id": 1
      },
      "authors": [
        {
          "id": 1,
          "name": "Ben Borowski"
        }
      ]
    }

A JSON API compliant output will look more like the following:

    {
      "data": {
        "type": "article",
        "id": 1,
        "attributes": {
          "title": "JSON API with Ember Data 2.1"
        },
        "relationships": {
          "author": {
            "data": { "id": 1, "type": "author" }
          }
        }
      },
      "included": [
        {
          "id": 1,
          "type": "authors",
          "attributes": { "name": "Ben Borowski" }
        }
      ]
    }

You can see here that the "type" and "id" of the object is stored as a separate key on "data", instead of containing all the "attributes" under the object type key. Certainly a bit more complex, but not too different. Now then, if you've been using *active_model_serializers* up until now, how do you get your data in a similar format with Rails?

At the moment, there are two decent options. You *could* use the master branch of *active_model_serializers* and set your adapter to the JsonApi adapter:

    ActiveModel::Serializer.config.adapter = ActiveModel::Serializer::Adapter::JsonApi

If you're starting with a new project though, I'd defintely recommend you jump straight to using the [jsonapi-resources](https://github.com/cerebris/jsonapi-resources) gem. It's a bit more "spec-complete" at the moment, plus it's written by some of the same folks that are working on the JSON API specification (mostly Dan Gebhardt, from the looks of it).

## Rails Setup

Let's start with a new Rails application:

    $ rails new -d postgresql backend
    $ bundle exec rake db:create

And we'll add two models/migrations to our database (we'll build everyone's favorite Rails demo, a blog):

    $ rails generate model Author name:string
    $ rails generate model Article title:string body:text author:references

Finally, let's migrate our database:

    $ bundle exec rake db:migrate

I'll also add some seed data to *db/seeds.rb* to get us started. I'm going to use the Faker gem to add some test data, so add to your *Gemfile*:

    gem 'faker', '~> 1.5.0'

and

    $ bundle install

to install the Faker gem. Finally, let's add some data in *db/seeds.rb*:

    author = Author.create(name: Faker::Name.name)
    5.times do
      Article.create(title: Faker::Book.title, body: Faker::Lorem.paragraphs, author: author)
    end

To get the data into the database, run the seeder:

    $ bundle exec rake db:seed

Let's see what we got via the console:

    $ rails console
    > Article.all.collect(&:title)
      Article Load (0.5ms)  SELECT "articles".* FROM "articles"
      => ["Tomato in the Window", "Next Day Previous Night", "Falling Flags", "Same Way Through", "The Frog Catchers Field Manual"]

Fantastic! We've got our simple data structure, a database, and some seed data. Now let's make a JSON API-compliant API!

## jsonapi-resources

We'll get started on the API by adding the jsonapi-resources gem. Add the following to your Gemfile:

    gem 'jsonapi-resources', '~> 0.6.1'

and install it:

    $ bundle install

The most basic component of jsonapi-resources is the `Resource`. These define the public interface to your API. In general, each of your models will have a corresponding resource. Let's start by creating resources for our two models:

    $ rails generate jsonapi:resource author
    $ rails generate jsonapi:resource article

This will generate two resource files in the default location (in *app/resources*). Edit those to define the attributes you want to include on the resource and define the relationships:

    class AuthorResource < JSONAPI::Resource
      attribute :name
    end

    class ArticleResource < JSONAPI::Resource
      attributes :title, :body
      has_one :author
    end

You'll note this looks pretty familiar if you've already been using active_model_serializers.

Routing to resources

The gem provides some very powerful features to set up an API without much code. First let's use the routing API and update *config/routes.rb*:

    Rails.application.routes.draw do
      jsonapi_resources :articles
      jsonapi_resources :authors
    end

Now we can expect the routes it's created from the command line:

    $ rake routes

                              Prefix Verb      URI Pattern                                          Controller#Action
    article_relationships_author GET       /articles/:article_id/relationships/author(.:format) articles#show_relationship {:relationship=>"author"}
                                 PUT|PATCH /articles/:article_id/relationships/author(.:format) articles#update_relationship {:relationship=>"author"}
                                 DELETE    /articles/:article_id/relationships/author(.:format) articles#destroy_relationship {:relationship=>"author"}
                  article_author GET       /articles/:article_id/author(.:format)               authors#get_related_resource {:relationship=>"author", :source=>"articles"}
                        articles GET       /articles(.:format)                                  articles#index
                                 POST      /articles(.:format)                                  articles#create
                         article GET       /articles/:id(.:format)                              articles#show
                                 PATCH     /articles/:id(.:format)                              articles#update
                                 PUT       /articles/:id(.:format)                              articles#update
                                 DELETE    /articles/:id(.:format)                              articles#destroy
                         authors GET       /authors(.:format)                                   authors#index
                                 POST      /authors(.:format)                                   authors#create
                          author GET       /authors/:id(.:format)                               authors#show
                                 PATCH     /authors/:id(.:format)                               authors#update
                                 PUT       /authors/:id(.:format)                               authors#update
                                 DELETE    /authors/:id(.:format)                               authors#destroy


Wow, so it's set up an entire RESTful routing sytem to do all the things we'd want to do with our articles and authors. So how do we handle these actions? Next we'll add some controllers to handle them:
    
    # app/controllers/articles_controller.rb
    class ArticlesController < JSONAPI::ResourceController
    end

    # app/controllers/authors_controller.rb
    class AuthorsController < JSONAPI::ResourceController
    end

Start up rails if you haven't yet and navigate to http://localhost:3000/articles.

    TODO: IMAGE OF OUTPUT

How about a single article? http://localhost:3000/articles/1.

    TODO: IMAGE OF OUTPUT

Okay, wow, it looks like our API is pretty much "done!" We can even post to this same endpoint to create an article:

    $ curl -i -H "Accept: application/vnd.api+json" -H 'Content-Type:application/vnd.api+json' -X POST -d '{"data": {"type":"authors", "attributes":{"name":"Fake Kname"}}}' http://localhost:3000/authors

You can add ?include=author to the URL to side load the author data as well http://localhost:3000/articles/1?include=author:

    TODO: image of output

There's lots more you can do to restrict access to resources, filter the data and so on, so I recommend you read the primary README file on github as it's loaded with great info. We've got a basic API to do CRUD operations with Ember, though, so let's create our Ember app.


## Ember.js

Let's start by creating a new application with Ember CLI along-side the rails *backend* folder:

    $ ember new frontend

Ember CLI is currently locked to Ember 1.13.x (this is going to change very shortly), so first thing we'll do is update those dependencies:

    $ npm install ember-data@2.1.0 --save-dev
    $ bower install ember#2.1.0 --save
    $ bower install ember-data#2.1.0 --save

If bower asks you to select a version, choose the one that persists the 2.1.0 version, like so:

    TODO: IMAGE

Great, now you're running Ember 2.0 when you run `ember serve`.

### Models

Let's generate models for the models we already created in the backend.
    
    $ ember generate model author name:string
    $ ember generate model article title:string body:string author:belongs-to:author

### Display the articles

First let's generate a view to display a list of articles in:

    $ ember generate route articles

Edit the generated route in *app/routes/articles.js*:

    import Ember from 'ember';
    export default Ember.Route.extend({
      model() {
        return this.store.findAll('article');
      }
    });


and then open up *app/templates/articles.hbs* and add a list of articles based on the model we're fetching:

    {{#each model as |article|}}
      <p>
        {{article.title}} by <em>{{article.author.name}}</em>
      </p>
    {{/each}}

Finally, let's start the Ember server up and proxy all requests to the Rails application (which should be running too):

    $ ember serve --proxy=http://localhost:3000

Hitting http://localhost:4200/articles should show a list of articles with authors now. 

    TODO: IMAGE

You may find that the author names do not display, if so, check your console output. It probably has to do with a Cross-Origin Resource Sharing (CORS) issue. To solve it, shut down the rails server and follow along with the next section. 

### CORS

We'll add the [rack-cors](https://github.com/cyu/rack-cors) gem to handle the CORS configuration for us:

    gem 'rack-cors', require: 'rack/cors'

Install the gem:

    $ bundle install

Add the following snippet to your *config/application.rb*:

    config.middleware.insert_before 0, "Rack::Cors", :debug => true, :logger => (-> { Rails.logger }) do
      allow do
        origins '*'
        resource '/cors', :headers => :any, :methods => [:post], :credentials => true, :max_age => 0
        resource '*', :headers => :any, :methods => [:get, :post, :delete, :put, :patch, :options, :head], :max_age => 0
      end
    end

Great, now start up the Rails server again and head back to your Ember app. The articles should be loading the author now as well. There may be some other warnings in the console that you'll have to resolve for a production app, but for our demo, we can safely ignore those for now.
