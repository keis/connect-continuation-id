# connect-continuation-id

[![NPM Version][npm-image]](https://npmjs.org/package/connect-continuation-id)
[![Build Status][travis-image]](https://travis-ci.org/keis/connect-continuation-id)
[![Coverage Status][coveralls-image]](https://coveralls.io/r/keis/reload-reload?branch=master)

A connect middleware that assigns a random id for each request that passes
through it and keeps the id around for the lifetime of the request using
continuation locale storage.

For an example on how to use this to greatly improve the tracibility of a busy
application log see [the rapidus examplesrepository](https://github.com/keis/rapidus-examples)

## Usage

    var express = require('express'),
        continuationId = require('connect-continuation-id')(),
        app;

    function doThings(callback) {
        setTimeout(callback, 100);
    }

    function doOtherThings(callback) {
        console.log('doing things for', continuationId.get());
        process.nextTick(callback);
    }

    app = express();
    app.use(continuationId.assign);
    app.get('/', function (req, res, next) {
        console.log('processing request', continuationId.get());
        doThings(function (err) {
            doOtherThings(function (err) {
                res.status(200).send('test');
            });
        });
    });

    app.listen(3000);

[npm-image]: https://img.shields.io/npm/v/connect-continuation-id.svg?style=flat
[travis-image]: https://img.shields.io/travis/keis/connect-continuation-id.svg?style=flat
[coveralls-image]: https://img.shields.io/coveralls/keis/connect-continuation-id.svg?style=flat
