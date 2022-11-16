*** Settings ***

Library     RPA.Robocorp.WorkItems
Library     RPA.Notifier
Library     RPA.Robocorp.Vault

*** Tasks ***
Check verified documents
    [Documentation]
    ...    Check if the verification in Nanonets UI
    ...    was completed, and if yes sends a couple
    ...    of details of the invoice to Slack.
    For Each Input Work Item    Check and handle item

*** Keywords ***
Check and handle item
    ${payload}=    Get Work Item Payload

    TRY
        # Only handle work items that has is_moderated = true
        IF    ${payload}[is_moderated]

            # Connect with Robocorp Vault
            ${slack_secret}=    Get Secret    Slack

            # Create the base of the Slack message
            ${message}=   Catenate    Nanonets: manual verification complete for invoice (
            ${message}=   Catenate    SEPARATOR=    ${message}    ${payload}[request_file_id]    ):

            # Get the needed field values from verified invoice data (moderated_boxes element)
            FOR    ${field}    IN    @{payload}[moderated_boxes]
                IF    $field["status"] == "moderated"
                    IF    "${field}[label]" == "seller_name" or "${field}[label]" == "invoice_amount"
                        ${message}=   Catenate    ${message}    ${field}[ocr_text]
                    END
                END
            END

            # Send the message to Slack.
            Notify Slack
            ...    message=${message}
            ...    channel=${slack_secret}[channel]
            ...    webhook_url=${slack_secret}[webhook]
        ELSE
            Log   Verification not complete in the UI, skipping the work item.
        END
    EXCEPT
        Log To Console    Something wrong with the work item
    END

    Release Input Work Item    DONE
