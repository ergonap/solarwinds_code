# Path to the original CSV file
$csvPath = "C:\path\to\your\original.csv"

# Import the CSV file with manual parsing
$data = Get-Content -Path $csvPath | ForEach-Object {
    $columns = $_ -split ' ', 2  # Split only into 2 parts: Site and Subnet
    [PSCustomObject]@{
        Site   = $columns[0]
        Subnet = $columns[1]
    }
}

# Group data by Site
$groupedData = $data | Group-Object -Property Site

# Loop through each group and create a new CSV for each site
foreach ($group in $groupedData) {
    $siteName = $group.Name

    # Ensure the site name is cleaned up for file naming
    $safeSiteName = $siteName -replace '[^a-zA-Z0-9]', '_'
    $outputPath = "C:\path\to\output\$safeSiteName.csv"

    # Select only the Subnet column and export to a new CSV file
    $group.Group | Select-Object -ExpandProperty Subnet | Out-File -FilePath $outputPath -Encoding utf8
}

Write-Output "CSV files created successfully."
