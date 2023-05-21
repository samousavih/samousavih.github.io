---
layout: post
title:  "Measuring Code Readability of Linq to Monad using ChatGPT"
date:   2023-05-12 21:31:54 +1000
categories: fop
---

Can we use ChatGPT to measure code readability?

![](https://cdn-images-1.medium.com/max/2048/1*EVCcwd1HXO1o4dgy_MqCFA.png)

### Background

As suggested, Linq can [improve the readability of functional C# and especially railway programming](https://medium.com/itnext/improving-code-readability-in-functional-c-using-linq-to-monad-d4c73194e9b1). But one question is, can we measure it? Can we measure how much using Linq improves readability?

### Can we measure code readability?

Code readability is difficult to measure because it is subjective. Background, skill, experience and preferences of engineers can impact the perceived readability of a piece of code. Engineers who are used to a specific style of writing code no matter how convoluted or complex, might consider that more readable compared to any new code structure and vice versa.

Despite that, there are industry metrics which can be used as a proxy for readability. Cognitive complexity [produces a measurement that reflects the relative difficulty of understanding, and therefore maintaining methods, classes, and applications.](https://www.sonarsource.com/resources/cognitive-complexity/) [SonarQube](https://docs.sonarqube.org/latest/user-guide/metric-definitions/) is a well known tool for static code analysis which can measure cognitive complexity.

I have [setup SonarQube in my local machine ](https://medium.com/c-sharp-progarmming/run-sonarqube-locally-b8d6613342c8)to calculate the metric.

### Measuring Linq to Monads readability using SonarQube

Let’s compare cognitive complexity of the two variations of create booking function, one with Linq and another with Bind operator as per the [Linq to Monad post](https://itnext.io/improving-code-readability-in-functional-c-using-linq-to-monad-d4c73194e9b1).

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

Interestingly the cognitive complexity is 0 for both of the above codes. Despite the first code extract being nested, and is expected to have lower code readability.

Looking deeper into the definition of cognitive complexity metric, the indifference to nesting of the first code is because there are no conditional statements, loops, exception handling, etc [as per page 16 of the white paper](https://www.sonarsource.com/resources/cognitive-complexity/). Cognitive complexity metric counts nested methods and lambdas, but the metric only increases when they are combined with the mentioned elements. In fact to display that, if we add an arbitrary condition in the first code as below, we see cognitive complexity increases to 4.

    public static Either<Problem, ConfirmedBooking> CreateBooking(BookingRequest bookingRequest)
    {
        return validateBooking(bookingRequest)
            .Bind(validatedBooking => {
            return generateBookingNumber(validatedBooking)
                .Bind(bookingNumber => {
                return calculateFees(validatedBooking)
                    .Bind(bookingFees => {
                        if(bookingFees.TotalFee < 0.0m)
                            return Problems.Nofee;
                    return createBookingAcknowledgement(validatedBooking, bookingNumber, bookingFees)
                        .Map(bookingAcknowledgement => new ConfirmedBooking
                        {
                            ValidatedBooking = validatedBooking,
                            BookingNumber = bookingNumber,
                            BookingAcknowledgement = bookingAcknowledgement,
                        });
                    });
                });
            });
    }

### Can we use ChatGPT?

Let’s try come with a [prompt](https://lilianweng.github.io/posts/2023-03-15-prompt-engineering/) so we can measure code readability. We are looking for a readability score ranging from 0 to 10. Which 0 is the lowest and 10 is the highest readability. The factors taken into account here are,

1. Variable and function naming

1. Code structure

1. Indentation

1. Cognitive effort to understand and reason about the code

Here is the prompt and it’s response using GPT-4 engine.
> Please rate the readability of the following code snippets on a scale of 0 to 10, where 0 represents the least readable code and 10 represents the most readable code. For each snippet, consider factors such as variable and function naming, code structure, indentation and the cognitive effort to understand and reason about the code by a developer. Explain how you get to the score step by step detailing the factors that contributed to the score. Please maintain consistency in your evaluation criteria across all snippets.
> Format of response:
> Readability rating:{x}/10
> Reason: {step by step details}
> Code Snippet 1: {The code with Bind}
> Code Snippet 2:{The code with Linq}

And the answer is
> Readability rating for Code Snippet 1: 7/10
Reason:
> 1. Function and Variable Naming (2/2): The function and variable names are very descriptive and provide a clear understanding of what they are expected to do or represent. This includes the function parameters as well which are appropriately named.
> 2. Code Structure (2/3): The structure of the function uses the Either Monadic structure, which is helpful for dealing with computations that can fail. The chaining of the computation using `.Bind` is also clear, however, it leads to nested code which can become hard to read when the computation becomes more complex.
> 3. Indentation (2/2): The code is properly indented, which makes it easy to follow the logical flow and the hierarchical structure.
> 4. Cognitive Effort (1/3): While the function and variable naming is good, the nested structure of the code makes it a bit hard to understand at first glance. You have to keep track of each computation and its result, which increases the cognitive load on the reader.
> — -
> Readability rating for Code Snippet 2: 9/10
Reason:
> 1. Function and Variable Naming (2/2): Just like the first snippet, the function and variable names are very descriptive and provide a clear understanding of what they are expected to do or represent. This includes the function parameters as well which are appropriately named.
> 2. Code Structure (3/3): The function uses the LINQ syntax to structure the computation. This makes the code very linear and easy to follow. Each computation is clearly separated from the others, which makes the code easier to understand and reason about.
> 3. Indentation (2/2): The code is properly indented, which makes it easy to follow the logical flow and the hierarchical structure.
> 4. Cognitive Effort (2/3): The LINQ syntax reduces the cognitive load compared to the first snippet as it’s easier to understand the flow of the computation. However, understanding the Either monadic structure and LINQ syntax might still pose some cognitive load to developers not familiar with these concepts.

Based on chatGPT readability rating as above, using Linq improves readability. The overall readability rating for using Linq is 9/10 versus 7/10 for using Bind operator.

### Discussion

This article only addresses readability. It is still up to the team and individual developers to choose the approach which works for them, as other factors should be taken into account when making technical decisions including skill, background, etc.

This article also shows how ineffective static metrics like cognitive complexity can be for measuring code readability. It is not hard to predict that code analysis including measuring readability would be uplifted by integrating AI models soon.

ChatGPT and other LLMs, however, come with their own challenges. Despite heaps of studies done to [keep LLM outputs consistent and reliable in production](https://huyenchip.com/2023/04/11/llm-engineering.html), this area is still young and immature.
