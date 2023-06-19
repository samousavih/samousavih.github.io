---
layout: post
title:  "Migrations are hard, data pipeline migrations are even harder"
date:   2023-05-23 21:31:54 +1000
categories: data
---

# The story
(Migrations are the hardest actual problem in computer science) [https://www.youtube.com/watch?v=yJOrMDMqeoI] and probably migrating data and data pipelines are the hardest of the hardest.
In this post I am describing the story of one of those migrations. The lessons learned are based on first hand experiences.

# The plot : Eligibility Pipeline
Xero is a global accounting platform for small business. Xero also facilitates their access to capital through integration with lenders. One of the projects to accelerate this integration was Eligibility Pipeline. The pipeline can ingest and process small businesses accounting and financial data, based certain eligibility rules. Then categories those business based on each lenders product.At this stage we knew which business was eligible for any specific lender product. Then we would inform those business that they can apply for capital through multiple channels. In some cases the integration could also happen through Xero's Accounting Software.
The following depicts the eligibility of data pipeline and it's components.

[The Eligibility components]

 - Sources, 
    - Source tables ingested using the data platform, those were invoices, bank statements, organization details, accounts, accounts movements, etc 
 - Transformation stage,
    - A collection of SQL queries running on Xero's legacy data platform and on an EMR cluster using spark sql, these queries transforming source tables into Data points
 - Financial Data Points (DPs)
    - A group of tables each consist of multiple features which then used to infer lender eligibly. Some examples of features were last 12 month of revenue, number of invoices paid or unpaid, specific account movements, etc. Each DP was holding features for one aspect of data, e.g. income and debt, account activity, etc.    
 - Lenders Eligibility Criteria
    - A set of rules applied on features to decide which business is eligible for which lending product. 
 - Quote generations
    - An Api which calculates the amount a business can borrow with a specific lender
 - Eligibility Apis
    - Apis to access eligibility data by integrated lenders
 - Marketing and Cohort generation
    - The process of informing business which are eligible for a product
 - Eligibility Events 
    - Events published using Amazon SNS with eligibility data  
# The migration
As mentioned before transformation stage was running on an EMR cluster. This stage was the costliest part of the whole pipeline. It could cost up to 10K for one time run of those sql queries. However, it wasn't the only reason for migration. Better usability and security where among the reasons.[Find out other reasons?]
The migration also was part of a company wide migration into a new data platform which was built on top of (Snowflake)[https://www.snowflake.com/en/why-snowflake/]. The new platform could utilise (dbt)[https://www.getdbt.com/product/what-is-dbt/] to run sql and specially transformation workloads. The primary language used in dbt is SQL which is super convenient for Analytics and Data engineers. However, for software engineers is a bit if hassle as I had to write a lot of code with SQL which certainly is not the primary language for me. With dbt you could even write your SQL tests in SQL which looked strange. dbt also utilises a template language called (Jinja)[https://jinja.palletsprojects.com/en/3.1.x/] which is so primitive that writing code in that language feels like early versions of static web if you know what I mean, but to Data engineers feel very sexy as they can uplift SQL using that and they are very happy about it.  
 [idea: what where other migrations across Xero, how did they go? what were their lessons?]

# The testing strategy
One of the first activities we undertook was devising a test plan. The most important aspect we had in mind was to make sure the new process works exactly the same way as the old one. Therefore, we landed on the following:

- Data tests/source tests
    - To make sure the source data/tables in the new platform are behaving in the same way as the old one and this included
      - Schema tests, column names, column precisions in the case of decimal numbers,etc.
      - freshness 
      - minimum number of rows in source tables
      - Unique current records :  some of the sources contained record history to show how a specific record changed over time but they must have only one current record.
      - Duplications
- Parallel end to end test
   - The plan was to do a broad end to end test which was to run the new process on the same set of sources as the old pipeline and then compare the results. This way we could test if new pipeline behaves the same way as the old one.[Diagram here]
- End to end testing
   - Run the whole pipeline including the parts which were out of scope for migration to make sure it all works.

# Challenging data sources
Before continuing to describe our testing journey, I should mention that landing data sources into the new data platform was a work in progress. Some of those data sources were relatively larger (several terra bytes) than the others and getting them into the platform was a challenge. Also, the Eligibility pipeline happen to depend on those data sources. The trick to unblock the migration was to bring a static snapshot of each data source into the new platform so we can use them as source. This strategy helped but over time cause the testing progress to hit a roadblock. 

# Date partition
The old data platform used to ingest the data from sources on a schedule. It would create snapshots of the sources multiple times during a month. Those snapshots were essentially partitioned based on the date they were ingested. Each snapshot was stored in a separate S3 key and each row did have an extra column called Date_Partition. 


# Attempt 1: Lets lock in the new sources and run the both pipelines and compare
The first parallel test attempt was based on date partitions. The idea was the we can pick the same recent date partition for each source table and run can compare the output of old and new pipeline. It turned out that the data sources in the new platform were updated using a different strategy. The data sources were updated on the fly. The data platform would bring any updates as it happened. Therefore, there was no need for data partitioning. The new platform was being updated more frequently. This discrepancy made it impossible to accurately test and compare the two systems because locking in the same input for the pipeline was difficult. Moreover, the new platform also gradually made some improvements on data quality e.g. removed some of the duplications in the old data platform and again this made the like for like comparison between the two pipelines more difficult. 
[needs a digram]
<!-- - Daily updates in new platform
- Expensive to query EMR ( How much?)
- Not convenient, remote desktop
- data wouldn't be the same 
- Some duplications, data quality issues fixed  -->

# Attempt 2: Lets bring a snapshot of old sources to Snowflake so we can run the new pipeline on both and compare
To make sure we can run the new pipeline on the same data, we decided to bring one of date partitions into the new platform and run the new pipeline on that. Also to make sure we don't have to copy huge amount of data we took a workaround. We created (external tables)[https://docs.snowflake.com/en/user-guide/tables-external-intro] on Snowflake which under the hood were connecting to the same S3 key and buckets which the partitioned data were stored. The external tables were up to 10 times slower. It made it almost impractical to run adhoc queries let alone running the whole pipeline. It was suggest that creating materialised views from those external tables would improve the performance. However, we didn't explore that path. The clock was ticking and we were getting close to the date when old platform was due to be decommissioned.
# Attempt 3: Let's dump on the Domain person to test it for us
- Compare histories and look for variances
- What was different in schemas?
- Look for a few specific orgs
- Is the method of comparing histories common? How others do that?

# Source tests:
 - They were slow
 - They were costly to run
 - we initially ran them as we developed later separated them

# Data point tests
 - Precision tests 

# Code testing
- Link to other article
- Most of the code was the same but there were differences 
    - New platform, new tech stack
    - Code changes due to handing dates which could be very important in this type of systems 
    - Schema difference, The changes were gradual 
- Issues with running the pipeline on your local? with sources could take to hours
- Makes development quicker
# Underestimation and human bias
- What we estimated
- Why humans underestimate when everything need to go right and over estimate when one thing need to go wrong 
- Explain what that means in this context and what needed to go right
    - Data should be migrated for testing
    - Data should have been comparable
    - Can identify the discrepancies
    - Can fix it
    - The source schema shouldn't change
    - The person who had the domain knowledge wouldn't leave
    - And many other things that needed to go right but we didn't even think of
- Show initial Estimate vs actual estimate
- Show the migration part vs test part
# Risk register
- what could go wrong
# Comms
- Weekly meetings with platform team/teams
- Shared slack channels
# Keeping the Scope minimal, lift and shift
- No automations
- minimal tech stacks
- No CI/CD
- Ignore multiple env
  - made things sometimes more complicated
- made us underestimate testing
- 

# Documentation
- Plans, Audits, ongoing issues, investigation results, technical guides, platform docs, meeting notes, Decision Registers, training docs, solution designs 

# Some values can overflow, how to use float instead of numbers?
- How float and numeric types are different? 

# The bigger Warehouse doesn't mean more expensive  
- [you need to pick a size before running] [https://docs.snowflake.com/en/user-guide/warehouses-considerations]
- Warehouse sizes and costs
- How to know if your workload would benefit from larger Warehouse?
- Autoscale Warehouse
    - How this can be done in dbt
- Monitor queries in snowflake and if there disk spilling, attention needed, and sometimes Warehouse sizing is a solution [https://community.snowflake.com/s/article/Performance-impact-from-local-and-remote-disk-spilling]

# Confusion on history and why everyone where looking for a reason (When things make sense it is not necessary true)
- Did the new code's behavior changed by change of data schema?(this is ridiculous)
- Would code testing helped?
- Did we need a more traceable pipeline?

# The whole project was put on hold and now we never know
- was handed over to another team
- The team was disbanded and the projects axed

# Migrations
- show a diagram of rate of changes in the platform and when we migrated, question for data platform eng. do you do that again?
- It would be impractical to migrate too late since huge costs, 
- show the sweet spot between cost of running legacy systems vs cost of migrating into the new system
- Early learning and feedback, this won't be achieved if migration happens when we think everything is ready
- But painful for end users
- Ask someone in management how did they decide when to allow for others joining the new platform?
# Conclusion
- Start early
- Write tests
    - Write small tests rather than broad ones
    - Engage domain experts early to come with test scenarios
    - Write code tests, broad data tests are never a replacement
- Make sure the key knowledge is shared across the team
- think about observability upfront
- Documentation


