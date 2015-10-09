import Ember from 'ember';
import personalClasses from 'frontend/utils/personal-classes';

export default Ember.Component.extend({
  tagName: 'li',
  model: null,
  classNameBindings: [
    'personalClass',
    'model.unreadCount:unread',
    'model.postingAllowed::read_only'
  ],

  personalClass: Ember.computed('model.maxUnreadLevel', function() {
    return personalClasses[this.get('model.maxUnreadLevel')];
  })
});
