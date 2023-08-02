---
layout: post
title:  "Specification Pattern and how to quantify the improved software stability"
date:   2020-08-07 21:31:54 +1000
thumbnail: /images/specification-pattern-and-how-to-quantify-the-improved-software-stability.jpg
tags: [Entity Framework, oo]
categories: oop
---


![](/images/specification-pattern-and-how-to-quantify-the-improved-software-stability.jpg)

Photo by [Markus Spiske](https://unsplash.com/@markusspiske) on [Unsplash](https://unsplash.com/s/photos/stability)
### Abstract

Using stability and abstraction metrics we can measure how stable a software architecture is. To show those metrics in action, I will display step by step how to apply the metrics and how utilising a design pattern can improve them. The design pattern I will use is Specification Pattern.

### Hotel Booking System as a case study

The architecture of a hotel booking system is described in this [article]({% link _posts/2022-06-24-the-story-of-an-evolving-architecture.md %}) in detail. However, for the purpose of this article, we review it briefly. The system is for booking and amending hotel accommodation. It consists of four components, booking creation component, booking amendment component, booking documents component and booking registry Component. Booking creation holds all of the logic and policies for creating a new booking, respectively booking amendment does a similar job for changing a booking which was created before. Both components can communicate with the other two to create or amend booking records and booking documents. Diagram 1 shows the architecture of the system. The focus of this article is the booking registry and its communication with other components.

![Diagram 1- Booking system’s overall architecture and the communications among its components](/images/booking-system-overall-architecture.jpg) *Diagram 1- Booking system’s overall architecture and the communications among its components*

### Booking Registry component and query implementations

As mentioned above the booking registry keeps all of the booking records. Additionally, it also allows other components which we call clients to query the registry to retrieve required records. Some clients might need the list of booking records which have already finalised, others might need the records still in progress. They could also fetch the booking records based on different identifiers or data fields, for example, all records for a single customer or one single record by a booking id. These queries are implemented inside the booking registry. The simplest way to implement them is by using a class which is called query handler. This class has methods for each of the possible queries. Each method knows how to fetch data from the data store which in this case is a database and respectively would map the result to a data model. The data model for booking also is a class which resides inside this component. The data model is a simple data structure. There is also an interface which describes how the query handler class looks like and is defined inside the registry component. The following diagram (diagram 2) shows all of the mentioned parts.

![Diagram 2- Classes inside booking registry](https://cdn-images-1.medium.com/max/2000/1*JONLGKtMgjYF101G5leUcA.jpeg)*Diagram 2- Classes inside booking registry*

if we zoom inside the query handler class we see methods for each query. The pseudocode for the class is displayed here.
```c#
Class BookingRegistryQueryHandler
    extends IBookingRegistryQueryHandler{
    BookingRecord GetBookingRecordsById(BookingId id){}
    BookingRecord[] GetBookingRecordsByStatus(BookingStatus status){}
    BookingRecord[] GetBookingRecordsByCustomer(CustomerId id){}
    ...  
}
```

Not all of these methods are being invoked by every client. Some might call only one some might do more. There could be also methods shared across one or more of those clients. As the product grows and new features implemented these methods need to be changed as well. Therefore, this class and the parent component would need to be altered. These change would happen at different times and for different reasons. Each time the new feature needed a new way of fetching data with new parameters we need to test and redeploy booking registry component too. Even worse, having shared queries across different components and different subdomains of the system could cause instability as those components would grow differently.

As described above, this architecture violates two principles. First [Open Close principle](https://en.wikipedia.org/wiki/Open%E2%80%93closed_principle) as we can not extend the query handler class without modifying its content. The second principle is the [Common Closure principle]({% link _posts/2022-06-24-the-story-of-an-evolving-architecture.md %}) as we have to change the booking registry component because of different reasons and at different times.

### Specification Pattern

Specification pattern is explained in [DDD book](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215) in details. The book also defines what a specification is.
> A Specification allows a client to describe (that is, specify) what it wants without concern for how it will be obtained

To achieve this we need to add a specification class to the booking registry component. Then each of the clients would need to define their own derived version of the specification based on the booking record query they want. Additionally, we can also make the specification class inside booking registry an abstract class. This is helpful because we do not expect any client to create an instance of the classes and they must always extend it. Here is how our new design looks like.

![Diagram 3- Booking registry with specifications](/images/booking-registry-with-specifications.jpg)
*Diagram 3- Booking registry with specifications*

And the query class would look like this :
```c#
Class BookingRegisteryQueryHandler
    extends IBookingRegisteryQueryHandler{
    BookingRecord[] GetBookingRecordsBySpecification(Specification s){}
}
```

And here is the specification class :
```c#
abstract class Specification {
    abstract bool IsSatisfiedBy(BookingRecord b)
}
```
Now each client can drive a new specification by extending the abstract class. Here are some examples.
```c#
class BookingStatusSpecification extend Specification {
    BookingStatus status
    bool IsSatisfiedBy(BookingRecord b){
        return b.Status == status
    }
}


class BookingCustomerSpecification extend Specification {
    CustomerId id
    bool IsSatisfiedBy(BookingRecord b){
        return b.Customer.Id == id
    }
}
```
The two specifications displayed above could reside in different components here is a component overview of specifications.

![Diagram 4- Clients can extend abstract specification class](/images/clients-can-extend-abstract-specification-class.jpg)*Diagram 4- Clients can extend abstract specification class*

The result booking registry is more extendable. To add a new query because of a new feature or a whole new component all you need to do is to extend the abstract specification class and implement a new one inside the client component. So, we no longer have to alter any class or code inside the booking registry. Moreover, The number of reasons to change booking registry is now a lot less than before we no longer have to change, test and redeploy the component because of other components. Although we made great progress we won't stop here. In the next section, we can measure and quantify how much more stable the new architecture is.

### Stability and Abstraction metrics

In the [Clean Architecture](https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164) book, there is a chapter called component coupling which describes these metrics in details. The first metric we explore is the stability metric. It can be calculated with the following equation.

    I = FanOut╱(FanIn+FanOut)

FanOut and FanIn are the number of dependencies pointing in and out of a component. It has a range between 0 to 1. If I = 0 we say the component is maximally stable and if I =1 we call it maximally unstable.

Abstraction metric which is also called A-metric is calculated by this equation

    A = Na╱Nc

Na is the total number of abstract classes and interfaces in a component and Nc is the total number of classes in a component, including abstract, interface and concrete classes. A-metric also similar to I-metric has a value range from 0 to 1. A-metric is 1 if the component only consists of abstract classes or interfaces. On the contrary, it is 0 if all of the classes are concrete classes.

Using the mentioned metrics we can draw a graph called A/I graph and point out every component. Next diagram displays the graph.

![Diagram 5- A/I graph](/images/a-i-graph.jpg)
*Diagram 5- A/I graph*

The main sequence is where ideally all of the components should be mapped. Because the more stable components are the more abstract they should be and vice versa. The ideal component is a component which is maximally stable and at the same time maximally abstract or maximally unstable and at the same time maximally concrete. To see more details and why this is the case, have a look at Clean Architecture book. Not all of the components would position on the main sequence so we calculate the distance to the main sequence using this equation.

    D = ┃A+I-1┃

D also has a value between 0 and 1. The smaller the D-metric for a component is, the closer it gets to the main sequence. When it has the value 0 the component is on the main sequence.

### Calculating D-metric improvement for booking registry component

To calculate the D-metric we need to first calculate A and I metrics. Based on diagram 6 we can do the math. As you can see in this diagram, the booking registry component contains 2 interface and abstract classes which are the query handler interface and the query specification class. Also, it has a total number of 4 classes. Therefore, A-metric is 2/4 = 0.5.

I-metric can also be calculated using the same diagram. Since the Fan-in is 2 because two other components are depending on booking registry, and Fan-out is 0 because it doesn’t depend on any other components. So I-metric is 0/(0+2) = 0. And finally, D metric would be calculated as

D =┃0.5+0 -1┃ = 0.5.

![Diagram 6- To calculate A-metric and I-metric](/images/to-calculate-a-metric-and-i-metric.jpg)*Diagram 6- To calculate A-metric and I-metric*

Let’s also see how much we improved the D-metric. If we calculate the D metric before using the specification pattern, the value would be 0.7¹. So we can see we were able to improve the D metric from 0.7 to 0.5 by applying the specification pattern and using an abstract specification class.

Additionally, we can visualise the D-metrics for the component before and after the refactoring by utilising the A/I graph in diagram 7.

![Diagram 7- visualising the D-metrics for the component before and after the refactoring](/images/visualising-the-d-metrics.jpg)
*Diagram 7- visualising the D-metrics for the component before and after the refactoring*

### Can we go further?

In the last component design, there are still some pain points. In the booking registry, we have some abstract classes and some concrete classes in the same component. The question is, do they change with the same reason and at the same time? the answer is no. The query handler class contains the details of the query we use for fetching booking records. This class knows about the data storage and potentially the framework used here. It also couples with the schema of the data storage. As a result, this class could change because of any of those details. Any changes in the schema, using a new framework or query optimisation might affect this class. However, the interface, specification class and even the booking record data structure would unlikely to change because of the mentioned reasons. Therefore, it doesn’t make a lot of sense to have them in the same component. For further improvement, let’s add a new component to our architecture. We can call that booking registry data gateway. Here, is how the architecture looks like with the new component.

![Diagram 8- Adding booking registry data gateway](/images/adding-booking-registry-data-gateway.jpg)*Diagram 8- Adding booking registry data gateway*

And finally, if we calculate the metrics and point out the two components on A/I graph, it looks like digram 9.

![Diagram 9- Booking registry and booking registry gateway displayed on A/I graph](/images/booking-registery-on-a-i-graph.jpg)*Diagram 9- Booking registry and booking registry gateway displayed on A/I graph*

As displayed in the diagram, the results are promising. We refactored booking registry into two new competes with D metrics 0.3 and 0.

### Conclusion and Discussion

Software quality has always been challenging to measure. However, using the mentioned metrics is a huge help toward that. A mathematical model of software quality would give us the opportunity to build more accurate and useful software tools which can give us hints and guidance toward, in this case, more stable software.

The mathematical model still shows us that there is room for improvement. The D-metric for booking registry is 0.7 and we can still pick more refactoring to reach a better one. This would be achieved by adding a new abstract class for booking record in booking registry component, then moving the booking record implementation into booking registry data gateway. This makes the D-metric for both components equal to 0. However, the booking record is supposed to be a simple data structure. It does not make a lot of sense to have a new abstract class while looks almost identical to its driven concrete class. Moreover, it doesn't seem to have a lot of benefits to our architecture in terms of stability. So, although the model predicts we can still improve our architecture it is up to us to decide when to stop.

I did not address the implementation side of the specification pattern. It depends, to some degree, on the infrastructure and framework the system is using for fetching data. Infrastructure and frameworks could also force you to change the structure of the specification class. However, the main intent of the specification pattern is still the same. There are also other concerns that are involved, including query performance. To see an implementation of this pattern please have a look at this [article]({% link _posts/2020-08-07-simple-and-practical-specification-pattern-with-ef-core-and-C.md %}).

¹-The D-metric actually is 0.66666…
