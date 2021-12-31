# Install

## Install with RubyGems (recommended)

```sh
# installing the latest release
$ gem install twurl
```

```sh
# verify installation
$ twurl -v
0.9.5
```

## Install from source

In case if you haven't installed `bundler` you need to install it first:

```sh
$ gem install bundler
```

```sh
$ git clone https://github.com/twitter/twurl
$ cd twurl
$ bundle install
```

If you don't want to install Twurl globally on your system, use `--path` [option](https://bundler.io/v2.0/bundle_install.html):

```
$ bundle install --path path/to/directory
$ bundle exec twurl -v
0.9.5
```
