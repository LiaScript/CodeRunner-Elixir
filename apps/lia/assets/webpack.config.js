const path = require('path');
const glob = require('glob');

const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const UglifyJsPlugin = require('uglifyjs-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new UglifyJsPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: {
    'main': './js/main.js'
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, '../priv/static/course')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.scss$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader?sourceMap=false',
          'sass-loader?sourceMap=false',
        ],
      },
      {
        test: /\.css$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          'style-loader',
          MiniCssExtractPlugin.loader,
          'css-loader?sourceMap=true'
        ]
      },
      {
        test: /\.(png|svg|jpg|gif)$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          'file-loader'
        ]
      },
      {
        test: /\.(woff|woff2|eot|ttf|otf)$/,
        use: [
          'file-loader'
        ]
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/[name].css' }),
    new CopyWebpackPlugin([
      { from: 'static/', to: '../' }
    ])
  ]
});
