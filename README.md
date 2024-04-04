# Routemaster

Routemaster is a simple bus prediction model built in R & Azure designed to detect the presence of London Buses within TFL’s JamCams API feed. It utilises serverless Azure custom handler functions to run R code on a schedule, an Azure custom vision object detection model and R Shiny for the frontend. You can view Routemaster [here](https://routemastershinyapp.azurewebsites.net/).

In short, the creation of Routemaster can be broken down into four core steps: scheduling the capture and storage of images from TFL’s API; training an object detection model; scheduling the submission of images for prediction and storing results; using the prediction results in a frontend application.

The following is a walkthrough on why and how I made Routemaster, as well as final thoughts on issues faced during its’ development and things I’d like to do differently. Each of the core steps is described, although some aspects like creating an Azure account, a resource group or storage account is skipped as Microsoft has numerous tutorials on these aspects.

### Why did I make Routemaster

Recently I started Microsoft’s learning pathway towards the [Azure AI Engineer Associate](https://learn.microsoft.com/en-us/credentials/certifications/azure-ai-engineer/) certificate, and within this I learnt more about Azure’s computer vision solutions as well as discovering a demo of its’ capabilities. Having never used Azure’s custom functions or Azure’s custom vision models, I wanted to create a small end-to-end project following a similar approach using my preferred language – R.

My only other self-imposed requirement was that I wanted to use real world data that was regularly updated or on a feed. Having previously used TFL’s APIs whilst at Parliament, I knew that they had free public endpoints which included their [JamCam API](https://api.tfl.gov.uk/Place/Type/JamCam). This API essentially exposes 10-second camera feeds and stills from 900+ traffic monitoring cameras from all over London with each camera updating roughly every five minute. A sample of the API is shown below.

