export default {
  name: 'currentUser',
  after: 'store',
  initialize: (container, application) => {
    application.deferReadiness();
    // Using 'current' as a fake ID to work around lack of singleton models.
    // This is ignored for the API request thanks to the overridden `buildURL`
    // in UserAdapter, and patched onto the response by UserSerializer.
    container.lookup('store:main').find('user', 'current').then((user) => {
      container.register('user:current', user, { instantiate: false, singleton: true });
      container.injection('route', 'currentUser', 'user:current');
      container.injection('controller', 'currentUser', 'user:current');
      application.advanceReadiness();
    });
  }
};
