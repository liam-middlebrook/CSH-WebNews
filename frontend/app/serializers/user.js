import DS from 'ember-data';

export default DS.ActiveModelSerializer.extend({
  normalizeHash: {
    user: (hash) => {
      hash.id = 'current';
      return hash;
    }
  }
});
