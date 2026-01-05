# Troubleshooting Guide

## Module Resolution Errors

### Error: `react-is` module cannot be resolved

If you encounter an error like:
```
trying to resolve module `react-is` from files .../node_modules/hoist-non-react-statics/dist/hoist-non-react-statics.cjs.js
the package json successfully found however this package itself specifies a main module field that could not be resolved
```

#### Solution 1: Install react-is (Recommended)

Install `react-is` in your project:

```bash
# Using npm
npm install react-is

# Using yarn
yarn add react-is

# Using pnpm
pnpm add react-is
```

#### Solution 2: Clear Metro Cache

Clear Metro bundler cache and restart:

```bash
# Clear Metro cache
npx react-native start --reset-cache

# Or if using Expo
npx expo start --clear
```

#### Solution 3: Check Metro Configuration

Ensure your `metro.config.js` properly resolves node_modules:

```javascript
const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

const config = {
  resolver: {
    // Ensure node_modules are resolved correctly
    nodeModulesPaths: ['node_modules'],
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
```

#### Solution 4: Reinstall Dependencies

Sometimes a clean reinstall fixes module resolution issues:

```bash
# Remove node_modules and lock files
rm -rf node_modules yarn.lock package-lock.json

# Reinstall
yarn install
# or
npm install
```

#### Solution 5: Check React Version Compatibility

Ensure you're using a compatible React version. This library requires:
- `react >= 18.0.0`
- `react-native >= 0.71.0`
- `react-is >= 16.12.0 || ^17.0.0 || ^18.0.0`

Check your `package.json` to verify versions.

### Additional Notes

- `react-is` is typically provided by React itself, but some bundlers require it to be explicitly installed
- This is a known issue with Metro bundler and transitive dependencies
- The library declares `react-is` as an optional peer dependency to help with resolution

