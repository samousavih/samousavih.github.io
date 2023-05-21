---
layout: post
title:  "Simple and practical specification pattern with EF Core and C#"
date:   2020-08-07 21:31:54 +1000
categories: oop
---

Photo by Samantha Gades on Unsplash

## Abstract

Here I address how to implement specification pattern in C#. The key to more efficiency is to use lambda expressions and watch for client evaluation.

### Implementing specifications

In [this article](https://medium.com/dev-genius/common-closure-principle-the-story-of-an-evolving-architecture-6919b452c8db), I described a hotel booking system and its components. Also, [here](https://itnext.io/specification-pattern-and-how-to-quantify-the-improved-software-stability-9a7cf5a74f1f) I explained how the [specification pattern](https://en.wikipedia.org/wiki/Specification_pattern) improved that architecture. In the current story, I will address how to implement a query handler which utilises this pattern. The framework of choice is EF Core and the language is C#.

The main part of the specification pattern is an abstract specification class. Let’s see how we can implement that using C#.

<iframe src="https://medium.com/media/8a96505cefb944700cb92b1e10abc2b1" frameborder=0></iframe>

Now let’s see how the query handler looks like in C#.

<iframe src="https://medium.com/media/d0eedd8f43425a9ad792f313524cd322" frameborder=0></iframe>

As you can see in the above code snippet “GetBookingBySpecification” method is calling the main method of a specification inside the where clause. To try this we can use the following class which specifies all of the bookings in the finished state.

<iframe src="https://medium.com/media/8aab2a65b9ae1673a7b677001735e5c5" frameborder=0></iframe>

As expected the query handler would return all of the finished bookings.

### Query performance concerns

We are using Entity Framework. It would translate Linq queries into SQL queries. If we [turn on query logging](https://docs.microsoft.com/en-us/ef/core/miscellaneous/logging?tabs=v3) we can see the generated query for the “FinishedBookingSpecification” looks like this.

    SELECT b.Id, b.Status,...
    FROM bookingrecord AS b

Surprisingly we can see it is missing the “Where” condition. The reason is EF has a limitation in converting Linq queries into SQL queries. EF would run the rest of the query in memory. It is called [client evaluation](https://docs.microsoft.com/en-us/ef/core/querying/client-eval). This query is inefficient and as the application scales up would be an issue. Let’s see how we can improve this in the next section.

### Using lambda expressions

C# has lambda expressions which if used inside a Linq query can be translated into SQL queries. Let’ see how abstract specification looks like with lambda expressions.

<iframe src="https://medium.com/media/5f630202a1000012e216e5fd443007ee" frameborder=0></iframe>

Let’s also reimplement the “FinishedBookingSpecification” using lambda expressions.

<iframe src="https://medium.com/media/967bb064b16998a658dd838f5c2b62c0" frameborder=0></iframe>

And here is how we need to change the query handler class.

<iframe src="https://medium.com/media/148ac5707f026340b59f10f1edf225eb" frameborder=0></iframe>

Finally, if we run the query and look into the generated result we see this.

    SELECT b.Id, b.Status,...
    FROM bookingrecord AS b
    WHERE b.status = 0

We have achieved the SQL query we were looking for.

### Client Evaluation

EF Core before version 2.2 does client evaluation which needs closer attention. When writing an expression in the specification pattern if the performance of the query matters, there is a way mentioned in this [article](https://docs.microsoft.com/en-us/ef/core/querying/client-eval) to avoid client evaluation or at least throw an exception. Having said that, in the later versions the exception would be thrown by default.

### Conclusion and Discussion

Using lambda expressions in C# would help with implementing more efficient specifications. However, you need to be mindful of client evaluation.

Working with any framework is sensitive to the type of the framework and its version. Any clever developer needs to always be aware of the limitations of the framework in hand. EF is not an exception, Make sure you know which version you are using and you have reviewed the documentation.
