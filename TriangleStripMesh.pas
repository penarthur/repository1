unit TriangleStripMesh;

interface

uses
  SceneObjects, dglOpenGL, glHelpers;

type TTriangleStripMesh = class(TObject)
private
  _Vertices: TVertexAttributeArray;
  _Indices: TIndexArray;
  _Width, _Depth: Integer;

  function IndexLength: Integer;
  procedure GenerateIndices;
public
  constructor Create(Width, Depth: Integer);

  function GetVerticeIndex(X, Z: Double): Integer;
  function GetHeightAt(X, Z: Double): Double;
  function GetSlopeBetween(X1, Z1, X2, Z2: Double): Double;

  procedure CalcNormals;

  property Vertices: TVertexAttributeArray read _Vertices;
  property Indices: TIndexArray read _Indices;

  property Width: Integer read _Width;
  property Depth: Integer read _Depth;
end;

implementation

uses System.Math;

constructor TTriangleStripMesh.Create(Width, Depth: Integer);
var
  I, J, base, index: Integer;
begin
  _Width := Width;
  _Depth := Depth;

  SetLength(_Vertices, Width * Depth);

  for J := 0 to Depth - 1 do
  begin
    base := J * Width;
    for I := 0 to Width - 1 do
    begin
      index := base + I;
      _Vertices[index].PosX := I;
      _Vertices[index].PosY := 0;
      _Vertices[index].PosZ := J;
      _Vertices[index].NormX := 0.0;
      _Vertices[index].NormY := 1.0;
      _Vertices[index].NormZ := 0.0;
      _Vertices[index].TexU := I / Width;
      _Vertices[index].TexV := J / Width;
    end;
  end;

  GenerateIndices;
end;

procedure TTriangleStripMesh.GenerateIndices;
var
  I, J, Index: Integer;
begin
  SetLength(_Indices, IndexLength);

  Index := 0;

  for J := 0 to _Depth - 2 do
  begin
    if J > 0 then
    begin
      _Indices[Index] := J * _Width;
      Inc(Index);
    end;

    for I := 0 to _Width - 1 do
    begin
      _Indices[Index] := J * _Width + I;
      Inc(Index);
      _Indices[Index] := (J + 1) * _Width + I;
      Inc(Index);
    end;

    if J < _Depth - 2 then
    begin
      _Indices[Index] := (J + 1) * _Width + (_Width - 1);
      Inc(Index);
    end;

    if Index > Length(_Indices) then
    begin
      break;
    end;
  end;
end;

function TTriangleStripMesh.GetHeightAt(X, Z: Double): Double;
var
  I, J: Integer;
  ID, JD: Double;
  A, B: Double;
begin
// note this does some averaging over vertices so doesn't use the Index function itself,
  if (X > - Width / 2) and (X < Width / 2) and (Z > - Depth / 2) and (Z < Depth / 2) then
  begin
    I := Trunc(X + Width / 2);
    J := Trunc(Z + Depth / 2);
    ID := X + Width / 2 - I;
    JD := Z + Depth / 2 - J;
    A := _Vertices[I + Width * J].PosY + ID * (_Vertices[I + 1 + Width * J].PosY - _Vertices[I + Width * J].PosY);
    B := _Vertices[I + Width * J].PosY + JD * (_Vertices[I + Width * (J + 1)].PosY - _Vertices[I + Width * (J + 1)].PosY);
    Result := (A + B) / 2;
  end
  else
    Result := 0;
end;

function TTriangleStripMesh.GetSlopeBetween(X1, Z1, X2, Z2: Double): Double;
var
  A, B, C, D: Double;
begin
  A := GetHeightAt(X1, Z1);
  B := GetHeightAt(X2, Z2);
  C := B - A;
  D := Sqrt((X1 - X2) * (X1 - X2) + (Z1 - Z2) * (Z1 - Z2));

  Result := Arctan2(C, D);
end;

function TTriangleStripMesh.GetVerticeIndex(X, Z: Double): Integer;
var
  I, J: Integer;
begin
  if (X > - Width / 2) and (X < Width / 2) and (Z > - Depth / 2) and (Z < Depth / 2) then
  begin
    I := Trunc(X + Width / 2 + 0.5);
    J := Trunc(Z + Depth / 2 + 0.5);
    Result := I + Width * J;
  end
  else
    Result := -1;
end;

procedure TTriangleStripMesh.CalcNormals;
var
  Base, I, J, INdex: Integer;
  U, V, N: TVector3f;
begin
  for J := 0 to _Depth - 1 do
  begin
    base := J * _Width;
    for I := 0 to _Width - 1 do
    begin
      index := base + I;

      U[0] := 1;
      U[2] := 0;
      if I = 0 then
        U[1] := _Vertices[index + 1].PosY - _Vertices[index].PosY
      else if I = _Width - 1 then
        U[1] := _Vertices[index].PosY - _Vertices[index - 1].PosY
      else
        U[1] := (_Vertices[index + 1].PosY - _Vertices[index - 1].PosY) / 2;

      V[0] := 0;
      if J = 0 then
        V[1] := _Vertices[index + _Width].PosY - _Vertices[index].PosY
      else if J = _Depth - 1 then
        V[1] := _Vertices[index].PosY - _Vertices[index - _Width].PosY
      else
        V[1] := (_Vertices[index + _Width].PosY - _Vertices[index - _Width].PosY) / 2;
      V[2] := 1;

      N := Cross(U, V);
      Normalize(N);

      _Vertices[index].NormX := N[0];
      _Vertices[index].NormY := N[1];
      _Vertices[index].NormZ := N[2];
    end;
  end;
end;

//  http://www.learnopengles.com/android-lesson-eight-an-introduction-to-index-buffer-objects-ibos/

  // int numIndPerRow = plane_width * 2 + 2;
  // int numIndDegensReq = (plane_height - 1) * 2;
  // int total_indices = numIndPerRow * plane_height + numIndDegensReq;

  // "numStripes = height - 1", "numIndices = numStripes * (2 * width - 1) + 1;

function TTriangleStripMesh.IndexLength: Integer;
begin
  Result := (_Depth - 1) * (2 * _Width) + 2 * (_Depth - 2);
end;

end.
