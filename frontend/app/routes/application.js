import Ember from 'ember';

export default Ember.Route.extend({
  currentUser: Ember.inject.service(),

  beforeModel: function() {
    return this.get('currentUser').setup();
  }
});
