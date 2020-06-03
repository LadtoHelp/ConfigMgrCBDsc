param ()

# Begin Testing
try
{
    $dscModuleName   = 'ConfigMgrCBDsc'
    $dscResourceName = 'DSC_CMFallbackStatusPoint'

    $testEnvironment = Initialize-TestEnvironment `
        -DSCModuleName $dscModuleName `
        -DSCResourceName $dscResourceName `
        -ResourceType 'Mof' `
        -TestType 'Unit'

    BeforeAll {
        $moduleResourceName = 'ConfigMgrCBDsc - DSC_CMFallbackStatusPoint'

        # Import Stub function
        Import-Module (Join-Path -Path $PSScriptRoot -ChildPath 'Stubs\ConfigMgrCBDscStub.psm1') -Force -WarningAction SilentlyContinue

        try
        {
            Import-Module -Name DscResource.Test -Force -ErrorAction 'Stop'
        }
        catch [System.IO.FileNotFoundException]
        {
            throw 'DscResource.Test module dependency not found. Please run ".\build.ps1 -Tasks build" first.'
        }

        $getInput = @{
            SiteCode       = 'Lab'
            SiteServerName = 'FSP01.contoso.com'
        }

        $getFSPReturn = @{
            SiteCode = 'Lab'
            Props    = @(
                @{
                    PropertyName = 'Throttle Count'
                    Value        = '10000'
                }
                @{
                    PropertyName = 'Throttle Interval'
                    Value        = '3600000'
                }
            )
        }

        $getReturnAbsent = @{
            SiteCode          = 'Lab'
            SiteServerName    = 'FSP01.contoso.com'
            StateMessageCount = $null
            ThrottleSec       = $null
            Ensure            = 'Absent'
        }

        $getReturnAll = @{
            SiteCode          = 'Lab'
            SiteServerName    = 'FSP01.contoso.com'
            StateMessageCount = '10000'
            ThrottleSec       = '3600'
            Ensure            = 'Present'
        }

        $inputAbsent = @{
            SiteCode       = 'Lab'
            SiteServerName = 'FSP01.contoso.com'
            Ensure         = 'Absent'
        }

        $inputPresent = @{
            SiteCode       = 'Lab'
            SiteServerName = 'FSP01.contoso.com'
            Ensure         = 'Present'
        }

        $inputMismatch = @{
            SiteCode          = 'Lab'
            SiteServerName    = 'FSP01.contoso.com'
            StateMessageCount = '10001'
            ThrottleSec       = '3601'
            Ensure            = 'Present'
        }
    }
    Describe "$moduleResourceName\Get-TargetResource" -Tag 'Get'{
        BeforeAll{
            Mock -CommandName Import-ConfigMgrPowerShellModule
            Mock -CommandName Set-Location
        }

        Context 'When retrieving fallback status point settings' {

            It 'Should return desired result when fallback status point is not currently installed' {
                Mock -CommandName Get-CMFallbackStatusPoint -MockWith { $null }

                $result = Get-TargetResource @getInput
                $result                   | Should -BeOfType System.Collections.HashTable
                $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
                $result.SiteServerName    | Should -Be -ExpectedValue 'FSP01.contoso.com'
                $result.StateMessageCount | Should -Be -ExpectedValue $null
                $result.ThrottleSec       | Should -Be -ExpectedValue $null
                $result.Ensure            | Should -Be -ExpectedValue 'Absent'
            }

            It 'Should return desired result when fallback status point is currently installed' {
                Mock -CommandName Get-CMFallbackStatusPoint -MockWith { $getFSPReturn }

                $result = Get-TargetResource @getInput
                $result                   | Should -BeOfType System.Collections.HashTable
                $result.SiteCode          | Should -Be -ExpectedValue 'Lab'
                $result.SiteServerName    | Should -Be -ExpectedValue 'FSP01.contoso.com'
                $result.StateMessageCount | Should -Be -ExpectedValue '10000'
                $result.ThrottleSec       | Should -Be -ExpectedValue '3600'
                $result.Ensure            | Should -Be -ExpectedValue 'Present'
            }
        }
    }

    Describe "$moduleResourceName\Set-TargetResource" -Tag 'Set'{
        Context 'When Set-TargetResource runs successfully' {
            BeforeEach{
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMFallbackStatusPoint
                Mock -CommandName Set-CMFallbackStatusPoint
                Mock -CommandName Remove-CMFallbackStatusPoint
            }

            It 'Should call expected commands for when changing settings' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                Set-TargetResource @inputMismatch
                Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
            }

            It 'Should call expected commands when fallback status point is absent' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                Mock -CommandName Get-CMSiteSystemServer -MockWith { $null }

                Set-TargetResource @getReturnAll
                Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
            }

            It 'Should call expected commands when fallback status point exists and expected absent' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                Set-TargetResource @inputAbsent
                Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
            }
        }

        Context 'When Set-TargetResource throws' {
            BeforeEach{
                Mock -CommandName Import-ConfigMgrPowerShellModule
                Mock -CommandName Set-Location
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer
                Mock -CommandName Add-CMFallbackStatusPoint
                Mock -CommandName Set-CMFallbackStatusPoint
                Mock -CommandName Remove-CMFallbackStatusPoint
            }

            It 'Should call expected commands and throw if Get-CMSiteSystemServer throws' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                Mock -CommandName Get-CMSiteSystemServer -MockWith { throw }

                { Set-TargetResource @getReturnAll } | Should -Throw
                Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
            }

            It 'Should call expected commands and throw if New-CMSiteSystemServer throws' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer -MockWith { throw }

                { Set-TargetResource @getReturnAll } | Should -Throw
                Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
            }

            It 'Should call expected commands and throw if Add-CMFallbackStatusPoint throws' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }
                Mock -CommandName Get-CMSiteSystemServer
                Mock -CommandName New-CMSiteSystemServer -MockWith { $true }
                Mock -CommandName Add-CMFallbackStatusPoint -MockWith { throw }

                { Set-TargetResource @getReturnAll } | Should -Throw
                Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 1 -Scope It
                Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
            }

            It 'Should call expected commands and throw if Set-CMFallbackStatusPoint throws' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                Mock -CommandName Set-CMFallbackStatusPoint -MockWith { throw }

                { Set-TargetResource @inputMismatch } | Should -Throw
                Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
                Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
            }

            It 'Should call expected commands and throw if Remove-CMFallbackStatusPoint throws' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }
                Mock -CommandName Remove-CMFallbackStatusPoint -MockWith { throw }

                { Set-TargetResource @inputAbsent } | Should -Throw
                Assert-MockCalled Import-ConfigMgrPowerShellModule -Exactly -Times 1 -Scope It
                Assert-MockCalled Set-Location -Exactly -Times 2 -Scope It
                Assert-MockCalled Get-TargetResource -Exactly -Times 1 -Scope It
                Assert-MockCalled Get-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled New-CMSiteSystemServer -Exactly -Times 0 -Scope It
                Assert-MockCalled Add-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Set-CMFallbackStatusPoint -Exactly -Times 0 -Scope It
                Assert-MockCalled Remove-CMFallbackStatusPoint -Exactly -Times 1 -Scope It
            }
        }
    }

    Describe "$moduleResourceName\Test-TargetResource" -Tag 'Test'{
        BeforeAll{
            Mock -CommandName Set-Location
            Mock -CommandName Import-ConfigMgrPowerShellModule
        }

        Context 'When running Test-TargetResource' {

            It 'Should return desired result false when ensure = present and FSP is absent' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                Test-TargetResource @inputPresent  | Should -Be $false
            }

            It 'Should return desired result true when ensure = absent and FSP is absent' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAbsent }

                Test-TargetResource @inputAbsent | Should -Be $true
            }

            It 'Should return desired result false when ensure = absent and FSP is present' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                Test-TargetResource @inputAbsent | Should -Be $false
            }

            It 'Should return desired result true when all returned values match inputs' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                Test-TargetResource @getReturnAll | Should -Be $true
            }

            It 'Should return desired result false when there is a mismatch between returned values and inputs' {
                Mock -CommandName Get-TargetResource -MockWith { $getReturnAll }

                Test-TargetResource @inputMismatch | Should -Be $false
            }
        }
    }
}
finally
{
    Restore-TestEnvironment -TestEnvironment $testEnvironment
}
