---
layout: post
title: Compojure Address Book Part 6
tags: clojure compojure
category: posts
---

# Deployment

At this point in our series you should have a fully functioning and tested
address book running on your local machine. That is great and all but naturally
we are going to want to be able to access our web application from anywhere on
the web.  Lucky for us deployment can actually be very easy. Today we are
going to cover one solution for hosting a Clojure web application, deploying
to Heroku.

# Heroku

## Register an Account

First, if you do not have one already, you will need to register for a
[Heroku](https://www.heroku.com/) account. Although all of the services we are
going to utilize in this post are free, you will need to have a credit card on
file with Heroku in order to install add-ons. Be sure to do this while you
are registering.

## Installing the Toolbelt

The [Heroku toolbelt](https://toolbelt.heroku.com/) is a CLI tool for managing
Heroku apps. Follow the link and install the proper version for your OS. Once
you have the toolbelt installed, issue the following command in your terminal:

``` text
heroku login
```

You will be prompted for the email address and password you used when creating
your Heroku account.

## Creating the Heroku Application

With the toolbelt installed and authentication credentials provided we are now
ready to create the Heroku app. Create your new application with the following
command:

``` text
heroku create your-name-address-book
```

We now have a empty Heroku application waiting for us to deploy.

## Adding Postrges

Before we deploy we are going to want to include the postgress add-on in our
project. Issue the following command:

``` text
heroku addons:add heroku-postgresql:hobby-dev
```

The command created a `hobby-dev` level postrgess database that we will have
access to from our application. The hobby-dev level is free to use and allows
us to store up to 10,000 rows in our database, which should be plenty to support
our single table.

## Preparing our Application for Deployment

Before we can deploy our application we need to make just a few modifications.
First, let's add a `production` profile. Update `project.clj` so the profiles
match the following:

``` clojure
:profiles {:test-local {:dependencies [[midje "1.6.3"]
                                       [javax.servlet/servlet-api "2.5"]
                                       [ring-mock "0.1.5"]]

                         :plugins     [[lein-midje "3.1.3"]]}

           ;; Set these in ./profiles.clj
           :test-env-vars {}
           :dev-env-vars  {}

           :test [:test-local :test-env-vars]
           :dev  [:dev-env-vars]

           :production {:ring {:open-browser? false
                               :stacktraces?  false
                               :auto-reload?  false}}}
```

All that we have added here are some configurations to disable a few ring
features that don't make sense in production.

Next, create a file named `Procfile` in the root of the project and populate it
with the following:

``` text
web: lein with-profile production trampoline ring server
```

The Procfile is Heroku's mechanism for declaring what commands are run by your
application when it starts. The `web:` declaration is all we will need to start our
application server.

## What About Our Database

Looking back to [Part 4](http://www.jarrodctaylor.com/posts/Compojure-Address-Book-Part-4/) of this
series we used the [environ](https://github.com/weavejester/environ) library to
manage our connection to the database for test and dev environments by
providing a `:database-url` in `profiles.clj`. When the command in the Procfile
is run which uses `with-profile production`, our application will start with the
production profile. The environ library will not find a value for `:database-url` in
`profiles.clj` so it will next look for an environment variable of
`database-url`. This environment variable will be found since one is
conveniently generated for us when we install the postgress add-on.

## Deploying to Heroku

We are now ready to deploy our application. You can do so by issuing the following command:

``` text
git push heroku master
```

When Heroku is finished taking care of business you can check and make sure
everything went well:

``` text
heroku ps
```

You should see something along the lines of:

``` text
=== web (1X): `lein with-profile production trampoline ring server`
web.1: up 2015/01/17 10:06:12 (~ 5m ago)
```

Take note of the status of `web.1` as long as it says `up` we are good to go.

# Wrap Up

Now that our web server is up you can visit `https://your-name-address-book.herokuapp.com`
and use your application in production.

We have successfully arrived at the end of our address book example. You can find
the code for the project on github at [Compojure Address Book](https://github.com/JarrodCTaylor/compojure-address-book).
