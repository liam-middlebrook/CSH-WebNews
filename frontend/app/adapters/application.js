import ActiveModelAdapter from 'active-model-adapter';
import $ from 'jquery';

export default ActiveModelAdapter.extend({
  headers: {
    'Accept': 'application/vnd.csh.webnews.v1+json',
    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
  }
});
