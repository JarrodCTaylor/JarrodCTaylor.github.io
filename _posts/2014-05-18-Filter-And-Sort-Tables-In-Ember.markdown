---
layout: post
title: Filter and Sort Tables in Ember
tags: ember
category: posts
---

# Introduction
Requirements for tables that can be filtered and sorted are common occurrences
in many types of web applications. When I would have such a need in the past I
would usually pull in a jQuery plugin and hope that I could mold it to meet my
needs with a minimal amount of rework. Thankfully, with the wave of JavaScript
frameworks, requirements such as these are trivially easy to fulfill.

# The Example
For our example, we will create a table of notable individuals in the
computer science arena. Our table will allow users to filter and sort the
contents of any field in the table.

## The Route
To begin, we create our index route. We have a model that consists of
an Ember array that lists the people to be displayed in our table.

``` javascript
App.IndexRoute = Ember.Route.extend({
  model: function() {
    return Ember.A([
      {id: 1, firstName: "Bram", lastName: "Moolenaar", knownFor: "Vim"},
      {id: 2, firstName: "Richard", lastName: "Stallman", knownFor: "GNU"},
      {id: 3, firstName: "Dennis", lastName: "Ritchie", knownFor: "C"},
      {id: 4, firstName: "Rich", lastName: "Hickey", knownFor: "Clojure"},
      {id: 5, firstName: "Guido", lastName: "Van Rossum", knownFor: "Python"},
      {id: 6, firstName: "Linus", lastName: "Torvalds", knownFor: "Linux"},
      {id: 7, firstName: "Yehuda", lastName: "Katz", knownFor: "Ember"}
    ]);
  }
});
```

## The Controller
The Ember controller takes care of the sorting for us, assuming that we provide
the desired attribute to sort in `sortProperties`. All that is left for us
to implement is a way to change what property is sorted and a filter for the
objects in our table.

We want to show all of the people when the user has no input in the filter
field so we only apply our filter if the `theFilter` field has a value in it. 
Note that we apply the filter to `arrangedContent`, we do this so the sort will
be reflected in our results when we change the value of `sortProperties`.
Finally, we will have the `filterPeople` property watch `theFilter` and
`sortProperties` for changes.

``` javascript
App.IndexController = Ember.ArrayController.extend({
  sortProperties: ['id'],
  theFilter: "",

  checkFilterMatch: function(theObject, str) {
    var field, match;
    match = false;
    for (field in theObject) {
      if (theObject[field].toString().slice(0, str.length) === str) {
        match = true;
      }
    }
    return match;
  },

  filterPeople: (function() {
    return this.get("arrangedContent").filter((function(_this) {
      return function(theObject, index, enumerable) {
        if (_this.get("theFilter")) {
          return _this.checkFilterMatch(theObject, _this.get("theFilter"));
        } else {
          return true;
        }
      };
    })(this));
  }).property("theFilter", "sortProperties"),

  actions: {
    sortBy: function(property) {
        this.set("sortProperties", [property]);
    }
  }
});
```

## The Template
Our temple is quite basic. The points to note are: we assign the `sortBy` action
to each of the column heads in the table to allow the user to be able to sort
by the desired field and we then loop over each element in the `filterPeople`
property.

``` text
{% raw %}
<script type="text/x-handlebars" data-template-name="application">
    {{outlet}}
</script>

<script type="text/x-handlebars" data-template-name="index">
 {{input value=theFilter type='text' placeholder='Filter'}}

  <table class="table table-striped">
    <thead>
      <tr>
        <th {{action "sortBy" "id"}}>ID</th>
        <th {{action "sortBy" "firstName"}}>First Name</th>
        <th {{action "sortBy" "lastName"}}>Last Name</th>
        <th {{action "sortBy" "knownFor"}}>Known For</th>
      <tr>
    </thead>
    <tbody>
      {{#each person in filterPeople}}
        <tr>
          <td>{{person.id}}</td>
          <td>{{person.firstName}}</td>
          <td>{{person.lastName}}</td>
          <td>{{person.knownFor}}</td>
        </tr>
      {{/each}}
    </tbody>
  </table>
</script>
{% endraw %}
```

# Results
Here is a live demo of the example provided. I have added some CSS to indicate
which column is being sorted as well as the ability to sort both ascending
and descending.

  <a class="jsbin-embed" href="http://emberjs.jsbin.com/yezonaxu/1/embed?output">Ember Starter Kit</a><script src="http://static.jsbin.com/js/embed.js"></script>
