---
layout: post
title: Python Decorators 201
tags: python
category: posts
---

# Introduction

In this post we are going to look at Python class decorators and why you might
want to use them. You should have a solid understanding of how method
decorators work before you try to digest the following examples. In case you need a
refresher on the fundamentals of working with method decorators,
check out one of my previous blog posts [Python Decorators 101](http://www.jarrodctaylor.com/posts/Python_Decorators_101/).

Although decorators in general, and class decorators specifically, are not a tool
you will use everyday occasionally they can come in very handy. Recently while
working on building a RESTful API we needed to require different permissions on
various HTTP methods within a class. This could have been accomplished by
adding decorators to each individual method within the class. We instead
implemented a class decorator where we could select the methods to decorate by
passing in the method names and the desired permissions for each. I believe
that this resulted in not only making the code look cleaner but also more
concisely communicating the permissions required on the class. Read on to learn
how to implement something similar in your own projects.

## A Basic Class Decorator Example

This is one of the most basic, and perhaps least useful, class decorators that
you can write.

``` python
def method_decorator(method):

    def new_method(self):
        print("Print from the new_method")
        return method(self)

    return new_method


def class_decorator():

    def method_modifier(klass):
        setattr(klass, 'example_method', method_decorator(getattr(klass, 'example_method')))
        return klass

    return method_modifier


@class_decorator()
class ExampleClass(object):

    def example_method(self):
        print("Print from the example_method")

    def non_decorated(self):
        print("This method is not decorated")


example = ExampleClass()
print("==== [Decorated Method] ====")
example.example_method()
print("\n==== [Nondecorated Method] ====")
example.non_decorated()
```

What we have done is decorated the `ExampleClass` with the `class_decorator`
decorator. The `class_decorator` function returns the `method_modifier`
function. All `method_modifier` does is set the `example_method` of the class
passed to it equal to the `method_decorator` function. That is a dense sentence
but reread it a few times and run the example and the purpose of the code will
become clear. Once you understand this basic example let's move onto something
a little more practical.


## Specifying The Methods That Get Decorated

The following example, although slightly contrived for the sake of brevity,
demonstrates a much more dynamic way of defining which methods in a class we
would like to decorate.

For the example, we are implementing some type of RPG and each player will be
required to posses specific attributes in order to perform actions within a
village.

``` python
from functools import wraps


def get_func(value, method):

    @wraps(method)
    def wrap(self):
        player_attrs = set(self.player.attrs)
        required_attr = set(value)
        if len(player_attrs.intersection(required_attr)) > 0:
            print("You DO have the required attrs to {}".format(method.__name__))
            return method(self)
        else:
            print("You DON'T have the required attrs to {}".format(method.__name__))
    return wrap


def required_attrs(*args, **kwargs):

    def class_with_requirements(klass):
        for k, v in kwargs.items():
            setattr(klass, k.lower(), get_func(v, getattr(klass, k.lower())))
        return klass
    return class_with_requirements


@required_attrs(ATTACK_BOSS=['level2'], HEAL=['cleric'])
class VillageOne(object):

    def __init__(self, player):
        self.player = player

    def attack_boss(self):
        print("  >>> Attacking the level boss <<<")

    def heal(self):
        print("  >>> You are healing something <<<")


class player(object):

    def __init__(self, name, attrs):
        self.name = name
        self.attrs = attrs

## Call the examples ##
player1 = player("Player 1", ['level1', 'cleric'])
player2 = player("Player 2", ['level2', 'fighter'])
player1_village1 = VillageOne(player1)
player2_village1 = VillageOne(player2)
print("===== [Player 1] =====")
player1_village1.attack_boss()
player1_village1.heal()
print("\n===== [Player 2] =====")
player2_village1.attack_boss()
player2_village1.heal()
```

You can see that we have used our decorator on the `VillageOne` class to
require that a player have a `level2` attribute in order to `attack_boss` or a
`cleric` attribute in order to `heal`. This decorator is useful in our pretend
game and the same technique could be used in your RESTful APIs to require
permissions on specific HTTP methods.
