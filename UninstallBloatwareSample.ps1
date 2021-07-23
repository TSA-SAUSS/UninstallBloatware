Import-Module "$PSScriptRoot\Module\UninstallBloatware.psm1" -Force

$logDirectory = "$env:ProgramData\UninstallBloatware"

$bulkRemoveAllAppxPublishers = @(
    'v10z8vjag6ke6'
    'CN=ED346674-0FA1-4272-85CE-3187C9C86E26'
)

$bloatwaresAppx = @(
    'HPAudioControl'
    'myHP'
    'HPJumpStart'
    'HPSupportAssistant'
    'HPPrivacySettings'
    'HPPCHardwareDiagnosticsWindows'
    'HPDesktopSupportUtilities'
)

$bloatwaresWin32 = @(
    'HP Collaboration Keyboard For Cisco UCC'
    'HP Collaboration Keyboard for Skype for Business'
    'HP Connection Optimizer'
    'HP Device Access Manager'
    'HP Documentation'
    'HP JumpStart Bridge'
    'HP JumpStart Launch'
    'HP JumpStart Apps'
    'HP Notifications'
    'HP Recovery Manager'
    'HP Security Update Service'
    'HP SoftPaq Download Manager'
    'HP Software Setup'
    'HP Support Assistant'
    'HP Sure Click'
    'HP Sure Connect'
    'HP Sure Recover'
    'HP Sure Run'
    'HP Sure Sense Installer'
    'HP System Software Manager'
    'HP Velocity'
    'HP Wolf Security'
    'HP WorkWise'
    'IPMPLUS'
    'HP Support Solutions Framework'
    'HP Client Security Manager'
)

$params = @{
    'LogDirectory'                  = $logDirectory
    'BulkRemoveAllAppxPublishers'   = $bulkRemoveAllAppxPublishers
    'BloatwaresAppx'                = $bloatwaresAppx
    'BloatwaresWin32'               = $bloatwaresWin32
}
Uninstall-Bloatware @params
