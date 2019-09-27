/**
 * Metro configuration for React Native
 * https://github.com/facebook/react-native
 *
 * @format
 */

const path = require('path');

module.exports = {
  transformer: {
    getTransformOptions: async () => ({
      transform: {
        experimentalImportSupport: false,
        inlineRequires: false,
      },
    }),
  },
  resolver: {
    extraNodeModules: { // peer dependencies
      '@babel/runtime': path.resolve(__dirname, 'node_modules/@babel/runtime'),
      'react': path.resolve(__dirname, 'node_modules/react'),
      'react-native': path.resolve(__dirname, 'node_modules/react-native'),
    },
  },
  watchFolders: [path.resolve(__dirname, '..')], // lib source
};
