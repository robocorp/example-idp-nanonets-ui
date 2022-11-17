*** Settings ***
Library     Collections
Library     DateTime
Library     RPA.Robocorp.WorkItems
Library     RPA.Robocorp.Vault
Library     RPA.Notifier
Library     RPA.DocumentAI.Nanonets
Library     RPA.HTTP

*** Variables ***
# Each extracted datapoint needs to be over this defined confidence
${THRESHOLD}                0.6
# Below are the parts used to construct the call to Nanonets API that get you a link to doc specific validation UI
${VALIDATION_URL_BASE}      https://preview.nanonets.com/Inferences/Model/858e4b37-6679-4552-9481-d5497dfc0b4a/ValidationUrl/
${VALIDATION_URL_PARAMS1}   ?redirect=slack%3A%2F%2Fopen&expires=
${VALIDATION_URL_PARAMS2}   &callback=https%3A%2F%2Fapi.eu1.robocorp.com%2Fprocess-v1%2Fworkspaces%2Fd6b65aa4-0c45-4fd7-8bec-d68a29896e78%2Fprocesses%2F7cf3c8cd-3f17-40f1-9397-db2495c01e2d%2Fruns-qs-authorization%3Ftoken%3D

*** Tasks ***
Consume items
    [Documentation]
    ...    Go through Nanonets extracted work items
    ...    and decide which documents require a manual.
    ...    review and get UI links for then. The rest
    ...    will be just sent to Slack with a few datapoints.
    For Each Input Work Item    Handle item

*** Keywords ***
Action for item
    [Documentation]
    ...    Get document extraction payloads and do something with them.
    ...    This example just posts document model name and confidence to Slack.
    [Arguments]    ${payload}

    #
    # THE FOLLOWING BLOCK SIMULATES DOCUMENT TRIAGE BASED ON THE CONFIDENCE RESULT
    # OF EACH EXTRACTED FIELD. THIS PART WOULD BE REPLACED WITH REAL BUSINESS LOGIC.
    #

    ${validation_needed}=   Set Variable      0
    ${slack_secret}=        Get Secret    Slack
    ${nanonets}=            Get Secret    Nanonets
    ${controlroom}=         Get Secret    Robocorp

    # Browse through all the prediction scores and check if any is below threshold
    # and set a flag for manual validation accordingly.
    FOR    ${element}    IN    @{payload}[result][0][prediction]
        IF    ${element}[score] < ${THRESHOLD}
            ${validation_needed}=   Set Variable  1
        END
    END

    # If validation is needed, get UI link from Nanonets API
    IF    ${validation_needed} == 1
        Log    Manual validation needed for invoice ${payload}[result][0][request_file_id]

        # Get current date and increment with one hour (in seconds) to set link expiration
        ${date} =	Get Current Date	result_format=epoch
        ${date} =   Evaluate    ${date}+3600

        # Construct URL for Nanonets API to fetch validation link.
        ${full_url}=   Catenate    SEPARATOR=    ${VALIDATION_URL_BASE}   ${payload}[result][0][request_file_id]   ${VALIDATION_URL_PARAMS1}    ${date}    ${VALIDATION_URL_PARAMS2}    ${controlroom}[apikey]

        ${creds}=  Evaluate  ("${nanonets}[username]", "")

        # Send request to Nanonets API to get the verification UI link
        ${response}=    GET
        ...    url=${full_url}
        ...    auth=${creds}
        Request Should Be Successful
        Status Should Be    200

        # Construct a message to be sent to user.
        ${message}=    Catenate    Nanonets: manual validation needed for invoice (
        ${message}=    Catenate    SEPARATOR=    ${message}    ${payload}[result][0][request_file_id]    ):
        ${message}=    Catenate    ${message}    ${response.text}

    ELSE
        # In this branch, user is just alerted that an invoice was processed, but no validation needed.
        Log    No validation needed for invoice ${payload}[result][0][request_file_id]

        ${message}=   Catenate    Nanonets: extraction successfull for invoice (
        ${message}=   Catenate    SEPARATOR=    ${message}    ${payload}[result][0][request_file_id]    ):

        # Browse through the extracted fields to get the Seller Name and Invoice Amount.
        ${fields}=    Get Fields From Prediction Result    ${payload}
        FOR    ${field}    IN    @{fields}
            # Log To Console    Label:${field}[label] Text:${field}[ocr_text]
            IF    $field["label"] == "seller_name" or $field["label"] == "invoice_amount"
                ${message}=   Catenate    ${message}    ${field}[ocr_text]
            END
        END

    END

    # Send message to Slack
    Notify Slack
    ...    message=${message}
    ...    channel=${slack_secret}[channel]
    ...    webhook_url=${slack_secret}[webhook]

Handle item
    [Documentation]    Error handling around one work item.
    ${payload}=    Get Work Item Variables
    TRY
        Action for item    ${payload}
        Release Input Work Item    DONE
    EXCEPT    Invalid data    type=START    AS    ${err}
        # Giving a good error message here means that data related errors can
        # be fixed faster in Control Room.
        # You can extract the text from the underlying error message.
        ${error_message}=    Set Variable
        ...    Data may be invalid, encountered error: ${err}
        Log    ${error_message}    level=ERROR
        Release Input Work Item
        ...    state=FAILED
        ...    exception_type=BUSINESS
        ...    code=INVALID_DATA
        ...    message=${error_message}
    EXCEPT    Manual review    type=START    AS    ${err}
        ${error_message}=    Set Variable
        ...    Work Item needs manual review and processing ${err}
        Log    ${error_message}    level=INFO
        Release Input Work Item
        ...    state=FAILED
        ...    exception_type=BUSINESS
        ...    code=MANUAL
        ...    message=${error_message}
    EXCEPT    *timed out*    type=GLOB    AS    ${err}
        ${error_message}=    Set Variable
        ...    Application error encountered: ${err}
        Log    ${error_message}    level=ERROR
        Release Input Work Item
        ...    state=FAILED
        ...    exception_type=APPLICATION
        ...    code=TIMEOUT
        ...    message=${error_message}
    END