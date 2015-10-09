import Ember from 'ember';
import DS from 'ember-data';

export default DS.Model.extend({
  description: DS.attr('string'),
  postingAllowed: DS.attr('boolean'),
  newestPostAt: DS.attr('date'),
  oldestPostAt: DS.attr('date'),
  unreadCount: DS.attr('number'),
  maxUnreadLevel: DS.attr('number'),
  isControl: Ember.computed('name', function() {
    return /^control/.test(this.get('id'));
  })
});
