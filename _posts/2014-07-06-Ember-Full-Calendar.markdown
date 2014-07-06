---
layout: post
title: Ember Full Calendar
tags: ember
category: posts
---

# Introduction
In a previous post I covered [creating a date picker](http://www.jarrodctaylor.com/posts/Date-Picker-And-Validation-In-Ember/)
and validating the user input. A date is often not much good without a place to
display it. In this post we are going to wrap the [fullcalendar](http://arshaw.com/fullcalendar/)
jQuery plugin in an Ember component.

# The Example
For our example, we will create a component that wraps the fullcalendar jQuery
plugin and allow for the user to add new events to the calendar. The
component will have two input boxes; one for the title of a new event and one
for the date. We will not focus on including error handling or validation in an
effort to keep the code clear so be sure to refer to previous posts if you
need an example of accomplishing those tasks.

## The Route
Our index route consists of a model that returns an object with an events
property that is an Ember array. This will be used to store our event data. We
begin by including one event with a start date of now.

``` javascript
App.IndexRoute = Ember.Route.extend({
  model: function() {
    return {
      events: Ember.A([
        {title: "Hackathon", start: Date.now()},
      ])
    };
  }
});
```
## The Component
In our component we use the `didInsertElement` event to create the
`fullCalendar` when the `calendar` div element is inserted into the DOM. We
initially populate `events` with the array containing the single event for today
that we created in the route.

We also create one action `addEvent`. When the action is triggered we create a
new event object with the data that was provided by the user. We then push the new
event object onto our `newEvent` array and call `renderEvent` on our
`fullCalendar` in order to display the new event without the user needing to
refresh the calendar. Note that using `renderEvent` will cause events to appear
to double up if they are added to months other than the currently displayed one.
You will need to add logic to deal with this if used in a production
environment.

Finally, make sure that fullcalendar.js and its dependencies are available as
resources to be used in your application.

``` javascript
App.FullCalendarComponent = Ember.Component.extend({

    newEvent: "",
    eventTitle: "",

    _initializeCalendar: (function() {
      return $("#calendar").fullCalendar({
        events: this.theEvents
      });
    }).on("didInsertElement"),

    actions: {
      addEvent: function() {
        var newEvent = {title: this.eventTitle, start: this.newEvent, allDay: false};
        this.theEvents.pushObject(newEvent);
        this.$("#calendar").fullCalendar('renderEvent', newEvent, true);
      }
    }

});
```

## The Template
Our template simply provides two input boxes for the user to enter the event
details and a button which calls our `addEvent` action. Be aware that we are
not doing any validation or formatting of the input and new events require a
date with a ISO format (E.g. '2015-03-23').

``` text
{% raw %}
  <script type="text/x-handlebars" data-template-name="index">
    {{full-calendar theEvents=model.events}}
  </script>

  <script type="text/x-handlebars" data-template-name="components/full-calendar">
    <label for="title">Title:</label>
    {{input id="title" class="form-control" value=eventTitle placeholder="Enter event title"}}

    <label for="event">Event:</label>
    {{input id="event" class="form-control" value=newEvent placeholder="Enter a new event date"}}
    <p>Date must ISO string: Ex. 2015-07-25</p>

    <a class="btn btn-primary" {{action "addEvent"}}>+ Add New Event</a>

    <hr>
    <div id="calendar"></div>
  </script>
{% endraw %}
```

## Results
Here is a live demo of the example.

  <a class="jsbin-embed" href="http://emberjs.jsbin.com/lucehaye/1/embed?output">Ember Starter Kit</a><script src="http://static.jsbin.com/js/embed.js"></script>
