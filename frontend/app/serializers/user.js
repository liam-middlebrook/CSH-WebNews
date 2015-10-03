import { ActiveModelSerializer } from 'active-model-adapter';

export default ActiveModelSerializer.extend({
  normalize: function(modelClass, hash, property) {
    hash.id = 'current';
    return this._super(modelClass, hash, property);
  }
});
