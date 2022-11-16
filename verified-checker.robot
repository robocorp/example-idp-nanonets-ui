*** Settings ***

Library     RPA.Robocorp.WorkItems
Library     RPA.Robocorp.Process
Library     RPA.Notifier
Library     RPA.DocumentAI.Nanonets
Library     RPA.Robocorp.Vault

*** Tasks ***
Check verified documents
    [Documentation]
    ...    Go through Nanonets extracted work items
    ...    and decide which documents require a manual.
    ...    review and git UI links for then. The rest
    ...    will be just sent to Slack with a few datapoints.
    For Each Input Work Item    Check and handle item

*** Keywords ***
Check and handle item
    ${payload}=    Get Work Item Payload

    ${slack_secret}=    Get Secret    Slack
    ${nanonets}=    Get Secret    Nanonets

    ${message}=   Catenate    Nanonets: manual verification complete for invoice (
    ${message}=   Catenate    SEPARATOR=    ${message}    ${payload}[request_file_id]    ):

    FOR    ${field}    IN    @{payload}[moderated_boxes]
        IF    $field["status"] == "moderated"
            IF    "${field}[label]" == "seller_name" or "${field}[label]" == "invoice_amount"
                ${message}=   Catenate    ${message}    ${field}[ocr_text]
            END
        END
    END

    IF    ${payload}[moderated_boxes]
        Notify Slack
        ...    message=${message}
        ...    channel=${slack_secret}[channel]
        ...    webhook_url=${slack_secret}[webhook]
    END

    Release Input Work Item    DONE
