---
layout: post
title: Compojure Address Book Part 5
tags: clojure compojure
category: posts
---

# The Finish Line

Our address book application has finally taken shape and we are in a position
to put the finishing touches on it. All that remains is to allow the user the
ability to edit and delete existing contacts.

Let's start by adding the necessary queries to `src/address_book/core/models/address_book_queries.sql`.

``` sql
-- name: delete-contact<!
-- Deletes a single contact
DELETE FROM contacts
    WHERE id = :id;

-- name: update-contact<!
-- Update a single contact
UPDATE contacts SET name = :name, phone = :phone, email = :email
    WHERE id = :id;
```

The queries we have written previously haven't required any keyword arguments.
Here we can see the syntax for using keywords in our queries. In
`delete-contact<!`  for example `:id` is going to be replaced with the value of
`:id` in the keyword map that we pass into the query function.

Next let's add a template which will allow us to edit a contact. Add the
following template to `src/address_book/core/views/address_book_layout.clj`.

``` clojure
(defn edit-contact [contact]
  (html
    [:div.contact
      [:form {:action (str "/edit/" (:id contact)) :method "post"}
        [:input {:type "hidden" :name "id" :value (h (:id contact))}]
        [:div.column-1
          [:input#name-input {:type "text" :name "name" :placeholder "Name" :value (h (:name contact))}]]
        [:div.column-2
          [:input#phone-input {:type "text" :name "phone" :placeholder "Phone" :value (h (:phone contact))}]]
        [:div.column-3
          [:input#email-input {:type "text" :name "email" :placeholder "Email" :value (h (:email contact))}]]
        [:div.button-group
          [:button.button.update {:type "submit"} "Update"]]]
      [:div.clear-row]]))
```

Here we have a hidden input field that contains the id of the contact that the
user is editing so we can do a post to the appropriate route.

Now finally we can modify `src/address_book/core/routes/address_book_routes.clj`
to include our final two routes. Update the file to look like the following:

``` clojure
(ns address-book.core.routes.address-book-routes
  (:require [ring.util.response :as response]
            [compojure.core :refer :all]
            [address-book.core.views.address-book-layout :refer [common-layout
                                                                 read-contact
                                                                 add-contact-form
                                                                 edit-contact]]
            [address-book.core.models.query-defs :as query]))

(defn display-contact [contact contact-id]
  (if (not= (and contact-id (Integer. contact-id)) (:id contact))
    (read-contact contact)
    (edit-contact contact)))

(defn post-route [request]
  (let [name  (get-in request [:params :name])
        phone (get-in request [:params :phone])
        email (get-in request [:params :email])]
    (query/insert-contact<! {:name name :phone phone :email email})
    (response/redirect "/")))

(defn get-route [request]
  (let [contact-id (get-in request [:params :contact-id])]
    (common-layout
      (for [contact (query/all-contacts)]
        (display-contact contact contact-id))
      (add-contact-form))))

(defn delete-route [request]
  (let [contact-id (get-in request [:params :contact-id])]
    (query/delete-contact<! {:id (Integer. contact-id)})
    (response/redirect "/")))

(defn update-route [request]
  (let [contact-id (get-in request [:params :id])
        name       (get-in request [:params :name])
        phone      (get-in request [:params :phone])
        email      (get-in request [:params :email])]
    (query/update-contact<! {:name name :phone phone :email email :id (Integer. contact-id)})
    (response/redirect "/")))

(defroutes address-book-routes
  (GET  "/"                   [] get-route)
  (POST "/post"               [] post-route)
  (GET  "/edit/:contact-id"   [] get-route)
  (POST "/edit/:contact-id"   [] update-route)
  (POST "/delete/:contact-id" [] delete-route))
```

A few changes to take note of here. We have changed the `get-route` to check
for a parameter of `contact-id`. We will be using the route to both get a
list off all the users the same as we have been doing and also to make a
request which will allow us to edit a specific user.  Instead of always calling
`read-contact` for each person in the address book we now call the function
`display-contact` that will display the edit contact from in the event that we
have a contact-id that matches a given contact and the `read-contact` template
in all other cases. The update and delete routes don't introduce any new
concepts. They get the needed parameters from the request and call the
appropriate queries.

# Add More Tests

We need to add tests for the edit and delete routes. These new tests are very
similar to the existing ones. Add the following tests to `test/address_book/core/address_book_tests.clj`.

``` clojure
  (fact "Test UPDATE a post request to /edit/<contact-id> updates desired contact information"
    (query/insert-contact<! {:name "JT" :phone "(321)" :email "JT@JT.com"})
    (let [response (app (mock/request :post "/edit/1" {:id "1" :name "Jrock" :phone "(999) 888-7777" :email "jrock@test.com"}))]
      (:status response) => 302
      (count (query/all-contacts)) => 1
      (first (query/all-contacts)) => {:id 1 :name "Jrock" :phone "(999) 888-7777" :email "jrock@test.com"}))

    (fact "Test DELETED a post to /delete/<contact-id> deletes desired contact from database"
      (query/insert-contact<! {:name "JT" :phone "(321)" :email "JT@JT.com"})
      (count (query/all-contacts)) => 1
      (let [response (app (mock/request :post "/delete/1" {:id 1}))]
        (count (query/all-contacts)) => 0))
```

# Wrap Up

At this point we have a fully functioning and tested address book application
that saves our data in a Postgres database. You can find the code for the
project on github at [Compojure Address Book](https://github.com/JarrodCTaylor/compojure-address-book).
