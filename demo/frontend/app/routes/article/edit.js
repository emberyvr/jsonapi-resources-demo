import Ember from 'ember';

export default Ember.Route.extend({

  model(params) {
    return this.store.findRecord('article', params.id);
  },

  actions: {

    savePost() {
      let model = this.get('controller.model');
      model.save().then(() => {
        console.info('saved!');
        this.transitionTo('articles');
      });
    }

  }

});
