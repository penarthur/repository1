unit DiamondSquareEngine;

interface

uses Math;

type
  TDiamondSquareEngine = class(TObject)
  private
    _max, _size: Integer;

    function GetV(x, y: Integer): Double;
    procedure SetV(x, y: Integer; Val: Double);
  public
    Map: Array of Double;

    constructor Create(ASize: Integer);
    procedure Generate(roughness: Double);

    property Size: Integer read _size;
  end;

implementation

constructor TDiamondSquareEngine.Create(ASize: Integer);
begin
  _size := Trunc(Math.Power(2, Log2(ASize))) + 1;
  _max := _size - 1;

  SetLength(Map, _size * _size);
end;

function TDiamondSquareEngine.GetV(x, y: Integer): Double;
var
  xx, yy: Integer;
begin
  if (x < 0) or (x > _max) or (y < 0) or (y > _max) then
  begin
    if x < 0 then
      xx := x + _max
    else if x > _max then
      xx := x - _max
    else
      xx := x;
    if y < 0 then
      yy := y + _max
    else if y > _max then
      yy := y - _max
    else
      yy := y;
    result := Map[xx + _size * yy];
  end
  else
    result := Map[x + _size * y];
end;

procedure TDiamondSquareEngine.SetV(x, y: Integer; Val: Double);
begin
  if not((x < 0) or (x > _max) or (y < 0) or (y > _max)) then
    Map[x + _size * y] := Val;
end;

procedure TDiamondSquareEngine.Generate(roughness: Double);

  procedure square(x, y, Size: Integer; offset: Double);
  var
    ave: Double;
  begin
    ave := 0.25 * (GetV(x - Size, y - Size) + GetV(x + Size, y - Size) +
      GetV(x + Size, y + Size) + GetV(x - Size, y + Size));

    SetV(x, y, ave + offset);
  end;

  procedure diamond(x, y, Size: Integer; offset: Double);
  var
    ave: Double;
  begin
    ave := 0.25 * (GetV(x, y - Size) + GetV(x + Size, y) + GetV(x, y + Size) +
      GetV(x - Size, y));

    SetV(x, y, ave + offset);
  end;

  procedure divide(Size: Integer);
  var
    x, y: Integer;
    half: Integer;
    scale: Double;
  begin
    half := Size div 2;
    if half < 1 then
      exit;

    scale := roughness * Size;

    y := half;
    while y < _max do
    begin
      x := half;
      while x < _max do
      begin
        square(x, y, half, Random * scale * 2 - scale);
        x := x + Size;
      end;
      y := y + Size;
    end;

    y := 0;
    while y <= _max do
    begin
      x := (y + half) mod Size;
      while x <= _max do
      begin
        diamond(x, y, half, Random * scale * 2 - scale);
        x := x + Size;
      end;
      y := y + half;
    end;

    divide(Size div 2);

  end;

begin
  SetV(0, 0, _max * roughness / 2);
  SetV(_max, 0, 0);
  SetV(_max, _max, -_max * roughness / 2);
  SetV(0, _max, 0);

  divide(_max);
end;

end.
