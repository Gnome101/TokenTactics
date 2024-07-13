const path = require("path");

module.exports = {
  entry: "./src/index.js",
  output: {
    filename: "bundle.js",
    path: path.resolve(__dirname, "dist"),
  },
  resolve: {
    fallback: {
      "tfhe_bg.wasm": require.resolve("tfhe/tfhe_bg.wasm"),
    },
  },
  module: {
    rules: [
      {
        test: /\.wasm$/,
        type: "webassembly/async",
      },
      {
        test: /\.wasm$/,
        type: "webassembly/async",
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: "babel-loader",
        },
      },
    ],
  },
};
