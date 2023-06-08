---
layout: post
title:  "The wrong way to test your data pipeline:lessons from the trenches"
date:   2023-05-23 21:31:54 +1000
categories: data
---

# The story

a pipeline for Eligibility, how it works the Architecture, Apis, Scale, Pipeline stages
and the migration, from AWS EMR,Redshift to Snowflake, dbt, SQL
(The irony of dbt)
# The testing strategy

- Data tests/source tests
- Parallel end to end test
- End to end testing
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

# Attempt 2: Lets bring a snapshot of old sources to Snowflake so we can run the new pipeline on both and compare
# Attempt 3: Let's dump on the Domain person to test it for us
- Compare histories and look for variances
- What was different in schemas?

# Source tests:
 - They were slow
 - They were costly to run
 - we initially ran them as we developed later separated them

# Data point tests
 - Precision tests 

# Some values can overflow, how to use float instead of numbers?

# The bigger cluster doesn't mean more expensive  

# Confusion on history and why everyone where looking for a reason (When things make sense it is not necessary true)

- Did the new code's behavior changed by change of data schema?(this is ridiculous)
- Would code testing helped?

# The whole project was put on hold and now we never know

# Traceability in data pipelines/ why /how to reason about the output/debugging? Logs