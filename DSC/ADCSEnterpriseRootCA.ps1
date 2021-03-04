
Configuration ADCSEnterpriseRootCA
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -Module xAdcsDeployment,PSDesiredStateConfiguration

    Node 'localhost'
    {
        WindowsFeature ADCS-Cert-Authority
        {
            Ensure = 'Present'
            Name   = 'ADCS-Cert-Authority'
        }

        xAdcsCertificationAuthority CertificateAuthority
        {
            Ensure     = 'Present'
            Credential = $Credential
            CAType     = 'EnterpriseRootCA'
            KeyLength  = 4096
            DependsOn  = '[WindowsFeature]ADCS-Cert-Authority'
        }

        WindowsFeature RSAT-ADCS 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority' 
        } 

        WindowsFeature RSAT-ADCS-Mgmt 
        { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS-Mgmt' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority' 
        }

        WindowsFeature ADCS-Web-Enrollment
        {
            Ensure = 'Present'
            Name   = 'ADCS-Web-Enrollment'
        }

        xAdcsWebEnrollment WebEnrollment
        {
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
            Credential       = $Credential
            DependsOn        = '[WindowsFeature]ADCS-Web-Enrollment'
        }
    }
}