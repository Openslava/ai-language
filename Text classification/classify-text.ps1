# Update these with your service and model values
$key=<YOUR KEY>
$endpoint=<YOUR ENDPOINT>
$projectName = <YOUR PROJECT NAME>
$modelName = <YOUR MODEL NAME>

# Set up headers for API call
$headers = @{}
$headers.add("Ocp-Apim-Subscription-Key", $key)
$headers.add("Content-Type","application/json")

# Get text to classify
$text_file = "test1.txt"
if ($args.count -gt 0)
{
    $text_file = $args[0]
}

try {
    $contents = get-content .\$text_file -raw -ErrorAction Stop
}
catch {
    Write-Host "`nError reading provided file, please verify file exists`n"
    Exit
}

# Build body of for API call
$data = @{
    "tasks" = @{
        "customClassificationTasks" = @(
            @{
                "parameters"= @{
                      "project-name" = $projectName
                      "deployment-name" = $modelName
                }
            }
        )
    }
    "analysisInput" = @{
        "documents" = @(
            @{
                "id" = "document_singleClassification"
                "text" = $contents
            }
        )
    }
} | ConvertTo-Json -Depth 6

# Post text for classification
Write-Host("`n***Submitting text classification task***")
$response = Invoke-WebRequest -Method Post `
          -Uri "$($endpoint)text/analytics/v3.2-preview.2/analyze" `
          -Headers $headers `
          -Body $data

# Extract the URL from the response
# to call the API to getting the analysis results
$resultUrl = $($response.Headers['Operation-Location'])

# Create the header for the REST GET with only the subscription key
$resultHeaders = @{}
$resultHeaders.Add( "Ocp-Apim-Subscription-Key", $key )

# Get the results
# Continue to request results until the analysis is "succeeded"
Write-Host "Getting results..."
Do {
    $result = Invoke-RestMethod -Method Get `
            -Uri $resultUrl `
            -Headers $resultHeaders | ConvertTo-Json -Depth 10

    $analysis = ($result | ConvertFrom-Json)
} while ($analysis.status -ne "succeeded")
Write-Host "...Done`n"

# Access the relevant fields from the analysis
$classification = $result | ConvertFrom-Json
$docs = $classification.tasks.customSingleClassificationTasks[0].results.documents

for (($idx = 0); $idx -lt $docs.Length; $idx++) {
    $item = $docs[$idx] 
    Write-Host ("Document #", ($idx+1))
    Write-Host ("  - Predicted Category: ", $($item.classification.category))
    Write-Host ("  - Confidence: ",$($item.classification.confidenceScore))
}
