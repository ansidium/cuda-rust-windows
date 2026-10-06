param(
    [string]$UpstreamRemote = 'upstream',
    [string]$UpstreamBranch = 'main',
    [string]$LocalBranch = 'main',
    [switch]$RunChecks,
    [switch]$Push
)

& (Join-Path $PSScriptRoot '..\cuda-oxide\scripts\sync-upstream.ps1') @PSBoundParameters
