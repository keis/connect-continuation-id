// A connect middleware that assigns a random id for each request that passes
// through it and keeps the id around for the lifetime of the request using
// continuation locale storage
var randomBytes = require('crypto').randomBytes,
    cls = require('continuation-local-storage'),
    createNamespace = cls.createNamespace,
    getNamespace = cls.getNamespace;

// Creates a namespace when you don't care about the name
function defaultNamespace() {
    var key = 'connect-continuation';
    return getNamespace(key) || createNamespace(key);
}

// Creates a 16 characters long random string with 12 bytes of entropy. The
// size 12 is chosen because it neatly encodes into base64 without any
// padding.
function randomId() {
    return randomBytes(12).toString('base64');
}

// Define a context with a middleware and utilities for getting the id. It
// takes a single argument: the cls namespace to use.  If none is passed a
// default namespace is used.
module.exports = function Context(namespace) {
    namespace = namespace || defaultNamespace();

    // The actual middleware function starts by generating a random id
    function middleware(req, res, next) {
        var cid = randomId();

        // The cls namespace is accessible through the request object
        req.getContinuationStorage = function () {
            return namespace;
        }

        // This makes sure the continuation is carried over when events are
        // emitted on either the request or response object
        namespace.bindEmitter(req);
        namespace.bindEmitter(res);

        // Mark the start of a new continuation and continue the call through
        // the middleware stack with `continuationId` set.
        namespace.run(function () {
            namespace.set('continuationId', cid);
            next();
        });
    };

    // A function to get the id of the active continuation
    function get() {
        return namespace.get('continuationId');
    }

    return {
        assign: middleware,
        namespace: namespace,
        get: get
    };
};

