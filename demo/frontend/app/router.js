import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.route('articles');

  this.route('article', function() {
    this.route('edit', { path: ':id/edit' });
  });
});

export default Router;
