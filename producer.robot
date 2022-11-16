*** Settings ***
Library     Collections
Library     String
Library     RPA.Robocorp.WorkItems
Library     RPA.Robocorp.Vault
Library     RPA.DocumentAI.Nanonets
Library     RPA.HTTP

*** Variables ***
# Supported extensions
@{extensions}       jpg    jpeg    png    pdf

*** Tasks ***
Produce items
    [Documentation]
    ...    Get email workitem that triggered the process.
    ...    Read look for jpeg and png files.
    ...    Extract data with Nanonets and create output workitems for each.
    ${paths}=    Get Work Item Files    *

    # Nanonets authentication
    ${nanonets}=    Get Secret    Nanonets
    Set Authorization    ${nanonets}[api-key]

    FOR    ${path}    IN    @{paths}

        # Take only supported file extension
        ${fileext}=    Fetch From Right    ${path}    .

        IF     $fileext.lower() in $extensions

            # Call Nanonets API for extraction.
            ${result}=    Predict File
            ...  ${path}
            ...  ${nanonets}[model]

            Log    File id: ${result}[result][0][request_file_id]

            Create Output Work Item
            ...    variables=${result}
            ...    save=True

        ELSE
            Log To Console    Ignoring file ${path}
        END
    END
    Release Input Work Item    DONE
