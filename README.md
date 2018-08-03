# Insight-DevOps-2018-Project
  This is the repo for my DevOps 2018 Insight Project

# CAPACITY PLANNING
  
## Introduction
   Nowadays, many businesses are adopting cloud based solutions to serve their clients. For these businesses, utilizing
   just the right amount of resources and maintaining their platforms in order to continuously serving their clients 
   is important to stay in business. 
   There are two main approaches to provision resources for such services:- 
   1) reactive capacity planning and 
   2) predictive and proactive capacity planning
   
   In the reactive approach, the system is already under stress from overload when the autoscalers attempt to provision new 
   resources and provisioning takes time and may be slow to meet current demands. 
   
   In a proactive approach, capacity requirements are estimated and provisioned before resources are depleted. So the system
   gets to immediate convergence when under stress and users are served by a system that seems to have infinite capacity. 
   
## Solution Strategy
   
   MONITOR --- ANALYZE --- PLAN --- EXECUTE
   
   Monitor the system to identify recurring patterns in the data and analyze current demand variations.
   Deploy resources to meet capacity requirements.
   Metrics of interest are (latency and capacity)
   
   TOOLS
   1) Terraform (IaC)
   2) Chef
   3) Jenkins (CI/CD) as a stretch goal
   4) Burrow (Monitoring)
   
   Terraform will provision EC2 servers, docker will create containers with the pre-install packages and kubernetes will 
   deploy the necessary docker containers. No need for a configuration management tool. 
   
   ### Benefits of using Terraform. 
    1) Opensource/portability
    2) Immutable states
    3) declarative lanaguage 
    4) client-only architecture and thus much better in security
   ### Benefits of using Chef
    1) Flexible
    2) Mature language
   ### Benefits of using Burrow
    1) Continously calculating lag over a sliding window
    2) Monitors multiple kafka clusters
    
# Pipeline
https://raw.githubusercontent.com/karthikvegi/world-monitor/master/images/pipeline.png
   
 # Stretch Goal
   Jenkins to provide continuous integration of code and continuous deployment of the code
   
   
   
   
   
   
