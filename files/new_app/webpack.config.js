'use strict';

const CleanWebpackPlugin = require('clean-webpack-plugin');
const fs = require('fs-extra');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const path = require('path')
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const TerserJSPlugin = require('terser-webpack-plugin');
const webpack = require('webpack');


function recursiveIssuer(m) {
  if (m.issuer) {
    return recursiveIssuer(m.issuer);
  } else if (m.name) {
    return m.name;
  } else {
    return false;
  }
}


module.exports = (env, argv) => ({
  context: path.join(__dirname, 'app/assets'),

  entry: {
    application: './js/application.js',
    // add other entry points here
  },

  output: {
    filename: argv.mode=='development' ? '[name].js' : '[name][hash].js',
    path: path.resolve(__dirname, 'public/dist'),
    publicPath: argv.mode=='development' ? 'http://localhost:3000/dist/' : '/dist/'
  },

  devtool: argv.mode=='development' ? 'inline-source-map' : false,

  devServer: argv.mode=='development' ? {
    compress: true,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
      'Access-Control-Allow-Headers': 'X-Requested-With, content-type, Authorization'
    },
    port: 3000,
    publicPath: "/dist/",
    proxy: {
      '/': 'http://localhost:3000'
    }
  } : {},

  optimization: argv.mode=='development' ? {} : {
    minimizer: [
      new TerserJSPlugin({}),
      new OptimizeCSSAssetsPlugin({})
    ],
    splitChunks: {
      chunks: 'all'
    }
  },

  plugins: [
    new CleanWebpackPlugin(),

    new MiniCssExtractPlugin(
      {
        filename: argv.mode=='development' ? '[name].css' : '[name][hash].css'
      }
    ),

    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.jQuery': 'jquery',
      // add other modules to automatically load instead of `import` or `require`
    }),

    function() {
      // output the fingerprint
      this.hooks.done.tap('AureliaCLI', function(stats) {
        let output = 'const ASSET_FINGERPRINT = "' + stats.hash + '"'
        fs.writeFileSync('config/initializers/fingerprint.jl', output, 'utf8');
      });
    }
  ],

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          query: {
            'presets': [
              [
                '@babel/preset-env',
                {
                  'modules': false
                }
              ]
            ],
            'plugins': ['@babel/plugin-syntax-dynamic-import']
          }
        }
      },

      {
        test: /\.coffee$/,
        loader: 'coffee-loader'
      },

      {
        test: /\.(sa|sc|c)ss$/,
        exclude: /node_modules/,
        use: [
          {
            loader: MiniCssExtractPlugin.loader,
            options: {
              hmr: argv.mode=='development',
            },
          },
          'css-loader', // parses CSS into CommonJS
          {
            loader: 'postcss-loader',
            options: {
              plugins: [
                require('autoprefixer')({
                  browsers: ['last 15 versions']
                })
              ]
            }
          },
          'sass-loader' // Sass to CSS
        ]
      },

      {
        test: /\.(png|svg|jpg|gif)$/,
        use: [
          {
            loader: 'file-loader' // use url-loader if loading via html
          }
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

  resolve: {
    extensions: ['.js', '.json', '.coffee'] // require('file') instead of require('file.coffee')
  }
});
