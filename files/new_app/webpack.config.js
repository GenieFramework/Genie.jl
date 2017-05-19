"use strict";

const path = require("path");
const webpack = require("webpack");
const fs = require("fs");

const prod = process.argv.indexOf("-p") !== -1;
const js_output_template = prod ? "js/[name]-[hash].js" : "js/[name].js";

module.exports = {
  context: path.join(__dirname, "/app/assets"),

  entry: {
    application: ["./js/application.js"]
    // contact: ["./js/contact.js"]
  },

  output: {
    path: path.join(__dirname, "/public"),
    filename: js_output_template
  },

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        loader: "babel-loader",
        query: {
          presets: ["es2015"]
        }
      },
      {
        test: /\.coffee$/,
        use: [ "coffee-loader" ]
      },
      {
        test: /\.css$/,
        use: [
          { loader: "style-loader" }, // creates style nodes from JS strings
          { loader: "css-loader" } // translates CSS into CommonJS
          // { loader: "style-loader/url" },
          // { loader: "file-loader" }
        ]
      },
      {
        test: /\.sass$/,
        use: [
          { loader: "style-loader" }, // creates style nodes from JS strings
          { loader: "css-loader" }, // translates CSS into CommonJS
          { loader: "sass-loader"} // compiles Sass to CSS
        ]
      },
      {
        test: /\.scss$/,
        use: [
          { loader: "style-loader" }, // creates style nodes from JS strings
          { loader: "css-loader" }, // translates CSS into CommonJS
          { loader: "sass-loader"} // compiles Sass to CSS
        ]
      },
      {
        test: /\.(woff2?|svg)$/,
        loader: "url-loader?limit=10000&name=/fonts/[name].[ext]"
      },
      {
        test: /\.(ttf|eot)$/,
        loader: 'file-loader?name=/fonts/[name].[ext]'
      }
    ]
  },

  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      "window.jQuery": "jquery"
    })
  ]
}
