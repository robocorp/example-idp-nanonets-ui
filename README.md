# Intelligent document processing (IDP) with Nanonets

This robot demonstrates the usage of [Nanonets](https://nanonets.com) library `RPA.DocumentAI.Nanonets` for extracting data from (English) invoices and sending manual review request to ones where the AI-based extraction is not successfull. As a result, you can confidently automate the purchase to pay processes with any inputs.

## What you'll learn with this reference architecture

- Using `RPA.DocumentAI.Nanonets` for extracting structured data from invoices, and working with the result set
- Using Nanonets API to get a human verification UI link, which also links back to Robocorp process
- Working with Work Data Management with Producer/Consumer robot template
- Triggering robots with emails
- Using `RPA.Notifier` to send Slack messages

The reference architecture splits tasks to separate steps allowing the hyperscaling of the automation operations. However, the example simplifies the tasks of the document extraction and simply sends key details of the invoice to Slack. This you would replace with your own business logic.

![nanonets-ref-architecture](https://user-images.githubusercontent.com/40179958/202437062-dbefa613-d90f-47c9-b765-cacbe052bdc6.png)

## How does it work

- The example is divided in to three robot files, consisting of three tasks:
  - **Producer** parses email attachements and sends the extraction request to Nanonets. The first task produces a work item for each supported attachment that has the JSON response from Nanonets as the payload.
  - **Consumer** processes each work item, and for the demonstration purposes sends the information of the invoice (seller and amount) to Slack, if the confidence threshold was met for all fields. If any field is below the set threshold, the automation generates a link to human verification UI using Nanonets API, and sends it in Slack.
  - **Verified Checker** is a separate robot/process that is triggered after the human verification has been completed, and sends the seller name and invoice amount to Slack based on the verified data.
- There are size limitations of the work item payload size (100 000 bytes), the implementation will not handle the over the max size situations.
- The implementation demonstrates parallel processing capabilities of Robocorp platform, as each output work item from the producer is realeased for the processing by Consumer immediately when ready, and there can be multiple parallel executions of Consumer robots.

## Prerequisites

- Nanonets account [Nanonets](https://nanonets.com), and an invoice model created in their service.
- Create a Vault in [Control Room](https://cloud.robocorp.com) called `Nanonets` that has three secrets called `model`, `api-key` and `username`.
- Create a [Slack webhook](https://slack.com/help/articles/115005265063-Incoming-webhooks-for-Slack) that allows posting to your workspace.
- Create a Vault in [Control Room](https://cloud.robocorp.com) called `Slack` that has two secrets: `webhook` that contains the webhook URL that you got from Slack, and `channel` which is the channel where the messages are posted.

<img width="649" alt="Screenshot 2022-11-17 at 13 49 31" src="https://user-images.githubusercontent.com/40179958/202438776-59fd9aba-e2a2-450d-8a03-8365fa606dea.png">

## Running the robot

While it's possible to run the robot in your development environment with the provided example data, it's meant to be used with email as a trigger. Once you have uploaded the robot code to the Control Room, configure a new process with two steps (Producer and Consumer) following the example of the picture. Notice that you might have given a different name for the robot when uploading it to the Control Room.

<img width="555" alt="Screenshot 2022-11-17 at 13 51 08" src="https://user-images.githubusercontent.com/40179958/202439126-d541b6cb-6541-4f44-962e-b210d8032801.png">

Then add new email trigger under Schedules & Triggers tab, and make sure to have both Parse email and Trigger process checkboxes selected. You should have things set up like in the screenshot below.

# TODO BELOW THIS

![image](https://user-images.githubusercontent.com/40179958/184806318-f0ad25de-932d-47bc-9022-8fd68e18c0e2.png)

Now, running the process is easy. Just send an email with some attachemts to the email address shown in the Control Room, and wait for the results. Easiest way to view the full response of Base64.ai API is to look for Work Data for each run of the Consumer task through Control Room. See the details in the screenshot below.

![image](https://user-images.githubusercontent.com/40179958/184807403-4b5dc10c-4a67-40d6-a312-f74516d7803e.png)

## Recommended further reading

- The [Producer-consumer](https://en.wikipedia.org/wiki/Producer%E2%80%93consumer_problem) model is not limited to two steps.
- [Using work items](https://robocorp.com/docs/development-guide/control-room/work-items)
- [Work item exception handling](https://robocorp.com/docs/development-guide/control-room/work-items#work-item-exception-handling)
