const path = require('path');
const pak = require('../package.json');

module.exports = {
  project: {
    ios: {
      automaticPodsInstallation: true,
    },
  },
  dependencies: {
    [pak.name]: {
      root: path.join(__dirname, '..'),
    },
  },
};
