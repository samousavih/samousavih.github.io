---
layout: post
title:  "How Linq to Monad works under the hood in C#"
date:   2023-04-03 21:31:54 +1000
thumbnail: /images/linq-under-the-hood.jpg
tags: [linq, functional programming]
categories: fop
---
Deep dive into Linq to Monads and how they work

![Diagram showing how LINQ to monad works under the hood](/images/linq-under-the-hood.jpg)
### Abstract

This is a deep dive into how Linq to monad works. We try to cover that in the simplest terms and with plenty of examples. We would also discuss how it relates to the Linq to object in C# which typically used for enumerables.

### Background

As we read in this [article](https://medium.com/@amin_mousavi/improving-readability-by-using-linq-instead-of-bind-operator-in-functional-c-d4c73194e9b1), we know that we can utilise Linq to monad to write more readable code when the code is complex. The example we saw there, was a workflow to create a new booking in a hotel system. In the following, we can see the full code extract of the workflow written with Linq.
```c#
public Either<Problem, ConfirmedBooking> CreateBooking(BookingRequest bookingRequest)
{
    return
        from validatedBooking in validateBooking(bookingRequest)
        from bookingNumber in generateBookingNumber(validatedBooking)
        from bookingFees in calculateFees(validatedBooking)
        from bookingAcknowledgement in createBookingAcknowledgement(validatedBooking, bookingNumber, bookingFees)
        select new ConfirmedBooking
        {
            ValidatedBooking = validatedBooking,
            BookingNumber = bookingNumber,
            BookingAcknowledgement = bookingAcknowledgement,
        };
}
```

Utilising Linq, to write the expressions as above, which operate on Either monad, requires implementing the following extension. The function we are implementing is SelectMany.
```c#
    public static class EitherExtension
    {
        public static Either<L, V> SelectMany<U, V, L, R>(
            this Either<L,R> first,
            Func<R, Either<L, U>> getSecond,
            Func<R, U, V> project) {
              return first.Bind(a => getSecond(a).Map(b => project(a, b)));
        }
    }
```
The question we are addressing in this article is how that actually works. What is the connection between Linq expression and SelectMany function and how SelectMany function should be implemented for Linq to work with Either monad.

### How Linq expressions are translated in SelectMany form

To understand how Linq to monad works, first step is to understand how Linq expressions can be rewritten with a SelectMany function. Why SelectMany? That is how C# works. The compiler would translate a Linq expression with more than one “from” clause into one or more SelectMany function calls. [Here](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/expressions#111835-from-let-where-join-and-orderby-clauses) you can read more about this in the C# specification. According to the specification,
> The following Linq expression,

    from «x1» in «e1»  
    from «x2» in «e2»  
    select «v»

> will be translated into this:

    ( «e1» ) . SelectMany( «x1» => «e2» , ( «x1» , «x2» ) => «v» )

To better understand how the translation works, consider this code extract,
```c#
int[] arrayA = { 1, 2 };
int[] arrayB = { 3, 4 };

var result = 
    from a in arrayA
    from b in arrayB
    select new { A = a, B = b };
```
We have two arrays which are joined and then projected into an array of elements with 2 fields A and B. So in a sense the first 2 lines of Linq expression starting with keyword “from” are creating a full join (Product to be more accurate) of all those arrays and then the projection makes it into a one dimensional array of the object type, an array of all of the possible combinations which would be something like this:

    [{A:1,B:3}, {A:1,B:4}, {A:2,B:3}, {A:2,B:4}]

And when it is translated into Linq we would see this code.
```c#
int[] arrayA = { 1, 2 };
int[] arrayB = { 3, 4 };

var result = arrayA
    .SelectMany(a => arrayB, (a, b) => new { A = a, B = b });
```
If we try the same Linq with three arrays as per the following code,
```c#
int[] arrayA = { 1, 2 };
int[] arrayB = { 3, 4 };
int[] arrayC = { 5, 6 };

var result = 
    from a in arrayA
    from b in arrayB
    from c in arrayC
    select new { A = a, B = b, C = c };
```
It again will be translated into this,
```c#
int[] arrayA = { 1, 2 };
int[] arrayB = { 3, 4 };
int[] arrayC = { 5, 6 };

var result = arrayA
    .SelectMany(a => arrayB, (a, b) => new { A = a, B = b })
    .SelectMany(ab => arrayC, (ab, c) => new { A = ab.A, B = ab.B, C = c });
```
And here would be the value of “result”.

    [{A:1,B:3,C:5}, {A:1,B:3,C:6} 
     {A:1,B:4,C:5}, {A:1,B:4,C:6}
     {A:2,B:3,C:5}, {A:2,B:3,C:6}
     {A:2,B:4,C:5}, {A:2,B:4,C:6}]

As you can see in the code above we have 2 calls of SelectMany the first argument is a function which returns the product of two arrays e.g “*X × Y”* and the second one is a projection which returns an object. The first SelectMany does “*arrayA × arrayB” *and returns an object with A and B fields. The second SelectMany does “(*arrayA × arrayB) × arrayC”* and returns an object with A,B and C fields. The objects essentially carrying the context to the next call.

### Arguments of SelectMany

As we saw above, the Linq expression would be converted into the two SelectMany calls above with two arguments. The first argument is a function which per each element in one array returns all of the elements in the next. As an example, in the first SelectMany call, the argument of SelectMany is “a => arrayB”, which “a” is an element of “arrayA”. This way we are building “arrayA *×* arrayB”. The second argument of the SelectMany call is another function. This function is called a projection function. The function is “(a,b) => new {A = a, B = b}” which per each pair of (a,b) returns an object of “{A = a, B = b}”.

Now If we look at the [SelectMany’s function signature](https://learn.microsoft.com/en-us/dotnet/api/system.linq.enumerable.selectmany?view=net-8.0#system-linq-enumerable-selectmany-3(system-collections-generic-ienumerable((-0))-system-func((-0-system-collections-generic-ienumerable((-1))))-system-func((-0-1-2)))) for an IEnumerable type, and its(simplified) implementation below,
```c#
public IEnumerable<TResult> SelectMany<TSource, TCollection,TResult>(
    this IEnumerable<TSource> firstEnumerable
    Func<TSource, IEnumerable<TCollection>> getSecondEnumerable,
    Func<TSource, TCollection, TResult> project){

    foreach (TSource element in firstEnumerable) {
            foreach (TCollection subElement in getSecondEnumerable(element)) {
                yield return project(element,subElement);
            }
    }
}
```
We can see the two arguments. The function is multiplying two enumerables. To be more accurate, it is doing this array multiplication.

    IEnumerable<TSource> × IEnumerable<TCollection> = IEnumerable<TResult>

Which “TSource” is the type of each element in the first enumerable, “TCollection” is the type in the second and “TResult” is the type of result, after multiplication and then projection. For more clarity, I have changed the name of those arguments from what it was in the original C# specification. The first argument is the first enumerable involved in the multiplication, The second argument is called “getSecondEnumerable” to show it returns the second enumerable of the multiplication. The second is called “project”, so it is clear that it does a projection. The implementation, also is essentially two “foreach” loops with calculating the product of two enumerables and returning an enumerable of the projections.

### Similarity between Either and IEnumerable

Now that we understand how Linq expressions can be converted to SelectMany function calls, we can (re)implement SelectMany function for Either type. Looking at this from another perspective we are introducing a new type of multiplication which happens between Either types. More accurately, we are introducing a new operator. If assume “#” shows the new operator we can run the following,

    Either<Problem,FirstType> # Either<Problem,SecondType> 
                                                      = Either<Problem,ResultType>

Which an example of this operation is when in the hotel booking system we are calling the “create booking” workflow functions, as shown in this code extract.
```c#
from validatedBooking in ValidateBooking(bookingRequest)
from bookingNumber in GenerateBookingNumber(validatedBooking)
select new ConfirmedBooking
    {
        ValidatedBooking = validatedBooking,
        BookingNumber = bookingNumber
    };
```
Replacing “FirstType” and “SecondType” and “ResultType” with the types from the code above, we have this.

    Either<Problem,ValidatedBooking> # Either<Problem,BookingNumber>
                                               = Either<Problem,ConfirmedBooking>

Please note the I have removed a few steps of the workflow for simplicity.

### How to implement SelectMany for Either type

Now let’s come back to the SelectMany implementation for Either monad, here is the code,
```c#
public static class EitherExtension
{
    public static Either<L, V> SelectMany<U, V, L, R>(
        this Either<L,R> first,
        Func<R, Either<L, U>> getSecond,
        Func<R, U, V> project) {
            return first.Bind(a => getSecond(a).Map(b => project(a, b)));
    }
}
```
The signature of the function above shouldn’t be a surprise. The implementation also should make more sense. We are Binding the “first” argument with the result of “getSecond” function and the projection of the result. But, since the projection doesn’t return an Either we utilise Map function to convert that into an Either. You can find an implementation of Map function [here](https://github.com/samousavih/HotelBookingSystem/blob/effacf0210db30d6cc5d0c153a18573382b00951/Core/Either.cs). The following diagram shows how the function above works step by step.

![A flowchart showing how SelectMany implementation works with Either monad, demonstrating the binding and mapping process](https://cdn-images-1.medium.com/max/2000/1*otbNPvQls8P8Ggkru0iPIQ.jpeg)

Also, for further clarity let’s look at the hotel booking example and focus on just one part of the workflow. The part which it validates the booking request and then generates a booking number. The code below shows that part, but with a SelectMany function.
```c#
ValidateBooking(bookingRequest).SelectMany(
    validatedBooking => GenerateBookingNumber(validatedBooking),
    (validatedBooking, bookingNumber) => new {validatedBooking,bookingNumber}
)
```
The first argument of SelectMany is the result of

    ValidateBooking(bookingRequest)

the second argument is the function

    validatedBooking => GenerateBookingNumber(validatedBooking)

and finally the projection function is

    (validatedBooking, bookingNumber) => new {validatedBooking,bookingNumber}

### How about when we only using one “from” clause?

Following is an example,
```c#
int[] arrayA = { 1, 2 };

var result = 
    from a in arrayA
    select new { A = a};
```
in this case we are not doing an array multiplication as obviously there is only one array involved. As per [C# specification](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/expressions#111834-degenerate-query-expressions), this code would be translated into one “Select” call.
```c#
var result = arrayA
    .Select(a => new { A = a });
```
Following code extract is an example when we using Linq to monad.
```c#
from validatedBooking in ValidateBooking(bookingRequest)
select validatedBooking; 
```
To implement this with Either monad, all that is required is to call the Map function. Essentially “Select” is a Map function. But to support Linq, we need to have a method with the name “Select”.
```c#
public static class EitherExtension
{
    public static Either<L, U> Select<U,L,R>(
            this Either<L,R> first, Func<R, U> map) => first.Map(map);
}
```
### Why we needed to implement SelectMany or Select?

As per C# specification there is a pattern called [query-expression pattern](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/expressions#11184-the-query-expression-pattern). The Query-expression pattern is a pattern of methods, that types can implement to support query expressions. Among these methods, we can see SelectMany and Select. So, if we make those functions publicly accessible members or public extensions for any type, the type can support Linq expressions. There are, however, other methods we can implement. But, for the scope of Either monad, SelectMany and Select is enough because in the Linq expressions above we are only using “from” clause and “select”.

### Conclusion

Understanding how Linq and Linq to monad works, deepens our understanding of monads. Also, paves the way to use that tool not just for Either monads and in the context of error handling but for other monadic types.

Not to mention understanding how things work in general, which you might not necessarily have to, is always a joy.

### The source code

You can find the full source code for this article [here](https://github.com/samousavih/HotelBookingSystem/tree/computational-expression/BookingCreation), also [here](https://github.com/samousavih/HotelBookingSystem/blob/computational-expression/Core/Either.cs) is the Either monad implementation.
