const { IS_PRODUCTION, WEBPACK_OUTPUT_PATH, WEBPACK_PUBLIC_PATH } = require('../webpack.constants');

function buildOutput(noHashedChunks) {
  const hashed = IS_PRODUCTION && !noHashedChunks;

  return {
    path: WEBPACK_OUTPUT_PATH,
    publicPath: WEBPACK_PUBLIC_PATH,
    filename: hashed ? '[name].[contenthash:8].bundle.js' : '[name].bundle.js',
    chunkFilename: hashed ? '[name].[contenthash:8].chunk.js' : '[name].chunk.js',
    globalObject: 'this',
  };
}

module.exports = { buildOutput };
