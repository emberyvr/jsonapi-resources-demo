import Ember from 'ember';

export default Ember.Controller.extend({

  articles: Ember.computed.alias('model')

});
