'----------------------------------------------------------------------
'
' Copyright (c) Microsoft Corporation. All rights reserved.
'
' Abstract:
' prnport.vbs - Port script for WMI on Windows
'     used to add, delete and list ports
'     also for getting and setting the port configuration
'
' Usage:
' prnport [-adlgt?] [-r port] [-s server] [-u user name] [-w password]
'                   [-o raw|lpr] [-h host address] [-q queue] [-n number]
'                   [-me | -md ] [-i SNMP index] [-y community] [-2e | -2d]"
'
' Examples
' prnport -a -s server -r IP_1.2.3.4 -e 1.2.3.4 -o raw -n 9100
' prnport -d -s server -r c:\temp\foo.prn
' prnport -l -s server
' prnport -g -s server -r IP_1.2.3.4
' prnport -t -s server -r IP_1.2.3.4 -me -y public -i 1 -n 9100
'
'----------------------------------------------------------------------

option explicit

'
' Debugging trace flags, to enable debug output trace message
' change gDebugFlag to true.
'
dim   gDebugFlag
const kDebugTrace = 1
const kDebugError = 2

gDebugFlag = false

'
' Operation action values.
'
const kActionAdd          = 0
const kActionDelete       = 1
const kActionList         = 2
const kActionUnknown      = 3
const kActionGet          = 4
const kActionSet          = 5

const kErrorSuccess       = 0
const KErrorFailure       = 1

const kFlagCreateOrUpdate = 0

const kNameSpace          = "root\cimv2"


'
' Constants for the parameter dictionary
'
const kServerName      = 1
const kPortName        = 2
const kDoubleSpool     = 3
const kPortNumber      = 4
const kPortType        = 5
const kHostAddress     = 6
const kSNMPDeviceIndex = 7
const kCommunityName   = 8
const kSNMP            = 9
const kQueueName       = 10
const kUserName        = 11
const kPassword        = 12

'
' Generic strings
'
const L_Empty_Text                 = ""
const L_Space_Text                 = " "
const L_Colon_Text                 = ":"
const L_LPR_Queue                  = "LPR"
const L_Error_Text                 = "Error"
const L_Success_Text               = "Success"
const L_Failed_Text                = "Failed"
const L_Hex_Text                   = "0x"
const L_Printer_Text               = "Printer"
const L_Operation_Text             = "Operation"
const L_Provider_Text              = "Provider"
const L_Description_Text           = "Description"
const L_Debug_Text                 = "Debug:"

'
' General usage messages
'
const L_Help_Help_General01_Text   = "Usage: prnport [-adlgt?] [-r port][-s server][-u user name][-w password]"
const L_Help_Help_General02_Text   = "               [-o raw|lpr][-h host address][-q queue][-n number]"
const L_Help_Help_General03_Text   = "               [-me | -md ][-i SNMP index][-y community][-2e | -2d]"
const L_Help_Help_General04_Text   = "Arguments:"
const L_Help_Help_General05_Text   = "-a     - add a port"
const L_Help_Help_General06_Text   = "-d     - delete the specified port"
const L_Help_Help_General07_Text   = "-g     - get configuration for a TCP port"
const L_Help_Help_General08_Text   = "-h     - IP address of the device"
const L_Help_Help_General09_Text   = "-i     - SNMP index, if SNMP is enabled"
const L_Help_Help_General10_Text   = "-l     - list all TCP ports"
const L_Help_Help_General11_Text   = "-m     - SNMP type. [e] enable, [d] disable"
const L_Help_Help_General12_Text   = "-n     - port number, applies to TCP RAW ports"
const L_Help_Help_General13_Text   = "-o     - port type, raw or lpr"
const L_Help_Help_General14_Text   = "-q     - queue name, applies to TCP LPR ports only"
const L_Help_Help_General15_Text   = "-r     - port name"
const L_Help_Help_General16_Text   = "-s     - server name"
const L_Help_Help_General17_Text   = "-t     - set configuration for a TCP port"
const L_Help_Help_General18_Text   = "-u     - user name"
const L_Help_Help_General19_Text   = "-w     - password"
const L_Help_Help_General20_Text   = "-y     - community name, if SNMP is enabled"
const L_Help_Help_General21_Text   = "-2     - double spool, applies to TCP LPR ports. [e] enable, [d] disable"
const L_Help_Help_General22_Text   = "-?     - display command usage"
const L_Help_Help_General23_Text   = "Examples:"
const L_Help_Help_General24_Text   = "prnport -l -s server"
const L_Help_Help_General25_Text   = "prnport -d -s server -r IP_1.2.3.4"
const L_Help_Help_General26_Text   = "prnport -a -s server -r IP_1.2.3.4 -h 1.2.3.4 -o raw -n 9100"
const L_Help_Help_General27_Text   = "prnport -t -s server -r IP_1.2.3.4 -me -y public -i 1 -n 9100"
const L_Help_Help_General28_Text   = "prnport -g -s server -r IP_1.2.3.4"
const L_Help_Help_General29_Text   = "prnport -a -r IP_1.2.3.4 -h 1.2.3.4"
const L_Help_Help_General30_Text   = "Remark:"
const L_Help_Help_General31_Text   = "The last example will try to get the device settings at the specified IP address."
const L_Help_Help_General32_Text   = "If a device is detected, then a TCP port is added with the preferred settings for that device."

'
' Messages to be displayed if the scripting host is not cscript
'
const L_Help_Help_Host01_Text      = "This script should be executed from the Command Prompt using CScript.exe."
const L_Help_Help_Host02_Text      = "For example: CScript script.vbs arguments"
const L_Help_Help_Host03_Text      = ""
const L_Help_Help_Host04_Text      = "To set CScript as the default application to run .VBS files run the following:"
const L_Help_Help_Host05_Text      = "     CScript //H:CScript //S"
const L_Help_Help_Host06_Text      = "You can then run ""script.vbs arguments"" without preceding the script with CScript."

'
' General error messages
'
const L_Text_Error_General01_Text  = "The scripting host could not be determined."
const L_Text_Error_General02_Text  = "Unable to parse command line."
const L_Text_Error_General03_Text  = "Win32 error code"

'
' Miscellaneous messages
'
const L_Text_Msg_General01_Text    = "Added port"
const L_Text_Msg_General02_Text    = "Unable to delete port"
const L_Text_Msg_General03_Text    = "Unable to get port"
const L_Text_Msg_General04_Text    = "Created/updated port"
const L_Text_Msg_General05_Text    = "Unable to create/update port"
const L_Text_Msg_General06_Text    = "Unable to enumerate ports"
const L_Text_Msg_General07_Text    = "Number of ports enumerated"
const L_Text_Msg_General08_Text    = "Deleted port"
const L_Text_Msg_General09_Text    = "Unable to get SWbemLocator object"
const L_Text_Msg_General10_Text    = "Unable to connect to WMI service"


'
' Port properties
'
const L_Text_Msg_Port01_Text       = "Server name"
const L_Text_Msg_Port02_Text       = "Port name"
const L_Text_Msg_Port03_Text       = "Host address"
const L_Text_Msg_Port04_Text       = "Protocol RAW"
const L_Text_Msg_Port05_Text       = "Protocol LPR"
const L_Text_Msg_Port06_Text       = "Port number"
const L_Text_Msg_Port07_Text       = "Queue"
const L_Text_Msg_Port08_Text       = "Byte Count Enabled"
const L_Text_Msg_Port09_Text       = "Byte Count Disabled"
const L_Text_Msg_Port10_Text       = "SNMP Enabled"
const L_Text_Msg_Port11_Text       = "SNMP Disabled"
const L_Text_Msg_Port12_Text       = "Community"
const L_Text_Msg_Port13_Text       = "Device index"

'
' Debug messages
'
const L_Text_Dbg_Msg01_Text        = "In function DelPort"
const L_Text_Dbg_Msg02_Text        = "In function CreateOrSetPort"
const L_Text_Dbg_Msg03_Text        = "In function ListPorts"
const L_Text_Dbg_Msg04_Text        = "In function GetPort"
const L_Text_Dbg_Msg05_Text        = "In function ParseCommandLine"

main

'
' Main execution starts here
'
sub main

    on error resume next

    dim iAction
    dim iRetval
    dim oParamDict

    '
    ' Abort if the host is not cscript
    '
    if not IsHostCscript() then

        call wscript.echo(L_Help_Help_Host01_Text & vbCRLF & L_Help_Help_Host02_Text & vbCRLF & _
                          L_Help_Help_Host03_Text & vbCRLF & L_Help_Help_Host04_Text & vbCRLF & _
                          L_Help_Help_Host05_Text & vbCRLF & L_Help_Help_Host06_Text & vbCRLF)

        wscript.quit

    end if

    set oParamDict = CreateObject("Scripting.Dictionary")

    iRetval = ParseCommandLine(iAction, oParamDict)

    if iRetval = 0 then

        select case iAction

            case kActionAdd
                iRetval = CreateOrSetPort(oParamDict)

            case kActionDelete
                iRetval = DelPort(oParamDict)

            case kActionList
                iRetval = ListPorts(oParamDict)

            case kActionGet
                iRetVal = GetPort(oParamDict)

            case kActionSet
                iRetVal = CreateOrSetPort(oParamDict)

            case else
                Usage(true)
                exit sub

        end select

    end if

end sub

'
' Delete a port
'
function DelPort(oParamDict)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg01_Text
    DebugPrint kDebugTrace, L_Text_Msg_Port01_Text & L_Space_Text & oParamDict(kServerName)
    DebugPrint kDebugTrace, L_Text_Msg_Port02_Text & L_Space_Text & oParamDict(kPortName)

    dim oService
    dim oPort
    dim iResult
    dim strServer
    dim strPort
    dim strUser
    dim strPassword

    iResult = kErrorFailure

    strServer   = oParamDict(kServerName)
    strPort     = oParamDict(kPortName)
    strUser     = oParamDict(kUserName)
    strPassword = oParamDict(kPassword)

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oPort = oService.Get("Win32_TCPIPPrinterPort='" & strPort & "'")

    else

        DelPort = kErrorFailure

        exit function

    end if

    '
    ' Check if Get succeeded
    '
    if Err.Number = kErrorSuccess then

        '
        ' Try deleting the instance
        '
        oPort.Delete_

        if Err.Number = kErrorSuccess then

            wscript.echo L_Text_Msg_General08_Text & L_Space_Text & strPort

        else

            wscript.echo L_Text_Msg_General02_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                         & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

            '
            ' Try getting extended error information
            '
            call LastError()

        end if

    else

        wscript.echo L_Text_Msg_General02_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

    end if

    DelPort = iResult

end function

'
' Add or update a port
'
function CreateOrSetPort(oParamDict)

    on error resume next

    dim oPort
    dim oService
    dim iResult
    dim PortType
    dim strServer
    dim strPort
    dim strUser
    dim strPassword

    DebugPrint kDebugTrace, L_Text_Dbg_Msg02_Text
    DebugPrint kDebugTrace, L_Text_Msg_Port01_Text & L_Space_Text & oParamDict.Item(kServerName)
    DebugPrint kDebugTrace, L_Text_Msg_Port02_Text & L_Space_Text & oParamDict.Item(kPortName)
    DebugPrint kDebugTrace, L_Text_Msg_Port06_Text & L_Space_Text & oParamDict.Item(kPortNumber)
    DebugPrint kDebugTrace, L_Text_Msg_Port07_Text & L_Space_Text & oParamDict.Item(kQueueName)
    DebugPrint kDebugTrace, L_Text_Msg_Port13_Text & L_Space_Text & oParamDict.Item(kSNMPDeviceIndex)
    DebugPrint kDebugTrace, L_Text_Msg_Port12_Text & L_Space_Text & oParamDict.Item(kCommunityName)
    DebugPrint kDebugTrace, L_Text_Msg_Port03_Text & L_Space_Text & oParamDict.Item(kHostAddress)

    strServer   = oParamDict(kServerName)
    strPort     = oParamDict(kPortName)
    strUser     = oParamDict(kUserName)
    strPassword = oParamDict(kPassword)

    '
    ' If the port exists, then get the settings. Later PutInstance will do an update
    '
    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oPort = oService.Get("Win32_TCPIPPrinterPort.Name='" & strPort & "'")

        '
        ' If get was unsuccessful then spawn a new port instance. Later PutInstance will do a create
        '
        if Err.Number <> kErrorSuccess then

            '
            ' Clear the previous error
            '
            Err.Clear

            set oPort = oService.Get("Win32_TCPIPPrinterPort").SpawnInstance_

        end if

    else

        CreateOrSetPort = kErrorFailure

        exit function

    end if

    if Err.Number <> kErrorSuccess then

        wscript.echo L_Text_Msg_General03_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        CreateOrSetPort = kErrorFailure

        exit function

    end if

    oPort.Name          = oParamDict.Item(kPortName)
    oPort.HostAddress   = oParamDict.Item(kHostAddress)
    oPort.PortNumber    = oParamDict.Item(kPortNumber)
    oPort.SNMPEnabled   = oParamDict.Item(kSNMP)
    oPort.SNMPDevIndex  = oParamDict.Item(kSNMPDeviceIndex)
    oPort.SNMPCommunity = oParamDict.Item(kCommunityName)
    oPort.Queue         = oParamDict.Item(kQueueName)
    oPort.ByteCount     = oParamDict.Item(kDoubleSpool)

    PortType     = oParamDict.Item(kPortType)

    '
    ' Update the port object with the settings corresponding
    ' to the port type of the port to be added
    '
    select case lcase(PortType)

            case "raw"

                 oPort.Protocol      = 1

                 if Not IsNull(oPort.Queue) then

                     wscript.echo L_Error_Text & L_Colon_Text & L_Space_Text _
                     & L_Help_Help_General14_Text

                     CreateOrSetPort = kErrorFailure

                     exit function

                 end if

            case "lpr"

                 oPort.Protocol      = 2

                 if IsNull(oPort.Queue) then

                     oPort.Queue = L_LPR_Queue

                 end if

            case else

                 '
                 ' PutInstance will attempt to get the configuration of
                 ' the device based on its IP address. Those settings
                 ' will be used to add a new port
                 '
    end select

    '
    ' Try creating or updating the port
    '
    oPort.Put_(kFlagCreateOrUpdate)

    if Err.Number = kErrorSuccess then

        wscript.echo L_Text_Msg_General04_Text & L_Space_Text & oPort.Name

        iResult = kErrorSuccess

    else

        wscript.echo L_Text_Msg_General05_Text & L_Space_Text & oPort.Name & L_Space_Text _
                     & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) _
                     & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

        iResult = kErrorFailure

    end if

    CreateOrSetPort = iResult

end function

'
' List ports on a machine.
'
function ListPorts(oParamDict)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg03_Text

    dim Ports
    dim oPort
    dim oService
    dim iRetval
    dim iTotal
    dim strServer
    dim strUser
    dim strPassword

    iResult = kErrorFailure

    strServer   = oParamDict(kServerName)
    strUser     = oParamDict(kUserName)
    strPassword = oParamDict(kPassword)

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set Ports = oService.InstancesOf("Win32_TCPIPPrinterPort")

    else

        ListPorts = kErrorFailure

        exit function

    end if

    if Err.Number <> kErrorSuccess then

        wscript.echo L_Text_Msg_General06_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        ListPrinters = kErrorFailure

        exit function

    end if

    iTotal = 0

    for each oPort in Ports

        iTotal = iTotal + 1

        wscript.echo L_Empty_Text
        wscript.echo L_Text_Msg_Port01_Text & L_Space_Text & strServer
        wscript.echo L_Text_Msg_Port02_Text & L_Space_Text & oPort.Name
        wscript.echo L_Text_Msg_Port03_Text & L_Space_Text & oPort.HostAddress

        if oPort.Protocol = 1 then

            wscript.echo L_Text_Msg_Port04_Text
            wscript.echo L_Text_Msg_Port06_Text & L_Space_Text & oPort.PortNumber

        else

            wscript.echo L_Text_Msg_Port05_Text
            wscript.echo L_Text_Msg_Port07_Text & L_Space_Text & oPort.Queue

            if oPort.ByteCount then

                wscript.echo L_Text_Msg_Port08_Text

            else

                wscript.echo L_Text_Msg_Port09_Text

            end if

        end if

        if oPort.SNMPEnabled then

            wscript.echo L_Text_Msg_Port10_Text
            wscript.echo L_Text_Msg_Port12_Text & L_Space_Text & oPort.SNMPCommunity
            wscript.echo L_Text_Msg_Port13_Text & L_Space_Text & oPort.SNMPDevIndex

        else

            wscript.echo L_Text_Msg_Port11_Text

        end if

        Err.Clear

    next

    wscript.echo L_Empty_Text
    wscript.echo L_Text_Msg_General07_Text & L_Space_Text & iTotal

    ListPorts = kErrorSuccess

end function

'
' Gets the configuration of a port
'
function GetPort(oParamDict)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg04_Text
    DebugPrint kDebugTrace, L_Text_Msg_Port01_Text & L_Space_Text & oParamDict(kServerName)
    DebugPrint kDebugTrace, L_Text_Msg_Port02_Text & L_Space_Text & oParamDict(kPortName)

    dim oService
    dim oPort
    dim iResult
    dim strServer
    dim strPort
    dim strUser
    dim strPassword

    iResult = kErrorFailure

    strServer   = oParamDict(kServerName)
    strPort     = oParamDict(kPortName)
    strUser     = oParamDict(kUserName)
    strPassword = oParamDict(kPassword)

    if WmiConnect(strServer, kNameSpace, strUser, strPassword, oService) then

        set oPort = oService.Get("Win32_TCPIPPrinterPort.Name='" & strPort & "'")

    else

        GetPort = kErrorFailure

        exit function

    end if

    if Err.Number = kErrorSuccess then

        wscript.echo L_Empty_Text
        wscript.echo L_Text_Msg_Port01_Text & L_Space_Text & strServer
        wscript.echo L_Text_Msg_Port02_Text & L_Space_Text & oPort.Name
        wscript.echo L_Text_Msg_Port03_Text & L_Space_Text & oPort.HostAddress

        if oPort.Protocol = 1 then

            wscript.echo L_Text_Msg_Port04_Text
            wscript.echo L_Text_Msg_Port06_Text & L_Space_Text & oPort.PortNumber

        else

            wscript.echo L_Text_Msg_Port05_Text
            wscript.echo L_Text_Msg_Port07_Text & L_Space_Text & oPort.Queue

            if oPort.ByteCount then

                wscript.echo L_Text_Msg_Port08_Text

            else

                wscript.echo L_Text_Msg_Port09_Text

            end if

        end if

        if oPort.SNMPEnabled then

            wscript.echo L_Text_Msg_Port10_Text
            wscript.echo L_Text_Msg_Port12_Text & L_Space_Text & oPort.SNMPCommunity
            wscript.echo L_Text_Msg_Port13_Text & L_Space_Text & oPort.SNMPDevIndex

        else

            wscript.echo L_Text_Msg_Port11_Text

        end if

        iResult = kErrorSuccess

    else

        wscript.echo L_Text_Msg_General03_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

        '
        ' Try getting extended error information
        '
        call LastError()

    end if

    GetPort = iResult

end function

'
' Debug display helper function
'
sub DebugPrint(uFlags, strString)

    if gDebugFlag = true then

        if uFlags = kDebugTrace then

            wscript.echo L_Debug_Text & L_Space_Text & strString

        end if

        if uFlags = kDebugError then

            if Err <> 0 then

                wscript.echo L_Debug_Text & L_Space_Text & strString & L_Space_Text _
                             & L_Error_Text & L_Space_Text & L_Hex_Text & hex(Err.Number) _
                             & L_Space_Text & Err.Description

            end if

        end if

    end if

end sub

'
' Parse the command line into its components
'
function ParseCommandLine(iAction, oParamDict)

    on error resume next

    DebugPrint kDebugTrace, L_Text_Dbg_Msg05_Text

    dim oArgs
    dim iIndex

    iAction = kActionUnknown

    set oArgs = Wscript.Arguments

    while iIndex < oArgs.Count

        select case oArgs(iIndex)

            case "-g"
                iAction = kActionGet

            case "-t"
                iAction = kActionSet

            case "-a"
                iAction = kActionAdd

            case "-d"
                iAction = kActionDelete

            case "-l"
                iAction = kActionList

            case "-2e"
                oParamDict.Add kDoubleSpool, true

            case "-2d"
                oParamDict.Add kDoubleSpool, false

            case "-s"
                iIndex = iIndex + 1
                oParamDict.Add kServerName, RemoveBackslashes(oArgs(iIndex))

            case "-u"
                iIndex = iIndex + 1
                oParamDict.Add kUserName, oArgs(iIndex)

            case "-w"
                iIndex = iIndex + 1
                oParamDict.Add kPassword, oArgs(iIndex)

            case "-n"
                iIndex = iIndex + 1
                oParamDict.Add kPortNumber, oArgs(iIndex)

            case "-r"
                iIndex = iIndex + 1
                oParamDict.Add kPortName, oArgs(iIndex)

            case "-o"
                iIndex = iIndex + 1
                oParamDict.Add kPortType, oArgs(iIndex)

            case "-h"
                iIndex = iIndex + 1
                oParamDict.Add kHostAddress, oArgs(iIndex)

            case "-q"
                iIndex = iIndex + 1
                oParamDict.Add kQueueName, oArgs(iIndex)

            case "-i"
                iIndex = iIndex + 1
                oParamDict.Add kSNMPDeviceIndex, oArgs(iIndex)

            case "-y"
                iIndex = iIndex + 1
                oParamDict.Add kCommunityName, oArgs(iIndex)

            case "-me"
                oParamDict.Add kSNMP, true

            case "-md"
                oParamDict.Add kSNMP, false

            case "-?"
                Usage(True)
                exit function

            case else
                Usage(True)
                exit function

        end select

        iIndex = iIndex + 1

    wend

    if Err = kErrorSuccess then

        ParseCommandLine = kErrorSuccess

    else

        wscript.echo L_Text_Error_General02_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_text & Err.Description


        ParseCommandLine = kErrorFailure

    end if

end  function

'
' Display command usage.
'
sub Usage(bExit)

    wscript.echo L_Help_Help_General01_Text
    wscript.echo L_Help_Help_General02_Text
    wscript.echo L_Help_Help_General03_Text
    wscript.echo L_Help_Help_General04_Text
    wscript.echo L_Help_Help_General05_Text
    wscript.echo L_Help_Help_General06_Text
    wscript.echo L_Help_Help_General07_Text
    wscript.echo L_Help_Help_General08_Text
    wscript.echo L_Help_Help_General09_Text
    wscript.echo L_Help_Help_General10_Text
    wscript.echo L_Help_Help_General11_Text
    wscript.echo L_Help_Help_General12_Text
    wscript.echo L_Help_Help_General13_Text
    wscript.echo L_Help_Help_General14_Text
    wscript.echo L_Help_Help_General15_Text
    wscript.echo L_Help_Help_General16_Text
    wscript.echo L_Help_Help_General17_Text
    wscript.echo L_Help_Help_General18_Text
    wscript.echo L_Help_Help_General19_Text
    wscript.echo L_Help_Help_General20_Text
    wscript.echo L_Help_Help_General21_Text
    wscript.echo L_Help_Help_General22_Text
    wscript.echo L_Empty_Text
    wscript.echo L_Help_Help_General23_Text
    wscript.echo L_Help_Help_General24_Text
    wscript.echo L_Help_Help_General25_Text
    wscript.echo L_Help_Help_General26_Text
    wscript.echo L_Help_Help_General27_Text
    wscript.echo L_Help_Help_General28_Text
    wscript.echo L_Help_Help_General29_Text
    wscript.echo L_Empty_Text
    wscript.echo L_Help_Help_General30_Text
    wscript.echo L_Help_Help_General31_Text
    wscript.echo L_Help_Help_General32_Text

    if bExit then

        wscript.quit(1)

    end if

end sub

'
' Determines which program is being used to run this script.
' Returns true if the script host is cscript.exe
'
function IsHostCscript()

    on error resume next

    dim strFullName
    dim strCommand
    dim i, j
    dim bReturn

    bReturn = false

    strFullName = WScript.FullName

    i = InStr(1, strFullName, ".exe", 1)

    if i <> 0 then

        j = InStrRev(strFullName, "\", i, 1)

        if j <> 0 then

            strCommand = Mid(strFullName, j+1, i-j-1)

            if LCase(strCommand) = "cscript" then

                bReturn = true

            end if

        end if

    end if

    if Err <> 0 then

        wscript.echo L_Text_Error_General01_Text & L_Space_Text & L_Error_Text & L_Space_Text _
                     & L_Hex_Text & hex(Err.Number) & L_Space_Text & Err.Description

    end if

    IsHostCscript = bReturn

end function

'
' Retrieves extended information about the last error that occurred
' during a WBEM operation. The methods that set an SWbemLastError
' object are GetObject, PutInstance, DeleteInstance
'
sub LastError()

    on error resume next

    dim oError

    set oError = CreateObject("WbemScripting.SWbemLastError")

    if Err = kErrorSuccess then

        wscript.echo L_Operation_Text            & L_Space_Text & oError.Operation
        wscript.echo L_Provider_Text             & L_Space_Text & oError.ProviderName
        wscript.echo L_Description_Text          & L_Space_Text & oError.Description
        wscript.echo L_Text_Error_General04_Text & L_Space_Text & oError.StatusCode

    end if

end sub

'
' Connects to the WMI service on a server. oService is returned as a service
' object (SWbemServices)
'
function WmiConnect(strServer, strNameSpace, strUser, strPassword, oService)

   on error resume next

   dim oLocator
   dim bResult

   oService = null

   bResult  = false

   set oLocator = CreateObject("WbemScripting.SWbemLocator")

   if Err = kErrorSuccess then

      set oService = oLocator.ConnectServer(strServer, strNameSpace, strUser, strPassword)

      if Err = kErrorSuccess then

          bResult = true

          oService.Security_.impersonationlevel = 3

          '
          ' Required to perform administrative tasks on the spooler service
          '
          oService.Security_.Privileges.AddAsString "SeLoadDriverPrivilege"

          Err.Clear

      else

          wscript.echo L_Text_Msg_General10_Text & L_Space_Text & L_Error_Text _
                       & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                       & Err.Description

      end if

   else

       wscript.echo L_Text_Msg_General09_Text & L_Space_Text & L_Error_Text _
                    & L_Space_Text & L_Hex_Text & hex(Err.Number) & L_Space_Text _
                    & Err.Description

   end if

   WmiConnect = bResult

end function

'
' Remove leading "\\" from server name
'
function RemoveBackslashes(strServer)

    dim strRet

    strRet = strServer

    if Left(strServer, 2) = "\\" and Len(strServer) > 2 then

        strRet = Mid(strServer, 3)

    end if

    RemoveBackslashes = strRet

end function

'' SIG '' Begin signature block
'' SIG '' MIIhpQYJKoZIhvcNAQcCoIIhljCCIZICAQExDzANBglg
'' SIG '' hkgBZQMEAgEFADB3BgorBgEEAYI3AgEEoGkwZzAyBgor
'' SIG '' BgEEAYI3AgEeMCQCAQEEEE7wKRaZJ7VNj+Ws4Q8X66sC
'' SIG '' AQACAQACAQACAQACAQAwMTANBglghkgBZQMEAgEFAAQg
'' SIG '' JP2OI/dGh8Dr4i1IHJc1kEljUqgI55azox+O936+ZZqg
'' SIG '' ggrjMIIFBDCCA+ygAwIBAgITMwAAAXRp3hCLN2Wo1wAA
'' SIG '' AAABdDANBgkqhkiG9w0BAQsFADCBhDELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjEuMCwGA1UEAxMlTWljcm9zb2Z0IFdpbmRv
'' SIG '' d3MgUHJvZHVjdGlvbiBQQ0EgMjAxMTAeFw0xNzA4MTEy
'' SIG '' MDIzMzVaFw0xODA4MTEyMDIzMzVaMHAxCzAJBgNVBAYT
'' SIG '' AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQH
'' SIG '' EwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
'' SIG '' cG9yYXRpb24xGjAYBgNVBAMTEU1pY3Jvc29mdCBXaW5k
'' SIG '' b3dzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
'' SIG '' AQEAyuCoDMzWlNVC+vhg3V+6NX6QuKLAjZJuXxDdoGJ1
'' SIG '' eo8ZZTtlh5g462LV0LR1t8mbQQE5iU3QhtdSreQvV9OS
'' SIG '' fQKLLBfgPd/S8JKsA5hmpQB7+GTiBjI59/W2T3ANdpbs
'' SIG '' zYJ7R7WjHcBDvCRK+2m4dFOjS45OyzIsEpp411BcWbOW
'' SIG '' BpOBiulFOsqvPhaUWnaMfv3u95Nwc1RnFNJkSPPa/50g
'' SIG '' D4Yeg2Bmfa7c3dDQr9pU6YJyvq7WhnYl9g3+qrLN/e71
'' SIG '' XHc9vjJEkIMzfp654a3EgM1fvfcfRoXnB8gwAFGBWwgg
'' SIG '' DuxYI7IiiTq02rfkxKFlyZAmuJqG7avckmBrQwIDAQAB
'' SIG '' o4IBgDCCAXwwHwYDVR0lBBgwFgYKKwYBBAGCNwoDBgYI
'' SIG '' KwYBBQUHAwMwHQYDVR0OBBYEFCYu9zida3q77NtVAqbC
'' SIG '' 2phmlwnVMFIGA1UdEQRLMEmkRzBFMQ0wCwYDVQQLEwRN
'' SIG '' T1BSMTQwMgYDVQQFEysyMjk4NzkrNzE5NTU1Y2ItNmRl
'' SIG '' Mi00NDZjLWFjYmEtZDkwODk0YWNkODcyMB8GA1UdIwQY
'' SIG '' MBaAFKkpAjmOFsSXeM2Q+Z5PmuF8Va9TMFQGA1UdHwRN
'' SIG '' MEswSaBHoEWGQ2h0dHA6Ly93d3cubWljcm9zb2Z0LmNv
'' SIG '' bS9wa2lvcHMvY3JsL01pY1dpblByb1BDQTIwMTFfMjAx
'' SIG '' MS0xMC0xOS5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsG
'' SIG '' AQUFBzAChkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
'' SIG '' cGtpb3BzL2NlcnRzL01pY1dpblByb1BDQTIwMTFfMjAx
'' SIG '' MS0xMC0xOS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG
'' SIG '' 9w0BAQsFAAOCAQEAsDAOTTJRFPx4BeEahMFQT2AP2xGp
'' SIG '' WnOQ4UPworK+VX5EX05sk/e/5nNs3rlHuZTs0G5EH3J8
'' SIG '' //93KB61rF7yhqhh3c0ZLSNug1Sssjqi2cZ4li3tyAwq
'' SIG '' BY2S1duDH9O64z23UMRQVf6ZbFLIMKd3p2+C1Z4CwcdW
'' SIG '' fT2RujFB1OgJfy2x/hTadzgTdJajNttiYHbcDUgIuCIQ
'' SIG '' NOEBSzZeH58mA91k3BqZ2vJibyfW4C3JaXIfCX6P8cqA
'' SIG '' 7i4QfD2nKPegweG9Cr4etSvGD4aat2B7oREHVtWCXeHh
'' SIG '' qrvpa3rY5YvCoC7NoG34Gvhi6h2AhBpJaydMAVO66L2a
'' SIG '' NHbPmjCCBdcwggO/oAMCAQICCmEHdlYAAAAAAAgwDQYJ
'' SIG '' KoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYD
'' SIG '' VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
'' SIG '' MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
'' SIG '' MjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmlj
'' SIG '' YXRlIEF1dGhvcml0eSAyMDEwMB4XDTExMTAxOTE4NDE0
'' SIG '' MloXDTI2MTAxOTE4NTE0MlowgYQxCzAJBgNVBAYTAlVT
'' SIG '' MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
'' SIG '' ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
'' SIG '' YXRpb24xLjAsBgNVBAMTJU1pY3Jvc29mdCBXaW5kb3dz
'' SIG '' IFByb2R1Y3Rpb24gUENBIDIwMTEwggEiMA0GCSqGSIb3
'' SIG '' DQEBAQUAA4IBDwAwggEKAoIBAQDdDLui5C4J4+fF95Zp
'' SIG '' vAAhvWkzM++tBMtUgO4Gg7vFIITZ99KL8ziwq6StLXxi
'' SIG '' eQX/40o/BDUgcOPE52vgnMA2demKMd2NcOXcN7V0RpYo
'' SIG '' W4dgIyy/3EelZ/dRJ55y6wemybkeO1M1fOXT7Ce5hxz+
'' SIG '' uckjCW+oRpHBbpY8QdPLoz9dAmpN7GkfJShcNv/9QxUK
'' SIG '' lOAZtM/fwhLiwlsn7id4MItbKglrIolTYBYswGgdU7rs
'' SIG '' SfOdYYyFaAlzRF19olQr3Xn3Fc81XWwcK1zOvJwji29u
'' SIG '' tSbZNhPDT9YnrrkyO0GSLOHHzXfoqlRO91wLBIdltEMY
'' SIG '' qLLgbRl37Fok+kgDAgMBAAGjggFDMIIBPzAQBgkrBgEE
'' SIG '' AYI3FQEEAwIBADAdBgNVHQ4EFgQUqSkCOY4WxJd4zZD5
'' SIG '' nk+a4XxVr1MwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBD
'' SIG '' AEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8w
'' SIG '' HwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQw
'' SIG '' VgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNy
'' SIG '' b3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9v
'' SIG '' Q2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEB
'' SIG '' BE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNy
'' SIG '' b3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRf
'' SIG '' MjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIB
'' SIG '' ABT8fHFRpXnCbrLvOT68PFIPbis/EBNz/qho0EimNE2K
'' SIG '' lgUm7jFGkGF51v84LkVr9MDlKLjaHY+K2wnXGsdMCjZm
'' SIG '' aozsG9cEkKgYF6SbueJAMjZ2xMFaxr/kBMDqFtOsw2jv
'' SIG '' YqzdVGxQMFim63z+lKdOjvTsfIZzV8JSIXM0WvOjilbI
'' SIG '' BNoHCe34i+PO9H6OrvD2C4oI+z/JHXJ/U7jrvmPg4z0x
'' SIG '' ZbCB5fKszRaknz2osZvCQtCQhF9UHf+J6rodR5BvsHNO
'' SIG '' QZ9An1/loSqyEZFziiEo8M7eczlfPqtcYOzfAxCo0wnp
'' SIG '' 9PaWhbZ/UYhmRxmNorASPYEqaAV3u5FMYnu2wQfHunqH
'' SIG '' NAMOS2J6menK/M5KN8ktpFd8HP493LgPWvrWxLMChQI6
'' SIG '' 6rPZbuRpITfegdH2dRkFZ9OTV14pGznI7i3hzeRFc1vQ
'' SIG '' 0s56qxYZgkZY0F6dgbNnr2w18rzlPyTiNaIKdQb2GFaZ
'' SIG '' 1Hgs0QUb69CIAZ2qEPEF37p+LGO3BpsjIcT5eGziWBcG
'' SIG '' NiuREgPMpNnyLbr5lJ1A7RhF8c6KXGs+qwPTcBgqCmrg
'' SIG '' X0fR1WMKMvKv1zYfKnBa5UJZCHFLV7p+g4HwITz0HMHF
'' SIG '' uZCTDohFk4bpsSCZvpjLxZWkXWLWoGMIIL11EHd9PfNF
'' SIG '' uZ+Xn8tXgG8zqQTPd6RiHFl+MYIWGjCCFhYCAQEwgZww
'' SIG '' gYQxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
'' SIG '' dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
'' SIG '' aWNyb3NvZnQgQ29ycG9yYXRpb24xLjAsBgNVBAMTJU1p
'' SIG '' Y3Jvc29mdCBXaW5kb3dzIFByb2R1Y3Rpb24gUENBIDIw
'' SIG '' MTECEzMAAAF0ad4QizdlqNcAAAAAAXQwDQYJYIZIAWUD
'' SIG '' BAIBBQCgggEEMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
'' SIG '' AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEV
'' SIG '' MC8GCSqGSIb3DQEJBDEiBCCgdyk74xzsIycf4Z+3cNuR
'' SIG '' hvWVWN+pR7h4cHZXcRLiMTA8BgorBgEEAYI3CgMcMS4M
'' SIG '' LEJDMldhN2FqYXZRWStTeWVkR1ZYYkYwanAwMGZFMkRu
'' SIG '' dFROclNQSEVnQ3c9MFoGCisGAQQBgjcCAQwxTDBKoCSA
'' SIG '' IgBNAGkAYwByAG8AcwBvAGYAdAAgAFcAaQBuAGQAbwB3
'' SIG '' AHOhIoAgaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3dp
'' SIG '' bmRvd3MwDQYJKoZIhvcNAQEBBQAEggEAo+hPpBPI36ZP
'' SIG '' L8wISCPjC4KcQfNblu/ztsk0zCPbft73XcitDMEGl4Xj
'' SIG '' AlVNTA8SIwSjlOwSvld+AAPLOf7n0pdFkpe6028dFjr1
'' SIG '' VIUNwr6IkYZtN7YExcVczOO8q1lKtLp/VhjtPpekB058
'' SIG '' 5dWPV8sY2wsAB44UGideqINMDTABjGIHHl3Vg8+QYZl4
'' SIG '' M9PWP6UeiNR7PTUAh086AbpF+XpMRaMvcrLzboFH4xIF
'' SIG '' 1DMjhcOOsG5B7FnAbao4+Kr8MsC+WIkFkX/LpQ5J+pwQ
'' SIG '' QOCLpYZtiwOdBGXYUmTdt6HVW6JP2HyOuwoHVdgWTvMl
'' SIG '' SqnEux9JnQgm2132oFk1vqGCE0YwghNCBgorBgEEAYI3
'' SIG '' AwMBMYITMjCCEy4GCSqGSIb3DQEHAqCCEx8wghMbAgED
'' SIG '' MQ8wDQYJYIZIAWUDBAIBBQAwggE8BgsqhkiG9w0BCRAB
'' SIG '' BKCCASsEggEnMIIBIwIBAQYKKwYBBAGEWQoDATAxMA0G
'' SIG '' CWCGSAFlAwQCAQUABCDyRahh+vERLP7eviN2+D0HjIq3
'' SIG '' 13DtrZ+2LlxaYAw4BAIGWpWBYE4hGBMyMDE4MDMxODIx
'' SIG '' NTY1OC41NTdaMAcCAQGAAgH0oIG4pIG1MIGyMQswCQYD
'' SIG '' VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
'' SIG '' A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
'' SIG '' IENvcnBvcmF0aW9uMQwwCgYDVQQLEwNBT0MxJzAlBgNV
'' SIG '' BAsTHm5DaXBoZXIgRFNFIEVTTjpGNkZGLTJEQTctQkI3
'' SIG '' NTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
'' SIG '' U2VydmljZaCCDsowggZxMIIEWaADAgECAgphCYEqAAAA
'' SIG '' AAACMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJV
'' SIG '' UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
'' SIG '' UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
'' SIG '' cmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBD
'' SIG '' ZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0xMDA3
'' SIG '' MDEyMTM2NTVaFw0yNTA3MDEyMTQ2NTVaMHwxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
'' SIG '' aW1lLVN0YW1wIFBDQSAyMDEwMIIBIjANBgkqhkiG9w0B
'' SIG '' AQEFAAOCAQ8AMIIBCgKCAQEAqR0NvHcRijog7PwTl/X6
'' SIG '' f2mUa3RUENWlCgCChfvtfGhLLF/Fw+Vhwna3PmYrW/AV
'' SIG '' UycEMR9BGxqVHc4JE458YTBZsTBED/FgiIRUQwzXTbg4
'' SIG '' CLNC3ZOs1nMwVyaCo0UN0Or1R4HNvyRgMlhgRvJYR4Yy
'' SIG '' hB50YWeRX4FUsc+TTJLBxKZd0WETbijGGvmGgLvfYfxG
'' SIG '' wScdJGcSchohiq9LZIlQYrFd/XcfPfBXday9ikJNQFHR
'' SIG '' D5wGPmd/9WbAA5ZEfu/QS/1u5ZrKsajyeioKMfDaTgaR
'' SIG '' togINeh4HLDpmc085y9Euqf03GS9pAHBIAmTeM38vMDJ
'' SIG '' RF1eFpwBBU8iTQIDAQABo4IB5jCCAeIwEAYJKwYBBAGC
'' SIG '' NxUBBAMCAQAwHQYDVR0OBBYEFNVjOlyKMZDzQ3t8RhvF
'' SIG '' M2hahW1VMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBB
'' SIG '' MAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8G
'' SIG '' A1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYG
'' SIG '' A1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9z
'' SIG '' b2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0Nl
'' SIG '' ckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQRO
'' SIG '' MEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9z
'' SIG '' b2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIw
'' SIG '' MTAtMDYtMjMuY3J0MIGgBgNVHSABAf8EgZUwgZIwgY8G
'' SIG '' CSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDov
'' SIG '' L3d3dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9k
'' SIG '' ZWZhdWx0Lmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUA
'' SIG '' ZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBt
'' SIG '' AGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAB+aI
'' SIG '' UQ3ixuCYP4FxAz2do6Ehb7Prpsz1Mb7PBeKp/vpXbRkw
'' SIG '' s8LFZslq3/Xn8Hi9x6ieJeP5vO1rVFcIK1GCRBL7uVOM
'' SIG '' zPRgEop2zEBAQZvcXBf/XPleFzWYJFZLdO9CEMivv3/G
'' SIG '' f/I3fVo/HPKZeUqRUgCvOA8X9S95gWXZqbVr5MfO9sp6
'' SIG '' AG9LMEQkIjzP7QOllo9ZKby2/QThcJ8ySif9Va8v/rbl
'' SIG '' jjO7Yl+a21dA6fHOmWaQjP9qYn/dxUoLkSbiOewZSnFj
'' SIG '' nXshbcOco6I8+n99lmqQeKZt0uGc+R38ONiU9MalCpaG
'' SIG '' pL2eGq4EQoO4tYCbIjggtSXlZOz39L9+Y1klD3ouOVd2
'' SIG '' onGqBooPiRa6YacRy5rYDkeagMXQzafQ732D8OE7cQnf
'' SIG '' XXSYIghh2rBQHm+98eEA3+cxB6STOvdlR3jo+KhIq/fe
'' SIG '' cn5ha293qYHLpwmsObvsxsvYgrRyzR30uIUBHoD7G4kq
'' SIG '' VDmyW9rIDVWZeodzOwjmmC3qjeAzLhIp9cAvVCch98is
'' SIG '' TtoouLGp25ayp0Kiyc8ZQU3ghvkqmqMRZjDTu3QyS99j
'' SIG '' e/WZii8bxyGvWbWu3EQ8l1Bx16HSxVXjad5XwdHeMMD9
'' SIG '' zOZN+w2/XU/pnR4ZOC+8z1gFLu8NoFA12u8JJxzVs341
'' SIG '' Hgi62jbb01+P3nSISRIwggTZMIIDwaADAgECAhMzAAAA
'' SIG '' pUgXcif5cL5jAAAAAAClMA0GCSqGSIb3DQEBCwUAMHwx
'' SIG '' CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
'' SIG '' MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
'' SIG '' b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jv
'' SIG '' c29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTE2MDkw
'' SIG '' NzE3NTY1MFoXDTE4MDkwNzE3NTY1MFowgbIxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xDDAKBgNVBAsTA0FPQzEnMCUGA1UE
'' SIG '' CxMebkNpcGhlciBEU0UgRVNOOkY2RkYtMkRBNy1CQjc1
'' SIG '' MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBT
'' SIG '' ZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
'' SIG '' CgKCAQEAtNqS1L1MXvDbVwffWWGBOia20xizacP9+8wj
'' SIG '' b9INzNMbVhbMUE2+wxL7XNbBNLPCOcm0+yH6MtdhbAoK
'' SIG '' Xm5PvgqXL9GtAuTh0O9pgZ8fMsZNhCb94nuo0iIsPPHM
'' SIG '' KzkyL/4b7J5Pb/2Lx1TzhZ1+gktSEo7uD2M9tjdE+k5b
'' SIG '' u1/dj/7mhdcDUhGewZT/NfuHMvYTIJGnmjeh8k+kMlRL
'' SIG '' 4CgU5echhu3Ww5qZNCEmMHUHmKBl6FO30JlalBJmu9tW
'' SIG '' VjTURJFhidC41F86TuWAOsfyUps6ddfcdqggUyDHGbcU
'' SIG '' VXV8+8oCIg6hS4HzsOZZxRqlC4HKFwI+asULjr/BtwID
'' SIG '' AQABo4IBGzCCARcwHQYDVR0OBBYEFOITq0vy7bFguHjx
'' SIG '' haBR/nLnsS+kMB8GA1UdIwQYMBaAFNVjOlyKMZDzQ3t8
'' SIG '' RhvFM2hahW1VMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6
'' SIG '' Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1
'' SIG '' Y3RzL01pY1RpbVN0YVBDQV8yMDEwLTA3LTAxLmNybDBa
'' SIG '' BggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6
'' SIG '' Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWlj
'' SIG '' VGltU3RhUENBXzIwMTAtMDctMDEuY3J0MAwGA1UdEwEB
'' SIG '' /wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
'' SIG '' hvcNAQELBQADggEBADZ9bXkrxi4vJCDKJfU0FYzc8ktH
'' SIG '' B/SjPu6GeAjee4fWBsVY6fvL8xdOH+kxoMbQwmYDn67N
'' SIG '' 8OycK1mTglO6kREcCp7HYhpao9UWyy2m6sDytP95fvsO
'' SIG '' 8DPqThuuXNr0UC7oS6hnGQarx9/BfWEFIjBhzqWYwMAC
'' SIG '' KH1pMSmZIG6kNufilNKEbNwNGknJ9eM2VW1t99VbEdQ5
'' SIG '' ugDfptEky0kxvCWAgmCk6xnmIYJpL0iSslDFDw6dN98e
'' SIG '' vP64cuuTQ/5bxh8bXqBoXd4OFOQi1GoVVuTo4uetj8on
'' SIG '' OGJm1mzbJhIvCYPFrnBB4jkehC0Lse+JcCZSBDLpPAwD
'' SIG '' nmxs+G6hggN0MIICXAIBATCB4qGBuKSBtTCBsjELMAkG
'' SIG '' A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
'' SIG '' BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29m
'' SIG '' dCBDb3Jwb3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYD
'' SIG '' VQQLEx5uQ2lwaGVyIERTRSBFU046RjZGRi0yREE3LUJC
'' SIG '' NzUxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
'' SIG '' IFNlcnZpY2WiJQoBATAJBgUrDgMCGgUAAxUAm8I13fuy
'' SIG '' JisaFDFlUC8dU5Rpgm+ggcEwgb6kgbswgbgxCzAJBgNV
'' SIG '' BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
'' SIG '' VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
'' SIG '' Q29ycG9yYXRpb24xDDAKBgNVBAsTA0FPQzEnMCUGA1UE
'' SIG '' CxMebkNpcGhlciBOVFMgRVNOOjI2NjUtNEMzRi1DNURF
'' SIG '' MSswKQYDVQQDEyJNaWNyb3NvZnQgVGltZSBTb3VyY2Ug
'' SIG '' TWFzdGVyIENsb2NrMA0GCSqGSIb3DQEBBQUAAgUA3llZ
'' SIG '' VzAiGA8yMDE4MDMxODIxMzIwN1oYDzIwMTgwMzE5MjEz
'' SIG '' MjA3WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDeWVlX
'' SIG '' AgEAMAcCAQACAiLiMAcCAQACAhfBMAoCBQDeWqrXAgEA
'' SIG '' MDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwGg
'' SIG '' CjAIAgEAAgMW42ChCjAIAgEAAgMHoSAwDQYJKoZIhvcN
'' SIG '' AQEFBQADggEBAFl3U5WMxEq598q/cBcOi/w0WxfFDx4X
'' SIG '' REbWJxI4Yv8PZIHDXn5FnlYFcEhlq0MX4KBNpaeJa2eG
'' SIG '' 0HOxpqiA807kWSF/ilh80ickkbJ45Q3mGB5Vq0rSiSi0
'' SIG '' Gy0/5ia5HaEYps1/uSILTF///m/tiBIrQp994iYRVyyP
'' SIG '' U3/+NYpvgb2jeeOwmC97wQ9M6vsKgZmuzdPJ+N1Kavgp
'' SIG '' d/0C9wZW+fTCdCGKoZbTlRerly90J5q7YlIBhqVQticB
'' SIG '' NRRj173CpzmmuqRdoaVwtSLNAU9s5zsvi5LU3eMyfou7
'' SIG '' 8Pg1NWMljal6DVgeYqNh8V68xT+8wtRpEXAif+Hzo7jJ
'' SIG '' LFIxggL1MIIC8QIBATCBkzB8MQswCQYDVQQGEwJVUzET
'' SIG '' MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
'' SIG '' bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
'' SIG '' aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFt
'' SIG '' cCBQQ0EgMjAxMAITMwAAAKVIF3In+XC+YwAAAAAApTAN
'' SIG '' BglghkgBZQMEAgEFAKCCATIwGgYJKoZIhvcNAQkDMQ0G
'' SIG '' CyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCDCuMlo
'' SIG '' 06R0vcKgYAsUWfChwREsyNqeU5exuNIhex7KujCB4gYL
'' SIG '' KoZIhvcNAQkQAgwxgdIwgc8wgcwwgbEEFJvCNd37siYr
'' SIG '' GhQxZVAvHVOUaYJvMIGYMIGApH4wfDELMAkGA1UEBhMC
'' SIG '' VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
'' SIG '' B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
'' SIG '' b3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUt
'' SIG '' U3RhbXAgUENBIDIwMTACEzMAAAClSBdyJ/lwvmMAAAAA
'' SIG '' AKUwFgQUVIur2F7aMoyCkF0YEUN9HvP4ZEkwDQYJKoZI
'' SIG '' hvcNAQELBQAEggEAPnQqc3yRWrUvoUnC2haM+uEnypXW
'' SIG '' QnRl2i2VRsyvxouT+bzg2CiJa8DBrZvwrRu0P/OUkioc
'' SIG '' aG1dYjpXM3ptFJ5atYI4LdG6Y8/iDk8/7KvWuJFv3v/3
'' SIG '' D+UXLpe30/kD0TWyPMLDMEk0kQ+RKfFYNt7rJJ9ORHk+
'' SIG '' ZKkPXNsVxXqDzFx0pnjfhBn33AIYxPcczqyUL+044gqZ
'' SIG '' 2BGhecd9iW7u5onmiJJmf9HMGMu0Dut5HIT6ipdHJMIX
'' SIG '' hSHTxqnZNZRSWrABBR3kIermViUwxQrcakutGTr+SV68
'' SIG '' FzpYgvE0uT0u09tf9yNiXhkKdbz7ekvAhbS0ACw3ODwO
'' SIG '' QwQUlg==
'' SIG '' End signature block
