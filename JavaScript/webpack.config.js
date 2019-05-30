var HtmlWebpackPlugin = require('html-webpack-plugin');
var HtmlWebpackInlineSourcePlugin = require('html-webpack-inline-source-plugin');

const path = require('path');

module.exports = {
	entry: './index.js',
	output: {
		path: path.resolve(__dirname, 'dist'),
		// filename: '[name].html'
		libraryTarget: 'var',
		library: 'exportedVariable'
	},
	resolve: {
		extensions: ['.js']
	},
	module: {
		rules: [
			{
				test: /\.css$/,
				use: ['style-loader', 'css-loader'],
			},
			{
				test: /\.(ttf|eot|svg|woff(2)?)(\?[a-z0-9=&.]+)?$/,
				loader: 'url-loader'
			}
		]

	},
	plugins: [
		new HtmlWebpackPlugin({
			title: 'Custom template',
			template: 'container.html',
			inlineSource: '.(js|css)$'
		}),
		new HtmlWebpackInlineSourcePlugin()
    ],
    optimization: {
        minimize: true
    }
}