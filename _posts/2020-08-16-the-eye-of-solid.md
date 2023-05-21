---
layout: post
title:  "The “eye” of SOLID"
date:   2020-08-16 21:31:54 +1000
categories: oop
---

Photo by Jarek Ceborski on Unsplash

### Interface segregation in one sentence

The heart of interface segregation is this phrase “Do not depend on things you do not need”. If you raised your eyebrows you are not wasting your time reading this. To explain why interface segregation means what I mentioned we need to step back a little bit and start with a real-life analogy.

### A real-life analogy

Imaging your home. Your home’s architecture is reflecting interface segregation. It is very common to divide the space inside a house into rooms, kitchen, bathroom and so on. In your living room, you watch TV and spend quality time with your family or friends. Therefore normally you can find a TV set, a sofa and a coffee table. These objects would be used together most of the time. Now imagine your kitchen, there is an oven, cabinets for your pans and cutleries and a fridge which you keep food inside. You can see the same pattern again. In every space in your house, you find objects which most likely you use and need together. In your living room, you do not need an oven so you do not see one. To be more accurate, your house’s interface is divided into multiple smaller ones. One to spend some quality time with your family and friends and have fun, the other is for storing food and cooking.

### What does this mean in software engineering?

When using a class while writing code, you introduce a dependency to that class and invoking its functionality through its interface. In a more accurate term, you are depending on the interface. However, you might not need all of the functionality of its interface. As an example, imagine you are implementing a report of how many users are active in your app. To achieve that you need a class which does CRUD¹ for the users of your app. However, you just need to read the list of users and not updating them. So if the interface is designed correctly you should just see methods related to fetching the list of users and not more. On the contrary, other parts of your application might need to update a user and not necessarily fetching the list, so you would use a different interface from the same class. The architect of the class should consider this when designing the interface as reading and updating customers are not happening in the same component of the software. This obviously might not happen upfront, most of the time you need to [refactor](https://martinfowler.com/books/refactoring.html) to achieve the segregation.

### What are the benefits?

The principle comes with several benefits. You might have already understood one of them, which is to make it easier to use a class since your mind as a developer does not have to deal with many things at the same time and probably making a mistake.

In addition, once objects in your software just depend on interfaces they need, you achieved loose coupling. This means you can change your software more easily. You can refactor your classes and components knowing that there is less chance of introducing unexpected behaviours.

### Does interface here means just “interface”?

Absolutely not !! different languages and technologies have different ways of implementing this. Javascript (well at least the vanilla one) does not have support for interfaces as a language feature but the principle still applies to every function you use, every argument of that functions and every property. Each time you have to call a function by some null arguments just because you do not care about those arguments you are forced to depend on things you do not need. Therefore the principle is violated. You probably can think of more examples now.

### Discussion

It is very important to understand the way you segregate your interfaces always depends on features and functionalities in the system. If for example, your system has a page which lets a user update their details it might make sense to have an interface which contains both read and update methods for a single user in one interface and maybe another one to get a list.

¹Create, Read, Update and Delete
