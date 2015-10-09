import Ember from 'ember';

export default Ember.Route.extend({
  currentUser: Ember.inject.service(),

  beforeModel: function() {
    this.refreshNewsgroups();
    return this.get('currentUser').setup();
  },

  refreshNewsgroups: function() {
    // store.findAll doesn't make metadata available
    this.store.query('newsgroup', {}).then((newsgroups) => {
      this.controllerFor('application').set('newsgroups', newsgroups);
      Ember.run.later(this, 'refreshNewsgroups', 10000);
    });
  }
});
