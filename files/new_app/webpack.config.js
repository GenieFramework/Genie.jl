"use strict";

const path = require("path");
const webpack = require("webpack");
const fs = require("fs");

const prod = process.argv.indexOf("-p") !== -1;
const js_output_template = prod ? "js/[name]-[hash].js" : "js/[name].js";

const ExtractTextPlugin = require("extract-text-webpack-plugin");
const LiveReloadPlugin = require("webpack-livereload-plugin");

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
          presets: [
            ["env", { "modules": false }]
          ]
        }
      },
      {
        test: /\.coffee$/,
        use: [ "coffee-loader" ]
      },
      {
        test: /\.css$/,
        exclude: /node_modules/,
        use: ExtractTextPlugin.extract({
          // { loader: "style-loader" }, // creates style nodes from JS strings
          // { loader: "css-loader" } // translates CSS into CommonJS
          // { loader: "style-loader/url" }, // loads css URL
          // { loader: "file-loader" } // loads file
          use: "css-loader",
          fallback: "style-loader"
        })
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
    }),

    new ExtractTextPlugin("css/application.css"),

    new LiveReloadPlugin({
      port: 44444,
      appendScriptTag: true
    }),

    function() {
      // output the fingerprint
      this.plugin("done", function(stats) {
        let output = "const ASSET_FINGERPRINT = \"" + stats.hash + "\""
        fs.writeFileSync("config/initializers/fingerprint.jl", output, "utf8");
      });
    },

    function() {
      // delete previous outputs
      this.plugin("compile", function() {
        let basepath = __dirname + "/public";
        let paths = ["/javascripts", "/stylesheets"];

        for (let x = 0; x < paths.length; x++) {
          const asset_path = basepath + paths[x];

          fs.readdir(asset_path, function(err, files) {
            if (files === undefined) {
              return;
            }

            for (let i = 0; i < files.length; i++) {
              fs.unlinkSync(asset_path + "/" + files[i]);
            }
          });
        }
      });
    }
  ]
}
