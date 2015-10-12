import Ember from 'ember';
import moment from 'moment';
const { computed } = Ember;

export default Ember.Component.extend({
  tagName: '',
  model: null,

  newsgroupSorting: ['id'],
  sortedNewsgroups: computed.sort('model', 'newsgroupSorting'),

  lastSyncAt: computed.alias('model.meta.last_sync_at'),
  syncIsStale: computed('lastSyncAt', function() {
    return moment().diff(this.get('lastSyncAt'), 'minutes') > 1;
  }),

  writableGroups: computed.filterBy('sortedNewsgroups', 'postingAllowed', true),
  controlGroups: computed.filterBy('sortedNewsgroups', 'isControl', true),
  readOnlyGroups: computed.filter('sortedNewsgroups', function(newsgroup) {
    return !newsgroup.get('postingAllowed') && !newsgroup.get('isControl');
  }),
  newsgroupGroups: computed(function() {
    return [
      this.get('writableGroups'),
      this.get('readOnlyGroups'),
      this.get('controlGroups')
    ];
  })
});
