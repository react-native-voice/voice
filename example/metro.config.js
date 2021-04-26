/* eslint-env node */

const path = require('path');
const fs = require('fs');
const blacklist = require('metro-config/src/defaults/blacklist');
const escape = require('escape-string-regexp');

const root = path.resolve(__dirname, '..');

function createExampleConfig(projectRoot, { packageRoot, extraNodeModules }) {
  const pak = JSON.parse(
    fs.readFileSync(path.join(packageRoot, 'package.json'), 'utf8'),
  );

  const modules = [
    ...extraNodeModules,
    ...Object.keys({
      ...pak.dependencies,
      ...pak.peerDependencies,
    }),
  ];

  return {
    projectRoot: projectRoot,
    watchFolders: [packageRoot],

    resolver: {
      blacklistRE: blacklist([
        new RegExp(`^${escape(path.join(packageRoot, 'node_modules'))}\\/.*$`),
      ]),

      extraNodeModules: modules.reduce((acc, name) => {
        acc[name] = path.join(projectRoot, 'node_modules', name);
        return acc;
      }, {}),
    },
  };
}

const exampleConfig = createExampleConfig(__dirname, {
  packageRoot: root,
  extraNodeModules: ['@babel/runtime'],
});

exampleConfig.transformer = {
  getTransformOptions: async () => ({
    transform: {
      experimentalImportSupport: false,
      inlineRequires: true,
    },
  }),
};

module.exports = exampleConfig;
