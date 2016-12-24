---
layout: post
title: Compojure Address Book Part 2
tags: clojure compojure
category: posts
---

# Recap and Restructure

So far we have modified the default Compojure template to include a basic POST
route and used Midje and Ring-Mock to write a test to confirm that it works.
Before we get started with templates and creating our address book we should
provide some additional structure to our application in an effort to keep
things organized as the project grows.

Create two new directories

* `/src/address_book/core/routes`
* `/src/address_book/core/views`

So far all of our application code has lived in
`src/address_book/core/handler.clj`. From here on out `handler.clj` is going to
hold: an initialize function that will run on project start up, our default not
found route and most importantly the `app` definition. The `app` definition is
where we combine all routes from our project and wrap them with any needed
middleware.  You might be able to guess what we are going to keep in the two
new directories. All the logic for the routes in the address book will go in
`routes` and `views` is going to hold our soon to be introduced hiccup
templates.

Let's restructure `src/address_book/core/handler.clj` so it only includes the following:

``` clojure
(ns address-book.core.handler
  (:require [compojure.core :refer [defroutes routes]]
            [compojure.route :as route]
            [ring.middleware.defaults :refer [wrap-defaults site-defaults]]
            [address-book.core.routes.address-book-routes :refer [address-book-routes]]))

(defn init []
  (println "Address book application is starting"))

(defroutes app-routes
  (route/not-found "Not Found"))

(def app
  (-> (routes address-book-routes app-routes)
      (wrap-defaults (assoc-in site-defaults [:security :anti-forgery] false))))
```

Notice that we add an init function. Currently it will just print a string, but
eventually we will use this as a hook to ensure that our database exists upon
starting the application. We also add the `address-book-routes` in our app
definition. We need to let our app know about the new init method. To achieve
this we need to add a line to the `:ring` map in `project.clj`.

``` clojure
:ring {:handler address-book.core.handler/app
       :init    address-book.core.handler/init}
```

Finally, we can move our existing routes into `/src/address_book/core/routes/address_book_routes.clj`.

``` clojure
(ns address-book.core.routes.address-book-routes
  (:require [compojure.core :refer [defroutes GET POST]]
            [address-book.core.views.address-book-layout :refer [common-layout]]))

(defn example-post [request]
  (let [post-value (get-in request [:params :example-post])]
    (str "You posted: " post-value)))

(defroutes address-book-routes
  (GET  "/"     [] "Example GET")
  (POST "/post" [] example-post))
```

# Hiccup Templates

Hiccup is a library for representing HTML in Clojure. It uses vectors to
represent elements and maps to represent an element's attributes. If you
understand HTML then it is intuitive to use and will be well suited for our
application.

We start by adding `[hiccup "1.0.5"]` as a dependency in `project.clj`. With
that done we can populate `src/address_book/core/views/address_book_layout.clj`
with the following:

``` clojure
(ns address-book.core.views.address-book-layout
  (:require [hiccup.page :refer [html5 include-css]]))

(defn common-layout [& body]
  (html5
    [:head
      [:title "Address Book"]
      (include-css "/css/address-book.css")]
    [:body
      [:h1#content-title "Address Book"]
      body]))
```

What we have done here is created a common layout that we will grow into the
base for all of the applications views. We can use a common frame and pass in
the desired body contents. You will also notice the `include-css` function. Our
lein template came with an empty `resources` directory that our application can
access. We will store our style sheet in here and serve it up with our
templates. To get our feet wet with templates let's extend our basic GET route
to use the `common-layout`. We need to require the common-layout in
`src/address_book/core/routes/address_book_routes.clj` and we will generate the
response body for our GET request from a new function named `example-get`.
Update your `address_book_routes.clj` with the following pieces:

``` clojure
(ns address-book.core.routes.address-book-routes
  (:require [compojure.core :refer :all]
            [address-book.core.views.address-book-layout :refer [common-layout]]))

(defn example-get [request]
  (common-layout
    [:p "Example GET"]))

(defroutes address-book-routes
  (GET "/" [] example-get)
  (POST "/post" [] example-post))
```

Before we test out our new templates, let us also add some content to our style
sheet so we can be sure that is being properly included. Create this file
`resources/public/css/address-book.css` and add to it, the following:

``` css
body {
  background-color: #BCE5FF
}

h1 {
  color: #FF6967;
}
```

At this point when we visit `http://localhost:3000/` we should see the following:
![Basic GET route](/assets/basic-get-route.png)

Due to our using a template now we should have a failing test. No longer is the
response equal to "Example GET" so we need to change our assertion to

``` clojure
(:body response) => (contains "Example GET")
```

# Wrap Up

At this point we have successfully laid the ground work for the majority of our
application. In the next installment we will add the real style sheet and
create hiccup templates for our primary views.

You can find all the code for this section in [Part 2](https://github.com/JarrodCTaylor/compojure-address-book/tree/2).

## [Read Part 3 In The Series](/posts/Compojure-Address-Book-Part-3/)
