---
layout: post
title:  "Common Closure Principle: The story of an evolving architecture"
date:   2022-06-24 21:31:54 +1000
categories: oop
---

Photo by Nick Bolton on Unsplash

## Abstract

This article demonstrates how following Common Closure Principle when designing software components speeds up adding new features. It also shows it can decrease the effort and cost to maintain stability throughout the software lifecycle. This is achieved by analysing the impact of two sample feature scenarios in existing architecture.

## What is CCP

CCP is described in detail in the [Clean Architecture](https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164) book. It works at the component level. It states classes which are close¹ to the same type of change should be put in the same component. In other words, classes which change because of the same reason and at the same time belong to the same component. Vice versa, classes which change because of different reasons and at different times should be in different components. By following this principle each time we need to change our software the minimum number of components will be affected. Because we already put the classes changed together in the same component. The fewer components we change the fewer deployment required, less version control, less testing and therefore less risk of unexpected behaviour and shorter delivery cycle*.* Moreover, this principle also minimises the effort to understand and find all of the pieces which need to be extended or modified. This is because related parts are as close as possible in the source repository.

## The story

The use case here is a hotel booking management system². For this article, we are focusing on just a few components. The first component here creates a booking and called Booking Creation component. It calculates fees, does some validations and checks for room availability. After you book a room you might want to amend it. You might want to change the room and switch to a smaller or bigger one or alter the people you booked the room for. Therefore, we also need a component to manage the amendments in a booking which is called Booking Amendment component. Similar to Booking Creation, it also checks for availability and does validations. There is no fee for changing a booking, so it does not need fee calculations.

On the other hand, we need to generate two sets of documents³. The first set would be generated at the time of initial booking which shows the room details, people you booked the room for and finally the details of fees and payments. The second set of documents Let’s call them amendment documents would show what has been changed in the booking. They will be stored in blob storage after generation and users can print or download them for future references. As you might already have guessed we are going to need another component in our booking system to generate these docs. We call it Booking Documents component. This component would know which type of documents required each time a booking creation or booking amendment happens and what is the content of each.

Finally, each time we want to apply a change we would need to know what are the details of the current booking. The last component we need here is called Booking Registry which stores details of each booking after creation as well as an amendment. Other components can retrieve the latest state of each booking through the booking registry component. These records would be stored by this component each time a booking is created or each time a booking is changed. All of the mentioned components are displayed in diagram 1.

Each component also consists of a set of classes which are displayed in the mentioned diagram as well. Inside booking creation, we have a class to calculate fees and costs for a booking. Also, a class which validates a booking, for example, it makes sure the number of people doesn’t exceed the capacity of rooms. Booking amendment also has a validation class which has its own logic. Consequently, the booking documents component includes classes which calculate which documents and with what content is required for both booking creation and amendment. Moreover, it also has another class to convert documents to pdf and another one to store them in blob storage. Similarly, booking registry also has classes for calculating registry records required for booking creation and booking amendment. It also has a class which helps with the retrieval of those records; this class does not depend on the type of operations and just returns whatever records are available with a given id.

![diagram 1](https://cdn-images-1.medium.com/max/2000/1*9Yw3GMsUC4a96uNB1BIWzw.jpeg)*diagram 1*

After showing which components we are dealing with let’s have a look at interactions among them. The interactions are easy to understand as displayed in the next diagram (diagram 2). Booking creation and booking amendment components initiate the call to the other two components to create documents and store the required records. As a part of the call they send the details of a new booking or in the case of amendment details of an amendment. The callee components would have the rules and logic to create documents or save the records with required values.

![diagram 2](https://cdn-images-1.medium.com/max/2000/1*bosKSaLRr5c3-a4d8wtHRw.jpeg)*diagram 2*

## Feature scenarios

The main challenge in every architecture is unpredictable changes. This section would display how explained architecture can respond to change. We will examine our architecture through two different requirement changes asked to be implemented in the system.

## Fee for booking amendments

The first new requirement is considering a fee each time a booking amendment happens. To apply this into our software we need to change a few components. Firstly, the booking amendment needs to have the logic which calculates the total fee based on the details of each amendment. Secondly, the booking amendment documents must reflect the incurred fee. And lastly, the booking registry now needs to store the calculated fee in its records. These changes have to be applied to all three components. We need to test, redeploy and version all three components. The next diagram (diagram 3) displays the changing classes in a different colour.

![diagram 3](https://cdn-images-1.medium.com/max/2000/1*zJ1OYtfw634X0izu-1B2Bw.jpeg)*diagram 3*

## Promotion code for a booking

The second change is a promotion code for booking. Different promotion codes can be used by users, and each would have a different discount for creation of a booking. Therefore, we will have to change the booking creation component to calculate the discounted fee if there is a promotion code. Also, we will need to modify the code for generating booking documents to show the discount when we are creating a booking. And also, we have to change the code for booking registry components to store the promotion code whenever the operation is booking creation and includes a promotion code. These changes also are displayed in the following diagram (diagram 4).

![diagram 4](https://cdn-images-1.medium.com/max/2000/1*6DjhWYO9PG9qgbKg9oBnEQ.jpeg)*diagram 4*

## CCP violation

As you can see, in the first scenario we had to apply a change to the booking documents component because of a change in booking amendment process, but also as mentioned in the second feature we had to alter that component because of a change in the company creation process. So far the booking documents component had these two reasons to be changed and these two are coming from two completely separate parts of the system and they could happen at totally different times in the project lifecycle. That violates CCP. The same argument can be made for the booking registry component. Finally, not following CCP in this architecture makes applying those two new requirements harder than should be as we have to change more components. And that is costly.

## Applying CCP

Let’s see how we can minimise the effect of change by applying CCP. Minimising the effect of change in this context means minimising the number of components needed to change. To apply CCP let’s move the classes which change at the same time and with the same reason to the same component. To achieve that, for the first requirement we should move the booking amendment document and booking amendment record classes into the booking amendment component. This would alter interfaces between the two components which I won’t go into the details as that is a topic for another article. The new architecture is displayed in diagram 5 after mentioned refactoring. Now, all we need to change is just one component which is the booking amendment.

![diagram 5](https://cdn-images-1.medium.com/max/2000/1*pbgh_p69cNZ35-yps8PNfA.jpeg)*diagram 5*

For the second requirement, you can easily guess what we need to do. Here is the final diagram.

![diagram 6](https://cdn-images-1.medium.com/max/2000/1*q1bGmvFb7pC64wWQ3MArFQ.jpeg)*diagram 6*

The architecture in diagram 6 would keep the changes needed after applying the two requirements minimised as we just need to modify one component in each. Moreover, it would be easier to understand the code as every business rule and logic related to creating a booking resides inside the booking creation component and respectively the same for the booking amendment component.

## Conclusion and discussion

It is important to understand that one of the main goals of every architecture is to minimise the effort needed to maintain software. In this context, maintaining software means coping with changes over time. So, the architecture of your system highly depends on the type of changes you will have in your system. In the booking system mentioned above, if changes were different we might end up with a different arrangement of classes in components.

It is also almost impossible to predict what changes may come, so an adapting and evolving architecture is the best way we can imagine to minimise the effort and costs of software. Refactoring and especially [preparatory refactoring](https://martinfowler.com/articles/preparatory-refactoring-example.html)* *is the key to an evolving architecture*.*

¹*The meaning of closure in Common Closure Principle*

²*The software system I experienced was different and had a completely different purpose. I made up a booking system because we are all familiar with its logic. However, the complexity is the same and the same principles would apply for both*.

³*These documents are like reports which are pre-generated in pdf format and stored in blob storage.*
