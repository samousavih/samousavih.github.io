---
layout: post
title:  "Improving code readability in functional C# using Linq to Monad"
date:   2023-05-18 21:31:54 +1000
thumbnail: /images/linq-to-monad.png
tags: [functional programming, Linq]
categories: fop
---

How to implement computation expressions in C#

![A puppy sitting at a computer appearing to read code, illustrating the concept of readable functional code](/images/wmihy9TV2z6x238jY4C6Hw.png)*A puppy enthusiastically reading well-written and readable code from a computer screen. Although from here it is not clear if that code is a functional code.*

### Background and intention

More and more software engineers are adopting the functional mindset and its toolbox, and as a result, functional programming techniques are being utilized in a growing number of software projects. Some of these projects are complex and require more flexibility from the tools. Monadic types as one of these tools are receiving increasing attention. However, their basic and well-known toolsets may not be sufficient for some of the more complex scenarios.

I have faced one of these complexities during development of a commercial software system. This article is based on my experience of dealing with the issue. The example in this article is recreated based on the the experience to be easily understandable for broader audience.

This article explores how one of the well-known capabilities of C# language, Linq, can be used to address the complexity. The technique used in this article is also known as [Linq to Monad](https://weblogs.asp.net/dixin/category-theory-via-csharp-7-monad-and-linq-to-monads) or [Computation Expressions](https://learn.microsoft.com/en-us/dotnet/fsharp/language-reference/computation-expressions).

### Story

A hotel booking system architecture was explained on [this]({% link _posts/2020-08-07-specification-pattern-and-how-to-quantify-the-improved-software-stability.md %} ) article. It has a handful of components. One of those components is called “Booking Creation”. The component is responsible for new bookings in the system. Let’s zoom in to Booking Creation component and see how it works. Here is a code extract which shows the implementation. It contains multiple steps to create a new hotel booking. Each step is a function.
```c#
public static ConfirmedBooking CreateBooking(BookingRequest bookingRequest)
{
    var validatedBooking = ValidateBooking(bookingRequest);
    var bookingNumber = GenerateBookingNumber(validatedBooking);
    var bookingFees = CalculateFees(validatedBooking);
    var bookingAcknowledgement = CreateBookingAcknowledgement(validatedBooking, bookingNumber, bookingFees);
    
    return new ConfirmedBooking
    {
        ValidatedBooking = validatedBooking,
        BookingNumber = bookingNumber,
        BookingAcknowledgement = bookingAcknowledgement,
    };
}
```
Here is what each step or function in the code extract does:

1. **Validate the booking request**: As the name suggests, it includes validations on the input request, making sure all of the required fields are provided, etc.

2. **Generate a booking number**: This step based on the data in the request creates a unique number or id for the request, which users can use for their possible future inquiries.

3. **Calculate fees**: Calculates the fees based on type of the room, extras, discounts, etc.

4. **Create a booking acknowledgment**: This step creates an event which would be passed in to the caller of the function, so then used as a notification to the rest of the system. To read more about this pattern refer to the book [Domain Modeling Made functional](https://www.amazon.com/Domain-Modeling-Made-Functional-Domain-Driven-dp-1680502549/dp/1680502549/ref=mt_other?_encoding=UTF8&me=&qid=1609590428), the section “communication between bounded contexts”.

5. **Return confirmed booking**:The step packs all of results of previous steps and returns a confirmed booking, this is the last step in the workflow.

We won’t go through each step and how they are implemented as it is not relevant to the topic of this article. However, it is not difficult to imagine how each function would be implemented.

### Error handling

The code above doesn’t have any error handling. Imagine each step can fail, therefore we are looking to stop the workflow and return the error to the caller of the CreateBooking function. Using [Monadic types](https://mikhail.io/2018/07/monads-explained-in-csharp-again/) and [railway programming](https://fsharpforfunandprofit.com/rop/) is a common functional approach to achieve this. The type used here is called “Either”, which all of the functions in this context will be returning. For example the main function signature would be changed to this.

    Either<Problem, ConfirmedBooking> CreateBooking(BookingRequest bookingRequest)

We can read the above code as CreateBooking function receives a booking request as the argument and returns “Either” a problem or a confirmed booking. Either monad is a member of [Alternative Value Monads](https://louthy.github.io/language-ext/LanguageExt.Core/DataTypes/Alternative%20Value%20Monads/index.html) family.

The type Problem is a simple type containing the details of the error. Here is a code extract of the type.
```c#
public class Problem
{
    public string Title { get; set; }
    public int Code { get; set; }
    public string Detail { get; set; }
}
```
Using Either monad commonly implies using Bind operator to chain(compose) the function steps. Next section shows how we can use this operator.

### Bind operator and readability problem

The basic idea behind the Bind operator is to make it seamless to chain functions with non matching input and output. it also hides the extra logic required after each step.

In this context Bind operator handles the logic of error handling after each step in the booking creation workflow. If there was an error it returns the error, if there wasn’t, it applies the next function in the chain on the result of previous step.

Before applying the Bind function, please see the way the steps are dependent on each other. Not each step just simply gets it’s input from the step before, it is more complicated. For example, to generate a booking acknowledgment we need a validated booking, a booking number and the calculated fees. So this step depends on the output of all the three steps before.

![A detailed flowchart showing the steps of binding and mapping functions in LINQ to monad](https://cdn-images-1.medium.com/max/2000/1*jPAjbXzt6jM0iv8i8kLYHg.jpeg)*Dependency graph for steps in create booking workflow, some of the steps have dependency on one or more steps before them and not just the immediate previous steps.*

Now by applying the Bind operator, here is how the create booking function looks like.
```c#
public static Either<Problem, ConfirmedBooking> CreateBooking(BookingRequest bookingRequest)
{
    return ValidateBooking(bookingRequest)
        .Bind(validatedBooking => {
        return GenerateBookingNumber(bookingRequest)
            .Bind(bookingNumber => {
            return CalculateFees(validatedBooking)
                .Bind(bookingFees => {
                    return CreateBookingAcknowledgement(bookingRequest, bookingNumber, bookingFees)
                        .Bind<ConfirmedBooking>(bookingAcknowledgement => new ConfirmedBooking {
                            BookingRequest = bookingRequest,
                            BookingNumber = bookingNumber,
                            BookingAcknowledgement = bookingAcknowledgement,
                        });
                });
        });
    });
}
```
The code above is nested. There are 4 levels of nesting. You can count the levels by counting the number of curly brackets. The reason we had to come with the nested code above was the dependency between steps of booking creation function as per the diagram shown before.

The code has poor readability, because it is nested. As we know nested code is one of the reasons for [decreasing readability](https://blog.codinghorror.com/flattening-arrow-code/). And also we know lack of readability can cause other issues, as increased chance of defects, slower and harder to change, etc. So that is the problem. Next let’s see how we can improve this.

### Using Linq

Turns out we can utilise Linq to make this simpler. Here is how the Create Booking workflow looks like if we use Linq.
```c#
public static Either<Problem, ConfirmedBooking> CreateBooking(BookingRequest bookingRequest)
{
    return 
        from validatedBooking in ValidateBooking(bookingRequest)
        from bookingNumber in GenerateBookingNumber(bookingRequest)
        from bookingFees in CalculateFees(validatedBooking)
        from bookingAcknowledgement in CreateBookingAcknowledgement(bookingRequest, bookingNumber, bookingFees)
        select new ConfirmedBooking
        {
            BookingRequest = bookingRequest,
            BookingNumber = bookingNumber,
            BookingAcknowledgement = bookingAcknowledgement,
        };
}
```
As we can see there is no nesting in this code. The code is more readable. Additionally, it can extend further to handle more complicated cases. You can add more steps into this workflow without impacting it’s readability.

However, the vanilla Linq to object in C# isn’t capable of this. You will need to use an external library.

### Which libraries to use?

[language-ext](https://github.com/louthy/language-ext) is a library which covers many aspects of functional programming in C# and is designed with Linq in mind. The library is also well documented. Another examples is [CSharpFunctionalExtensions](https://github.com/vkhorikov/CSharpFunctionalExtensions). Although the language-ext is a much more comprehensive library. But for the example above both would work. Have a look at this [code repository](https://github.com/samousavih/HotelBookingSystem/tree/computational-expression/BookingCreation) for various examples.

### Can I implement this myself without using any libraries?

Yes you can, in fact the implementation is not complicated. So if you want the minimal implementation which just covers what you need, have a look [here](https://github.com/samousavih/HotelBookingSystem/blob/computational-expression/Core/Either.cs).

### What? How is this possible?

If you want to fully understand how Linq is doing the magic and how it is implemented, [here]({% link _posts/2023-04-03-linq-to-monad-under-the-hood.md %}) is a how the implementation works in full details.

### What if I had Async functions and Non-monadic functions?

Non-monadic functions are functions which are not returning a monadic type. In the context of error handling and more specifically Either monad this means the function would not return an Either type. Said other way, the function never returns a problem and always returns a value.

[language-ext](https://github.com/louthy/language-ext) and [CSharpFunctionalExtensions](https://github.com/vkhorikov/CSharpFunctionalExtensions) are supporting async and non-monadic functions. Using those libraries you might still need to write more extensions to utilise Linq seamlessly. [This]({% link _posts/2023-04-18-linq-to-monad-practical-approaches-to-handle-async-and-non-monadic-functions.md %}) article addresses the issue in more details. Also have a look at this [code repository](https://github.com/samousavih/HotelBookingSystem/tree/computational-expression/BookingCreation) for various examples.

### Discussions

Resolving similar complexities as shown in the create booking workflow example isn’t a new topic in fully functional languages. F# developers, for example, are used to [computation expressions](https://fsharpforfunandprofit.com/series/computation-expressions/). The pattern is more capable than Linq to monad in C# as it can support a variety of scenarios including conditional branches and loops. Refer to the book [Domain Modeling Made functional](https://www.amazon.com/Domain-Modeling-Made-Functional-Domain-Driven-dp-1680502549/dp/1680502549/ref=mt_other?_encoding=UTF8&me=&qid=1609590428), the section “make life easier with computation expressions”. Having said that, most of the time you can get around that by pushing these extra scenarios into functions. Using Linq to monad is as close as possible we can get to computation expressions at C# 10.

C# already supports computation expressions for handling asynchronous programming since version 5. That is async/await. Before that you would have to use different techniques e.g. using the “Beginxxx” and Endxxx” methods and callbacks. Which using them in complex scenarios would lead to the same code readability problems. Maybe in the future we would see the same happens for error handling. So for the example above you could write code as following.
```c#
public error Either<Problem,ConfirmedBooking> ConfirmedBooking CreateBooking(BookingRequest bookingRequest)
{
    var validatedBooking = result ValidateBooking(bookingRequest);
    var bookingNumber = result GenerateBookingNumber(validatedBooking);
    var bookingFees = result CalculateFees(validatedBooking);
    var bookingAcknowledgement = result CreateBookingAcknowledgement(validatedBooking, bookingNumber, bookingFees);
    
    return new ConfirmedBooking
    {
        ValidatedBooking = validatedBooking,
        BookingNumber = bookingNumber,
        BookingAcknowledgement = bookingAcknowledgement,
    };
}
```
Then we would have error/result just like async/await.

### The source code

You can find the full source code for this article [here](https://github.com/samousavih/HotelBookingSystem/tree/computational-expression/BookingCreation).
