---
layout: post
title: Date Picker and Validation in Ember
tags: ember
category: posts
---

# Introduction
I have never been filled with joy when faced with the need to work with dates
and I am certain that I am not alone in feeling this way. However, you will not
be able to work on creating too many web forms before the need to provide a
date picker appears. Accomplishing this is much easier now that it was only a
few years ago. With the aid of a few great JavaScript libraries and Ember we
can quite easily create a date picker and validate what the user has provided
is a correct date.

# The Example
For our example, we will create a single date input field that will allow the
user to either type in a date or select one from a date picker. To accomplish
this there is no need to reinvent the wheel. We will leverage
[Pikaday](https://github.com/dbushell/Pikaday) to provide our date picker and
[Moment](http://momentjs.com/) to do the validation. All that is left for us to
do is wire it all up.

## The Route
To begin, we create our index route. We have a model that consists of an
object. The object has properties that will track our date, a human readable
version of our date that we will display on the page and a boolean we will use
to track if the date entered is valid or not.

``` javascript
App.IndexRoute = Ember.Route.extend({
  model: function() {
    return {
      date: new Date(),
      dateDisplay: "",
      valid: false
    };
  }
});
```

## The View
We have two primary goals for our example. Create a datepicker and confirm
that a valid date has been entered. We will accomplish both of these in
our view.

We use the `didInsertElement` event on our view to create a Pikaday object
when the `TextField` is inserted into the DOM. When the user changes the
value of the text field `updateValues` will use moment.js to check if the
new value is valid and update our variables accordingly.

``` javascript
App.DateField = Ember.TextField.extend({
  classNames: ['form-control', 'date-input'],
  picker: null,

  updateValues: (function() {
    var date;
    date = moment(this.get("value"));
    if (date.isValid()) {
      this.set("date", date.toDate());
      this.set("dateDisplay", date.format("MMM Do YYYY"));
      return this.set("valid", true);
    } else {
      this.set("date", null);
      this.set("dateDisplay", "Invalid");
      return this.set("valid", false);
    }
  }).observes("value"),

  didInsertElement: function() {
    var picker;
    picker = new Pikaday({
      field: this.$()[0],
      format: "YYYY-MM-DD"
    });
    return this.set("picker", picker);
  }
});
```

## The Template
Our template simply displays: the date object, the date object formatted as a
string and weather or not the date entered is valid. Make sure that moment.js
and pikaday.js are available to our application.

``` text
{% raw %}
<script type="text/x-handlebars" data-template-name="index">
  <div class="example-objects">
    <strong>Date Object: </strong> {{date}}</br>
    <strong>Date Object Formatted For Display: </strong> {{dateDisplay}}</br>
    <strong>Date Valid: </strong> {{valid}}
  </div>

  <h3>Example</h3>
  <label for="example-input">Date Field:</label>
  {{view App.DateField date=date dateDisplay=dateDisplay valid=valid}}
</script>
{% endraw %}
```

# Results
Here is a live demo of the example provided. I have added some CSS to indicate
if the date is valid or not and some minimal styling.

  <a class="jsbin-embed" href="http://emberjs.jsbin.com/viguqidu/1/embed?output">Ember Starter Kit</a><script src="http://static.jsbin.com/js/embed.js"></script>
