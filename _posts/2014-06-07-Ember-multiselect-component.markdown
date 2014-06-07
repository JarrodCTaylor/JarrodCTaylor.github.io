---
layout: post
title: Ember Multi Select Component
tags: ember
category: posts
---

# Introduction
One of my concerns when I first began building applications with Ember was that
I would have to leave behind many of the existing jQuery plugins that so often
come in handy when doing front end work. Thankfully for Ember developers
everywhere there is no need to reinvent any wheels. We can easily wrap most
existing jQuery plugins in Ember components.

# The Example
For our example we are going to create a multi select widget using the
[multiselect.js](http://loudev.com/) plugin, and demonstrate how easy it is to
incorporate existing jQuery plugins into our Ember applications.

## The Route
For our index route we will return an object that consists of an Ember
array, containing a list of people, that will populate the example multi select
box.

``` javascript
App.IndexRoute = Ember.Route.extend({
  model: function() {
    return {
      people: Ember.A([
        {id: 1, firstName: 'Jarrod'},
        {id: 2, firstName: 'Brandon'},
        {id: 3, firstName: 'Matt'},
        {id: 4, firstName: 'Joel'},
        {id: 5, firstName: 'Wes'},
        {id: 6, firstName: 'Aaron'}
      ])
    };
  }
});
```

## The Component
In our component we actually wrap the jQuery plugin. The `didInsertElement`
event is fired when the component is added to the page, and the `_initializeMulti`
property is called when this event occures. At this point the internals of the
property are straight from the multiselct.js documentation. We use a jQuery
selector to grab the field with a class of `multi` and call the `multiSelect`
method on it.  For this examle we are just doing a console log when a selection
is made or removed.

``` javascript
App.MultiSelectComponent = Ember.Component.extend({
  _initializeMulti: (function() {
    return $(".multi").multiSelect({

      afterSelect: (function(_this) {
        return function(values) {
          return _this.sendAction("addAction", values);
        };
      })(this),

      afterDeselect: (function(_this) {
        return function(values) {
          return _this.sendAction("removeAction", values);
        };
      })(this)

    });
  }).on("didInsertElement")
});
```

## The Templates
For our index template we call the multi-select component and pass to it the
options that we want to use to populate the select box. In the componet
template we loop over the passed in options and create a corresponding select
option for each one.

``` text
{% raw %}
  <script type="text/x-handlebars" data-template-name="index">
    {{multi-select options=model.people}}
  </script>

  <script type="text/x-handlebars" data-template-name="components/multi-select">
    <select class="multi" multiple="multiple">
      {{#each person in options}}
        <option {{bind-attr value="person.id"}}>{{person.firstName}}</option>
      {{/each}}
    </select>
  </script>
{% endraw %}
```

# Live Example
Here is a live demo of the example provided above. I have added a controller
with a property that is used to track the `id` number of the people that have been
selected, providing a more realistic use case.

  <a class="jsbin-embed" href="http://emberjs.jsbin.com/toxaceji/2/embed?output">Ember Starter Kit</a><script src="http://static.jsbin.com/js/embed.js"></script>
