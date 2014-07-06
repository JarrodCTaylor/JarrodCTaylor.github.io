---
layout: post
title: Python Decorators 101
tags: python
category: posts
---

## What Is A Decorator

The python [wiki](https://wiki.python.org) defines a decorator as "a specific change to the Python
syntax that allows us to more conveniently alter functions and methods". The
description itself is a little ambiguous, but stick with me and we will learn
what decorators are and why they might be useful. In order to understand
decorators we must understand two fundamental Python concepts.
1. Functions can return functions.
2. Functions can take other functions as arguments.

## Functions That Return Functions

In Python everything is an object including functions. One thing that this means
is we can have our functions return other functions. It is really not as
confusing as it sounds here is a very short example:

``` python
def function_maker():

    def returned_function():
        print("A new function, that will be returned")

    return returned_function

example = function_maker()
example()
# Prints: 'A new function, that will be returned'
```

What we have just done is declared the function `function_maker` which itself
defines `returned_function`, we then return the newly created function. Be
sure to notice that we do not return the value of the new function which we
would get by returning `returned_function()`, we actually return the new function
itself with `return returned_function`. To prove that it worked we assign the
returned function to a variable `example` and then call the function
as we would any other regular function.

## Functions As An Argument To Other Functions

Now that we have seen that we can return functions we are half way to
understanding decorators. Next up we need to understand that functions can
accept other functions as arguments.

``` python
def accepts_a_function(func):
    print "I will call your function next"
    return func()

def hello():
    print("Hello Stranger!")

accepts_a_function(hello)
```

Here we pass a function object as an argument to `accepts_a_function` which
prints a line of text and then calls the function that was passed to it.

## Combine The Two Steps And We Have A Decorator

Now we are all set to write our first actual Python decorator. Let's rewrite
the example from above as a decorator.

``` python
def decorate_hello(func):
    def decorated_hello():
      print "I will call your function next"
      return func()
    return decorated_hello

def hello():
    print("Hello Stranger!")

example = decorate_hello(hello)
example()
```

And that's it! We have now written our own decorator. Not so bad, huh? What we
have done is declared a function `decorate_hello` that accepts a function as
an argument. We then declare another function `decorated_hello` that will be
returned which actually calls the function that was passed in as an argument to
`decorate_hello`.

That is all that a decorator does. The `@decorator_name` syntax that you may
have seen or used is just a shortcut provided by Python that functionally does
the same thing we just did here.

We could rewrite the example above with the more idiomatic decorator syntax.

``` python
def decorate_hello(func):
    def decorated_hello():
      print "I will call your function next"
      return func()
    return decorated_hello

@decorate_hello
def hello():
    print("Hello Stranger!")

hello()
```

The `@decorated_hello` syntax says that we want to pass the `hello` function as
an argument to `decorate_hello` now when we call `hello()` what we are actually
doing is calling `decorate_hello(hello)`.

## Do I Need To Use This?

Now that we understand what a decorator is and how we go about writing one,
you may be asking yourself "do I need to use this?". Although I can't answer that
for you I can give you an example of where decorators come in handy and offer
one that may be of practical use as you develop your Python programs.

One of the most common use cases that I encounter is some type of
`login_required` decorator. Often when developing web apps we want to make
sure that a user is authenticated prior to serving a page. There would be no
sense in repeating authentication code in every view that requires it and as a
bonus, the decorator syntax above a view declaration is a great reminder of that
view's privileged status.

One final example. Often when writing a program it is useful to time your
functions to see where potential bottle necks are. Here is a decorator that
will do just that. For serious timing analytics you may still be best served
using the `timeit.Timer` method. However, this technique has helped me out on a
few occasions.

``` python
import time
import functools


def timer(decorated_method):

        @functools.wraps(decorated_method)  # maintain the original attributes __name__ etc
        def wrapper(*args, **kwargs):
            start = time.time()
            method_to_time = decorated_method(*args, **kwargs)
            finish = time.time()
            function_name = decorated_method.__name__
            run_time = finish - start
            print("Function [{0}] took {1} seconds to run".format(function_name, run_time))
            return method_to_time

        return wrapper

@timer
def something():
    time.sleep(4)
    return "Hello decorators"


something()
```

The possibilities of decorators extend well beyond what has been covered here.
However, with this information you should have all that you need to understand any
other examples you might find out in the world.
