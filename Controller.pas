unit Controller;

interface

uses
  TDXInput_TLB, ActiveX;

type
  TController = class(TObject)
  private
    Device: ISimpleDevice;
    Sensor: ISensor;
    SensorPeriod: Double;
  public
    Connected : Boolean;
    RX, RY, RZ, RA: Double;
    TX, TY, TZ, TL: Double;
    constructor Create;
    destructor Destroy; override;
    function Poll: Boolean;
  end;

implementation

constructor TController.Create;
var
  IHelper: IUnknown;
  LR: HRESULT;
begin
  Connected := False;

  CoInitialize(nil);

  LR := CoCreateInstance(CLASS_Device, nil, CLSCTX_INPROC_SERVER,
    ISimpleDevice, IHelper);

  if LR = S_OK then
  begin
    LR := IHelper.QueryInterface(ISimpleDevice, Device);
    if LR = S_OK then
      Device.Connect;
    if Device.IsConnected then
    begin
      Sensor := Device.Sensor;
      Connected := True;
    end;
  end;
end;

destructor TController.Destroy;
begin
  CoUninitialize;

  Inherited;
end;

function TController.Poll: Boolean;
begin
  Result := False;

  if Connected and Assigned(Sensor) then
  begin
    SensorPeriod := Sensor.Period;

    RX := Sensor.Rotation.X;
    RY := Sensor.Rotation.Y;
    RZ := Sensor.Rotation.Z;
    RA := Sensor.Rotation.Angle;

    TX := Sensor.Translation.X;
    TY := Sensor.Translation.Y;
    TZ := Sensor.Translation.Z;
    TL := Sensor.Translation.Length;

    Result := True;
  end;
end;

end.
