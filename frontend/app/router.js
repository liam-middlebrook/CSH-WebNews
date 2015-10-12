import Ember from 'ember';
import config from './config/environment';

var Router = Ember.Router.extend({
  location: config.locationType
});

Router.map(function() {
  this.route('newsgroup', { path: 'news/:newsgroup_id' });
});

export default Router;
