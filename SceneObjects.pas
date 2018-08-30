unit SceneObjects;

interface

uses
  dglOpenGL, Generics.Collections, GLHelpers, SysUtils, Math, Windows;

type
  TObjectNormalisation = (onNone, onCentre, onCentreBottom);

  TVertexAttribute = packed record
    PosX, PosY, PosZ: GLFloat;
    NormX, NormY, NormZ: GLFloat;
    TexU, TexV: GLFloat;
    Extra: GLFloat;
  end;

  TVertexAttributeArray = packed Array of TVertexAttribute;

  TIndexArray = Array of GLUInt;

  TMyEffectParms = packed record
    Emission: TGLVectorf4;
    Ambient: TGLVectorf4;
    Diffuse: TGLVectorf4;
    Specular: TGLVectorf4;
    Transparent: TGLVectorf4;
    Transparency: GLfloat;
    IOR: GLfloat;
    Shininess: GLFloat;
    Spare: GLFloat;
  end;

  TMyEffect = class(TObject)
  public
    Name: String;
    LightingModel: String;
    Parms: TMyEffectParms;
  end;

  TTexture = packed record
    Name: GLUint;
    ScaleFactor: Single;
  end;

  TOpenGLData = class(TObject)
    VBO: GLUInt;
    VBOLength: Integer;
    VertexAttributeSize: GLUInt;
    EBO: GLUInt;
    EBOLength: Integer;
    constructor Create;
    procedure Copy(Source: TOpenGLData);
  end;

  TMesh = class(TObject)
  public
    Name: String;
    OpenGLData: TOpenGLData;
    Drawmode: GLUInt;
    Colour: TGLVectorf4;
    Effect: TMyEffect;
    Textures: TList<TTexture>;
    constructor Create(AName: String);
    destructor Destroy; override;
    procedure SetColour(R, G, B, A: Single);
    procedure AddVertices(VertStart: Pointer; VertCount: Integer);
    procedure AddIndexes(IdxStart: Pointer; IdxCount: Integer);
    procedure AddTexture(Tex: GLUInt; Factor: Single);
  end;

  TSceneModel = class(TObject)
  public
    Name: String;
    Meshes: TObjectList<TMesh>;
    Orientation: TGLVectorf3;
    Scale: TGLVectorf3;
    BBMin, BBMax: TGLVectorf3;
    constructor Create(AName: String);
    destructor Destroy; override;
    procedure AddMesh(Mesh: TMesh);
    function InitMesh: TMesh;
  end;

  TSceneObject = class(TObject)
  public
    Name: String;
    Position: TGLVectorf3;
    Velocity: TGLVectorf3;
    Rotation: TGLVectorf3;
    Spin: TGLVectorf3;
    Scale: TGLVectorf3;
    Shift: TGLVectorf3;
    Wobble: TGLVectorf3;
    ModelOffset: TGLVectorf3;
    MinPos, MaxPos: TGLVectorf3;
    Weightless, Damped, Active: Boolean;
    ActivatedTC, LifetimeMS: UInt32;
    Colour: TGLVectorf4;
    ShaderProgram: glHandle;
    Model: TSceneModel;
    constructor Create(ObjectName: String);
    destructor Destroy; override;
    function GetModelMatrix: TGLMatrixF4;
    function TestCollision(Object2: TSceneObject; DebugPoints: Array of TSceneObject): Boolean;
    procedure InitRandom(minx, miny, minz, maxx, maxy, maxz: GLFLOAT);
    procedure InitUnit;
    procedure SetColour(R, G, B, A: GLFloat);
    procedure Move(DeltaTime: Double);
    procedure SetPosition(px, py, pz: GLFloat);
    procedure SetShift(sx, sy, sz: GLFloat);
    procedure SetVelocity(vx, vy, vz: GLFloat);
    procedure SetRotation(rx, ry, rz: GLFloat);
    procedure SetSpin(sx, sy, sz: GLFloat);
    procedure SetModelOffset(ox, oy, oz: GLFloat);
    procedure SetWobble(wx, wy, wz: GLFloat);
    procedure SetScale(mx, my, mz: GLFloat); overload;
    procedure SetScale(m: GLFloat); overload;
    procedure Accelerate(V: GLFloat);
    procedure Turn(delta: GLFloat; lagginess: GLFloat);
    procedure SetBounds(X0, Y0, Z0, X1, Y1, Z1: GLFloat); overload;
    procedure SetBounds(D: GLFloat); overload;
    procedure Activate(LifeTime: Integer);
    procedure Deactivate;
    procedure CheckLifespan;
  end;

implementation

const
  G = 10;
  Epsilon = 2.22045E-016; // take from c++ sampls

constructor TOpenGLData.Create;
begin
  VBO := 0;
  VBOLength := 0;
  VertexAttributeSize := 3; // defaults to just xyz
  EBO := 0;
  EBOLength := 0;
end;

procedure TOpenGLData.Copy(Source: TOpenGLData);
begin
  VBO := Source.VBO;
  VBOLength := Source.VBOLength;
  VertexAttributeSize := Source.VertexAttributeSize;
  EBO := Source.EBO;
  EBOLength := Source.EBOLength;
end;

constructor TMesh.Create(AName: String);
begin
  Name := AName;
  Drawmode := GL_NONE;
  OpenGLData := TOpenGLData.Create;
  Effect := nil;
  Colour[0] := 0.5;
  Colour[1] := 0.5;
  Colour[2] := 0.5;
  Colour[3] := 0.5;
  Textures := TList<TTexture>.Create;
end;

procedure TMesh.SetColour(R, G, B, A: Single);
begin
  Colour[0] := R;
  Colour[1] := G;
  Colour[2] := B;
  Colour[3] := A;
end;

destructor TMesh.Destroy;
begin
  Effect.Free;
  Textures.Free;
  OpenGLData.Free;
  inherited;
end;

procedure TMesh.AddVertices(VertStart: Pointer; VertCount: Integer);
begin
  if OpenGLData.VBO = 0 then
    glGenBuffers(1, @OpenGLData.VBO);
  glBindBuffer(GL_ARRAY_BUFFER, OpenGLData.VBO);
  OpenGLData.VBOLength := VertCount;
  glBufferData(GL_ARRAY_BUFFER, VertCount * SizeOf(TVertexAttribute),
    VertStart, GL_STATIC_DRAW);
  OpenGLData.VertexAttributeSize := SizeOf(TVertexAttribute) div SizeOf(GLFloat);
end;

procedure TMesh.AddIndexes(IdxStart: Pointer; IdxCount: Integer);
begin
  if OpenGLData.EBO = 0 then
    glGenBuffers(1, @OpenGLData.EBO);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, OpenGLData.EBO);
  OpenGLData.EBOLength := IdxCount;
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, IdxCount * SizeOf(GLUInt),
    IdxStart, GL_STATIC_DRAW);
end;

procedure TMesh.AddTexture(Tex: GLUInt; Factor: Single);
var
  T: TTexture;
begin
  T.Name := Tex;
  T.ScaleFactor := Factor;
  Textures.Add(T);
end;

constructor TSceneModel.Create(AName: String);
begin
  Name := AName;
  Meshes := TObjectList<TMesh>.Create(False);
  Orientation[0] := 0.0;
  Orientation[1] := 0.0;
  Orientation[2] := 0.0;
  Scale[0] := 1.0;
  Scale[1] := 1.0;
  Scale[2] := 1.0;
end;

constructor TSceneObject.Create(ObjectName: String);
begin
  Name := ObjectName;
  ShaderProgram := 0;
  LifetimeMS := 0;
  ActivatedTC := 0;
  InitUnit;
end;

procedure TSceneObject.SetColour(R, G, B, A: Single);
begin
  Colour[0] := R;
  Colour[1] := G;
  Colour[2] := B;
  Colour[3] := A;
end;

procedure TSceneModel.AddMesh(Mesh: TMesh);
begin
  Meshes.Add(Mesh);
end;

function TSceneModel.InitMesh: TMesh;
begin
  Result := TMesh.Create(Name);
  AddMesh(Result);
end;

destructor TSceneModel.Destroy;
var
  M: TMesh;
begin
  for M in Meshes do
    M.Free;

  Meshes.Clear;
  Meshes.Free;

  inherited;
end;

destructor TSceneObject.Destroy;
begin
  inherited;
end;

procedure TSceneObject.Activate(LifeTime: Integer);
begin
  ActivatedTC := GetTickCount;
  LifetimeMS := LifeTime * 1000;
  Active := True;
end;

procedure TSceneObject.CheckLifespan;
begin
  if Active and (ActivatedTC <> 0) then
  begin
    if GetTickCount - ActivatedTC > LifetimeMS then
    begin
      Active := False;
      ActivatedTC := 0;
      LifetimeMS := 0;
    end;
  end;
end;

procedure TSceneObject.Deactivate;
begin
  Active := False;
end;

procedure TSceneObject.SetBounds(X0, Y0, Z0, X1, Y1, Z1: GLFloat);
begin
  MinPos[0] := X0;
  MinPos[1] := Y0;
  MinPos[2] := Z0;
  MaxPos[0] := X1;
  MaxPos[1] := Y1;
  MaxPos[2] := Z1;
end;

procedure TSceneObject.SetBounds(D: GLFloat);
begin
  SetBounds(-D, -D, -D, D, D, D);
end;

procedure TSceneObject.SetPosition(px, py, pz: GLFloat);
begin
  Position[0] := px;
  Position[1] := py;
  Position[2] := pz;
end;

procedure TSceneObject.SetModelOffset(ox, oy, oz: GLFloat);
begin
  ModelOffset[0] := ox;
  ModelOffset[1] := oy;
  ModelOffset[2] := oz;
end;

procedure TSceneObject.SetShift(sx, sy, sz: GLFloat);
begin
  Shift[0] := sx;
  Shift[1] := sy;
  Shift[2] := sz;
end;

procedure TSceneObject.SetVelocity(vx, vy, vz: GLFloat);
begin
  Velocity[0] := vx;
  Velocity[1] := vy;
  Velocity[2] := vz;
end;

procedure TSceneObject.SetRotation(rx, ry, rz: GLFloat);
begin
  Rotation[0] := rx;
  Rotation[1] := ry;
  Rotation[2] := rz;
end;

procedure TSceneObject.SetWobble(wx, wy, wz: GLFloat);
begin
  Wobble[0] := wx;
  Wobble[1] := wy;
  Wobble[2] := wz;
end;

procedure TSceneObject.SetSpin(sx, sy, sz: GLFloat);
begin
  Spin[0] := sx;
  Spin[1] := sy;
  Spin[2] := sz;
end;

procedure TSceneObject.SetScale(mx, my, mz: GLFloat);
begin
  Scale[0] := mx;
  Scale[1] := my;
  Scale[2] := mz;
end;

procedure TSceneObject.SetScale(m: GLFloat);
begin
  Scale[0] := m;
  Scale[1] := m;
  Scale[2] := m;
end;

procedure TSceneObject.Accelerate(V: GLFloat);
begin
  Velocity[0] := Velocity[0] - V * cos(Rotation[0]) * Sin(Rotation[1]);
  Velocity[1] := Velocity[1] - V * sin(Rotation[0]);
  Velocity[2] := Velocity[2] + V * cos(Rotation[0]) * Cos(Rotation[1]);
end;

procedure TSceneObject.Turn(delta: GLFloat; lagginess: GLFloat);
var
  V: GLFloat;
begin
  // we can balance out the "directness" of the turn
  // this is the rate of turn
  Spin[1] := Spin[1] + lagginess * delta;
  // this is the current direction
  Rotation[1] := Rotation[1] + (1 - lagginess) * delta;
end;

procedure TSceneObject.Move(DeltaTime: Double);
var
  Dim: Integer;
  V: GLFloat;
begin
  if Damped then
  begin
    // decay velocity
    Velocity[0] := Velocity[0] * (1 - DeltaTime / 5);
    Velocity[1] := Velocity[1] * (1 - DeltaTime / 5);
    Velocity[2] := Velocity[2] * (1 - DeltaTime / 5);

    // decay spin
    Spin[0] := Spin[0] * (1 - DeltaTime / 2);
    Spin[1] := Spin[1] * (1 - DeltaTime / 2);
    Spin[2] := Spin[2] * (1 - DeltaTime / 2);
  end;

  if not Weightless then
  begin
    // apply gravity to non fixed objects
    Velocity[1] := Velocity[1] - DeltaTime * G;
  end;

  Rotation[0] := Rotation[0] + Spin[0] * DeltaTime;
  Rotation[1] := Rotation[1] + Spin[1] * DeltaTime;
  Rotation[2] := Rotation[2] + Spin[2] * DeltaTime;

  // get magnitude of velocity in XZ plane
  V := Sqrt(Velocity[0] * Velocity[0] + Velocity[2] * Velocity[2]);

  // calculate new velocity components in XZ plane
  if V <> 0 then
  begin
    Velocity[0] := - V * Sin(Rotation[1]);
    Velocity[2] := + V * Cos(Rotation[1]);
  end;

  Position[0] := Position[0] + Velocity[0] * DeltaTime;
  Position[1] := Position[1] + Velocity[1] * DeltaTime;
  Position[2] := Position[2] + Velocity[2] * DeltaTime;

  // test for wrap arounds
  if MinPos[0] <> -999999 then
  begin
    for Dim := 0 to 2 do
      if (MinPos[Dim] <> -999999) and (Position[Dim] < MinPos[Dim]) then
        Position[Dim] := MaxPos[Dim]
      else if (MaxPos[Dim] <> 999999) and (Position[Dim] > MaxPos[Dim]) then
        Position[Dim] := MinPos[Dim];
  end;
end;

procedure TSceneObject.InitUnit;
begin
  Position[0] := 0;
  Position[1] := 0;
  Position[2] := 0;

  Velocity[0] := 0;
  Velocity[1] := 0;
  Velocity[2] := 0;

  Rotation[0] := 0;
  Rotation[1] := 0;
  Rotation[2] := 0;

  Spin[0] := 0;
  Spin[1] := 0;
  Spin[2] := 0;

  Colour[0] := 1;
  Colour[1] := 1;
  Colour[2] := 1;

  Scale[0] := 1;
  Scale[1] := 1;
  Scale[2] := 1;

  MinPos[0] := -999999;
  MinPos[1] := -999999;
  MinPos[2] := -999999;
  MaxPos[0] := 999999;
  MaxPos[1] := 999999;
  MaxPos[2] := 999999;

  Weightless := True;
  Damped := False;
  Active := True;
end;

procedure TSceneObject.InitRandom;
begin
  InitUnit;

  Position[0] := minx + Random * (maxx - minx);
  Position[1] := miny + Random * (maxy - miny);
  Position[2] := minz + Random * (maxz - minz);

  Velocity[0] := 5 * (Random - 0.5);
  Velocity[1] := 5 * (Random - 0.5);
  Velocity[2] := 5 * (Random - 0.5);

  Rotation[0] := PI * Random;
  Rotation[1] := PI * Random;
  Rotation[2] := PI * Random;

  Spin[0] := PI * (Random - 0.5);
  Spin[1] := PI * (Random - 0.5);
  Spin[2] := PI * (Random - 0.5);

  Colour[0] := Random;
  Colour[1] := Random;
  Colour[2] := Random;

  Scale[0] := Random;
  Scale[1] := Scale[0];
  Scale[2] := Scale[0];
end;

function TSceneObject.GetModelMatrix: TGLMatrixF4;
var
  cx, sx, cy, sy, cz, sz: GLFloat;
  ModelMat, ScaleMat: TGLMatrixF4;
begin
  // rotations
  if Model <> nil then
  begin
    cx := Cos(Rotation[0] + Wobble[0] + Model.Orientation[0]);
    cy := Cos(Rotation[1] + Wobble[1] + Model.Orientation[1]);
    cz := Cos(Rotation[2] + Wobble[2] + Model.Orientation[2]);

    sx := Sin(Rotation[0] + Wobble[0] + Model.Orientation[0]);
    sy := Sin(Rotation[1] + Wobble[1] + Model.Orientation[1]);
    sz := Sin(Rotation[2] + Wobble[2] + Model.Orientation[2]);
  end
  else
  begin
    cx := Cos(Rotation[0] + Wobble[0]);
    cy := Cos(Rotation[1] + Wobble[1]);
    cz := Cos(Rotation[2] + Wobble[2]);

    sx := Sin(Rotation[0] + Wobble[0]);
    sy := Sin(Rotation[1] + Wobble[1]);
    sz := Sin(Rotation[2] + Wobble[2]);
  end;

  // from opengl super bible edition7 p77
  ModelMat[0, 0] := cy * cz;
  ModelMat[0, 1] := -cy * sz;
  ModelMat[0, 2] := sy;
  ModelMat[0, 3] := 0;

  ModelMat[1, 0] := cx * sz + sx * sy * cz;
  ModelMat[1, 1] := cx * cz - sx * sy * sz;
  ModelMat[1, 2] := -sx * cy;
  ModelMat[1, 3] := 0;

  ModelMat[2, 0] := sx * sz - cx * sy * cz;
  ModelMat[2, 1] := sx * cz + cx * sy * sz;
  ModelMat[2, 2] := cx * cy;
  ModelMat[2, 3] := 0;

  ModelMat[3, 0] := Position[0] + ModelOffset[0] + Shift[0];
  ModelMat[3, 1] := Position[1] + ModelOffset[1] + Shift[1];
  ModelMat[3, 2] := Position[2] + ModelOffset[2] + Shift[2];
  ModelMat[3, 3] := 1;

  if Model <> nil then
    ScaleMat[0, 0] := Scale[0] * Model.Scale[0]
  else
    ScaleMat[0, 0] := Scale[0];
  ScaleMat[0, 1] := 0;
  ScaleMat[0, 2] := 0;
  ScaleMat[0, 3] := 0;

  ScaleMat[1, 0] := 0;
  if Model <> nil then
    ScaleMat[1, 1] := Scale[1] * Model.Scale[1]
  else
    ScaleMat[1, 1] := Scale[1];
  ScaleMat[1, 2] := 0;
  ScaleMat[1, 3] := 0;

  ScaleMat[2, 0] := 0;
  ScaleMat[2, 1] := 0;
  if Model <> nil then
    ScaleMat[2, 2] := Scale[2] * Model.Scale[2]
  else
    ScaleMat[2, 2] := Scale[2];
  ScaleMat[2, 3] := 0;

  ScaleMat[3, 0] := 0;
  ScaleMat[3, 1] := 0;
  ScaleMat[3, 2] := 0;
  ScaleMat[3, 3] := 1;

  Result := Multiply(ScaleMat, ModelMat);
end;

function TSceneObject.TestCollision(Object2: TSceneObject; DebugPoints: Array of TSceneObject): Boolean;
var
  D, CR: Double;
  SinR, CosR: Double;
  X, Y: Double;
  pp, aa, bb, cc, dd: TGLVectorf2;
  I: Integer;

  // from Collision Detection book, p 205
  function Cross2D(u, v: TGLVectorf2): GLfloat;
  begin
    result := u[1] * v[0] - u[0] * v[1];
  end;

  function VDiff(a, b: TGLVectorf2): TGLVectorf2;
  begin
    VDiff[0] := a[0] - b[0];
    VDiff[1] := a[1] - b[1];
  end;

  function PointInTriangle(p, a, b, c: TGLVectorf2): Boolean;
  begin
    if Cross2D(VDiff(p, a), VDiff(b, a)) < 0.0 then
      Result := false
    else if Cross2D(VDiff(p, b), VDiff(c, b)) < 0.0 then
      Result := false
    else if Cross2D(VDiff(p, c), VDiff(a, c)) < 0.0 then
      Result := false
    else
      Result := true;
  end;

  function Vec2(x, y: GLFloat): TGLVectorf2;
  begin
    Vec2[0] := x;
    Vec2[1] := y;
  end;

begin
  Result := False;

  // test for intersection in zx plane first
  D := Sqrt((Position[0] - Object2.Position[0]) * (Position[0] - Object2.Position[0])
     + (Position[2] - Object2.Position[2]) * (Position[2] - Object2.Position[2]));

  CR := Max(Model.BBMax[0] * Scale[0], Model.BBMax[2] * Scale[2]) +
    Max(Object2.Model.BBMax[0] * Object2.Scale[0], Object2.Model.BBMax[2] * Object2.Scale[2]);

  if D > CR then
  begin
    Result := False;
    Exit;
  end;

  // test for possible vertical overlap
  if Abs(Position[1] - Object2.Position[1]) >
    Object2.Model.BBMax[1] * Object2.Scale[1] + Model.BBMax[1] * Scale[1] then
  begin
    Result := False;
    Exit;
  End;

  CR := 0.0 * (Min(Model.BBMax[0] * Scale[0], Model.BBMax[2] * Scale[2]) +
    Min(Object2.Model.BBMax[0] * Object2.Scale[0], Object2.Model.BBMax[2] * Object2.Scale[2]));

  if D < CR then
  begin
    Result := True;
    Exit;
  end
  else
  begin
    // test for object 1 inside object 2 bounding box
    pp := Vec2(Position[0], Position[2]);

    SinR := Sin(Object2.Rotation[1]);
    CosR := Cos(Object2.Rotation[1]);

    if Length(DebugPoints) = 4 then
    begin
      if DebugPoints[0] <> nil then
      begin
        aa := Vec2(Object2.Position[0] + Object2.Model.BBMin[0] * Object2.Scale[0] * CosR + Object2.Model.BBMin[2] * Object2.Scale[2] * SinR,
          Object2.Position[2] + Object2.Model.BBMin[2] * Object2.Scale[2] * CosR - Object2.Model.BBMin[0] * Object2.Scale[0] * SinR);
        DebugPoints[0].SetPosition(aa[0], Object2.Position[1] + 1, aa[1]);

        bb := Vec2(Object2.Position[0] + Object2.Model.BBMin[0] * Object2.Scale[0] * CosR + Object2.Model.BBMax[2] * Object2.Scale[2] * SinR,
          Object2.Position[2] + Object2.Model.BBMax[2] * Object2.Scale[2] * CosR - Object2.Model.BBMin[0] * Object2.Scale[0] * SinR);
        DebugPoints[1].SetPosition(bb[0], Object2.Position[1] + 1, bb[1]);

        cc := Vec2(Object2.Position[0] + Object2.Model.BBMax[0] * Object2.Scale[0] * CosR + Object2.Model.BBMax[2] * Object2.Scale[2] * SinR,
          Object2.Position[2] + Object2.Model.BBMax[2] * Object2.Scale[2] * CosR - Object2.Model.BBMax[0] * Object2.Scale[0] * SinR);
        DebugPoints[2].SetPosition(cc[0], Object2.Position[1] + 1, cc[1]);

        dd := Vec2(Object2.Position[0] + Object2.Model.BBMax[0] * Object2.Scale[0] * CosR + Object2.Model.BBMin[2] * Object2.Scale[2] * SinR,
          Object2.Position[2] + Object2.Model.BBMin[2] * Object2.Scale[2] * CosR - Object2.Model.BBMax[0] * Object2.Scale[0] * SinR);
        DebugPoints[3].SetPosition(dd[0], Object2.Position[1] + 1, dd[1]);

        for I := 0 to 3 do
          DebugPoints[I].Activate(2);
      end;
    end;

    if PointInTriangle(pp, aa, cc, bb) or PointInTriangle(pp, aa, dd, cc) then
      Result := true;
  end;
end;

end.
