const path = require('path');
const glob = require('glob');

var elmSource = __dirname + '/liascript'
const elmMinify = require("elm-minify");
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
    '/editor/index':  './liascript/src/javascript/webcomponents/ace.js',
    '/formula/index': './liascript/src/javascript/webcomponents/katex.js',
    'app': ['./js/app.js'].concat(glob.sync('./vendor/**/*.js'))
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
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: {
          loader: 'elm-webpack-loader?verbose=true',
          options: {
            forceWatch: true,
            cwd: elmSource,
            //debug: true,
            optimize: true,
          },
        },
      }
    ]
  },
  plugins: [
    new elmMinify.WebpackPlugin(),
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin([
      { from: 'static/', to: '../' },
//      { from: 'liascript/', to: '../course/' },
//      { from: 'liascript/css/', to: '../css/' },
      { from: 'liascript/src/assets/logo.png', to: '../images' },
      { from: 'node_modules/katex/dist/katex.min.css', to: '../course/formula' },
      { from: 'node_modules/ace-builds/src-min-noconflict/', to: '../course/editor' },
      { from: "liascript/vendor/material_icons/material.css", to: '../css'},
      { from: "liascript/vendor/roboto/roboto.css", to: '../css'},
      { from: "liascript/vendor/material_icons/flUhRq6tzZclQEJ-Vdg-IuiaDsNc.woff2", to: '../css/fonts'},
      { from: "liascript/vendor/roboto/fonts", to: '../css/fonts'},
    ])
  ]
});
