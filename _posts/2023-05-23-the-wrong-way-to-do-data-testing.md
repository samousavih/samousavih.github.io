---
layout: post
title:  "Migrations are hard, data pipeline migrations are even harder"
date:   2023-05-23 21:31:54 +1000
categories: data
---

# The story

a pipeline for Eligibility, how it works the Architecture, Apis, Scale, Pipeline stages
and the migration, from AWS EMR,Redshift to Snowflake, dbt, SQL
(The irony of dbt)
 - Why did we want to migrate?
 - EMR costs
 - A data platform migration happened org wide
 - idea: what where other migrations across Xero, how did they go? what were their lessons?
# The testing strategy

- Data tests/source tests
- Parallel end to end test
- End to end testing

# Under estimation and human bias
- What we estimated
- Why humans underestimate when everything need to go right and over estimate when one thing need to wrong 
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

# Attempt 1: Lets lock in the new sources and run the both pipelines and compare
- Date partition issue
- Daily updates in new platform
- Expensive to query EMR ( How much?)
- Not convenient, remote desktop
- data wouldn't be the same 
- Some duplications, data quality issues fixed 

# Attempt 2: Lets bring a snapshot of old sources to Snowflake so we can run the new pipeline on both and compare
- Huge tables (how big?)
- Data was stored on S3 but external tables in snow flake and they were slow, how slow? why it was slow?
- even getting a subset of data was time consuming let alone the whole pipeline
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

# migrating at the same time as data platform itself is evolving 
- show a diagram of rate of changes in the platform and when we migrated, question for data platform eng. do you do that again?
- It would be impractical to migrate too late since huge costs, 
- show the sweet spot between cost of running legacy systems vs cost of migrating into the new system
- Early learning and feedback, this won't be achieved if migration happens when we think everything is ready
- But painful for end users
- Ask someone in management how did they decide when to allow for others joining the new platform?

# Some values can overflow, how to use float instead of numbers?
- How float and numeric types are different? 

# The bigger Warehouse doesn't mean more expensive  
- [you need to pick a size before running] [https://docs.snowflake.com/en/user-guide/warehouses-considerations]
- Warehouse sizes and costs
- How to know if your workload would benefit from larger Warehouse?
- Autoscale Warehouse
    - How this can be done in dbt
- Monitor quereis in snowflake and if there disk spilling, attention needed, and sometimes Warehouse sizing is a solution [https://community.snowflake.com/s/article/Performance-impact-from-local-and-remote-disk-spilling]

# Confusion on history and why everyone where looking for a reason (When things make sense it is not necessary true)
- Did the new code's behavior changed by change of data schema?(this is ridiculous)
- Would code testing helped?
- Did we need a more traceable pipeline?

# The whole project was put on hold and now we never know
- was handed over to another team
- The team was disbanded and the projects axed

