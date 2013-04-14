Nginx & PHP-FPM build pack
========================

This is a build pack bundling PHP and Nginx for Heroku apps.

- Includes additional extensions: APC, Mcrypt and Mongodb driver.
- Dependency management handled by [Composer][ch].

[ch]: http://getcomposer.org/

Configuration
-------------

The config files are bundled:

* conf/nginx.conf.erb
* conf/php.ini
* conf/php-fpm.conf

### Overriding Configuration Files During Deployment

Create a `conf/` directory in the root of the your deployment. Any files with names matching the above will be copied over and overwitten.

This way, you can customise settings specific to your application, especially the document root in `nginx.conf.erb`. (Note the .erb extension.)

Alternatively, the bundled `nginx.conf.erb` will automatically include all nginx configuration snippets within the application directory: `conf/nginx.d/*.conf`. This is another way that you can modify the `root` and `index` directives. Further, if the config snippets end with `.erb`, they will be parsed and have `.conf` extension appended to its filename. 

### Running App-specific Scripts
Heroku now supports running a single `.profile` script in the root of your application during startup, right before `boot.sh` is executed. See <https://devcenter.heroku.com/articles/dynos#startup>.

For more advanced usage of .profile scripts, see <https://devcenter.heroku.com/articles/profiled>.

Pre-compiling binaries
----------------------

### Preparation
Edit `pre_compile/set-env.sh` and `bin/compile` to update the version numbers.
````
$ gem install vulcan
$ vulcan create <build-server-name>
````

### Nginx
Run:
````
$ pre_compile/pre_compile_nginx
````
The binary package will be produced in the current directory. Upload it to Amazon S3.

### libmcrypt
Run:
````
$ pre_compile/dependencies/pre_compile_libmcrypt
````
The binary package will be produced in the current directory. Upload it to Amazon S3.

### PHP
PHP requires supporting libraries to be available when being built. Please have the preceding packages built and uploaded onto S3 before continuing.

Review the `pre_compile/vulcan-build-php.sh` build script and verify the version numbers in `pre_compile/set-env.sh`.

Run:
````
$ pre_compile/pre_compile_php
````
The binary package will be produced in the current directory. Upload it to Amazon S3.

### Bundling Caching
To speed up the slug compilation stage, precompiled binary packages are cached. The buildpack will attempt to fetch `manifest.md5sum` to verify that the cached packages are still fresh.

This file is generated with the md5sum tool:
```
$ md5sum *.tar.gz > manifest.md5sum
```

Remember to upload an updated `manifest.md5sum` to Amazon S3 whenever you upload new precompiled binary packages.

Usage
-----
Read through this whole README file first and decide if you need to make any changes to this buildpack; if you do need to make changes, fork this repo and replace the following URLs with yours.

### Deploying
To use this buildpack, on a new Heroku app:
````
heroku create -s cedar -b git://github.com/dibyendu/heroku-buildpack-nginx-php-fpm.git
````

On an existing app:
````
heroku config:add BUILDPACK_URL=git://github.com/dibyendu/heroku-buildpack-nginx-php-fpm.git
heroku config:add PATH="/app/vendor/bin:/app/local/bin:/app/vendor/nginx/sbin:/app/vendor/php/bin:/app/vendor/php/sbin:/usr/local/bin:/usr/bin:/bin"
````

Push deploy your app and you should see Nginx, mcrypt, and PHP being bundled.

### Declaring Dependencies using Composer
[Composer][] is the de facto dependency manager for PHP, similar to Bundler in Ruby.

- Declare your dependencies in `composer.json`; see [docs][cdocs] for syntax and other details.
- Run `php composer.phar install` *locally* at least once to generate a `composer.lock` file. Make sure both `composer.json` and `composer.lock` files are committed into version control.
- When you push the app, the buildpack will fetch and install dependencies when it detects both `composer.json` and `composer.lock` files.

Note: It is optional to have `composer.phar` within the application root. If missing, the buildpack will automatically fetch the latest version available from <http://getcomposer.org/composer.phar>.

[cdocs]: http://getcomposer.org/doc/00-intro.md#declaring-dependencies
[composer]: http://getcomposer.org/


Credits
-------

Original buildpack adapted and modified for Nginx + PHP support by [Ronald Ip][iht]. Buildpack originally inspired, and forked from <https://github.com/heroku/heroku-buildpack-php>.

Credits to original authors.

[iht]: http://ronaldip.com/

