# Path to the original CSV file
$csvPath = "C:\path\to\your\original.csv"

# Import the CSV file with manual parsing
$data = Get-Content -Path $csvPath | ForEach-Object {
    $columns = $_ -split ' '
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
    $outputPath = "C:\path\to\output\$siteName.csv"

    # Select only the Subnet column and export to a new CSV file
    $group.Group | Select-Object -ExpandProperty Subnet | Out-File -FilePath $outputPath -Encoding utf8
}

Write-Output "CSV files created successfully."
