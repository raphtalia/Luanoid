$output = (run-in-roblox --place examples/serverSideCharacters/example.rbxl --script tests/init.server.lua) -join "`n"

$resultGroups = ($output | Select-String -Pattern '(?ms)Test results:.+^(\d+) passed, (\d+) failed, (\d+) skipped').Matches.Groups
# $numPassed = $resultGroups[1].Value
$numFailed = $resultGroups[2].Value
# $numSkipped = $resultGroups[3].Value

Write-Output $output

if ($numFailed -gt 0) {
    exit 1
}
