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
using a Mac, [postgresapp](http://postgresapp.com/) is a very simple way of
installing. If you are on another OS you will need to follow the install
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

In order to use Postgres in our application we need to add the following to our
dependencies in `project.clj`.

``` clojure
[org.clojure/java.jdbc "0.3.5"]
[postgresql/postgresql "9.1-901-1.jdbc4"]
[yesql "0.5.0-beta2"]
```

`jdbc` and the Postgres driver allow us to access the database.  We are also going
to use [yesql](https://github.com/krisajenkins/yesql) which is a Clojure
library for using SQL. The idea behind yesql is we can use actual SQL in our
clojure program instead of a DSL that translates to SQL. I will give an
overview of yesql shortly when we begin writing database queries but, first
let's tell the application how to connect to our database.

Create a file called `src/address_book/core/models/database.clj` and populate
it with the following:

``` clojure
(ns address-book.core.models.database)

(def database
  {:dev  {:subprotocol "postgresql"
          :subname "//127.0.0.1:5432/address_book"
          :user "address_book_user"
          :password "password1"}
   :test {:subprotocol "postgresql"
          :subname "//127.0.0.1:5432/address_book_test"
          :user "address_book_user"
          :password "password1"}})

(def db (database :dev))
```

Here we have defined the connection to our `db` by default we are using the
`:dev` database. Structuring the connections this way will allow us to redefine
`db` in our tests and use the `:test` connection.


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
SELECT * FROM contacts;

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
file called `src/address-book/core/models/query-defs.clj` and populate it with
the following:

``` clojure
(ns address-book.core.models.query-defs
  (:require [address-book.core.models.database :refer [database db]]
            [yesql.core :refer [defqueries]]))

(defqueries "address_book/core/models/address_book_queries.sql" {:connection db})
```

We can now require the `query-defs` file to utilize our queries. Let's go
ahead and update our init function in `src/address_book/core/handler.clj`. The
requires and init function should now look like this.

``` clojure
(ns address-book.core.handler
  (:require [compojure.core :refer :all]
            [compojure.route :as route]
            [ring.middleware.defaults :refer [wrap-defaults site-defaults]]
            [address-book.core.routes.address-book-routes :refer [address-book-routes]]
            [address-book.core.models.database :refer [db]]
            [address-book.core.models.query-defs :as query]))

(defn init []
  (query/create-contacts-table-if-not-exists! {} {:connection db}))
```

We pass our query two maps. The first is a map of any arguments that our query
expects and the second is the database we are executing the query against.

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
            [address-book.core.models.database :refer [db]]
            [address-book.core.models.query-defs :as query]))

(defn post-route [request]
  (let [name  (get-in request [:params :name])
        phone (get-in request [:params :phone])
        email (get-in request [:params :email])]
    (query/insert-contact<! {:name name :phone phone :email email} {:connection db})
    (response/redirect "/")))

(defn get-route [request]
  (common-layout
    (for [contact (query/all-contacts {} {:connection db})]
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
            [address-book.core.models.database :refer [database db]]
            [address-book.core.models.query-defs :as query]))

(def test-db (database :test))

(facts "Example GET and POST tests"
  (with-state-changes [(before :facts (query/create-contacts-table-if-not-exists! {} {:connection test-db}))
                       (after  :facts (query/drop-contacts-table!                 {} {:connection test-db}))]

  (fact "Test GET"
    (with-redefs [db test-db]
      (query/insert-contact<! {:name "JT" :phone "(321)" :email "JT@JT.com"} {:connection test-db})
      (query/insert-contact<! {:name "Utah" :phone "(432)" :email "J@Buckeyes.com"} {:connection test-db})
      (let [response (app (mock/request :get "/"))]
        (:status response) => 200
        (:body response) => (contains "<div class=\"column-1\">JT</div>")
        (:body response) => (contains "<div class=\"column-1\">Utah</div>"))))

  (fact "Test POST"
    (with-redefs [db test-db]
      (count (query/all-contacts {} {:connection test-db})) => 0
      (let [response (app (mock/request :post "/post" {:name "Some Guy" :phone "(123)" :email "a@a.cim"}))]
        (:status response) => 302
        (count (query/all-contacts {} {:connection test-db})) => 1)))))
```

We start out defining the test-db that we are going to use so as not to alter any
working data. Midje allows us to define functions that will run before and
after every test. We define those in the `with-state-changes` function. We will
create the test table before every test and destroy it after. The only remaining
part we need to do in order to run our production code against a test database
is redefine the database connection with our `test-db`. We use `with-redefs`
to temporarily redefine `db` to point to our `test-db` for the duration of the
test.

# Wrap Up

Our application is all most finished. All that remains is adding routes to edit
and delete contacts from our address book. We will cover those in the final
installment of this series. As usual you can find the code for this installment
on github in [Part 4](https://github.com/JarrodCTaylor/compojure-address-book/tree/4).

## [Read the fifth and final part in the series](/posts/Compojure-Address-Book-Part-5/)
