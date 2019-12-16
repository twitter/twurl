Twurl
=====

[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/twitter/twurl/blob/master/LICENSE)
 [![Gem Version](https://badge.fury.io/rb/twurl.svg)](https://badge.fury.io/rb/twurl)

Twurl is like curl, but tailored specifically for the Twitter API.
It knows how to grant an access token to a client application for
a specified user and then sign all requests with that access token.

It also provides other development and debugging conveniences such
as defining aliases for common requests, as well as support for
multiple access tokens to easily switch between different client
applications and Twitter accounts.

Installing Twurl
----------------

Twurl can be installed using RubyGems:

```sh
gem install twurl
```

Getting Started
---------------

If you haven't already, the first thing to do is apply for a developer account to access Twitter APIs:

```text
https://developer.twitter.com/en/apply-for-access
```

After you have that access you can create a Twitter app and generate a consumer key and secret.

When you have your consumer key and its secret you authorize
your Twitter account to make API requests with that consumer key
and secret.

```sh
twurl authorize --consumer-key key       \
                --consumer-secret secret
```

This will return an URL that you should open up in your browser.
Authenticate to Twitter, and then enter the returned PIN back into
the terminal.  Assuming all that works well, you will be authorized
to make requests with the API. Twurl will tell you as much.

Making Requests
---------------

The simplest request just requires that you specify the path you
want to request.

```sh
twurl /1.1/statuses/home_timeline.json
```

Similar to curl, a GET request is performed by default.

You can implicitly perform a POST request by passing the -d option,
which specifies POST parameters.

```sh
twurl -d 'status=Testing twurl' /1.1/statuses/update.json
```

You can explicitly specify what request method to perform with
the -X (or --request-method) option.

```sh
twurl -X POST /1.1/statuses/destroy/1234567890.json
```

Creating aliases
----------------

```sh
twurl alias h /1.1/statuses/home_timeline.json
```

You can then use "h" in place of the full path.

```sh
twurl h
```

Paths that require additional options (such as request parameters, for example) can be used with aliases the same as with full explicit paths, just as you might expect.

```sh
twurl alias tweet /1.1/statuses/update.json
twurl tweet -d "status=Aliases in twurl are convenient"
```

Changing your default profile
-----------------------------

The first time you authorize a client application to make requests on behalf of your account, twurl stores your access token information in its .twurlrc file. Subsequent requests will use this profile as the default profile. You can use the 'accounts' subcommand to see what client applications have been authorized for what user names:

```sh
twurl accounts
  noradio
    HQsAGcBm5MQT4n6j7qVJw
    hhC7Koy2zRsTZvQh1hVlSA (default)
  testiverse
    guT9RsJbNQgVe6AwoY9BA
```

Notice that one of those consumer keys is marked as the default. To change the default use the 'set' subcommand, passing then either just the username, if it's unambiguous, or the username and consumer key pair if it isn't unambiguous:

```sh
twurl set default testiverse
twurl accounts
  noradio
    HQsAGcBm5MQT4n6j7qVJw
    hhC7Koy2zRsTZvQh1hVlSA
  testiverse
    guT9RsJbNQgVe6AwoY9BA (default)
```

```sh
twurl set default noradio HQsAGcBm5MQT4n6j7qVJw
twurl accounts
  noradio
    HQsAGcBm5MQT4n6j7qVJw (default)
    hhC7Koy2zRsTZvQh1hVlSA
  testiverse
    guT9RsJbNQgVe6AwoY9BA
```

Contributors
------------

Marcel Molina <marcel@twitter.com> / @noradio
Erik Michaels-Ober / @sferik

and there are many [more](https://github.com/twitter/twurl/graphs/contributors)!
