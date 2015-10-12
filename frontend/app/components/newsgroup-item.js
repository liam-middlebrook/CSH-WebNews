import Ember from 'ember';
import personalClasses from 'frontend/utils/personal-classes';

export default Ember.Component.extend({
  tagName: '',
  model: null,

  personalClass: Ember.computed('model.maxUnreadLevel', function() {
    return personalClasses[this.get('model.maxUnreadLevel')];
  })
});
