sinon = require 'sinon'
connect = require 'connect'
request = require 'supertest'
{createNamespace, getNamespace} = require 'continuation-local-storage'

getId = ->
    namespace = getNamespace 'test-namespace'
    namespace.get 'continuationId'

describe "middleware", ->
    clsMiddleware = require '../../lib'
    namespace = createNamespace 'test-namespace'

    it "returns a function", ->
        m = clsMiddleware()
        assert.isFunction m

    it "acts as a connect middleware", (done) ->
        app = connect()
        app.use clsMiddleware()
        app.use (req, res) ->
            res.end "hello world"

        request app
            .get '/whatever'
            .expect 200, "hello world", done

    it "configures an id for the request", (done) ->
        txid = null
        app = connect()
        app.use clsMiddleware namespace
        app.use (req, res) ->
            txid = getId()
            res.end "hello world"

        request app
            .get '/whatever'
            .expect ->
                assert.isString txid
            .end done

    it "keeps the id throughout the request", (done) ->
        txid = null
        app = connect()
        app.use clsMiddleware namespace
        app.use (req, res) ->
            req.on 'data', ->
                txid = getId()
            res.end "hello world"

        request app
            .post '/whatever'
            .send 'zoidberg'
            .expect ->
                assert.isString txid
            .end done

    it "provides a method to get the cls namespace on request", (done) ->
        nsbyreq = null
        app = connect()
        app.use clsMiddleware namespace
        app.use (req, res) ->
            nsbyreq = req.getContinuationStorage()
            res.end "hello world"
        request app
            .get '/whatever'
            .expect ->
                assert.strictEqual nsbyreq, namespace
            .end done
