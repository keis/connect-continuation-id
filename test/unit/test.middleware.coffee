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

    it "returns a object with a function", ->
        {assign} = clsMiddleware()
        assert.isFunction assign

    it "acts as a connect middleware", (done) ->
        app = connect()
        app.use clsMiddleware().assign
        app.use (req, res) ->
            res.end "hello world"

        request app
            .get '/whatever'
            .expect 200, "hello world", done

    it "configures an id for the request", (done) ->
        {assign} = clsMiddleware namespace
        txid = null
        app = connect()
        app.use assign
        app.use (req, res) ->
            txid = getId()
            res.end "hello world"

        request app
            .get '/whatever'
            .expect ->
                assert.isString txid
            .end done

    it "keeps the id throughout the request", (done) ->
        {assign} = clsMiddleware namespace
        txid = null

        app = connect()
        app.use assign
        app.use (req, res) ->
            req.on 'data', ->
                txid = getId()
            res.end "hello world"

        request app
            .post '/whatever'
            .send 'zoidberg'
            .expect ->
                assert.isString txid
                assert.lengthOf txid, 16
            .end done

    it "provides a method to get the cls namespace on request", (done) ->
        {assign} = clsMiddleware namespace
        nsbyreq = null
        app = connect()
        app.use assign
        app.use (req, res) ->
            nsbyreq = req.getContinuationStorage()
            res.end "hello world"
        request app
            .get '/whatever'
            .expect ->
                assert.strictEqual nsbyreq, namespace
            .end done

    it "provides access to the cls namespace", () ->
        {namespace} = clsMiddleware()
        assert.isFunction namespace.get

    it "provides access to the current continuation id", (done) ->
        {assign, get} = clsMiddleware()
        txid = null

        app = connect()
        app.use assign
        app.use (req, res) ->
            req.on 'data', ->
                txid = get()
            res.end "hello world"

        request app
            .post '/whatever'
            .send 'zoidberg'
            .expect ->
                assert.isString txid
                assert.lengthOf txid, 16
            .end done
