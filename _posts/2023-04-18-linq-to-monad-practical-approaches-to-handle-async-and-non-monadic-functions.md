---
layout: post
title:  "Linq to Monad: Practical approaches to handle async and non-monadic functions"
date:   2023-04-18 21:31:54 +1000
thumbnail: https://cdn-images-1.medium.com/max/2048/1*j65KedocsoH9e_vHUtjl-Q.png
categories: fop
---


Making Linq to monad work in production code when things don’t play well

![](https://cdn-images-1.medium.com/max/2048/1*j65KedocsoH9e_vHUtjl-Q.png)

### Background

[Linq to monad](https://medium.com/itnext/improving-code-readability-in-functional-c-using-linq-to-monad-d4c73194e9b1) is an approach to write more readable code when working with monads. It works well when all of the functions are returning a monadic type and the type is the same. However, in production code, often we are facing a variety of different functions which are not monadic or they are returning a derivative of the monadic type, e.g async functions. In this article we are discussing different practical approaches, so we can seamlessly handle those functions in the Linq expression.

### Story

[This](https://medium.com/@amin_mousavi/improving-readability-by-using-linq-instead-of-bind-operator-in-functional-c-d4c73194e9b1) article covers the Create Booking workflow in a hotel booking system. Also, from the same article we know we can utilise Linq to improve readability. The following code extract from the article displays the workflow using Linq to monad when all of the functions are returning an “Either” type.
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
Let’s change the above code slightly, so we can see the signature of each function. We are injecting the functions for the workflow steps. The main reason to do this in production code would be to make the workflow testable.
```c#
    public static Either<Problem, ConfirmedBooking> CreateBooking(
            BookingRequest bookingRequest,
            Func<BookingRequest, Either<Problem, ValidatedBooking>> validateBooking,
            Func<ValidatedBooking, Either<Problem, BookingNumber>> generateBookingNumber,
            Func<ValidatedBooking, Either<Problem, BookingFees>> calculateFees,
            Func<ValidatedBooking, BookingNumber, BookingFees, Either<Problem, BookingAcknowledgement>> createBookingAcknowledgement)
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
It is visible in the above code that all of the functions are returning an Either<Problem, X>*,* which “X” is different based on the step function. As an example the return type of “calculateFees” function is Either<Problem, BookingFees>.

### Introducing Non-monadic and Async functions to the workflow

Now, let’s imagine “validateBooking” is an async function, assuming it might call an api or look up some records from database. Same for “generateBookingNumber” function. Also, “calculateFees” would just calculate the booking fees using some formulas which always return a value and never fails, therefore, we do not need to return an Either type for this one. Now, the function signature for “CreateBooking” would look like the following code extract.
```c#
    public static async Task<Either<Problem, ConfirmedBooking>> CreateBooking(
            BookingRequest bookingRequest,
            Func<BookingRequest, Task<Either<Problem, ValidatedBooking>>> validateBooking,
            Func<ValidatedBooking, Task<Either<Problem, BookingNumber>>> generateBookingNumber,
            Func<ValidatedBooking, BookingFees> calculateFees,
            Func<ValidatedBooking, BookingNumber, BookingFees, Either<Problem, BookingAcknowledgement>> createBookingAcknowledgement)
        {
            ....
        }
```
As you can see, “validateBooking” function is returning a `Task<Either<Problem, ValidatedBooking>>`, “generateBookingNumber” function is returning `Task<Either<Problem, BookingNumber>>` and “calculateFees” has “BookingFees” as the return type.

Since in addition to Either<Problem,X>,we now have Task<Either<Problem,X> and non-monadic types e.g “BookingFees”, the original Linq to monad implementation is not working. Depending on the library used or whether you have implemented the Either monad yourself, there are a few strategies which can be utilised to resolve this. These strategies are described next.

### Lifting non-monadic and sync functions to async and monadic using type conversion

This technique essentially means to convert all of the different return types to a common type. Since, it is not possible to go from monadic to non-monadic and from async to sync, we would need to lift all of the return types to async and monadic. More accurately, for the the example above the following conversions needed to happen.

    1) Either<Problem,X> => Task<Either<Problem,X>
    2) X => Task<Either<Problem,X>

So for example, if you are using [language-ext](https://github.com/louthy/language-ext) library you would need to use some of the extensions already built into the library. The code below displays how the conversion can be done.
```C#
    public static async Task<Either<Problem, ConfirmedBooking>> CreateBooking2(
          BookingRequest bookingRequest,
          Func<BookingRequest, Task<Either<Problem, ValidatedBooking>>> validateBooking,
          Func<ValidatedBooking, Task<Either<Problem, BookingNumber>>> generateBookingNumber,
          Func<ValidatedBooking, BookingFees> calculateFees,
          Func<ValidatedBooking, BookingNumber, BookingFees, Either<Problem, BookingAcknowledgement>> createBookingAcknowledgement)
      {
          return await
              from validatedBooking in validateBooking(bookingRequest).ToAsync()
              from bookingNumber in generateBookingNumber(validatedBooking).ToAsync()
              let bookingFees = calculateFees(validatedBooking)
              from bookingAcknowledgement in createBookingAcknowledgement(validatedBooking, bookingNumber, bookingFees)
                    .AsTask()
                    .ToAsync()
              select new ConfirmedBooking
              {
                  ValidatedBooking = validatedBooking,
                  BookingNumber = bookingNumber,
                  BookingAcknowledgement = bookingAcknowledgement,
              };
      }
```
As you can see, we are using “ToAsync” and “AsTask” to lift the types. These utility functions are already part of the library. Notice, we used “let” operator too, but ignore that for now as we address this a bit further.

In some other cases, you might need to write your own type conversion extensions. For example if you are using [CSharpFunctionalExtensions](https://github.com/vkhorikov/CSharpFunctionalExtensions), you would need to add this extension.
```c#
    public static class ResultExtensions
    {
        public static Task<Result<T, Problem>> ToResultAsync<T>(this T value)
        {
            return Task.FromResult(Result.Success<T,Problem>(value));
        }
    }
```
Then, the above example using that library and with all of the different types would look like the following code.
```c#
    public static async Task<Result<ConfirmedBooking, Problem>> CreateBooking(BookingRequest bookingRequest,
            Func<BookingRequest, Task<Result<ValidatedBooking, Problem>>> validateBooking,
            Func<ValidatedBooking, Task<Result<BookingNumber,Problem>>> generateBookingNumber,
            Func<ValidatedBooking, BookingFees> calculateFees,
            Func<ValidatedBooking, BookingNumber, BookingFees, Result<BookingAcknowledgement, Problem>> createBookingAcknowledgement)
        {
            return await
                from validatedBooking in validateBooking(bookingRequest)
                from bookingNumber in generateBookingNumber(validatedBooking)
                from bookingFees in calculateFees(validatedBooking).ToResultAsync()
                from bookingAcknowledgement in createBookingAcknowledgement(validatedBooking, bookingNumber, bookingFees)
                select new ConfirmedBooking
                {
                    ValidatedBooking = validatedBooking,
                    BookingNumber = bookingNumber,
                    BookingAcknowledgement = bookingAcknowledgement,
                };
        }
```
Notice, we only needed to lift the type “BookingFees” as this library already does handle other types.

### Adding SelectMany and Select extensions which account for the differences in the type

The main benefit of this method is you will have cleaner code. As Select and SelectMany would handle the type difference under the hood. The extensions you need to add for [language-ext](https://github.com/louthy/language-ext) library are shown in the code below.
```c#
    public static class TaskExtension
    {
        public static async Task<Either<L, R3>> SelectMany<R2, R3, L, R>(this Task<Either<L, R>> first, Func<R, Task<Either<L, R2>>> getSecond, Func<R, R2, R3> project)
        {
            return await first.BindAsync(async a => (await getSecond(a)).Map(b => project(a, b)));
        }
    
        public static async Task<Either<L, R3>> SelectMany<R2, R3, L, R>(this Either<L, R> first, Func<R, Task<Either<L, R2>>> getSecond, Func<R, R2, R3> project)
        {
            return await first.BindAsync(async a => (await getSecond(a)).Map(b => project(a, b)));
        }
    
        public static async Task<Either<L, R3>> SelectMany<R2, R3, L, R>(this Task<Either<L, R>> first, Func<R, Either<L, R2>> getSecond, Func<R, R2, R3> project)
        {
            return (await first).Bind(a => getSecond(a).Map(b => project(a, b)));
        }
    }
```
The first SelectMany function would handle the case when both consequent workflow steps returning Task<Either<L, R>> as below.

    Task<Either<L, R3>> SelectMany<R2, R3, L, R>(this Task<Either<L, R>> first, 
    Func<R, Task<Either<L, R2>>> getSecond,
    Func<R, R2, R3> project)

The second SelectMany function is for when in two consequent workflow steps, the first return type is Either<L, R>, but the second one is async and is returning Task<Either<L, R2>> as shown below.

    Task<Either<L, R3>> SelectMany<R2, R3, L, R>(this Either<L, R> first,
     Func<R, Task<Either<L, R2>>> getSecond,
     Func<R, R2, R3> project)

And the last one is the opposite of the second one, it is for when the first workflow step returning Task<Either<L, R2>> and the second step returning Either<L, R>.

As you can see, we are covering all of the different combinations of types when they are used consequently in a Linq expression. The number of these combinations, can significantly surge as more types you are trying to cover. To fully understand how SelectMany helps here have a look at [this](https://itnext.io/how-linq-to-monad-works-under-the-hood-in-c-55e301943673) article.

After applying the extensions above, the Create Booking example would look like the following code extract.
```c#
    public static async Task<Either<Problem, ConfirmedBooking>> CreateBooking(
            BookingRequest bookingRequest,
            Func<BookingRequest, Task<Either<Problem, ValidatedBooking>>> validateBooking,
            Func<ValidatedBooking, Task<Either<Problem, BookingNumber>>> generateBookingNumber,
            Func<ValidatedBooking, BookingFees> calculateFees,
            Func<ValidatedBooking, BookingNumber, BookingFees, Either<Problem, BookingAcknowledgement>> createBookingAcknowledgement)
        {
            return await
                from validatedBooking in validateBooking(bookingRequest)
                from bookingNumber in generateBookingNumber(validatedBooking)
                let bookingFees = calculateFees(validatedBooking)
                from bookingAcknowledgement in createBookingAcknowledgement(validatedBooking, bookingNumber, bookingFees)
                select new ConfirmedBooking
                {
                    ValidatedBooking = validatedBooking,
                    BookingNumber = bookingNumber,
                    BookingAcknowledgement = bookingAcknowledgement,
                };
        }
```
### Using “let” operator for non-monadic functions

Another useful technique which can be utilised in combination of the above methods, is using “let” operator in Linq. By using the operator, we are highlighting that the function we are dealing with, is not monadic. Under the hood, the “let” operator would be translated into a “Select” call as per [this](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/expressions#112035-from-let-where-join-and-orderby-clauses) part of C# specification. As you might have already noticed in the sample code above the operator is used for “calulateFees” function.

let bookingFees = calculateFees(validatedBooking)

As we already know, the function returns a non-monadic type “BookingFees”.

Depending on the library you use, you may or may not need to add the “Select” extension yourself. Following code extract shows the implementation of “Select” extension for [language-ext](https://github.com/louthy/language-ext) library.

    public static class TaskExtension
    {
        public static async Task<Either<L, R2>> Select<R2, L, R>(this Task<Either<L, R>> first, Func<R, R2> map) => (await first).Map(map);
    }

### Discussion

The techniques covered in this article depend on the library you use and the use case you have for Linq to monad. If most of the time you are using async types with just a few exceptions, perhaps lifting other types to async using type conversion extensions makes more sense. However, if you found yourself needing to use “ToSomething()” functions too many times, at least for some of more common types in your workflow, you can implement more SelectMany extensions.

### Source code

You can find the full source code of examples for non-monadic and async function in [here](https://github.com/samousavih/HotelBookingSystem/tree/computational-expression/BookingCreation).
