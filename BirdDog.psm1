<#
NAME     : BirdDog.psm1
AUTHOR   : Matt Griffin
CREATED  : 08/02/2018
MODIFIED :
COMMENT  : Script module to connect and interact with the BirdDog API. This Module was written for the BirdDog v2 API - it has 'some' flexibility to interact with the v1 API (assuming the arguments are the same).
#>
function Get-BirdDogAccessToken {
    <#
    .SYNOPSIS
        Get an AccessToken - required for all other API Interactions.
    .EXAMPLE
        PS C:\> Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential)
        By specifying your ApiKey, UserName and Password provided by BirdDog Account Rep you can get an AccessToken to interact with other API Functions
    .OUTPUTS
        Access Token String used with other API Functions
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$ApiKey,
        [parameter(Mandatory=$true)]
        [PSCredential]$Credential,
        [string]$Version = 'v2',
        [string]$ApiUri = 'https://api.birddoghr.com'
    )

    begin {
        $UserName = $Credential.UserName
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
    }

    process {
        $uri = "$ApiUri/$Version/accesstoken"
        $body = @{
            apiKey = $ApiKey;
            userName = $UserName;
            password = $Password
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $json = $body | ConvertTo-Json
        $token = Invoke-RestMethod -uri $uri -Method POST -ContentType 'application/json' -body $json
    }

    end {
        return $token.token
    }
}

function Get-BirdDogJobCandidate {
    <#
    .SYNOPSIS
        Returns list of Job Candidates from ATS BirdDog Module.
    .EXAMPLE
        PS C:\> Get-BirdDogJobCandidate -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential))
        Returns list of all BirdDog ATS Job Candidates
    .EXAMPLE
        PS C:\> Get-BirdDogJobCandidate -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential)) -Disp 'Hired' -NumDays 90
        Returns list of all BirdDog ATS Job Candidates that were hired over the last 90 days.
    .OUTPUTS
        PSObject of Job Candidates
    #>
    [CmdletBinding()]
    param (
        $AccessToken = (Get-BirdDogAccessToken),
        $ApiUri = 'https://api.birddoghr.com',
        $Version = 'v2',
        $disp,
        $numDays = 0
    )

    begin {
    }

    process {
        $uri = "$ApiUri/$Version/JobCandidates?numdays=$numDays"
        $headers = @{
            Authorization = "BDToken $($AccessToken)"
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $results = Invoke-RestMethod -uri $uri -Method GET -ContentType 'application/json' -Headers $headers
    }

    end {
        return $results.candidates
    }
}

function Get-BirdDogEmployee {
    <#
    .SYNOPSIS
        Returns list of Applicants in the Bird Dog Onboarding Module
    .EXAMPLE
        PS C:\> Get-BirdDogEmployee -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential))
        Returns list of all BirdDog Onboarding Applicants that are incomplete with a hire date after current time.
    .EXAMPLE
        PS C:\> Get-BirdDogEmployee -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential)) -disp Complete -SearchDate ((Get-Date).AddDays(-7)) -SearchDateType 'completedate'
        Returns list of all BirdDog Onboarding Applicants that are complete with a complete in the last 7 days.
    .OUTPUTS
        PSObject of Employees
    #>
    [CmdletBinding()]
    param (
        $AccessToken = (Get-BirdDogAccessToken),
        $ApiUri = 'https://api.birddoghr.com',
        $Version = 'v2',
        $Disp = "incomplete",
        $SearchDate,
        $SearchDateType = 'hiredate'
    )

    begin {
        if($SearchDate -ne $null) {
            $SearchDate = (Get-Date -Date $SearchDate -Format MM/dd/yyyy)
        }
        else {
            $SearchDate = (Get-Date -Format MM/dd/yyyy)
        }
    }

    process {
        $uri = "$ApiUri/$Version/Employees?disp=$Disp&SearchDate=$SearchDate&SearchDateType=$SearchDateType"
        $headers = @{
            Authorization = "BDToken $($AccessToken)"
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $results = Invoke-RestMethod -uri $uri -Method GET -ContentType 'application/json' -Headers $headers
    }

    end {
        return $results.employees
    }
}

function Get-BirdDogTalentUser {
    <#
    .SYNOPSIS
        Returns list of Talent Users in the Bird Dog Talent Module
    .EXAMPLE
        PS C:\> Get-BirdDogTalentUser -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential))
        Returns list of all BirdDog Talent Users that are in the Bird Dog Talent Module.
    .EXAMPLE
        PS C:\> Get-BirdDogTalentUser -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential)) -User 'user@example.com'
        Returns list of specified BirdDog Talent User that is in the Bird Dog Talent Module.
    .OUTPUTS
        PSObject of Talent User(s)
    #>
    [CmdletBinding(DefaultParameterSetName='AllUsers')]
    param (
        $AccessToken = (Get-BirdDogAccessToken),
        $ApiUri = 'https://api.birddoghr.com',
        $Version = 'v2',
        [parameter(Mandatory=$false, ParameterSetName="AllUsers")]
        [parameter(Mandatory=$true, ParameterSetName="User")]
        [string]$User
    )
    
    begin {
    }
    
    process {
        if($User -eq $null){
            $uri = "$ApiUri/$Version/TalentUsers"
        }
        else{
            $uri = "$ApiUri/$Version/TalentUser?userName=$User"
        }
        
        $headers = @{
            Authorization = "BDToken $($AccessToken)"
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $results = Invoke-RestMethod -uri $uri -Method GET -ContentType 'application/json' -Headers $headers
    }
    
    end {
        return $results.TalentUsers
    }
}

function Get-BirdDogEmployeeCertification {
    <#
    .SYNOPSIS
        Returns list of Employee Certifications in the Bird Dog Talent Module
    .EXAMPLE
        PS C:\> Get-BirdDogEmployeeCertification -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential)) -User 'user@example.com'
        Returns list of BirdDog Talent User Certificates that are in the Bird Dog Talent Module.
    .OUTPUTS
        PSObject of Talent User and their certificates
    #>
    [CmdletBinding(DefaultParameterSetName='AllUsers')]
    param (
        $AccessToken = (Get-BirdDogAccessToken),
        $ApiUri = 'https://api.birddoghr.com',
        $Version = 'v2',
        [parameter(Mandatory=$true)]
        [string[]]$User
    )
    
    begin {
    }
    
    process {
        $i = 0
        foreach($count in $User){
            if($i -eq 0){
                $uri = "$ApiUri/$Version/EmployeeCertification?userName[$i]=$count"
            }
            else{
                $uri += "&userName[$i]=$count"
            }
            $i++
        }
        
        $headers = @{
            Authorization = "BDToken $($AccessToken)"
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $results = Invoke-RestMethod -uri $uri -Method GET -ContentType 'application/json' -Headers $headers
    }
    
    end {
        return $results.employees
    }
}

function Get-BirdDogEmployeeLearningTranscript {
    <#
    .SYNOPSIS
        Returns list of Talent User(s) Transcripts in the Bird Dog Talent Module
    .EXAMPLE
        PS C:\> Get-BirdDogEmployeeLearningTranscript -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential)) -User 'user@example.com'
        Returns list of all BirdDog Talent Users that are in the Bird Dog Talent Module.
    .OUTPUTS
        PSObject of Talent User(s) Learning Transcript
    #>
    [CmdletBinding(DefaultParameterSetName='AllUsers')]
    param (
        $AccessToken = (Get-BirdDogAccessToken),
        $ApiUri = 'https://api.birddoghr.com',
        $Version = 'v2',
        [parameter(Mandatory=$true)]
        [string[]]$User
    )
    
    begin {
    }
    
    process {
        $i = 0
        foreach($count in $User){
            if($i -eq 0){
                $uri = "$ApiUri/$Version/EmployeeLearningTranscript?userName[$i]=$count"
            }
            else{
                $uri += "&userName[$i]=$count"
            }
            $i++
        }
        
        $headers = @{
            Authorization = "BDToken $($AccessToken)"
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $results = Invoke-RestMethod -uri $uri -Method GET -ContentType 'application/json' -Headers $headers
    }
    
    end {
        return $results.transcripts
    }
}

function Get-BirdDogEmployeeDocument {
    <#
    .SYNOPSIS
        Returns list of Application User Employee Document in the Bird Dog Onboarding Module
    .EXAMPLE
        PS C:\> Get-BirdDogEmployeeDocument -AccessToken (Get-BirdDogAccessToken -ApiKey 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE' -Credential (Get-Credential)) -UserName 'user@example.com' -DocumentType W4FEDERAL
        Returns BirdDog Onboarding User Document that are is in the Bird Dog Onboarding Module.
    .OUTPUTS
        PSObject of Bird Dog Onboarding Application Document
    #>
    [CmdletBinding()]
    param (
        $AccessToken = (Get-BirdDogAccessToken),
        $ApiUri = 'https://api.birddoghr.com',
        $Version = 'v2',
        [parameter(Mandatory=$true)]
        [string]$UserName,
        [parameter(Mandatory=$true)]
        [string]$DocumentType,
        [string]$DocumentSubType
    )
    
    begin {
    }
    
    process {
        if($DocumentSubType -eq $null){
            $uri = "$ApiUri/$Version/GetEmployeeDocument?userName=$UserName&documentType=$DocumentType"
        }
        else{
            $uri = "$ApiUri/$Version/GetEmployeeDocument?userName=$UserName&documentType=$DocumentType&documentSubType=$DocumentSubType"
        }
        $headers = @{
            Authorization = "BDToken $($AccessToken)"
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $results = Invoke-RestMethod -uri $uri -Method GET -ContentType 'application/json' -Headers $headers
    }
    
    end {
        return $results
    }
}