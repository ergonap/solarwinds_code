# Path to the original CSV file
$csvPath = "C:\path\to\your\original.csv"

# Import the CSV file
Import-Csv -Path $csvPath -Delimiter ' ' -Header Site,Subnet |
    ForEach-Object -Begin {
        $SitePipelines = @{} # Dictionary to hold pipelines for each site
    } -Process {
        $siteName = $_.Site
        $subnet = $_.Subnet

        if (-not $SitePipelines.ContainsKey($siteName)) {
            # Create a new pipeline for the site if it doesn't exist
            $safeSiteName = $siteName -replace '[^a-zA-Z0-9]', '_'
            $outputPath = "C:\path\to\output\$safeSiteName.csv"
            $Pipeline = { Export-Csv -NoTypeInformation -Path $outputPath }.GetSteppablePipeline()
            $Pipeline.Begin($True)
            $SitePipelines[$siteName] = $Pipeline
        }

        # Process the current subnet with the corresponding site's pipeline
        $SitePipelines[$siteName].Process($_)

    } -End {
        # End all pipelines
        foreach ($pipeline in $SitePipelines.Values) {
            $pipeline.End()
        }
    }

Write-Output "CSV files created successfully."
