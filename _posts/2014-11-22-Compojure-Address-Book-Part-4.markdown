---
layout: post
title: Compojure Address Book Part 4
tags: clojure compojure
category: posts
---

# Persisting Data in Postgres

At this point we have an address book that will allow us to add new contacts.
However, we are not persisting our new additions. It's time to change that. You
will need to have [Postgres](http://www.postgresql.org/) installed. If you are
using a Mac, [postgresapp](http://postgresapp.com/) is a very simple way to get
up and running.  If you are on another OS you will need to follow the install
instructions from the Postgres website.

Once you have Postgres installed and running we are going to create a test user
and two databases.

## Configuring Postgres

We need to create two databases one for test and one for development. We also
need to create a user that can access these new databases. To accomplish this
in Postgres, issue the following commands:

* `CREATE ROLE address_book_user LOGIN;`
* `ALTER ROLE address_book_user WITH PASSWORD 'password1';`
* `CREATE DATABASE address_book;`
* `CREATE DATABASE address_book_test;`
* `GRANT ALL PRIVILEGES ON DATABASE address_book TO address_book_user;`
* `GRANT ALL PRIVILEGES ON DATABASE address_book_test TO address_book_user;`

## Replacing the Atom with a Database

In order to use Postgres in our application we are going to add a few
dependencies in our `project.clj`.  We are going to bring in
`org.clojure/java.jdbc`, `postgresql/postgresql`, `yesql` and `environ`. I will
give a brief overview of what each one does before we modify our file.

`jdbc` and the Postgres driver allow us to access the database. The [environ](https://github.com/weavejester/environ)
library will make it so we can easily use environment variables in our
application. By doing this, we can connect to different databases for test,
dev and production. We are also going to use [yesql](https://github.com/krisajenkins/yesql)
which is a Clojure library for using SQL. The idea behind yesql is using
actual SQL in our clojure program instead of a DSL that translates to SQL. I
will give some more detail about yesql when we begin writing database queries
but first, let's define the environment variables that we will use to connect to
our databases.

Create `profiles.clj` in the root of our project to store our test
and dev environment variables. In your real world apps you will want to keep
this file out of version control. For our example project you will find the
file in the Github repo.

``` clojure
{:dev-env-vars  {:env {:database-url "postgres://address_book_user:password1@127.0.0.1:5432/address_book"}}
 :test-env-vars {:env {:database-url "postgres://address_book_user:password1@127.0.0.1:5432/address_book_test"}}}
```

Here we have defined the connection to our database. We will use the environ
library to pull the database-url for the correct environment.  The test and dev
environments will be determined by the `lein` commands we issue. Structuring
the connections this way accomplishes two major goals. First, we will easily be
able to use a different database for test, dev and production.  Second, we are
keeping our configuration separate from our code.

The last part of setting our project up to use environment variables involves
defining a dev and test profile in our `project.clj`. We will also include our
new dependencies. Update the file to look like the following:

``` clojure
(defproject address-book "0.1.0-SNAPSHOT"
  :description "FIXME: write description"
  :url "http://example.com/FIXME"
  :min-lein-version "2.5.0"

  :ring {:handler address-book.core.handler/app
         :init    address-book.core.handler/init}

  :dependencies   [[org.clojure/clojure   "1.6.0"]
                   [compojure             "1.3.1"]
                   [ring/ring-defaults    "0.1.3"]
                   [hiccup                "1.0.5"]
                   [org.clojure/java.jdbc "0.3.6"]
                   [postgresql/postgresql "9.3-1102.jdbc41"]
                   [yesql                 "0.5.0-rc1"]
                   [environ               "1.0.0"]]

  :plugins        [[lein-ring             "0.9.1"]
                   [lein-environ          "1.0.0"]]

  :profiles {:test-local {:dependencies [[midje "1.6.3"]
                                         [javax.servlet/servlet-api "2.5"]
                                         [ring-mock "0.1.5"]]

                           :plugins     [[lein-midje "3.1.3"]]}

             ;; Set these in ./profiles.clj
             :test-env-vars {}
             :dev-env-vars  {}

             :test [:test-local :test-env-vars]
             :dev  [:dev-env-vars]})
```

Now we can write some queries. Using yesql we can write multiple SQL statements
in a single SQL file. The format for the file is as follows:

``` text
-- name: The function name used to call the query
-- docstring comments
SQL
```

Create `src/address_book/core/models/address_book_queries.sql` and populate it
with the following:

``` sql
-- name: all-contacts
-- Selects all contacts
SELECT id
       ,name
       ,phone
       ,email
FROM contacts;

-- name: insert-contact<!
-- Queries a single contact
INSERT INTO contacts (name, phone, email)
    VALUES (:name, :phone, :email);

-- name: drop-contacts-table!
-- drop the contacts table
DROP TABLE contacts;

-- name: create-contacts-table-if-not-exists!
-- create the contacts table if it does not exist
CREATE TABLE IF NOT EXISTS contacts (
   id serial PRIMARY KEY,
   name VARCHAR (20) NOT NULL,
   phone VARCHAR (14) NOT NULL,
   email VARCHAR (25) NOT NULL);
```

We now have queries to get all of the contacts and to insert a new contact. The
`drop-contacts-table!` query will be used in our tests against the test
database and `create-contacts-table-if-not-exists!` will be used in our init
function to make sure we have a table for our data when starting the server.
Notice that when we are doing a INSERT/UPDATE/DELETE the function name needs to
end with `<!`.

Before we can execute a query we need to use yesql to read the file. Create a
file called `src/address-book/core/models/query_defs.clj` and populate it with
the following:

``` clojure
(ns address-book.core.models.query-defs
  (:require [environ.core :refer [env]]
            [yesql.core :refer [defqueries]]))

(defqueries "address_book/core/models/address_book_queries.sql" {:connection (env :database-url)})
```

We can now require the `query-defs.clj` file to utilize our queries. Let's go
ahead and update our init function in `src/address_book/core/handler.clj`. The
require and init function should now look like this.

``` clojure
(ns address-book.core.handler
  (:require [compojure.core :refer :all]
            [compojure.route :as route]
            [ring.middleware.defaults :refer [wrap-defaults site-defaults]]
            [address-book.core.routes.address-book-routes :refer [address-book-routes]]
            [address-book.core.models.query-defs :as query]))

(defn init []
  (query/create-contacts-table-if-not-exists!))
```

We can now replace the atom in
`src/address_book/core/routes/address_book_routes.clj` with queries against our
database. Update the file to look like the following:

``` clojure
(ns address-book.core.routes.address-book-routes
  (:require [ring.util.response :as response]
            [compojure.core :refer :all]
            [address-book.core.views.address-book-layout :refer [common-layout
                                                                 read-contact
                                                                 add-contact-form]]
            [address-book.core.models.query-defs :as query]))

(defn post-route [request]
  (let [name  (get-in request [:params :name])
        phone (get-in request [:params :phone])
        email (get-in request [:params :email])]
    (query/insert-contact<! {:name name :phone phone :email email})
    (response/redirect "/")))

(defn get-route [request]
  (common-layout
    (for [contact (query/all-contacts)]
      (read-contact contact))
    (add-contact-form)))

(defroutes address-book-routes
  (GET  "/"     [] get-route)
  (POST "/post" [] post-route))
```

## Testing Against the Database

Update `test/address_book/core/address_book_tests.clj` with the following
contents and then we will discuss the changes.

``` clojure
(ns address-book.core.address-book-tests
  (:use midje.sweet)
  (:require [clojure.test :refer :all]
            [ring.mock.request :as mock]
            [address-book.core.handler :refer :all]
            [address-book.core.models.query-defs :as query]))

(facts "Example GET and POST tests"
  (with-state-changes [(before :facts (query/create-contacts-table-if-not-exists!))
                       (after  :facts (query/drop-contacts-table!))]

  (fact "Test GET"
    (query/insert-contact<! {:name "JT" :phone "(321)" :email "JT@JT.com"})
    (query/insert-contact<! {:name "Utah" :phone "(432)" :email "J@Buckeyes.com"})
    (let [response (app (mock/request :get "/"))]
      (:status response) => 200
      (:body response) => (contains "<div class=\"column-1\">JT</div>")
      (:body response) => (contains "<div class=\"column-1\">Utah</div>")))

  (fact "Test POST"
    (count (query/all-contacts)) => 0
    (let [response (app (mock/request :post "/post" {:name "Some Guy" :phone "(123)" :email "a@a.cim"}))]
      (:status response) => 302
      (count (query/all-contacts)) => 1))))
```

Midje allows us to define functions that will run before and after every test.
We define those in the `with-state-changes` function. We will create the test
table before every test and destroy it after. We will now run our tests with
`lein with-profile test midje`. This will use the test profile which uses
environ to pull in the connections to our test database.

# Wrap Up

Our application is all most finished. All that remains is adding routes to edit
and delete contacts from our address book. We will cover those in the final
installment of this series. As usual you can find the code for this installment
on github in [Part 4](https://github.com/JarrodCTaylor/compojure-address-book/tree/4).

## [Read the fifth and final part in the series](/posts/Compojure-Address-Book-Part-5/)
