{$IFDEF PROFILE} {$WARNINGS OFF} {$ENDIF }
{$IFDEF PROFILE} {    Do not delete previous line(s) !!! } {$ENDIF }
{$IFDEF PROFILE} { Otherwise sources can not be cleaned !!! } {$ENDIF }
{$IFDEF PROFILE} {$INLINE OFF} {$ENDIF }
unit TDxInput_TLB;

// ************************************************************************ //
// WARNING                                                                    
// -------                                                                    
// The types declared in this file were generated from data read from a       
// Type Library. If this type library is explicitly or indirectly (via        
// another type library referring to this type library) re-imported, or the   
// 'Refresh' command of the Type Library Editor activated while editing the   
// Type Library, the contents of this file will be regenerated and all        
// manual modifications will be lost.                                         
// ************************************************************************ //

// $Rev: 52393 $
// File generated on 21/03/2018 15:39:34 from Type Library described below.

// ************************************************************************  //
// Type Lib: C:\Program Files\3Dconnexion\3DxWare\3DxWinCore64\Win32\TDxInput.dll (1)
// LIBID: {7858B9E0-5793-4BE4-9B53-661D922790D2}
// LCID: 0
// Helpfile: 
// HelpString: 3Dconnexion TDxInput 1.0 Type Library
// DepndLst: 
//   (1) v2.0 stdole, (C:\Windows\SysWOW64\stdole2.tlb)
// SYS_KIND: SYS_WIN32
// Errors:
//   Hint: Parameter 'label' of IKeyboard.GetKeyLabel changed to 'label_'
//   Hint: Symbol 'Type' renamed to 'type_'
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers. 
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}

interface

uses Winapi.Windows, System.Classes, System.Variants, System.Win.StdVCL, Vcl.Graphics, Vcl.OleServer, Winapi.ActiveX{$IFNDEF PROFILE};{$ELSE}{},Profint;{$ENDIF}
  

// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:        
//   Type Libraries     : LIBID_xxxx                                      
//   CoClasses          : CLASS_xxxx                                      
//   DISPInterfaces     : DIID_xxxx                                       
//   Non-DISP interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  TDxInputMajorVersion = 1;
  TDxInputMinorVersion = 0;

  LIBID_TDxInput: TGUID = '{7858B9E0-5793-4BE4-9B53-661D922790D2}';

  IID_IAngleAxis: TGUID = '{1EF2BAFF-54E9-4706-9F61-078F7134FD35}';
  CLASS_AngleAxis: TGUID = '{512A6C3E-3010-401B-8623-E413E2ACC138}';
  IID_IVector3D: TGUID = '{8C2AA71D-2B23-43F5-A6ED-4DF57E9CD8D5}';
  CLASS_Vector3D: TGUID = '{740A7479-C7C1-44DA-8A84-B5DE63C78B32}';
  DIID__ISensorEvents: TGUID = '{E6929A4A-6F41-46C6-9252-A8CC53472CB1}';
  IID_ISensor: TGUID = '{F3A6775E-6FA1-4829-BF32-5B045C29078F}';
  CLASS_Sensor: TGUID = '{85004B00-1AA7-4777-B1CE-8427301B942D}';
  DIID__IKeyboardEvents: TGUID = '{6B6BB0A8-4491-40CF-B1A9-C15A801FE151}';
  IID_IKeyboard: TGUID = '{D6F968E7-2993-48D7-AF24-8B602D925B2C}';
  CLASS_Keyboard: TGUID = '{25BBE090-583A-4903-A61B-D0EC629AC4EC}';
  DIID__ISimpleDeviceEvents: TGUID = '{8FE3A216-E235-49A6-9136-F9D81FDADEF5}';
  IID_ISimpleDevice: TGUID = '{CB3BF65E-0816-482A-BB11-64AF1E837812}';
  CLASS_Device: TGUID = '{82C5AB54-C92C-4D52-AAC5-27E25E22604C}';
  IID_ITDxInfo: TGUID = '{00612962-8FB6-47B2-BF98-4E8C0FF5F559}';
  CLASS_TDxInfo: TGUID = '{1A960ECE-0E57-4A68-B694-8373114F1FF4}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  IAngleAxis = interface;
  IAngleAxisDisp = dispinterface;
  IVector3D = interface;
  IVector3DDisp = dispinterface;
  _ISensorEvents = dispinterface;
  ISensor = interface;
  ISensorDisp = dispinterface;
  _IKeyboardEvents = dispinterface;
  IKeyboard = interface;
  IKeyboardDisp = dispinterface;
  _ISimpleDeviceEvents = dispinterface;
  ISimpleDevice = interface;
  ISimpleDeviceDisp = dispinterface;
  ITDxInfo = interface;
  ITDxInfoDisp = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library                       
// (NOTE: Here we map each CoClass to its Default Interface)              
// *********************************************************************//
  AngleAxis = IAngleAxis;
  Vector3D = IVector3D;
  Sensor = ISensor;
  Keyboard = IKeyboard;
  Device = ISimpleDevice;
  TDxInfo = ITDxInfo;


// *********************************************************************//
// Interface: IAngleAxis
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {1EF2BAFF-54E9-4706-9F61-078F7134FD35}
// *********************************************************************//
  IAngleAxis = interface(IDispatch)
    ['{1EF2BAFF-54E9-4706-9F61-078F7134FD35}']
    function Get_X: Double; safecall;
    procedure Set_X(pVal: Double); safecall;
    function Get_Y: Double; safecall;
    procedure Set_Y(pVal: Double); safecall;
    function Get_Z: Double; safecall;
    procedure Set_Z(pVal: Double); safecall;
    function Get_Angle: Double; safecall;
    procedure Set_Angle(pVal: Double); safecall;
    property X: Double read Get_X write Set_X;
    property Y: Double read Get_Y write Set_Y;
    property Z: Double read Get_Z write Set_Z;
    property Angle: Double read Get_Angle write Set_Angle;
  end;

// *********************************************************************//
// DispIntf:  IAngleAxisDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {1EF2BAFF-54E9-4706-9F61-078F7134FD35}
// *********************************************************************//
  IAngleAxisDisp = dispinterface
    ['{1EF2BAFF-54E9-4706-9F61-078F7134FD35}']
    property X: Double dispid 1;
    property Y: Double dispid 2;
    property Z: Double dispid 3;
    property Angle: Double dispid 4;
  end;

// *********************************************************************//
// Interface: IVector3D
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {8C2AA71D-2B23-43F5-A6ED-4DF57E9CD8D5}
// *********************************************************************//
  IVector3D = interface(IDispatch)
    ['{8C2AA71D-2B23-43F5-A6ED-4DF57E9CD8D5}']
    function Get_X: Double; safecall;
    procedure Set_X(pVal: Double); safecall;
    function Get_Y: Double; safecall;
    procedure Set_Y(pVal: Double); safecall;
    function Get_Z: Double; safecall;
    procedure Set_Z(pVal: Double); safecall;
    function Get_Length: Double; safecall;
    procedure Set_Length(pVal: Double); safecall;
    property X: Double read Get_X write Set_X;
    property Y: Double read Get_Y write Set_Y;
    property Z: Double read Get_Z write Set_Z;
    property Length: Double read Get_Length write Set_Length;
  end;

// *********************************************************************//
// DispIntf:  IVector3DDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {8C2AA71D-2B23-43F5-A6ED-4DF57E9CD8D5}
// *********************************************************************//
  IVector3DDisp = dispinterface
    ['{8C2AA71D-2B23-43F5-A6ED-4DF57E9CD8D5}']
    property X: Double dispid 1;
    property Y: Double dispid 2;
    property Z: Double dispid 3;
    property Length: Double dispid 4;
  end;

// *********************************************************************//
// DispIntf:  _ISensorEvents
// Flags:     (4096) Dispatchable
// GUID:      {E6929A4A-6F41-46C6-9252-A8CC53472CB1}
// *********************************************************************//
  _ISensorEvents = dispinterface
    ['{E6929A4A-6F41-46C6-9252-A8CC53472CB1}']
    function SensorInput: HResult; dispid 1;
  end;

// *********************************************************************//
// Interface: ISensor
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {F3A6775E-6FA1-4829-BF32-5B045C29078F}
// *********************************************************************//
  ISensor = interface(IDispatch)
    ['{F3A6775E-6FA1-4829-BF32-5B045C29078F}']
    function Get_Translation: IVector3D; safecall;
    function Get_Rotation: IAngleAxis; safecall;
    function Get_Device: IDispatch; safecall;
    function Get_Period: Double; safecall;
    property Translation: IVector3D read Get_Translation;
    property Rotation: IAngleAxis read Get_Rotation;
    property Device: IDispatch read Get_Device;
    property Period: Double read Get_Period;
  end;

// *********************************************************************//
// DispIntf:  ISensorDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {F3A6775E-6FA1-4829-BF32-5B045C29078F}
// *********************************************************************//
  ISensorDisp = dispinterface
    ['{F3A6775E-6FA1-4829-BF32-5B045C29078F}']
    property Translation: IVector3D readonly dispid 1;
    property Rotation: IAngleAxis readonly dispid 2;
    property Device: IDispatch readonly dispid 3;
    property Period: Double readonly dispid 4;
  end;

// *********************************************************************//
// DispIntf:  _IKeyboardEvents
// Flags:     (4096) Dispatchable
// GUID:      {6B6BB0A8-4491-40CF-B1A9-C15A801FE151}
// *********************************************************************//
  _IKeyboardEvents = dispinterface
    ['{6B6BB0A8-4491-40CF-B1A9-C15A801FE151}']
    function KeyDown(keyCode: SYSINT): HResult; dispid 1;
    function KeyUp(keyCode: SYSINT): HResult; dispid 2;
  end;

// *********************************************************************//
// Interface: IKeyboard
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {D6F968E7-2993-48D7-AF24-8B602D925B2C}
// *********************************************************************//
  IKeyboard = interface(IDispatch)
    ['{D6F968E7-2993-48D7-AF24-8B602D925B2C}']
    function Get_Keys: Integer; safecall;
    function Get_ProgrammableKeys: Integer; safecall;
    function GetKeyLabel(key: Integer): WideString; safecall;
    function GetKeyName(key: Integer): WideString; safecall;
    function Get_Device: IDispatch; safecall;
    function IsKeyDown(key: Integer): WordBool; safecall;
    function IsKeyUp(key: Integer): WordBool; safecall;
    property Keys: Integer read Get_Keys;
    property ProgrammableKeys: Integer read Get_ProgrammableKeys;
    property Device: IDispatch read Get_Device;
  end;

// *********************************************************************//
// DispIntf:  IKeyboardDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {D6F968E7-2993-48D7-AF24-8B602D925B2C}
// *********************************************************************//
  IKeyboardDisp = dispinterface
    ['{D6F968E7-2993-48D7-AF24-8B602D925B2C}']
    property Keys: Integer readonly dispid 1;
    property ProgrammableKeys: Integer readonly dispid 2;
    function GetKeyLabel(key: Integer): WideString; dispid 3;
    function GetKeyName(key: Integer): WideString; dispid 4;
    property Device: IDispatch readonly dispid 5;
    function IsKeyDown(key: Integer): WordBool; dispid 6;
    function IsKeyUp(key: Integer): WordBool; dispid 7;
  end;

// *********************************************************************//
// DispIntf:  _ISimpleDeviceEvents
// Flags:     (4096) Dispatchable
// GUID:      {8FE3A216-E235-49A6-9136-F9D81FDADEF5}
// *********************************************************************//
  _ISimpleDeviceEvents = dispinterface
    ['{8FE3A216-E235-49A6-9136-F9D81FDADEF5}']
    function DeviceChange(reserved: Integer): HResult; dispid 1;
  end;

// *********************************************************************//
// Interface: ISimpleDevice
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {CB3BF65E-0816-482A-BB11-64AF1E837812}
// *********************************************************************//
  ISimpleDevice = interface(IDispatch)
    ['{CB3BF65E-0816-482A-BB11-64AF1E837812}']
    procedure Connect; safecall;
    procedure Disconnect; safecall;
    function Get_Sensor: ISensor; safecall;
    function Get_Keyboard: IKeyboard; safecall;
    function Get_type_: Integer; safecall;
    function Get_IsConnected: WordBool; safecall;
    procedure LoadPreferences(const PreferencesName: WideString); safecall;
    property Sensor: ISensor read Get_Sensor;
    property Keyboard: IKeyboard read Get_Keyboard;
    property type_: Integer read Get_type_;
    property IsConnected: WordBool read Get_IsConnected;
  end;

// *********************************************************************//
// DispIntf:  ISimpleDeviceDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {CB3BF65E-0816-482A-BB11-64AF1E837812}
// *********************************************************************//
  ISimpleDeviceDisp = dispinterface
    ['{CB3BF65E-0816-482A-BB11-64AF1E837812}']
    procedure Connect; dispid 1;
    procedure Disconnect; dispid 2;
    property Sensor: ISensor readonly dispid 3;
    property Keyboard: IKeyboard readonly dispid 4;
    property type_: Integer readonly dispid 5;
    property IsConnected: WordBool readonly dispid 6;
    procedure LoadPreferences(const PreferencesName: WideString); dispid 7;
  end;

// *********************************************************************//
// Interface: ITDxInfo
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {00612962-8FB6-47B2-BF98-4E8C0FF5F559}
// *********************************************************************//
  ITDxInfo = interface(IDispatch)
    ['{00612962-8FB6-47B2-BF98-4E8C0FF5F559}']
    function RevisionNumber: WideString; safecall;
  end;

// *********************************************************************//
// DispIntf:  ITDxInfoDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {00612962-8FB6-47B2-BF98-4E8C0FF5F559}
// *********************************************************************//
  ITDxInfoDisp = dispinterface
    ['{00612962-8FB6-47B2-BF98-4E8C0FF5F559}']
    function RevisionNumber: WideString; dispid 1;
  end;

// *********************************************************************//
// The Class CoAngleAxis provides a Create and CreateRemote method to          
// create instances of the default interface IAngleAxis exposed by              
// the CoClass AngleAxis. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoAngleAxis = class
    class function Create: IAngleAxis;
    class function CreateRemote(const MachineName: string): IAngleAxis;
  end;

// *********************************************************************//
// The Class CoVector3D provides a Create and CreateRemote method to          
// create instances of the default interface IVector3D exposed by              
// the CoClass Vector3D. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoVector3D = class
    class function Create: IVector3D;
    class function CreateRemote(const MachineName: string): IVector3D;
  end;

// *********************************************************************//
// The Class CoSensor provides a Create and CreateRemote method to          
// create instances of the default interface ISensor exposed by              
// the CoClass Sensor. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoSensor = class
    class function Create: ISensor;
    class function CreateRemote(const MachineName: string): ISensor;
  end;

// *********************************************************************//
// The Class CoKeyboard provides a Create and CreateRemote method to          
// create instances of the default interface IKeyboard exposed by              
// the CoClass Keyboard. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoKeyboard = class
    class function Create: IKeyboard;
    class function CreateRemote(const MachineName: string): IKeyboard;
  end;

// *********************************************************************//
// The Class CoDevice provides a Create and CreateRemote method to          
// create instances of the default interface ISimpleDevice exposed by              
// the CoClass Device. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoDevice = class
    class function Create: ISimpleDevice;
    class function CreateRemote(const MachineName: string): ISimpleDevice;
  end;

// *********************************************************************//
// The Class CoTDxInfo provides a Create and CreateRemote method to          
// create instances of the default interface ITDxInfo exposed by              
// the CoClass TDxInfo. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoTDxInfo = class
    class function Create: ITDxInfo;
    class function CreateRemote(const MachineName: string): ITDxInfo;
  end;

implementation

uses System.Win.ComObj;

class function CoAngleAxis.Create: IAngleAxis;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,2 or $61020000); {$ENDIF}
  Result := CreateComObject(CLASS_AngleAxis) as IAngleAxis;
{$IFDEF PROFILE}finally; Profint.ProfExit(2); end;{$ENDIF}
end;

class function CoAngleAxis.CreateRemote(const MachineName: string): IAngleAxis;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,3 or $61020000); {$ENDIF}
  Result := CreateRemoteComObject(MachineName, CLASS_AngleAxis) as IAngleAxis;
{$IFDEF PROFILE}finally; Profint.ProfExit(3); end;{$ENDIF}
end;

class function CoVector3D.Create: IVector3D;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,4 or $61020000); {$ENDIF}
  Result := CreateComObject(CLASS_Vector3D) as IVector3D;
{$IFDEF PROFILE}finally; Profint.ProfExit(4); end;{$ENDIF}
end;

class function CoVector3D.CreateRemote(const MachineName: string): IVector3D;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,5 or $61020000); {$ENDIF}
  Result := CreateRemoteComObject(MachineName, CLASS_Vector3D) as IVector3D;
{$IFDEF PROFILE}finally; Profint.ProfExit(5); end;{$ENDIF}
end;

class function CoSensor.Create: ISensor;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,6 or $61020000); {$ENDIF}
  Result := CreateComObject(CLASS_Sensor) as ISensor;
{$IFDEF PROFILE}finally; Profint.ProfExit(6); end;{$ENDIF}
end;

class function CoSensor.CreateRemote(const MachineName: string): ISensor;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,7 or $61020000); {$ENDIF}
  Result := CreateRemoteComObject(MachineName, CLASS_Sensor) as ISensor;
{$IFDEF PROFILE}finally; Profint.ProfExit(7); end;{$ENDIF}
end;

class function CoKeyboard.Create: IKeyboard;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,8 or $61020000); {$ENDIF}
  Result := CreateComObject(CLASS_Keyboard) as IKeyboard;
{$IFDEF PROFILE}finally; Profint.ProfExit(8); end;{$ENDIF}
end;

class function CoKeyboard.CreateRemote(const MachineName: string): IKeyboard;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,9 or $61020000); {$ENDIF}
  Result := CreateRemoteComObject(MachineName, CLASS_Keyboard) as IKeyboard;
{$IFDEF PROFILE}finally; Profint.ProfExit(9); end;{$ENDIF}
end;

class function CoDevice.Create: ISimpleDevice;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,10 or $61020000); {$ENDIF}
  Result := CreateComObject(CLASS_Device) as ISimpleDevice;
{$IFDEF PROFILE}finally; Profint.ProfExit(10); end;{$ENDIF}
end;

class function CoDevice.CreateRemote(const MachineName: string): ISimpleDevice;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,11 or $61020000); {$ENDIF}
  Result := CreateRemoteComObject(MachineName, CLASS_Device) as ISimpleDevice;
{$IFDEF PROFILE}finally; Profint.ProfExit(11); end;{$ENDIF}
end;

class function CoTDxInfo.Create: ITDxInfo;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,12 or $61020000); {$ENDIF}
  Result := CreateComObject(CLASS_TDxInfo) as ITDxInfo;
{$IFDEF PROFILE}finally; Profint.ProfExit(12); end;{$ENDIF}
end;

class function CoTDxInfo.CreateRemote(const MachineName: string): ITDxInfo;
begin
{$IFDEF PROFILE}Profint.ProfStop; Try; Profint.ProfEnter(NIL,13 or $61020000); {$ENDIF}
  Result := CreateRemoteComObject(MachineName, CLASS_TDxInfo) as ITDxInfo;
{$IFDEF PROFILE}finally; Profint.ProfExit(13); end;{$ENDIF}
end;

end.
