---
layout: post
title: Compojure Address Book Part 1
tags: clojure compojure
category: posts
---

# Introduction

Clojure is a great language that is continuing to improve itself and expand its
user base year over year. The Clojure ecosystem has many great libraries
focused on being highly composable. This composability allows developers to
easily build impressive applications from seemingly simple parts. Once you have
a solid understanding of how Clojure libraries fit together, integration
between them can become very intuitive. However, if you have not reached this
level of understanding, knowing how all of the parts fit together can be
daunting.  Fear not, this series will walk you through start to finish,
building a tested compojure web app backed by a Postgres Database.

# Where We Are Going

The project we will build and test over the course of this blog series is an
address book application. We will build the app using ring and Compojure and
persist the data in a Postgres Database. The app will be a traditional client
server app with no JavaScript. Here is a teaser of the final product. ![Address Book Gif](https://cloud.githubusercontent.com/assets/4416952/5156018/c8f0475a-726a-11e4-8c46-a5fa9e62e582.gif)

# Compojure / Ring the TL;DR Version

At the core of most Clojure web projects you will find [Ring](https://github.com/ring-clojure/ring).
Ring is a Clojure web application library, that abstracts the details of HTTP
into a simple unified API. [Compojure](https://github.com/weavejester/compojure) provides a concise syntax
for generating Ring handlers. Ring and Compojure will be the heart of our
address book application.

# Let's Get Started

We will build off of the [default compojure template](https://github.com/weavejester/compojure-template).
The easiest way to start any Clojure project is to utilize
[Leiningen](http://leiningen.org/) which we will use to get the default
template by issuing the following command.

``` sh
lein new compojure address-book
```

What the template gives us is a single route hello world app. You can checkout the app in your
browser with

``` sh
lein ring server
```

which will open the application in your default browser.

## GET, POST and Tests

For the first installment of this blog series we are going to create and test a
bare bones GET and POST scenario to get a feel for how Compojure Routes work and
how we can test them.

### Routes

In Compojure each route consists of: a HTTP method, a pattern that will match
the requested URL, an argument list and the contents that will be returned as
the response body to the requester. For example:

``` clojure
(GET "/example-route" [] "Response body")
```

Here we specify that a GET request to `/example-route` with no arguments will
return the string `Response body`.

Let's modify the response that gets
returned from the default "/" and add a POST route while we are at it. Modify
the routes in `src/address_book/core/handler.clj` to look like the following:

``` clojure
(defroutes app-routes
  (GET "/" [] "Example GET")
  (POST "/post" [] example-post)
  (route/not-found "Not Found"))
```

The contents that we return may come from a function as we are doing here with
the POST route. Let's add the `example-post` function above our routes
definition.

``` clojure
(defn example-post [request]
  (let [post-value (get-in request [:params :example-post])]
    (str "You posted: " post-value)))
```

All body functions must accept the request as an argument. Here we are
expecting that a field named `example-post` will be posted to the URL.
We extract the `:example-post` keyword value from `:params` in our request and
include it in the response.  Since this is a throw away route we are not
providing any way to make the post from the browser. We will prove that this
works with a test instead.

To keep things streamlined for our example we are going to turn off the
`anti-forgery` settings provided by [Ring-Defaults](https://github.com/ring-clojure/ring-defaults) so we can make
our POST without the CSRF protection. You can read about how to enable it for
your own projects at the link above. To turn if off for our example we set
`:anti-forgery` to false in `wrap-defaults` like so.

``` clojure
(def app (wrap-defaults app-routes (assoc-in site-defaults [:security :anti-forgery] false)))
```

### Tests

When it comes to writing Clojure tests you have a few options. For this
application, we are going to use [Midje](https://github.com/marick/Midje). In
order to use Midje we need to add `[midje "1.6.3"]` to dependencies and
`[lein-midje "3.1.3"]` to plugins in `project.clj`. Now we can make
`test/address_book/core/address_book_tests.clj` look like the following:

``` clojure
(ns address-book.core.address-book-tests
  (:use midje.sweet)
  (:require [clojure.test :refer :all]
            [ring.mock.request :as mock]
            [address-book.core.handler :refer :all]))

(facts "Example GET and POST tests"

  (fact "Test GET"
    (let [response (app (mock/request :get "/"))]
      (:status response) => 200
      (:body response) => "Example GET"))

  (fact "Test POST"
    (let [response (app (mock/request :post "/post" {:example-post "Some data"}))]
      (:status response) => 200
      (:body response) => "You posted: Some data")))
```

Now if we run

``` sh
lein midje :autotest
```

you should see the message `All checks (4) succeeded`. We are using `ring.mock`
to create a mock request map that we pass to our app. Notice how in the `post`
route we are passing in the `example-post` field.

# Wrap Up

With a basic GET and POST and two passing tests we arrive at the end of our
first installment. In the next installment, our application will begin taking shape as
we add [hiccup](https://github.com/weavejester/hiccup) templates to render HTML
and a style sheet to make our project look presentable.

I have created a github repo that will have all the code for our project with
tags corresponding to the parts of the blog. You can find all the code for this
section in [Part 1](https://github.com/JarrodCTaylor/compojure-address-book/tree/1).

## [Read Part 2 In The Series](/posts/Compojure-Address-Book-Part-2/)
