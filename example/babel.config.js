const pak = require('../package.json');
const path = require('path');

function createResolver(pkg) {
  return {
    [pkg.name]: path.join(
      __dirname,
      '..',
      pkg['react-native'] || pkg.module || pkg.main,
    ),
  };
}

module.exports = function(api) {
  api.cache(true);
  return {
    presets: ['module:metro-react-native-babel-preset'],
    plugins: [
      [
        'babel-plugin-module-resolver',
        {
          alias: createResolver(pak),
        },
      ],
    ],
  };
};
