---
layout: post
title: Compojure Address Book Part 3
tags: clojure compojure
category: posts
---

# Introduction

In this installment of the address book series we are finally ready to start
building the actual application. We have laid all of the ground work required to
finally get to work.

# Templates

Let's begin by fleshing out our templates into a state that will actually
handle our contacts. First the code then some explanation. Update
`src/address_book/core/views/address_book_layout.clj` to look like the
following:

``` clojure
(ns address-book.core.views.address-book-layout
  (:require [hiccup.page :refer [html5 include-css]]
            [hiccup.core :refer [html h]]))

(defn common-layout [& body]
  (html5
    [:head
     [:title "Address Book"]
     (include-css "/css/address-book.css")
     (include-css "http://netdna.bootstrapcdn.com/font-awesome/3.2.1/css/font-awesome.css")]
    [:body
     [:div#wrapper
      [:h1#content-title "Address Book"]
      [:div#contacts
       [:div.contact.header
        [:div.column-1
         [:i.icon-user.icon-style] " Name"]
        [:div.column-2
         [:i.icon-phone.icon-style] " Phone"]
        [:div.column-3
         [:i.icon-envelope.icon-style] " Email"]
        [:div.clear-row]]
       body]]]))

(defn add-contact-form []
  (html
    [:div.contact
      [:form {:action "/post" :method "post"}
        [:div.column-1
          [:input#name-input {:type "text" :name "name" :placeholder "Name"}]]
        [:div.column-2
          [:input#phone-input {:type "text" :name "phone" :placeholder "Phone"}]]
        [:div.column-3
          [:input#email-input {:type "text" :name "email" :placeholder "Email"}]]
        [:button.button.add {:type "submit"} "Add "]]
        [:div.clear-row]]))

(defn read-contact [contact]
  (html
    [:div.contact
      [:div.contact-text
        [:div.column-1 (h (:name contact))]
        [:div.column-2 (h (:phone contact))]
        [:div.column-3 (h (:email contact))]]
      [:div.button-group
        [:form {:action (str "/edit/" (h (:id contact))) :method "get"}
          [:button.button.edit {:type "submit"}
            [:i.icon-pencil]]]
        [:form {:action (str "/delete/" (h (:id contact))) :method "post"}
          [:button.button.remove {:type "submit"}
            [:i.icon-remove]]]]
      [:div.clear-row]]))
```

It looks like a lot of code but you may be surprised that you will already
understand most of it. From `hiccup.core` we are now requiring two new
functions `html` and `h`. The `html` function renders a Clojure data structure to
a string of HTML, and the `h` function will change special characters into HTML
character entities. A good idea since we are dealing with user input.

The only real new concept here is rendering forms. The following snippet

``` clojure
(html
  [:form {:action "/post" :method "post"}
    [:input#example-1 {:type "text" :name "example-input"}]
    [:button {:type "submit"} "Submit Form"]])
```

would evaluate to the following HTML string

``` html
"<form action=\"/post\" method=\"post\">
  <input id=\"example-1\" name=\"example-input\" type=\"text\" />
  <button type=\"submit\">Submit Form</button>
</form>"
```

So we can see in our templates we have three forms; one to POST to the `/post`
route allowing us to create a new contact, one to do a GET to the
`/edit/contact-id` route which we will use to update an existing contact and
a POST to `/delete/contact-id`.

# Routes

Now let's update `src/address_book/core/routes/address_book_routes.clj` to use
our newly created templates. Update the file to look like the following:

``` clojure
(ns address-book.core.routes.address-book-routes
  (:require [ring.util.response :as response]
            [compojure.core :refer :all]
            [address-book.core.views.address-book-layout :refer [common-layout
                                                                 read-contact
                                                                 add-contact-form]]))

(def contacts (atom [{:id 1 :name "Jarrod Taylor" :phone "(555) 666-7777" :email "Jarrod@JarrodCTaylor.com"}
                     {:id 2 :name "James Dalton"  :phone "(123) 567-8901" :email "Cooler@Roadhouse.com"}
                     {:id 3 :name "Johnny Utah"   :phone "(543) 333-1234" :email "J.Utah@Buckeyes.com"}]))

(defn next-id []
  (->>
    @contacts
    (map :id)
    (apply max)
    (+ 1)))

(defn post-route [request]
  (let [name  (get-in request [:params :name])
        phone (get-in request [:params :phone])
        email (get-in request [:params :email])]
    (swap! contacts conj {:id (next-id) :name name :phone phone :email email})
    (response/redirect "/")))

(defn get-route [request]
  (common-layout
    (for [contact @contacts]
      (read-contact contact))
    (add-contact-form)))

(defroutes address-book-routes
  (GET  "/"     [] get-route)
  (POST "/post" [] post-route))
```

In the next installment we will persist our data in a postgres database, but
for now we are going to make due with keeping our contacts in an atom. We made a
small helper function to get the appropriate next contact id when we add
additional people. This is of course temporary as our database will handle this
for us once we make the switch.

When we post a new contact, our form includes the name, phone and email of the
new person. The first thing we do in the `post-route` is extract those values
to variables. We then update our contacts atom and redirect the user to the `/`
route where we will display our updated contacts list. The `get-route` still
extends the `common-layout` and adds a body consisting of a `read-contact`
template for each contact in our contacts atom.

# Style Sheet

Since this is not a blog focused on CSS I am not going to go into detail
and break down the contents of the style sheet. So I officially sign off on you just copying and pasting the
[stylesheet found here](https://github.com/JarrodCTaylor/compojure-address-book/blob/master/resources/public/css/address-book.css)
to `resources/public/css/address-book.css`. Lucky you.

# Update the Tests

At this point we actually have a contact book that is styled and allows us to
add additional contacts. There are a number of issues we still need to address.
We haven't added routes to edit and delete contacts and we are not persisting
our contact list so any additions will be lost when we restart our server. We
will get to those issues soon enough, but before we do let's get ourselves a
test to prove that our work so far is functional.

Update `test/address_book/core/address_book_tests.clj` to match the following:

``` clojure
(ns address-book.core.address-book-tests
  (:use midje.sweet)
  (:require [clojure.test :refer :all]
            [ring.mock.request :as mock]
            [address-book.core.handler :refer :all]
            [address-book.core.routes.address-book-routes :refer [contacts]]))

(facts "Example GET and POST tests"

  (fact "Test GET"
    (let [response (app (mock/request :get "/"))]
      (:status response) => 200
      (:body response) => (contains "<div class=\"column-1\">Jarrod Taylor</div>")
      (:body response) => (contains "<div class=\"column-1\">Johnny Utah</div>")
      (:body response) => (contains "<div class=\"column-1\">James Dalton</div>")))

  (fact "Test POST"
    (let [response (app (mock/request :post "/post" {:name "Bodhi" :phone "555-7890" :email "bells@beach.com"}))
          new-contact (filter #(= 4 (:id %)) @contacts)]
      (:status response) => 302
      (:name (first new-contact)) => "Bodhi")))
```

If we run `lein midje` we should be green. We tested that making a GET request
to the `/` route is successful and returns the expected contacts. We also have
a test to the `/post` route where we add a new contact, make sure we get a 302
redirect and check that the new contact is now present in our contacts atom.

# Wrap Up

We now have a styled application with working GET and POST routes. That takes
care of the CR in our CRUD app. In the next installment we will wire up the
database and cover how to write our tests using a test database that mirrors
production. As usual you can find the code for this installment on
github in [Part 3](https://github.com/JarrodCTaylor/compojure-address-book/tree/3).

## [Read Part 4 In The Series](/posts/Compojure-Address-Book-Part-4/)
