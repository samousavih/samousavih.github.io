---
layout: post
title:  "Data pipeline migrations are even harder : The story of a data pipeline migration with focus on testing" 
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
One of the first activities we undertook was devising a test plan. The most important aspect we had in mind was to make sure the new process works exactly the same way as the legacy one. Therefore, we landed on the following:

- Data tests/source tests
    - To make sure the source data/tables in the new platform are behaving in the same way as the legacy one and this included
      - Schema tests, column names, column precisions in the case of decimal numbers,etc.
      - freshness 
      - minimum number of rows in source tables
      - Unique current records :  some of the sources contained record history to show how a specific record changed over time but they must have only one current record.
      - Duplications
- Parallel end to end test
   - The plan was to do a broad end to end test which was to run the new process on the same set of sources as the legacy pipeline and then compare the results. This way we could test if new pipeline behaves the same way as the legacy one.[Diagram here]
- End to end testing
   - Run the whole pipeline including the parts which were out of scope for migration to make sure it all works.

# Challenging data sources
Before continuing to describe our testing journey, I should mention that landing data sources into the new data platform was a work in progress. Some of those data sources were relatively larger (several terra bytes) than the others and getting them into the platform was a challenge. Also, the Eligibility pipeline happen to depend on those data sources. The trick to unblock the migration was to bring a static snapshot of each data source into the new platform so we can use them as source. This strategy helped but over time cause the testing progress to hit a roadblock. 

# Date partition
The legacy data platform used to ingest the data from sources on a schedule. It would create snapshots of the sources multiple times during a month. Those snapshots were essentially partitioned based on the date they were ingested. Each snapshot was stored in a separate S3 key and each row did have an extra column called Date_Partition. 


# Attempt 1: Lets lock in the new sources and run the both pipelines and compare
The first parallel test attempt was based on date partitions. The idea was the we can pick the same recent date partition for each source table and run can compare the output of legacy and new pipeline. It turned out that the data sources in the new platform were updated using a different strategy. The data sources were updated on the fly. The data platform would bring any updates as it happened. Therefore, there was no need for data partitioning. The new platform was being updated more frequently. This discrepancy made it impossible to accurately test and compare the two systems because locking in the same input for the pipeline was difficult. Moreover, the new platform also gradually made some improvements on data quality e.g. removed some of the duplications in the legacy data platform and again this made the like for like comparison between the two pipelines more difficult. 
[needs a digram]
<!-- - Daily updates in new platform
- Expensive to query EMR ( How much?)
- Not convenient, remote desktop
- data wouldn't be the same 
- Some duplications, data quality issues fixed  -->

# Attempt 2: Lets bring a snapshot of legacy sources to Snowflake so we can run the new pipeline on both and compare
To make sure we can run the new pipeline on the same data, we decided to bring one of date partitions into the new platform and run the new pipeline on that. Also to make sure we don't have to copy huge amount of data we took a workaround. We created (external tables)[https://docs.snowflake.com/en/user-guide/tables-external-intro] on Snowflake which under the hood were connecting to the same S3 key and buckets which the partitioned data were stored. The external tables were up to 10 times slower. It made it almost impractical to run adhoc queries let alone running the whole pipeline. It was suggest that creating materialised views from those external tables would improve the performance. However, we didn't explore that path. The clock was ticking and we were getting close to the date when legacy platform was due to be decommissioned.
# Attempt 3: Comparing consequent results for different run dates(Variance testing)
At this point we were at a panic state. We have moved on from setting up a like for like test. An alternative option was to compare consequent results for different run dates. The target was whether since the migration happened is there any big drop or jump in the number of eligible businesses for each product.Another way said, we were looking for any unjustified variances in the result since the migration happened. We knew the total number of businesses are increasing over time, so a gradual increase in number of eligible businesses was expected. However, the results surprised us. 
We have repeated these tests in different stages, this was due to evolving data sources. In the initial step all of the data sources were similar to legacy data sources and they were sourced for the legacy data plat for and as time passed more and more data sources where ingested from the transactional DB itself and through streaming (Fivetran). As we repeated the tests the new results using the new data sources were more and more different than the previous ones. In some cases these difference were close to 120% more eligible businesses for a specific lender while the total number of baseline businesses only changed 7%.
We speculated although couldn't be sure the the following were contributing to the unexpected results:

 1. Not all of the sources were from the same origin 
 2. Due to data size, the record history older than 1 year ago wasn't migrated to the new platform
 3. Data sources in the new platform were updated daily while in the legacy platform less frequently e.g. weekly or biweekly

 <!-- - The record history wasn't the same in the legacy platform
- We were comparing legacy vs new to gain our confidence but data team were comparing the new platform with the transactional DB
- very difficult to find out why just by looking at the variances
- What was different in schemas?
- Look for a few specific orgs
- Is the method of comparing histories common? How others do that? -->

# Lack of domain knowledge and impact on testing
Many steps of the legacy pipeline including transformation stage was developed and maintained for a while by only one person. Those steps contained complex SQL and python code which happened to be the key part of the pipeline and at the core of migration.

We also knew that the time is short, so the strategy for migration was to keep the changes to the pipeline at the absolute minimum and do what we have to do so we remove the dependency on the legacy data platform.

With that mindset we postponed many possible improvements to the future. But understanding of how those pipeline steps work was postponed too. Therefore, most of us wouldn't be able to reason about the system. This limited the ability to test the system when first and second attempt failed to only one person in the team. This would increase the pressure on one person specially at time close to the deadline and when the stakes were high.

# Source tests
As discussed before, testing sources were a priority for us. These tests were written using dbt and dbt-expectation framework. In addition to basic tests including null checks, column checks,etc., we have written some more complex tests which were testing current rows are unique. These tests were slow and costly. Initially we underestimated the costs and were running them as we developed the data pipeline on the local dev machine. This exacerbated the costs, later one we decided to run the source tests just when needed for example when we run the data pipeline in production environment. But still they were slow, so to mitigate this we decided to limit the date range. This decreased their efficiency. In one case we discovered duplicated results which was due to duplicated rows in source tables but because the anomaly was out of date range our tests didn't detect that. Also, because those tests needed to be started manually they were often ignored. 

Despite all of the challenges with source tests, they had some benefits. They helped us identify changes in source tables as they were evolving. By just running all of the source tests we were able to highlight what was different between legacy sources and new sources while some of the discrepancies were not documented necessarily well.

# Testing Grid
We are all familiar with the famous (test pyramid)[https://martinfowler.com/articles/practical-test-pyramid.html] which gives us an idea of how we should focus our effort when it comes to testing software. When it comes to data intensive applications the similar idea is described using a (Test Grid)[https://www.thoughtworks.com/en-au/insights/blog/testing/practical-data-test-grid]. The data test grid depicts testing effort across two axises, code and data.
Despite you can still think about testing data on it's own e.g. source data quality tests, often you are facing a mixture of data and code. Depending how broad the code scope is from a single sql query to the whole data pipeline or how specific is the data involved in test you can categorise your tests. For example a point unit test only tests a small part of the data pipeline and for just enough data and columns which covers a specific scenario and a global E2E tests would include the whole pipeline with maximum size of data most likely in an environment similar to production.

Also, to map the test varieties for the Eligibility pipeline on Testing Grid. We can draw the diagram below[digram]. As you can see the test effort was not focussed proportionally.

# Reasons that we focused on global E2E tests 
- Lack of domain knowledge
   - why? how?
   - Could ask the domain person to help us write test scenarios, shift left tests
- Lack of knowledge and experience with the new tech stack
- It is quicker with global E2E tests 
   - What is code testing and how would that help?
   - We could test correctness of the pipeline without the impact of data source changes and pollutions, using CSVs
   - Makes development quicker, TDD, and less costly as we don't have to run the pipeline on local against a big data source
- Underestimating the code changes or most of the code was the same but there were differences 
    - The code gradually changed 
    - New platform, new tech stack
    - Code changes due to handing dates which could be very important in this type of systems 
    - Schema difference, The changes were gradual 
- Underestimating the time spent on running the pipeline on local? with fulls sources
- Underestimating the costs of running the pipeline on local? with fulls sources

# How we could have written tests
- How to write point unit tests? 
- How to write service sample tests 
- Examples of each
- Show diagram for each tests type and explain

# Sample/Global E2E tests using Zero clone copy

# But many point unit tests are a lot of effort
- Exercise is a lot of effort,
- Eating well is not easy, etc
- Over estimate how your body can continue work

# How others done it?

- What was missing? Code testing? Lets dig into that?
- Repos to study
   - https://github.dev.xero.com/Xero/XeroGoRevenueTransforms
      - uses sample/point unit tests using dbt_unit_testing
   - https://github.dev.xero.com/Xero/xade_dbt_pia
      - sample service tests by seeds and some sample/point test using dbt_unit_testing
   - https://github.dev.xero.com/4Xero/EIS.Standards/ 
      - point unit tests using dbt_unit_testing
      - global service tests using dbt singular tests
      - Zero clone copy
   - https://github.dev.xero.com/sbi/xsbi-pipeline-xade
      - global tests
      - they have multiple pipeline stages which each has a set of source tests:how this works? [Talk to someone]
   - https://github.dev.xero.com/Xero/dt-cups-data-pipeline
      - sample E2E using seeds/Csvs 
   - Payments?
   - Others across Xero?
# Challenges of data pipeline testing
- They need DB which is sometimes remote
- point unit test is different than software unit tests 

# Conclusion
- Start early
- Write tests
    - Write small tests rather than broad ones
    - Engage domain experts early to come with test scenarios
    - Write code tests, broad data tests are never a replacement
- Make sure the key knowledge is shared across the team
- think about observability upfront
- Documentation

