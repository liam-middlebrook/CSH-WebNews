import Ember from 'ember';

export default Ember.Service.extend({
  store: Ember.inject.service(),

  model: null,

  // Using 'current' as a fake ID to work around lack of singleton models.
  // This is ignored for the API request thanks to the overridden `buildURL`
  // in UserAdapter, and patched onto the response by UserSerializer.
  setup: function() {
    const currentUser = this.get('store').find('user', 'current');
    this.set('model', currentUser);
    return currentUser;
  }
});
