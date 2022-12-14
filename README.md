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

### Part 1: extracting data from incoming invoices

While it's possible to run the robot in your development environment with the provided example data, it's meant to be used with email as a trigger. Once you have uploaded the robot code to the Control Room, configure a new process with two steps (Producer and Consumer) following the example of the picture. Notice that you might have given a different name for the robot when uploading it to the Control Room.

<img width="555" alt="Screenshot 2022-11-17 at 13 51 08" src="https://user-images.githubusercontent.com/40179958/202439126-d541b6cb-6541-4f44-962e-b210d8032801.png">

Then add new email trigger under Schedules & Triggers tab, and make sure to have both Parse email and Trigger process checkboxes selected. You should have things set up like in the screenshot below.

<img width="570" alt="Screenshot_18_11_2022__8_24" src="https://user-images.githubusercontent.com/40179958/202635476-5fd7489f-73c9-4584-ab53-2a07b2331884.png">

### Part 2: Processing callbacks from Nanonets manual verification UI

Next, set up another process that will be responsible for receiving the callbacks from the Nanonets manual verification UI. Follow the screen graps to get going.

Add a process with a single step, which is the PostVerify from the sample code.

![image](https://user-images.githubusercontent.com/40179958/202699118-102cab18-d632-4c23-bd26-0fb5f26cda25.png)

Under API, add a new API key and give it any name. It needs to have at minimum the Trigger Process Run enabled. Remember to copy your key to the clipboard after creating it.

![image](https://user-images.githubusercontent.com/40179958/202699306-f9c09194-9b6a-4c44-a09e-a8ba15f96142.png)

Add a Vault entry called `Robocorp` and one key called `apikey`. Past the key from your clipboard in the value field.

![image](https://user-images.githubusercontent.com/40179958/202699700-8ffcfb2e-8b69-41c9-8b9c-07a2f3ce7742.png)

--

Now, running the process is easy. Just send an email with some invoices as attachmets to the email address shown in the Control Room, and wait for the results in your chosen Slack channel! The example is set up with extremely low threshold, so by default practically everything will require a manual review. Once the Slack message arrives for review, open the UI and once the complete review is done, the process continues on the Robocorp side.

![image](https://user-images.githubusercontent.com/40179958/202706038-47555201-ba4e-49b0-9ff8-9d0a2c3e55a9.png)

## Recommended further reading

- [Using work items](https://robocorp.com/docs/development-guide/control-room/work-items)
- [Work item exception handling](https://robocorp.com/docs/development-guide/control-room/work-items#work-item-exception-handling)
