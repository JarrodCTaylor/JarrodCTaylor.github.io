---
layout: post
title: Drag And Drop Ember Components
tags: ember
category: posts
---

# Introduction
Features like drag and drop are one of the many user interfaces that have come
to be expected in modern web applications. HTML5 defines an event-based
mechanism and JavaScript API that allows us to make just about any element on a
page be draggable. Combine that with the power of Ember and we can easily
create reusable draggable components for our web applications.

# The Example
For our example we will assume that we are creating some kind of file browser
and we would like to be able to drag files from a folder to the trash.

## The Route
To begin we will create our index route. We will have a model that consists of
two Ember arrays `inFolder` and `inTrash` that will keep track of where our
example files currently reside. We will start with all of the example files in
the folder.

``` javascript
App.IndexRoute = Ember.Route.extend({
  model: function() {
    return {
      inFolder: Ember.A([
        {id: 1, name: "File 1"},
        {id: 2, name: "File 2"},
        {id: 3, name: "File 3"}
      ]),
      inTrash: Ember.A([])
    };
  }
});
```

## Draggable File Component
In order to make an element draggable all we have to do is set the `draggable`
element to true. Our file component will only consist of a draggable div that
displays the file name. There are a number of events that fire during various
stages of the drag and drop process that we can utilize in our applications.
We have hooks for `dragStart`, `dragEnter`, `dragOver`, `dragLeave`, `drag`,
`drop` and `dragEnd`.  In our example we are going to be moving files between
arrays, to accomplish this we need the pk of the file we want to move.  We will
use the dragStart event to set the pk data that is going to be transferred when
we drop our file.

``` javascript
App.DraggableFileComponent = Ember.Component.extend({
  dragStart: function(event) {
    event.dataTransfer.setData('text/data', this.get('file.id'));
  }
});
```
We create the template for the `draggable-file` component

``` text
{% raw %}
<script type="text/x-handlebars" data-template-name="components/draggable-file">
  <div class="file" draggable="true">
    {{file.name}}
  </div>
</script>
{% endraw %}
```

We can now add our component to the index route.

``` text
{% raw %}
<script type="text/x-handlebars" data-template-name="index">
  <h3>Files in folder</h3>
  {{#each file in model.inFolder}}
    {{draggable-file file=file}}
  {{/each}}
</script>
{% endraw %}
```

What we have at this point is three draggable file elements on our page. This
is only have the equation though so let's give our users somewhere to drop the
files.

## Trash Can Component
Our trash can component is going to utilize a few of the other event hooks
that were mentioned earlier. Specifically we are going to prevent the default
event that is fired when we dragOver our component and we want to move our file
objects when they are dropped in the trash can.


``` javascript
App.DroppableTrashComponent = Ember.Component.extend({
  dragOver: function(event) {
    event.preventDefault();
  },
  drop: function(event) {
    var id = event.dataTransfer.getData('text/data');
    var record = this.get('inFolder').findProperty('id', parseInt(id, 10));
    this.get('inTrash').pushObject(record);
    this.get('inFolder').removeObject(record);
  }
});
```

We create the template for the `droppable-trash` component

``` text
<script type="text/x-handlebars" data-template-name="components/droppable-trash">
  <div>Drag files here to put in trash</div>
</script>
```

Finally we can add our trash can component and the inTrash array to our index
template to make it look like this.

``` text
{% raw %}
<script type="text/x-handlebars" data-template-name="index">
  <h3>Files in folder</h3>
  {{#each file in model.inFolder}}
    {{draggable-file file=file}}
  {{/each}}

  <br>
  {{droppable-trash inFolder=model.inFolder inTrash=model.inTrash}}
  <br>

  <h3>Files in trash</h3>
  {{#each item in model.inTrash}}
    {{item.name}}
  {{/each}}
</script>
{% endraw %}
```

# Results
Here is a live demo of the example provided above plus a little css to give the
user some feedback when they are over the trash can.  A good exercise for the
reader would be to modify the example to allow the files to be moved back out
of the trash and into the folder.

  <a class="jsbin-embed" href="http://emberjs.jsbin.com/tafuzabi/1/embed?output">Ember Drag And Drop Components</a><script src="http://static.jsbin.com/js/embed.js"></script>
