---
layout: post
title:  "testing data pipelines"
date:   2023-05-23 21:31:54 +1000
categories: data
---

### Background and intention

### Scope
make it practical and based on Xero/Nab 

testing inside a data product
testing for bigger scope considering multiple data products

### data-testing layers

1)Point data test
2)Sample data tests
    -Synthetic data? How to generate? Chatgpt 
3)Global data tests
    Expensive, Slow, Example of Eligibility End Dates
    Source testing

## Pipeline code testing
  Testing SQL how?
   # dbt:
   # using CSV seeds
   - maintenance issues
   # using Zero clone
   # using dbt unit testing
   - issue with tables with many columns
   # source testing
   - expensive
   - how to separate them
   - if it was automated do you run them every time?



  Testing Python Pipeline?

Python Pipelines

dbt Pipelines

Xero 

Nab

Snowflake

DataBricks


### Shifting tests left

devising specific testing strategies
Confluence
examples in Xero

#### Manual testing

dependency on key people

#### TDD for data pipelines


### Refs
https://www.thoughtworks.com/en-au/insights/blog/testing/practical-data-test-grid
https://www.thoughtworks.com/en-au/insights/blog/data-science-and-analytics/synthetic-data
https://www.thoughtworks.com/en-au/insights/blog/testing/get-back-to-basics-with-testing-data-pipelines-two-orthogonal-planes    
