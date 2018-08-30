unit MainU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, System.StrUtils, System.Math, DateUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, dglOpenGL, Generics.Collections,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, SceneManager, TriangleStripMesh,
  SceneObjects, GlHelpers;

const
  MAXINSTANCES = 1024;
  MAXLIGHTS = 5;
  GRIDSIZE = 512; // note must be a power of 2
  MINIMAPSIZE = 128; // resolution of the minimap square in pixels

  Epsilon = 2.22045E-016; // take from c++ sampls

  // used to identify loc in shaders
  IDX_POSITION = 0;
  IDX_NORMAL = 1;
  IDX_TEXCOORD = 2;
  IDX_EXTRA = 3;

type
  TKeyMatrix = Record
    K_UP, K_RIGHT, K_DOWN, K_LEFT, K_SLASH: Boolean;
  public
    procedure Init;
  End;

  TMainForm = class(TForm)
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Timer1Timer(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    Running, StopNow, Paused: Boolean;
    WireframeMode, CollisionBoxDisplayMode, TextureMode: Boolean;
    Culling, InstancingEnabled, MiniMapMode: Boolean;

    KeyMatrix: TKeyMatrix;

    GLContext: HGLRC;
    glDC: HDC;
    OpenGLReady: Boolean;

    // variables for shaders
    MainShader: glHandle;
    MainInstancedShader: glHandle;
    ActiveShader: glHandle;

    // used for passing effect block as uniform
    EffectBuffer: GLUInt;

    // buffer for instanced rendering
    InstanceBuffer: GLUInt;
    InstanceArray: Array [0 .. MAXINSTANCES - 1] of TGLInstanceData;

    LightBuffer: GLUInt;
    LightArray: Array [0 .. MAXLIGHTS - 1] of TGLLight;

    // global RunTime variable
    RunTime: GLFloat;

    // vairables for location of variables in shaders
    locModel, locView, locProjection, locEye, locColour, locScale, locid1,
      locid2, locid3, locselmode, locRT, locTextures, locTex0, locTex1, locTex2,
      locET, locUseEffect, idxEffectBlock, idxInstanceBlock, locLights, idxLightBlock: GLInt;

    SceneManager: TSceneManager;

    // control of view
    Eye: TSceneObject;

    // handy pointers to special permanent/reusable objects
    Player: TSceneObject;
    Terrain: TSceneObject;
    Sea: TSceneObject;
    Sky: TSceneObject;
    MiniMap: TSceneObject;
    Dymo: TSceneObject;
    Dymo2D: TSceneObject;

    // keep this one as a "master" as it has a special shader
    Explosion: TSceneObject;

    CollisionBox: TSceneObject;
    DebugPoint: Array [0 .. 3] of TSceneObject;

    MinimapAge: TDateTime;
    MMFrameBuffer: GLUInt;
    MMColourTexture, MMDepthTexture: GLUInt;

    TSTerrain: TTriangleStripMesh;
    WorkArray: Array of GLFloat;

    Level: Integer;
    Score: Integer;
    TargetsRemaining: Integer;
    PercentPolluted: Integer;

    LookatMatrix: TGLMatrixF4;
    ViewMatrix: TGLMatrixF4;
    ProjectionMatrix: TGLMatrixF4;

    SelectionMode: Boolean;
    SelX, SelY: Integer;
    SelectedObject: TSceneObject;

    WasWidth, WasHeight: Integer;

    procedure ActivateShader(Shader: glHandle);

    procedure TestKeys(AKey: Word; Toggle: Boolean);
    procedure PollKeys(DT: Double);
  public
    { Public declarations }
    CloudMesh: TMesh;

    PointGeometry: TOpenGLData;
    CubeGeometry: TOpenGLData;
    Cube2Geometry: TOpenGLData;

    procedure MyInitOpenGL;
    procedure InitSceneObjects;

    procedure PositionObject(SceneObject: TSceneObject);

    procedure DrawObjectlist(ObjectList: TSceneObjectList);
    procedure DrawObject(O: TSceneObject; InstanceCount: Integer);
    procedure DrawObjectlistLabels(Objects: TSceneObjectList);

    procedure RenderLoop;
    procedure DoRender;

    procedure LoadPointCloud(Number: Integer);

    procedure InitialiseTerrain;
    procedure GenerateTerrain;

    procedure BuildSea;

    procedure BuildSky;

    procedure BuildMiniMap;
    procedure UpdateMiniMap;
    procedure DrawMiniMap;

    procedure Draw2DLabel(Text: String; X, Y, Height: GLFloat;
      Alignment: TAlignment; Colour: TGLVectorf4);

    procedure AddTerrainObjects;

    procedure OnRotation(const RX, RY, RZ, Angle: Double);
    procedure OnTranslation(const DX, DY, DZ, Length: Double);
    procedure OnAcceleration(Force: Double);

    procedure ResetPosition;
    procedure SetViewMatrix;

    procedure UpdateLights;

    procedure GetLocations(AShader: glHandle);

    procedure LaunchMissile;
    procedure TestMissileCollisions(Missile: TSceneObject);

    procedure TestBoatCollisions;
    procedure NextLevel;

    procedure DoLuckyDip;
    procedure GenerateTargets;

    procedure UpdateTerrain;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  DiamondSquareEngine, FontEngine, IniFiles;

// this code has to match EXACTLY that in water_v.glsl
function GetWaveHeightAt(RT, X, Z: Double): Double;
var
  SwellF, Swell, RippleF, Ripple: Single;
const
  TWOPI = 6.28318531;
begin
  SwellF := TWOPI * (RT / 16 + Z / 16); // period = 16s, wavelength = 16m
  Swell := 0.5 * Sin(SwellF); // .5m amplitude

  RippleF := TWOPI * (RT / 4 + (X + Z) / 4); // period = 4s, wavelength = 4m
  Ripple := 0.1 * Sin(RippleF); // .1m amplitude

  Result := Swell + Ripple;
end;

procedure TKeyMatrix.Init;
begin
  K_UP := False;
  K_RIGHT := False;
  K_DOWN := False;
  K_LEFT := False;
  K_SLASH := False;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  System.ReportMemoryLeaksOnShutdown := True;

  WasWidth := Screen.Width;
  WasHeight := Screen.Height;

  Paused := False;
  WireframeMode := False;
  TextureMode := True;
  Culling := True;
  CollisionBoxDisplayMode := False;

  InstancingEnabled := True;
  MiniMapMode := False;

  Level := 1;

  // ChangeMonitorResolution(Monitor.MonitorNum, 720, 480);

  OpenGLReady := False;
  SelectionMode := False;

  MyInitOpenGL;

  DistanceFont := TDistanceFont.Create;
//  DistanceFont.LoadFont('Arial32df');
  DistanceFont.LoadFont('ComicSans64');

  SceneManager := TSceneManager.Create;

  InitSceneObjects;

  BuildSky;

  InitialiseTerrain;

  BuildSea;

  LoadPointCloud(2048);

  GenerateTargets;

  BuildMiniMap;
  UpdateMiniMap;

  ResetPosition;

  Timer1.Enabled := True;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if not OpenGLReady then
    Exit;

  ProjectionMatrix := PerspectiveMatrix(ClientWidth, ClientHeight);
  glViewport(0, 0, ClientWidth, ClientHeight);
end;

procedure TMainForm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  RenderLoop;
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  StopNow := True;
end;

procedure TMainForm.ResetPosition;
begin
  Player.SetPosition(0.0, 0.0, 0.0);
  if Assigned(TSTerrain) then
    Player.Position[1] := TSTerrain.GetHeightAt(0.0, 0.0);

  Player.SetShift(0.0, 0.0, 0.0);
  Player.SetSpin(0.0, 0.0, 0.0);
  Player.SetRotation(0.0, 0.0, 0.0);
  Player.SetVelocity(0.0, 0.0, 0.0);
  Player.SetWobble(0.0, 0.0, 0.0);

  Eye.SetPosition(0.0, 2.5, -5.0);
  Eye.SetRotation(0.0, PI, 0.0);

  KeyMatrix.Init;
end;

procedure TMainForm.LaunchMissile;
var
  O: TSceneObject;
begin
  O := TSceneObject.Create('MISSILE');
  O.Model := SceneManager.GetModel('MISSILE');
  O.SetColour(1.0, 1.0, 1.0, 1.0);
  O.Active := False;
  O.Weightless := True;
  O.SetScale(0.1, 0.2, 2.5);

  O.Position := Player.Position;
  O.Rotation := Player.Rotation;

  O.Velocity[0] := Player.Velocity[0] - 40 * Sin(Player.Rotation[1]);
  O.Velocity[1] := 0;
  O.Velocity[2] := Player.Velocity[2] + 40 * Cos(Player.Rotation[1]);

  O.Activate(5);

  SceneManager.TemporaryObjects.Add(O);
end;

procedure TMainForm.TestBoatCollisions;
var
  O: TSceneObject;
begin
  for O in SceneManager.StaticObjects.Objects do
  begin
    if O.Active and Player.TestCollision(O, DebugPoint) then
    begin
      Player.SetVelocity(-0.1 * Player.Velocity[0], 0, -0.1 * Player.Velocity[2]);
      Break;
    end;
  end;

  for O in SceneManager.DynamicObjects.Objects do
  begin
    if O.Active and Player.TestCollision(O, DebugPoint) then
    begin
      if O.Name = 'STAR' then
      begin
        O.Deactivate;
        SceneManager.DynamicObjects.Objects.Delete
          (SceneManager.DynamicObjects.Objects.IndexOf(O));
        O.Free;
        Score := Score + 25;
      end;
    end;
  end;
end;

procedure TMainForm.TestMissileCollisions(Missile: TSceneObject);
var
  C: Integer;
  procedure IntTest(List: TSceneObjectList; Delta: Integer);
  var
    O, E: TSceneObject;
  begin
    for O in List.Objects do
    begin
      if O.Active then
      begin
        if Missile.TestCollision(O, DebugPoint) then
        begin
          Missile.Deactivate;
          O.Deactivate;

          // here be explosion
          E := TSceneObject.Create('EXPLOSION');
          E.Model := SceneManager.GetModel('POINTCLOUD');
          E.ShaderProgram := Explosion.ShaderProgram;
          E.Position := Missile.Position;
          E.Weightless := True;
          E.Activate(5);
          SceneManager.TemporaryObjects.Add(E);

          Score := Score + Delta;
        end
        else
          Inc(C);
      end;
    end;
  end;

begin
  if Missile.Active then
  begin
    C := 0;
    IntTest(SceneManager.StaticObjects, -5);

    C := 0;
    IntTest(SceneManager.DynamicObjects, +20);

    if C = 0 then
      NextLevel;

    TargetsRemaining := C;
  end;
end;

procedure TMainForm.SetViewMatrix;
var
  Pitch, Yaw: Double;
  Fwd, Side, Up: TGLVector3f;
begin
  // just for clarity
  Yaw := Eye.Rotation[1] + Player.Rotation[1];
  // 0 should be down -ve z axis +ve is right
  Pitch := Eye.Rotation[0] + Player.Rotation[0]; // +ve is look up

  // from OpenGL super Bible p. 84-86
  // forward vector
  // Fwd[0] := Sin(Yaw) * Cos(Pitch);
  // Fwd[1] := Sin(Pitch);
  // Fwd[2] := Cos(Yaw) * Cos(Pitch);

  // https://stackoverflow.com/questions/1568568/how-to-convert-euler-angles-to-directional-vector
  Fwd[0] := -Sin(Yaw) * Cos(Pitch);
  Fwd[1] := Sin(Pitch);
  Fwd[2] := Cos(Yaw) * Cos(Pitch);

  // suggest initial up vector based on orientation
  if (Abs(Fwd[0]) < Epsilon) and (Abs(Fwd[2]) < Epsilon) then
  begin
    Up[0] := 0;
    Up[1] := 0;
    if Fwd[1] > 0 then
      Up[2] := -1
    else
      Up[2] := 1;
  end
  else
  begin
    Up[0] := 0;
    Up[1] := 1;
    Up[2] := 0;
  end;

  // calculate side vector
  Side := Cross(Up, Fwd);
  Normalize(Side);

  // calculate proper up vector
  Up := Cross(Fwd, Side);
  Normalize(Up);

  // populate lookat matrix XYZ axes and position
  LookatMatrix[0, 0] := Side[0];
  LookatMatrix[0, 1] := Side[1];
  LookatMatrix[0, 2] := Side[2];
  LookatMatrix[0, 3] := 0;

  LookatMatrix[1, 0] := Up[0];
  LookatMatrix[1, 1] := Up[1];
  LookatMatrix[1, 2] := Up[2];
  LookatMatrix[1, 3] := 0;

  LookatMatrix[2, 0] := Fwd[0];
  LookatMatrix[2, 1] := Fwd[1];
  LookatMatrix[2, 2] := Fwd[2];
  LookatMatrix[2, 3] := 0;

  LookatMatrix[3, 0] := Player.Position[0] + Eye.Position[0] * Cos(Player.Rotation[1]) -
    Eye.Position[2] * Sin(Player.Rotation[1]);
  LookatMatrix[3, 1] := Player.Position[1] + Eye.Position[1];
  LookatMatrix[3, 2] := Player.Position[2] + Eye.Position[2] * Cos(Player.Rotation[1]) +
    Eye.Position[0] * Sin(Player.Rotation[1]);
  LookatMatrix[3, 3] := 1;

  // and invert it to get the
  ViewMatrix := MatrixInvert(LookatMatrix);
end;

procedure TMainForm.OnTranslation(const DX, DY, DZ, Length: Double);
var
  F: Double;
begin
  F := 0.1;

  With Eye do
  begin
    Position[0] := Position[0] + F * Length *
      (DX * LookatMatrix[0, 0] + DY * LookatMatrix[1, 0] + DZ *
      LookatMatrix[2, 0]);
    Position[1] := Position[1] + F * Length *
      (DX * LookatMatrix[0, 1] + DY * LookatMatrix[1, 1] + DZ *
      LookatMatrix[2, 1]);
    Position[2] := Position[2] + F * Length *
      (DX * LookatMatrix[0, 2] + DY * LookatMatrix[1, 2] + DZ *
      LookatMatrix[2, 2]);
  end;
end;

procedure TMainForm.OnRotation(const RX, RY, RZ, Angle: Double);
var
  F: Double;
begin
  F := 0.1;
  With Eye do
  begin
    Rotation[0] := Rotation[0] + F * Angle * RX;
    Rotation[1] := Rotation[1] + F * Angle * RY;
    Rotation[2] := 0;

    // limit pitch to +/- 90
    if Rotation[0] < -PI / 2 + 0.01 then
      Rotation[0] := -PI / 2 + 0.01
    else if Rotation[0] > PI / 2 - 0.01 then
      Rotation[0] := PI / 2 - 0.01;

    // wrap rotation round at 360
    if Rotation[1] < -2 * PI then
      Rotation[1] := Rotation[1] + 2 * PI
    else if Rotation[1] > 2 * PI then
      Rotation[1] := Rotation[1] - 2 * PI;
  end;
end;

procedure TMainForm.OnAcceleration(Force: Double);
begin
  With Player do
  begin
    Accelerate(Force);
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  If (WasWidth <> Screen.Width) or (WasHeight <> Screen.Height) then
    ChangeMonitorResolution(Monitor.MonitorNum, WasWidth, WasHeight);

  Eye.Free;

  Explosion.Free;

  CollisionBox.Free;

  SceneManager.Free;

  TSTerrain.Free;

  MiniMap.Free;

  Dymo.Free;
  Dymo2D.Free;

  DistanceFont.Free;

  PointGeometry.Free;
  CubeGeometry.Free;
  Cube2Geometry.Free;

  wglMakeCurrent(Canvas.Handle, 0);
  wglDeleteContext(GLContext);
end;

procedure TMainForm.GetLocations(AShader: glHandle);
begin
  locView := glGetUniformLocation(AShader, PGLchar('View'));
  locProjection := glGetUniformLocation(AShader, PGLchar('Projection'));
  locEye := glGetUniformLocation(AShader, PGLchar('Eye'));
  locModel := glGetUniformLocation(AShader, PGLchar('Model'));
  locColour := glGetUniformLocation(AShader, PGLchar('Colour'));
  locLights := glGetUniformLocation(AShader, PGLchar('Lights'));

  locScale := glGetUniformLocation(AShader, PGLchar('Scale'));
  locRT := glGetUniformLocation(AShader, PGLchar('RT'));
  locET := glGetUniformLocation(AShader, PGLchar('ET'));

  locTextures := glGetUniformLocation(AShader, PGLchar('Textures'));
  locTex0 := glGetUniformLocation(AShader, PGLchar('Tex0'));
  locTex1 := glGetUniformLocation(AShader, PGLchar('Tex1'));
  locTex2 := glGetUniformLocation(AShader, PGLchar('Tex2'));

  locUseEffect := glGetUniformLocation(AShader, PGLchar('UseEffect'));

  locselmode := glGetUniformLocation(AShader, PGLchar('selmode'));

  idxEffectBlock := glGetUniformBlockIndex(AShader, PGLchar('EffectBlock'));
  idxInstanceBlock := glGetUniformBlockIndex(AShader, PGLchar('InstanceBlock'));
  idxLightBlock := glGetUniformBlockIndex(AShader, PGLChar('LightBlock'));

  if SelectionMode then
  begin
    locid1 := glGetUniformLocation(AShader, PGLchar('id1'));
    locid2 := glGetUniformLocation(AShader, PGLchar('id2'));
    locid3 := glGetUniformLocation(AShader, PGLchar('id3'));
  end;
end;

procedure TMainForm.MyInitOpenGL;
var
  pfd: TPixelFormatDescriptor;
  FormatIndex: Integer;
begin
  InitOpenGL;

  FillChar(pfd, SizeOf(pfd), 0);
  with pfd do
  begin
    nSize := SizeOf(pfd);
    nVersion := 1;
    dwFlags := PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL;
    iPixelType := PFD_TYPE_RGBA;
    cColorBits := 24;
    cDepthBits := 32;
    iLayerType := PFD_MAIN_PLANE;
  end;

  glDC := GetDC(Handle);
  FormatIndex := ChoosePixelFormat(glDC, @pfd);
  SetPixelFormat(glDC, FormatIndex, @pfd);
  GLContext := wglCreateContext(glDC);
  ActivateRenderingContext(glDC, GLContext);
  wglMakeCurrent(glDC, GLContext);

  glGenBuffers(1, @EffectBuffer);
  glGenBuffers(1, @InstanceBuffer);
  glGenBuffers(1, @LightBuffer);

  glEnable(GL_DEPTH_TEST);
  glEnable(GL_COLOR_MATERIAL);
  glEnable(GL_PROGRAM_POINT_SIZE);
  glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
  glEnable(GL_POINT_SPRITE);

  MainInstancedShader := BuildProgramObject('shader_instanced_v.glsl', 'shader_instanced_f.glsl', '');
  MainShader := BuildProgramObject('shader_v.glsl', 'shader_f.glsl', '');

  if InstancingEnabled then
    GetLocations(MainInstancedShader)
  else
    GetLocations(MainShader);

  OpenGLReady := True;

  UpdateLights;
end;

procedure TMainForm.BuildMiniMap;
const
  draw_buffers: Array [0 .. 0] of GLenum = (GL_COLOR_ATTACHMENT0);
var
  I, J, N: Integer;
  MapST: TTriangleStripMesh;
  M: TMesh;
begin
  // oglsb p. 393
  glCreateFramebuffers(1, @MMFrameBuffer);
  glBindFramebuffer(GL_FRAMEBUFFER, MMFrameBuffer);

  glGenTextures(1, @MMColourTexture);
  glBindTexture(GL_TEXTURE_2D, MMColourTexture);
  glTexStorage2D(GL_TEXTURE_2D, 1, GL_RGBA8, MINIMAPSIZE, MINIMAPSIZE);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  glGenTextures(1, @MMDepthTexture);
  glBindTexture(GL_TEXTURE_2D, MMDepthTexture);
  glTexStorage2D(GL_TEXTURE_2D, 1, GL_DEPTH_COMPONENT32F, MINIMAPSIZE,
    MINIMAPSIZE);

  glFrameBufferTexture(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
    MMColourTexture, 0);
  glFrameBufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, MMDepthTexture, 0);

  glDrawBuffers(1, @draw_buffers);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  MiniMap := TSceneObject.Create('MINIMAP');
  MiniMap.Model := SceneManager.AddModel('MINIMAP');

  MapST := TTriangleStripMesh.Create(2, 2);

  for J := 0 to 1 do
  begin
    for I := 0 to 1 do
    begin
      N := I + J * 2;
      MapST.Vertices[N].PosX := I;
      MapST.Vertices[N].PosY := J;
      MapST.Vertices[N].PosZ := 0;
      MapST.Vertices[N].TexU := I;
      MapST.Vertices[N].TexV := J;
    end;
  end;

  MapST.CalcNormals;

  M := TMesh.Create(MiniMap.Name);

  M.SetColour(1.0, 1.0, 1.0, 1.0);

  M.AddVertices(@MapST.Vertices[0], Length(MapST.Vertices));
  M.AddIndexes(@MapST.Indices[0], Length(MapST.Indices));

  MapST.Free;

  M.Drawmode := GL_TRIANGLE_STRIP;
  MiniMap.Model.AddMesh(M);

  MiniMap.ShaderProgram := BuildProgramObject('minimap_v.glsl',
    'minimap_f.glsl', '');

  MinimapAge := 0;
end;

procedure TMainForm.UpdateMiniMap;
var
  WasEyeP, WasBoatP, WasEyeR, WasBoatR: TGLVectorf3;
begin
  glBindFramebuffer(GL_FRAMEBUFFER, MMFrameBuffer);
  glViewport(0, 0, MINIMAPSIZE, MINIMAPSIZE);

  glClearColor(1.0, 1.0, 1.0, 1.0);
  glClearDepth(1.0);

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  WasEyeP := Eye.Position;
  WasEyeR := Eye.Rotation;
  WasBoatP := Player.Position;
  WasBoatR := Player.Rotation;

  Player.SetPosition(0.0, 0.0, 0.0);
  Player.SetRotation(0.0, 0.0, 0.0);

  // doesn't really seem to matter apart from clipping
  Eye.SetPosition(0.0, GRIDSIZE / 2, 0.0);
  Eye.SetRotation(PI / 2, 0.0, 0.0);

  ProjectionMatrix := OrthogonalMatrix(MINIMAPSIZE, MINIMAPSIZE);

  SetViewMatrix;

  MiniMapMode := True;
  DrawObjectlist(SceneManager.CoreObjects);
  DrawObjectlist(SceneManager.StaticObjects);
  MiniMapMode := False;

  Eye.Position := WasEyeP;
  Eye.Rotation := WasEyeR;
  Player.Position := WasBoatP;
  Player.Rotation := WasBoatR;

  glBindFramebuffer(GL_FRAMEBUFFER, 0);
  ProjectionMatrix := PerspectiveMatrix(ClientWidth, ClientHeight);
  glViewport(0, 0, ClientWidth, ClientHeight);

  MinimapAge := Now;
end;

procedure TMainForm.DrawMiniMap;
var
  M: TMesh;
  AR: Double;
  locAR: Integer;
  locSR: Integer;
  locCR: Integer;
  O: TSceneObject;

  procedure MMPoint(X, Z: GLFloat);
  var
    I, J: GLFloat;
  begin
    I := 0.5 + X / TSTerrain.Width;
    J := 0.5 + Z / TSTerrain.Depth;

    glNormal3f(0.0, 0.0, 1.0);
    glVertex3f(1 - I, J, 0.0);
  end;

begin
  if Assigned(MiniMap) and (MiniMap.ShaderProgram <> 0) then
  begin
    if SecondsBetween(Now, MinimapAge) > 2 then
    begin
      UpdateTerrain;
      UpdateMiniMap;
    end;

    glDisable(GL_BLEND);
    glDisable(GL_DEPTH_TEST);

    AR := ClientWidth / ClientHeight;

    GetLocations(MiniMap.ShaderProgram);
    glUseProgram(MiniMap.ShaderProgram);

    glUniform1i(locTextures, 1);
    glUniform1i(locTex0, 0);
    locAR := glGetUniformLocation(MiniMap.ShaderProgram, 'AR');
    locSR := glGetUniformLocation(MiniMap.ShaderProgram, 'SR');
    locCR := glGetUniformLocation(MiniMap.ShaderProgram, 'CR');

    glUniform1f(locAR, AR);

    if Abs(Eye.Rotation[0] - PI / 2) < 4.4E-08 then
    begin
      glUniform1f(locSR, Sin(Eye.Rotation[1] + Player.Rotation[1]));
      glUniform1f(locCR, Cos(Eye.Rotation[1] + Player.Rotation[1]));
    end
    else
    begin
      glUniform1f(locSR, Sin(Eye.Rotation[1] + Player.Rotation[1] + PI));
      glUniform1f(locCR, Cos(Eye.Rotation[1] + Player.Rotation[1] + PI));
    end;

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, MMColourTexture);

    glEnableVertexAttribArray(IDX_POSITION);
    glEnableVertexAttribArray(IDX_NORMAL);
    glEnableVertexAttribArray(IDX_TEXCOORD);
    glEnableVertexAttribArray(IDX_EXTRA);

    M := MiniMap.Model.Meshes[0];
    glBindBuffer(GL_ARRAY_BUFFER, M.OpenGLData.VBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, M.OpenGLData.EBO);

    glVertexAttribPointer(IDX_POSITION, 3, GL_FLOAT, False,
      SizeOf(TVertexAttribute), GLVoid(0 * SizeOf(GLFloat)));
    glVertexAttribPointer(IDX_NORMAL, 3, GL_FLOAT, False,
      SizeOf(TVertexAttribute), GLVoid(3 * SizeOf(GLFloat)));
    glVertexAttribPointer(IDX_TEXCOORD, 2, GL_FLOAT, False,
      SizeOf(TVertexAttribute), GLVoid(6 * SizeOf(GLFloat)));
    glVertexAttribPointer(IDX_EXTRA, 1, GL_FLOAT, False,
      SizeOf(TVertexAttribute), GLVoid(8 * SizeOf(GLFloat)));

    glDrawElements(M.Drawmode, M.OpenGLData.EBOLength, GL_UNSIGNED_INT, NIL);

    glDisableVertexAttribArray(IDX_EXTRA);
    glDisableVertexAttribArray(IDX_TEXCOORD);
    glDisableVertexAttribArray(IDX_NORMAL);
    glDisableVertexAttribArray(IDX_POSITION);

    glUniform1i(locTextures, 0);

    glPointSize(4);
    glUniform4f(locColour, 1.0, 0.4, 0.4, 1.0);
    glBegin(GL_POINTS);
    MMPoint(Player.Position[0], Player.Position[2]);
    glEnd;

    glPointSize(3);
    glUniform4f(locColour, 1.0, 0.4, 0.4, 1.0);
    glBegin(GL_POINTS);
    for O in SceneManager.TemporaryObjects.Objects do
    begin
      if O.Active and ((O.Name = 'MISSILE') or (O.Name = 'BOMB')) then
        MMPoint(O.Position[0], O.Position[2]);
    end;
    glEnd;

    glPointSize(3);
    glUniform4f(locColour, 1.0, 1.0, 0.4, 1.0);

    glBegin(GL_POINTS);
    for O in SceneManager.DynamicObjects.Objects do
    begin
      if O.Active and (Copy(O.Name, 1, 6) = 'Target') then
        MMPoint(O.Position[0], O.Position[2]);
    end;
    glEnd;

    glEnable(GL_DEPTH_TEST);
  end;
end;

procedure TMainForm.UpdateTerrain;
var
  I, J, N: Integer;
  U, D, L, R: Integer;
  W: GLFloat;
  T: Double;
begin
  for J := 0 to TSTerrain.Depth - 1 do
  begin
    if J = 0 then
      U := (TSTerrain.Depth - 1) * TSTerrain.Width
    else
      U := - TSTerrain.Width;

    if J = TSTerrain.Depth - 1 then
      D := - (TSTerrain.Depth - 1) * TSTerrain.Width
    else
      D := TSTerrain.Width;

    for I := 0 to TSTerrain.Width - 1 do
    begin
      N := I + J * TSTerrain.Width;

      if I = 0 then
        L := TSTerrain.Width - 1
      else
        L := - 1;

      if I = TSTerrain.Width - 1 then
        R := - (TSTerrain.Width - 1)
      else
        R := 1;

      // average the extra value in the sourrounding 8 cells
      W := 0.125 * (TSTerrain.Vertices[N + U].Extra + TSTerrain.Vertices[N + U + R].Extra +
        TSTerrain.Vertices[N + R].Extra + TSTerrain.Vertices[N + R + D].Extra +
        TSTerrain.Vertices[N + D].Extra + TSTerrain.Vertices[N + D + L].Extra +
        TSTerrain.Vertices[N + L].Extra + TSTerrain.Vertices[N + L + U].Extra);

      // if the surrounding average is higher, incresae the current value
      if W > TSTerrain.Vertices[N].Extra then
        WorkArray[N] := Min(TSTerrain.Vertices[N].Extra + W / 2, 1.0)
      else
        WorkArray[N] := TSTerrain.Vertices[N].Extra;
    end;
  end;

  T := 0;

  for J := 0 to TSTerrain.Depth - 1 do
  begin
    for I := 0 to TSTerrain.Width - 1 do
    begin
      N := I + J * TSTerrain.Width;
      TSTerrain.Vertices[N].Extra := WorkArray[N];

      T := T + WorkArray[N];
    end;
  end;

  PercentPolluted := Trunc(100 * T / (TSTerrain.Depth * TSTerrain.Width));

  // update polluted cells
  glBindBuffer(GL_ARRAY_BUFFER, Terrain.Model.Meshes[0].OpenGLData.VBO);

  // use this to reload the whole vertex data buffer
  glBufferSubData(GL_ARRAY_BUFFER, 0, SizeOf(TVertexAttribute) *
    Length(TSTerrain.Vertices), @TSTerrain.Vertices[0]);
end;

procedure TMainForm.GenerateTerrain;
const
  TS = GRIDSIZE / 8;
var
  I, J, N, K, L: Integer;
  Size: Integer;
  DSEngine: TDiamondSquareEngine;
  Edge: TTriangleStripMesh;
begin
  // Generate Terrain
  DSEngine := TDiamondSquareEngine.Create(GRIDSIZE);
  DSEngine.Generate(0.05); // 0.05 is a really nice value
  Size := DSEngine.Size;

  // create a terrain surface and store for height tests
  if TSTerrain = nil then
    TSTerrain := TTriangleStripMesh.Create(Size, Size);

  for J := 0 to Size - 1 do
  begin
    for I := 0 to Size - 1 do
    begin
      N := I + J * Size;
      TSTerrain.Vertices[N].PosX := I - Size / 2;
      TSTerrain.Vertices[N].PosY := DSEngine.Map[N];
      TSTerrain.Vertices[N].PosZ := J - Size / 2;
      TSTerrain.Vertices[N].TexU := I / (Size / TS);
      TSTerrain.Vertices[N].TexV := 1 - J / (Size / TS);
      TSTerrain.Vertices[N].Extra := 0;
    end;
  end;

  DSEngine.Free;

  TSTerrain.CalcNormals;

  Terrain.Model.Meshes[0].AddVertices(@TSTerrain.Vertices[0],
    Length(TSTerrain.Vertices));
  Terrain.Model.Meshes[0].AddIndexes(@TSTerrain.Indices[0],
    Length(TSTerrain.Indices));

  if Assigned(Sea) then
  begin
    Sea.Model.Meshes[0].AddVertices(@TSTerrain.Vertices[0],
      Length(TSTerrain.Vertices));
    Sea.Model.Meshes[0].AddIndexes(@TSTerrain.Indices[0],
      Length(TSTerrain.Indices));
  end;

  // length of border in units
  L := 2 * (TSTerrain.Width + TSTerrain.Depth);
  Edge := TTriangleStripMesh.Create(L, 2);
  Size := TSTerrain.Width;

  K := 0;
  I := 0;
  for N := 0 to Size - 1 do
  begin
    // Left edge
    J := N;
    Edge.Vertices[N + K].PosX := I - Size / 2;
    Edge.Vertices[N + K].PosY := Min(0, TSTerrain.Vertices[I + J * Size].PosY);
    Edge.Vertices[N + K].PosZ := J - Size / 2;
    Edge.Vertices[N + K].NormX := -1;
    Edge.Vertices[N + K].NormY := 0;
    Edge.Vertices[N + K].NormZ := 0;
    Edge.Vertices[N + K].TexU := N / (Size / TS);
    Edge.Vertices[N + K].TexV := 0;

    Edge.Vertices[N + K + L].PosX := I - Size / 2;
    Edge.Vertices[N + K + L].PosY :=
      Max(0, TSTerrain.Vertices[I + J * Size].PosY);
    Edge.Vertices[N + K + L].PosZ := J - Size / 2;
    Edge.Vertices[N + K + L].NormX := -1;
    Edge.Vertices[N + K + L].NormY := 0;
    Edge.Vertices[N + K + L].NormZ := 0;
    Edge.Vertices[N + K + L].TexU := N / (Size / TS);
    Edge.Vertices[N + K + L].TexV := 1;
  end;

  K := Size;
  J := Size - 1;
  for N := 0 to Size - 1 do
  begin
    // Top edge
    I := N;
    Edge.Vertices[N + K].PosX := I - Size / 2;
    Edge.Vertices[N + K].PosY := Min(0, TSTerrain.Vertices[I + J * Size].PosY);
    Edge.Vertices[N + K].PosZ := J - Size / 2;
    Edge.Vertices[N + K].NormX := 0;
    Edge.Vertices[N + K].NormY := 0;
    Edge.Vertices[N + K].NormZ := 1;
    Edge.Vertices[N + K].TexU := N / (Size / TS);
    Edge.Vertices[N + K].TexV := 0;

    Edge.Vertices[N + K + L].PosX := I - Size / 2;
    Edge.Vertices[N + K + L].PosY :=
      Max(0, TSTerrain.Vertices[I + J * Size].PosY);
    Edge.Vertices[N + K + L].PosZ := J - Size / 2;
    Edge.Vertices[N + K + L].NormX := 0;
    Edge.Vertices[N + K + L].NormY := 0;
    Edge.Vertices[N + K + L].NormZ := 1;
    Edge.Vertices[N + K + L].TexU := N / (Size / TS);
    Edge.Vertices[N + K + L].TexV := 1;
  end;

  K := Size + Size;
  I := Size - 1;
  for N := 0 to Size - 1 do
  begin
    // Right edge
    J := Size - N;
    Edge.Vertices[N + K].PosX := I - Size / 2;
    Edge.Vertices[N + K].PosY := Min(0, TSTerrain.Vertices[I + J * Size].PosY);
    Edge.Vertices[N + K].PosZ := J - Size / 2;
    Edge.Vertices[N + K].NormX := 1;
    Edge.Vertices[N + K].NormY := 0;
    Edge.Vertices[N + K].NormZ := 0;
    Edge.Vertices[N + K].TexU := 1 - N / (Size / TS);
    Edge.Vertices[N + K].TexV := 0;

    Edge.Vertices[N + K + L].PosX := I - Size / 2;
    Edge.Vertices[N + K + L].PosY :=
      Max(0, TSTerrain.Vertices[I + J * Size].PosY);
    Edge.Vertices[N + K + L].PosZ := J - Size / 2;
    Edge.Vertices[N + K + L].NormX := 1;
    Edge.Vertices[N + K + L].NormY := 0;
    Edge.Vertices[N + K + L].NormZ := 0;
    Edge.Vertices[N + K + L].TexU := 1 - N / (Size / TS);
    Edge.Vertices[N + K + L].TexV := 1;
  end;

  K := Size + Size + Size;
  J := 0;
  for N := 0 to Size - 1 do
  begin
    // Bottom edge
    I := Size - N;
    Edge.Vertices[N + K].PosX := I - Size / 2;
    Edge.Vertices[N + K].PosY := Min(0, TSTerrain.Vertices[I + J * Size].PosY);
    Edge.Vertices[N + K].PosZ := J - Size / 2;
    Edge.Vertices[N + K].NormX := 0;
    Edge.Vertices[N + K].NormY := 0;
    Edge.Vertices[N + K].NormZ := -1;
    Edge.Vertices[N + K].TexU := 1 - N / (Size / TS);
    Edge.Vertices[N + K].TexV := 0;

    Edge.Vertices[N + K + L].PosX := I - Size / 2;
    Edge.Vertices[N + K + L].PosY :=
      Max(0, TSTerrain.Vertices[I + J * Size].PosY);
    Edge.Vertices[N + K + L].PosZ := J - Size / 2;
    Edge.Vertices[N + K + L].NormX := 0;
    Edge.Vertices[N + K + L].NormY := 0;
    Edge.Vertices[N + K + L].NormZ := -1;
    Edge.Vertices[N + K + L].TexU := 1 - N / (Size / TS);
    Edge.Vertices[N + K + L].TexV := 1;
  end;

  Terrain.Model.Meshes[1].AddVertices(@Edge.Vertices[0], Length(Edge.Vertices));
  Terrain.Model.Meshes[1].AddIndexes(@Edge.Indices[0], Length(Edge.Indices));

  Edge.Free;

  AddTerrainObjects;

  SetLength(WorkArray, TSTerrain.Width * TSTerrain.Depth);

  if Assigned(MiniMap) then
    UpdateMiniMap;
end;

procedure TMainForm.InitialiseTerrain;
var
  M: TMesh;
begin
  // create the terrain rendering object
  Terrain := TSceneObject.Create('GROUND');
  Terrain.Model := SceneManager.AddModel('GROUND');
  Terrain.ShaderProgram := BuildProgramObject('land_v.glsl', 'land_f.glsl', '');
  Terrain.Weightless := True;

  M := TMesh.Create(Terrain.Name);
  M.SetColour(0.2, 0.6, 0.2, 1.0);
  M.Drawmode := GL_TRIANGLE_STRIP;
  M.AddTexture(SceneManager.LoadTexture('sand2.jpg'), 1.0);
  M.AddTexture(SceneManager.LoadTexture('grass.jpg'), 1.0);
  M.AddTexture(SceneManager.LoadTexture('seaweed.jpg'), 1.0);
  Terrain.Model.AddMesh(M);

  M := TMesh.Create(Terrain.Name);
  M.SetColour(0.5, 0.5, 0.5, 1.0);
  M.Drawmode := GL_TRIANGLE_STRIP;
  Terrain.Model.AddMesh(M);

  GenerateTerrain;

  SceneManager.CoreObjects.Add(Terrain);
end;

procedure TMainForm.AddTerrainObjects;
var
  O: TSceneObject;
  M: TSceneModel;
  I: Integer;
  X, Y, Z: Double;
begin
  for O in SceneManager.StaticObjects.Objects do
    O.Free;
  SceneManager.StaticObjects.Clear;

  M := SceneManager.GetModel('TREE');

  // make hte number of trees proprtional to the area of the map...
  for I := 1 to GRIDSIZE * GRIDSIZE div 300 do
  begin
    Repeat
      X := GRIDSIZE * (Random - 0.5);
      Z := GRIDSIZE * (Random - 0.5);
      if Assigned(TSTerrain) then
        Y := TSTerrain.GetHeightAt(X, Z)
      else
        Y := 0.01;
    Until Y > 0;

    O := TSceneObject.Create('TREE' + IntToStr(I));
    O.Model := M;
    O.SetPosition(X, Y, Z);
    O.SetScale(2 + Random * 1.5, 7.5 + Random * 2.5, 2 + Random * 1.5);

    // give the tree a slight tilt and rotate about 360 degrees
    O.SetRotation(0.1 * (Random - 0.5), Random * 2 * PI, 0.1 * (Random - 0.5));

    O.SetColour(Random * 0.2 - 0.1, Random * 0.2 - 0.1, Random * 0.2 - 0.1, 1.0);

    SceneManager.StaticObjects.Add(O);
  end;

  // make the number of houses proportional to the size
  for I := 1 to GRIDSIZE * GRIDSIZE div 10000 do
  begin
    O := TSceneObject.Create('HOUSE' + IntToStr(I));
    O.Model := SceneManager.GetModel('FARMHOUSE');

    Repeat
      X := GRIDSIZE * (Random - 0.5);
      Z := GRIDSIZE * (Random - 0.5);
      if Assigned(TSTerrain) then
        Y := TSTerrain.GetHeightAt(X, Z)
      else
        Y := 0.01;
    Until Y > 0;

    O.SetPosition(X, Y, Z);
    O.SetRotation(0, Random * PI, 0);

    O.SetScale(5 + Random * 10, 3 + Random * 3, 10 + Random * 5);

    SceneManager.StaticObjects.Add(O);
  end;
end;

procedure TMainForm.BuildSky;
const
  RES = 36;
  RAD = GRIDSIZE * 1.5;
var
  I, J, N: Integer;
  M: TMesh;
  Width, Depth: Integer;
  SkyTriangleStrip: TTriangleStripMesh;
  R, E, Y: Double;
  CE: Double;
begin
  Sky := TSceneObject.Create('SKY');
  Sky.Model := SceneManager.AddModel('SKY');
  Sky.ShaderProgram := BuildProgramObject('sky_v.glsl', 'sky_f.glsl', '');
  Sky.SetRotation(0, Random * PI, 0);
  Sky.SetSpin(0, 0.001, 0);

  M := TMesh.Create(Sky.Name);
  M.SetColour(0.33, 0.33, 0.33, 1.0);
  M.Drawmode := GL_TRIANGLE_STRIP;
  M.AddTexture(SceneManager.LoadTexture('skydome2.jpg'), 1.0);

  Depth := RES;
  Width := 4 * RES;
  SkyTriangleStrip := TTriangleStripMesh.Create(Width, Depth);

  for J := 0 to Depth - 1 do
  begin
    E := 0.6 * PI * J / (Depth - 1) - 0.1 * PI;
    // start a bit lower to fill in below the horizon
    CE := Cos(E);
    Y := RAD * Sin(E);
    for I := 0 to Width - 1 do
    begin
      N := I + J * Width;
      R := 2 * PI * I / (Width - 1); // round 360 degrees
      SkyTriangleStrip.Vertices[N].PosX := RAD * Cos(R) * CE;
      SkyTriangleStrip.Vertices[N].PosY := Y;
      SkyTriangleStrip.Vertices[N].PosZ := RAD * Sin(R) * CE;
      SkyTriangleStrip.Vertices[N].TexU := I / Width;
      SkyTriangleStrip.Vertices[N].TexV := 1 - J / Depth;
    end;
  end;

  SkyTriangleStrip.CalcNormals;

  M.AddVertices(@SkyTriangleStrip.Vertices[0],
    Length(SkyTriangleStrip.Vertices));
  M.AddIndexes(@SkyTriangleStrip.Indices[0], Length(SkyTriangleStrip.Indices));

  SkyTriangleStrip.Free;

  Sky.Model.AddMesh(M);

  SceneManager.CoreObjects.Add(Sky);
end;

procedure TMainForm.BuildSea;
begin
  Sea := TSceneObject.Create('SEA');
  Sea.Model := SceneManager.AddModel('SEA');
  Sea.ShaderProgram := BuildProgramObject('water_v.glsl', 'water_f.glsl', '');
  Sea.Weightless := True;

  with Sea.Model.InitMesh do
  begin
    SetColour(0.2, 0.2, 0.8, 0.5);
    Drawmode := GL_TRIANGLE_STRIP;
    AddTexture(SceneManager.LoadTexture('water.png'), 1.0);
  // M.AddTexture(LoadGLTexture('checks.jpg'));

    AddVertices(@TSTerrain.Vertices[0], Length(TSTerrain.Vertices));
    AddIndexes(@TSTerrain.Indices[0], Length(TSTerrain.Indices));
  end;

  SceneManager.CoreObjects.Add(Sea);
end;

procedure TMainForm.LoadPointCloud(Number: Integer);
var
  Vertices: TVertexAttributeArray;
  N: Integer;
  Rot, Ele, RAD: Double;
begin
  SetLength(Vertices, Number);

  for N := 0 to Number - 1 do
  begin
    Rot := (Random - 0.5) * 2 * PI;
    Ele := (Random - 0.5) * PI;
    RAD := Random * 10;

    Vertices[N].PosX := RAD * Sin(Rot) * Cos(Ele);
    Vertices[N].PosY := RAD * Sin(Ele);
    Vertices[N].PosZ := RAD * Cos(Rot) * Cos(Ele);
    Vertices[N].Extra := Random * 10;
  end;

  CloudMesh := TMesh.Create('POINTCLOUD');
  glGenBuffers(1, @CloudMesh.OpenGLData.VBO);
  glBindBuffer(GL_ARRAY_BUFFER, CloudMesh.OpenGLData.VBO);
  CloudMesh.OpenGLData.VBOLength := Number;
  glBufferData(GL_ARRAY_BUFFER, Number * SizeOf(TVertexAttribute), @Vertices[0],
    GL_STATIC_DRAW);
  CloudMesh.Drawmode := GL_POINTS;

  Explosion := TSceneObject.Create('EXPLOSION');
  Explosion.ShaderProgram := BuildProgramObject('explosion_v.glsl',
    'explosion_f.glsl', '');
  Explosion.Model := SceneManager.AddModel('POINTCLOUD');
  Explosion.Model.AddMesh(CloudMesh);
  Explosion.Model.Meshes[0].SetColour(1.0, 0.8, 0.1, 1.0);
end;

procedure TMainForm.InitSceneObjects;
const
  PointVertices: Array [0 .. 2] of GLFloat = (0, 0, 0);
  LineVertices: Array [0 .. 5] of GLFloat = (0, 0, 0, 1, 0, 0);
  PlaneVertices: Array [0 .. 11] of GLFloat = (-0.5, 0, -0.5, 0.5, 0, -0.5, 0.5,
    0, 0.5, -0.5, 0, 0.5);
  PlaneTXCoords: Array [0 .. 7] of GLFloat = (0.0, 0.0, 1.0, 0.0, 1.0, 1.0,
    0.0, 1.0);

  // http://www.paridebroggi.com/2015/06/optimized-cube-opengl-triangle-strip.html
  CubeVertices: Array [0 .. 23] of GLFloat = (0.5, 0.5, 0.5, -0.5, 0.5, 0.5,
    0.5, 0.5, -0.5, -0.5, 0.5, -0.5, 0.5, -0.5, 0.5, -0.5, -0.5, 0.5, -0.5,
    -0.5, -0.5, 0.5, -0.5, -0.5);

  Cube2Vertices: Array [0 .. 23] of GLFloat = (0.5, 1.0, 0.5, -0.5, 1.0, 0.5,
    0.5, 1.0, -0.5, -0.5, 1.0, -0.5, 0.5, -0.0, 0.5, -0.5, -0.0, 0.5, -0.5,
    -0.0, -0.5, 0.5, -0.0, -0.5);

  CubeIndices: Array [0 .. 13] of GLUInt = (3, 2, 6, 7, 4, 2, 0, 3, 1, 6,
    5, 4, 1, 0);

//  PyramidVertices: Array [0 .. 14] of GLFloat = (0.51, 0.5, 0.51, -0.51, 0.5,
//    0.51, 0.51, 0.5, -0.51, -0.51, 0.5, -0.51, 0.0, 1.25, 0.0);
//
//  PyramidIndices: Array [0 .. 13] of GLUInt = (3, 2, 4, 4, 4, 2, 0, 3, 1, 4,
//    4, 4, 1, 0);

  matrixA: Array [0 .. 15] of GLFloat = (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
    12, 13, 14, 15);
  matrixB: Array [0 .. 3, 0 .. 3] of GLFloat = ((0, 1, 2, 3), (4, 5, 6, 7),
    (8, 9, 10, 11), (12, 13, 14, 15));

var
  Model: TSceneModel;
  Mesh: TMesh;
  I: Integer;
  IniFile: TIniFile;

const
  Grid = 32;
  GridSpacing = 1;

procedure LoadDefinedModel(Feature: String);
var
  S: String;
  Normalisation: TObjectNormalisation;
  Model: TSceneModel;
begin
  if IniFile.SectionExists(Feature) then
  begin
    if IniFile.ValueExists(Feature, 'MODEL') then
    begin
      S := IniFile.ReadString(Feature, 'NORMALISATION', 'NONE');
      if S = 'CENTRE' then
        Normalisation := onCentre
      else if S = 'CENTREBOTTOM' then
        Normalisation := onCentreBottom
      else
        Normalisation := onNone;

      S := IniFile.ReadString(Feature, 'MODEL', 'cube.obj');
      if not FileExists(ExtractFilePath(Application.ExeName) + 'models\' + S) then
        S := 'cube.obj';

      Model := SceneManager.LoadModel(Feature, S, Normalisation);
      if Model <> nil then
      begin
        if IniFile.ValueExists(Feature, 'ORIENTX') then
          Model.Orientation[0] := IniFile.ReadFloat(Feature, 'ORIENTX', 0) * PI / 180;
        if IniFile.ValueExists(Feature, 'ORIENTY') then
          Model.Orientation[1] := IniFile.ReadFloat(Feature, 'ORIENTY', 0) * PI / 180;
        if IniFile.ValueExists(Feature, 'ORIENTZ') then
          Model.Orientation[2] := IniFile.ReadFloat(Feature, 'ORIENTZ', 0) * PI / 180;

        if IniFile.ValueExists(Feature, 'SCALEX') then
          Model.Scale[0] := IniFile.ReadFloat(Feature, 'SCALEX', 0);
        if IniFile.ValueExists(Feature, 'SCALEY') then
          Model.Scale[1] := IniFile.ReadFloat(Feature, 'SCALEY', 0);
        if IniFile.ValueExists(Feature, 'SCALEZ') then
          Model.Scale[2] := IniFile.ReadFloat(Feature, 'SCALEZ', 0);
      end;
    end;
  end;
end;

begin
  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'config.ini');

  LoadDefinedModel('PLAYER');
  LoadDefinedModel('TREE');
  LoadDefinedModel('PLANE');
  LoadDefinedModel('STAR');
  LoadDefinedModel('TARGET');
  LoadDefinedModel('FARMHOUSE');
  LoadDefinedModel('BOMB');

  IniFile.Free;

  Eye := TSceneObject.Create('EYE');

  Player := TSceneObject.Create('PLAYER');
  Player.Model := SceneManager.GetModel('PLAYER');
  Player.Damped := True;
  Player.Weightless := False;
  SceneManager.CoreObjects.Add(Player);

  PointGeometry := TOpenGLData.Create;
  glGenBuffers(1, @PointGeometry.VBO);
  glBindBuffer(GL_ARRAY_BUFFER, PointGeometry.VBO);
  PointGeometry.VBOLength := Length(PointVertices) div 3;
  glBufferData(GL_ARRAY_BUFFER, Length(PointVertices) * SizeOf(GLFloat),
    @PointVertices, GL_STATIC_DRAW);

  for I := 0 to 3 do
  begin
    DebugPoint[I] := TSceneObject.Create('DEBUGPOINT');
    DebugPoint[I].Model := SceneManager.AddModel('DEBUGPOINT');
    DebugPoint[I].Deactivate;
    Mesh := TMesh.Create(DebugPoint[I].Name);
    Mesh.OpenGLData.Copy(PointGeometry);
    Mesh.Drawmode := GL_POINTS;
    Mesh.SetColour(1.0, 0.0, 0.0, 1.0);
    DebugPoint[I].Model.AddMesh(Mesh);
    DebugPoint[I].SetScale(4.0, 4.0, 4.0);
    SceneManager.CoreObjects.Add(DebugPoint[I]);
  end;

  // create a cube vbo centre aligned
  CubeGeometry := TOpenGLData.Create;

  glGenBuffers(1, @CubeGeometry.VBO);
  glBindBuffer(GL_ARRAY_BUFFER, CubeGeometry.VBO);
  CubeGeometry.VBOLength := Length(CubeVertices) div 3;
  glBufferData(GL_ARRAY_BUFFER, Length(CubeVertices) * SizeOf(GLFloat),
    @CubeVertices, GL_STATIC_DRAW);

  glGenBuffers(1, @CubeGeometry.EBO);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, CubeGeometry.EBO);
  CubeGeometry.EBOLength := Length(CubeIndices);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, Length(CubeIndices) * SizeOf(GLUInt),
    @CubeIndices, GL_STATIC_DRAW);

  // create a cube vbo this timebottom aligned
  Cube2Geometry := TOpenGLData.Create;

  glGenBuffers(1, @Cube2Geometry.VBO);
  glBindBuffer(GL_ARRAY_BUFFER, Cube2Geometry.VBO);
  Cube2Geometry.VBOLength := Length(Cube2Vertices) div 3;
  glBufferData(GL_ARRAY_BUFFER, Length(Cube2Vertices) * SizeOf(GLFloat),
    @Cube2Vertices, GL_STATIC_DRAW);

  glGenBuffers(1, @Cube2Geometry.EBO);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, Cube2Geometry.EBO);
  Cube2Geometry.EBOLength := Length(CubeIndices);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, Length(CubeIndices) * SizeOf(GLUInt),
    @CubeIndices, GL_STATIC_DRAW);

  Dymo := TSceneObject.Create('DYMO');
  Dymo.Model := SceneManager.AddModel('DYMO');
  Dymo.SetScale(1.0, 1.0, 1.0);
  Dymo.Active := False;
  Mesh := TMesh.Create(Dymo.Name);
  Mesh.Drawmode := GL_TRIANGLES;
  Mesh.SetColour(1.0, 1.0, 1.0, 0.5);
  Mesh.AddTexture(DistanceFont.Texture, 1.0);
  Dymo.Model.AddMesh(Mesh);
  Dymo.ShaderProgram := BuildProgramObject('font_v.glsl', 'font_f.glsl', '');

  Dymo2D := TSceneObject.Create('DYMO2D');
  Dymo2D.Model := SceneManager.AddModel('DYMO2D');
  Dymo2D.SetScale(0.25, 0.25, 0.25);
  Dymo2D.Active := False;
  Mesh := TMesh.Create(Dymo2D.Name);
  Mesh.Drawmode := GL_TRIANGLES;
  Mesh.SetColour(1.0, 1.0, 1.0, 0.5);
  Mesh.AddTexture(DistanceFont.Texture, 1.0);
  Dymo2D.Model.AddMesh(Mesh);
  Dymo2D.ShaderProgram := BuildProgramObject('font_2d_v.glsl', 'font_2d_f.glsl', '');

  Model := SceneManager.AddModel('MISSILE');
  Mesh := TMesh.Create('MISSILE');
  Mesh.OpenGLData.Copy(CubeGeometry);
  Mesh.Drawmode := GL_TRIANGLE_STRIP;
  Mesh.SetColour(1.0, 1.0, 1.0, 1);
  Model.AddMesh(Mesh);

  Model.BBMin[0] := -0.5;
  Model.BBMin[1] := -0.5;
  Model.BBMin[2] := -0.5;

  Model.BBMax[0] := 0.5;
  Model.BBMax[1] := 0.5;
  Model.BBMax[2] := 0.5;

  CollisionBox := TSceneObject.Create('CUBE');
  CollisionBox.Model := SceneManager.AddModel('CUBE');
  CollisionBox.Active := False;
  CollisionBox.SetScale(1.0, 1.0, 1.0);
  Mesh := TMesh.Create(CollisionBox.Name);
  Mesh.OpenGLData.Copy(Cube2Geometry);
  Mesh.Drawmode := GL_LINE_LOOP;
  Mesh.SetColour(1.0, 1.0, 1.0, 1.0);
  CollisionBox.Model.AddMesh(Mesh);
end;

procedure TMainForm.TestKeys(AKey: Word; Toggle: Boolean);
begin
  if AKey = VK_Up then
    KeyMatrix.K_UP := Toggle

  Else If AKey = VK_Down then
    KeyMatrix.K_DOWN := Toggle

  else if AKey = VK_Left then
    KeyMatrix.K_LEFT := Toggle

  else if AKey = VK_Right then
    KeyMatrix.K_RIGHT := Toggle

  else if AKey = VK_OEM_2 then
    KeyMatrix.K_SLASH := Toggle;
end;

procedure TMainForm.PollKeys(DT: Double);
begin
  if KeyMatrix.K_UP and not KeyMatrix.K_DOWN then
    OnAcceleration(5 * DT)

  else if KeyMatrix.K_DOWN and not KeyMatrix.K_UP then
    OnAcceleration(-5 * DT);

  if KeyMatrix.K_LEFT and not KeyMatrix.K_RIGHT then
    Player.Turn(-2 * DT, 0.1)

  else if KeyMatrix.K_RIGHT and not KeyMatrix.K_LEFT then
    Player.Turn(2 * DT, 0.1);

  if KeyMatrix.K_SLASH then
    Player.Velocity[1] := Player.Velocity[1] + 50 * DT;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  TestKeys(Key, True);
end;

procedure TMainForm.FormKeyPress(Sender: TObject; var Key: Char);
var
  AKey: String;
  F: Double;
const
  Delta = 0.1;
begin
  F := 1.0;

  AKey := LowerCase(Key);

  if AKey = #13 then
    ResetPosition

  else if AKey = #32 then
    LaunchMissile

  else if AKey = 'g' then
  begin
    GenerateTerrain;
    ResetPosition;
  end

  else if AKey = 'j' then
  begin
    CollisionBoxDisplayMode := not CollisionBoxDisplayMode;
    MinimapAge := 0;
  end

  else if AKey = 'y' then
    InstancingEnabled := not InstancingEnabled

  else if AKey = 'w' then
    WireframeMode := not WireframeMode

  else if AKey = 'p' then
    Paused := not Paused

  else if AKey = 't' then
    TextureMode := not TextureMode

  else if AKey = 'c' then
    Culling := not Culling

  else if AKey = 'o' then
  begin
    Player.SetPosition(0.0, 0.0, 0.0);
    Player.SetRotation(0.0, 0.0, 0.0);

    Eye.SetPosition(0.0, GRIDSIZE / 2, 0.0);
    Eye.SetRotation(PI / 2, 0.0, 0.0);
  end

  else if AKey = 'l' then
    OnTranslation(1, 0, 0, -10 * F)
  else if AKey = 'r' then
    OnTranslation(1, 0, 0, 10 * F)

  else if AKey = 'u' then
    OnTranslation(0, 1, 0, 10 * F)
  else if AKey = 'd' then
    OnTranslation(0, 1, 0, -10 * F)

  else if AKey = 'f' then
    OnTranslation(0, 0, 1, -10 * F)
  else if AKey = 'b' then
    OnTranslation(0, 0, 1, 10 * F)

  else if AKey = 'q' then
    OnRotation(1, 0, 0, F * -PI / 45)
  else if AKey = 'a' then
    OnRotation(1, 0, 0, PI / 45)

  else if AKey = 'z' then
    OnRotation(0, 1, 0, -PI / 45)
  else if AKey = 'x' then
    OnRotation(0, 1, 0, PI / 45)

  else if AKey = #27 then
    StopNow := True;
end;

procedure TMainForm.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  TestKeys(Key, False);
end;

procedure TMainForm.RenderLoop;
var
  OT, T, T2: UInt32;
  FR, DeltaT, FCT, H: Double;
  FrameCount, I: Integer;
  O, E: TSceneObject;
  S: String;
begin
  Running := True;

  OT := GetTickCount;
  T2 := OT;
  FrameCount := 0;
  FR := 0;

  Repeat
    LastErrNo := 0;

    T := GetTickCount;
    RunTime := T / 1000;

    DeltaT := (T - T2);  // delta time in milliseconds

    T2 := T;

    // limit frame rate to 100 fps
    if DeltaT < 10 then
    begin
      Sleep(Trunc(10 - DeltaT));
      DeltaT := 10;
    end;

    PollKeys(DeltaT / 1000);

    if not Paused then
    begin
      SceneManager.MoveObjects(DeltaT);

      TestBoatCollisions;

      DoLuckyDip;

      // test for bomb/missile collisions
      if Assigned(Terrain) then
      begin
        glBindBuffer(GL_ARRAY_BUFFER, Terrain.Model.Meshes[0].OpenGLData.VBO);

        for O in SceneManager.TemporaryObjects.Objects do
        begin
          if O.Active and (O.Name = 'MISSILE') then
          begin
            // fix missile to terrain or sea level + 0.5m if lower
            O.Position[1] := Max(O.Position[1], TSTerrain.GetHeightAt(O.Position[0],
              O.Position[2]) + 0.5);

            TestMissileCollisions(O);
          end;

          if O.Active and (O.Name = 'BOMB') then
          begin
            // get the terrain height at position
            H := Max(0, TSTerrain.GetHeightAt(O.Position[0], O.Position[2]));

            // has the bomb hit the deck?
            if O.Position[1] < H then
            begin
              I := TSTerrain.GetVerticeIndex(O.Position[0], O.Position[2]);
              if (I <> -1) and (I < Length(TSTerrain.Vertices)) then
              begin
                TSTerrain.Vertices[I].Extra := 1.0;
                glBufferSubData(GL_ARRAY_BUFFER, SizeOf(TVertexAttribute) * I,
                  SizeOf(TVertexAttribute), @TSTerrain.Vertices[I]);
              end;

              O.Deactivate;

              E := TSceneObject.Create('EXPLOSION');
              E.Model := SceneManager.GetModel('POINTCLOUD');
              E.ShaderProgram := Explosion.ShaderProgram;
              E.Position := O.Position;
              E.Position[1] := H;
              E.Activate(5);
              SceneManager.TemporaryObjects.Add(E);
            end;
          end;
        end;
      end;

      // update cell pollution status
      if Assigned(Terrain) then
      begin
        glBindBuffer(GL_ARRAY_BUFFER, Terrain.Model.Meshes[0].OpenGLData.VBO);

        // halve the value where the boat is
        I := TSTerrain.GetVerticeIndex(Player.Position[0], Player.Position[2]);
        if (I <> -1) and (I < Length(TSTerrain.Vertices)) then
        begin
          TSTerrain.Vertices[I].Extra := Max(0, TSTerrain.Vertices[I].Extra / 2);
          glBufferSubData(GL_ARRAY_BUFFER, SizeOf(TVertexAttribute) * I,
            SizeOf(TVertexAttribute), @TSTerrain.Vertices[I]);
        end;

        // update polluted cells
        for O in SceneManager.DynamicObjects.Objects do
        begin
          if O.Active and (Copy(O.Name, 1, 6) = 'Target') then
          begin
            I := TSTerrain.GetVerticeIndex(O.Position[0], O.Position[2]);
            if (I <> -1) and (I < Length(TSTerrain.Vertices)) then
            begin
              TSTerrain.Vertices[I].Extra :=
                Min(1, TSTerrain.Vertices[I].Extra + Random);
              glBufferSubData(GL_ARRAY_BUFFER, SizeOf(TVertexAttribute) * I,
                SizeOf(TVertexAttribute), @TSTerrain.Vertices[I]);
            end;
          end;
        end;
      end;
    end;

    // use this to reload the whole vertex data buffer - but done every 2 seconds in minimap update
    // glBufferSubData(GL_ARRAY_BUFFER, 0, SizeOf(TVertexAttribute) * Length(TSTerrain.Vertices),
    // @TSTerrain.Vertices[0]);

    SetViewMatrix;

    ErrorCheck;

    DoRender;

    Inc(FrameCount);
    FCT := T - OT; // time in milliseconds elapsed since last frame rate calculation
    if FCT >= 1000 then
    begin
      FR := 1000 * FrameCount / FCT;
      FrameCount := 0;
      OT := T;
    end;

    if InstancingEnabled then
      S := ' Inst'
    else
      S := '';

    Caption := Format('pxyz = %n, %n, %n,', [LookatMatrix[3, 0], LookatMatrix[3, 1], LookatMatrix[3, 2]]) + ' ' +
      Format('rxyz = %n, %n, %n', [(Eye.Rotation[0] + Player.Rotation[0]) * 180 /
      PI, (Eye.Rotation[1] + Player.Rotation[1]) * 180 / PI,
      (Eye.Rotation[2] + Player.Rotation[2]) * 180 / PI]) + ' @' +
      Format('%3.0n', [FR]) + 'fps, DeltaT = ' + Format('%.3n', [DeltaT]) + 'ms LastErr = ' + IntToStr(LastErrNo) + S;

    Application.ProcessMessages;

  Until StopNow;

  Running := False;
  Close;
end;

procedure TMainForm.DoRender;
var
  Pixels: Array [0 .. 2] of GLFloat;
  C: TGLVectorf4;
  ObjID: Integer;
begin
  if not OpenGLReady then
    Exit;

  ErrorCheck;

  if WireframeMode then
    glClearColor(0.0, 0.0, 0.0, 1)
  else
    glClearColor(0.5, 0.5, 0.5, 1);

  glClearDepth(1.0);

  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  if TextureMode then
  begin
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  end
  else
    glDisable(GL_BLEND);

  ErrorCheck;

  // draw the dynamic objects once in selection mode
  if SelectionMode then
  begin
    DrawObjectlist(SceneManager.DynamicObjects);
    glFlush;

    GlPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glReadPixels(SelX, ClientHeight - SelY, 1, 1, GL_RGB, GL_FLOAT, @Pixels);

    ObjID := Trunc(255 * Pixels[0] * 256 * 256 + 255 * Pixels[1] * 256 + 255 *
      Pixels[2]);

    Caption := IntToStr(SelX) + ',' + IntToStr(SelY) + ' = ' +
      FloatToStr(Pixels[0]) + ',' + FloatToStr(Pixels[1]) + ',' +
      FloatToStr(Pixels[2]) + ' > ' + IntToStr(ObjID);

    if ObjID < SceneManager.DynamicObjects.Objects.Count then
      SelectedObject := SceneManager.DynamicObjects.Objects.Items[ObjID];

    SelectionMode := False;
  end;

  ErrorCheck;

  UpdateLights;

  // make sure the player boat is positioned correctly
  PositionObject(Player);

  if not CollisionBoxDisplayMode then
    DrawObjectlist(SceneManager.CoreObjects);

  DrawObjectlist(SceneManager.StaticObjects);
  DrawObjectlist(SceneManager.DynamicObjects);
  DrawObjectlist(SceneManager.TemporaryObjects);

//  DrawObjectListLabels(SceneManager.StaticObjects);
//  DrawObjectlistLabels(SceneManager.DynamicObjects);

  DrawMiniMap;

  ErrorCheck;

  if not CollisionBoxDisplayMode then
  begin
    C[0] := 1.0;
    C[1] := 1.0;
    C[2] := 0.4;
    C[3] := 0.5;
    Draw2DLabel('Score : ' + IntToStr(Score), 0.98, 0.93, 0.06,
      taRightJustify, C);
    Draw2DLabel('Targets remaining : ' + IntToStr(TargetsRemaining), -0.98,
      0.93, 0.06, taLeftJustify, C);

    C[0] := 1.0;
    C[0] := 1.0 - PercentPolluted / 100;
    C[2] := 0.4 - PercentPolluted / 400;
    C[3] := 0.5;
    Draw2DLabel('Pollution level   : ' + IntToStr(PercentPolluted), -0.98, 0.83,
      0.06, taLeftJustify, C);

    C[0] := 0.4;
    C[1] := 0.4;
    C[2] := 0.4;
    C[3] := 0.5;
    Draw2DLabel
      ('Controls : Arrow keys = acc/dec/turn, Space = fire missile, Esc = Quit',
      -0.98, -0.93, 0.04, taLeftJustify, C);

    C[0] := 1.0;
    C[1] := 1.0;
    C[2] := 0.0;
    C[3] := 0.9;
    Draw2DLabel(Caption, -0.98, -0.99, 0.03, taLeftJustify, C);
  end;

  glFlush;

  Swapbuffers(glDC);
end;

procedure TMainForm.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  SelectionMode := True;
  SelX := X;
  SelY := Y;
end;

procedure TMainForm.NextLevel;
begin
  Inc(Level);

  GenerateTerrain;
  ResetPosition;
  GenerateTargets;
end;

procedure TMainForm.ActivateShader(Shader: glHandle);
begin
  if (Shader = -1) and (ActiveShader <> -1) then
    glUseProgram(0)
  else
  begin
    glUseProgram(Shader);
    GetLocations(Shader);

    // set uniform matrices for eye position and projection
    // note use one dimensional matrices for simplicity
    glUniformMatrix4fv(locView, 1, GL_FALSE, @ViewMatrix);
    glUniformMatrix4fv(locProjection, 1, GL_FALSE, @ProjectionMatrix);

    // used for calculating fog and lighting etc.
    glUniform3f(locEye, LookatMatrix[3, 0], LookatMatrix[3, 1], LookatMatrix[3, 2]);

    if SelectionMode then
      glUniform1i(locselmode, 1)
    else
      glUniform1i(locselmode, 0);

    glUniform1f(locRT, RunTime);
  end;

  ActiveShader := Shader;
end;

procedure TMainForm.DrawObject(O: TSceneObject; InstanceCount: Integer);
var
  Mesh: TMesh;
  ModelMatrix: TGLMatrixF4;
  V: UInt32;
  V1, V2, V3: GLUInt;

  procedure DrawMesh(M: TMesh);
  var
    I: Integer;
    DrawMode: GLUint;
  begin
    if WireframeMode and (M.Drawmode <> GL_POINTS) then
      DrawMode := GL_LINE_LOOP
    else
      DrawMode := M.Drawmode;

    if M.Colour[3] = 1.0 then
      glDisable(GL_BLEND)
    else
      glEnable(GL_BLEND);

    if (M.Textures.Count <> 0) and not WireframeMode and TextureMode and
      not MiniMapMode and not CollisionBoxDisplayMode then
    begin
      glUniform1i(locTextures, M.Textures.Count);

      for I := 0 to M.Textures.Count - 1 do
      begin
        glActiveTexture(GL_TEXTURE0 + I);
        glBindTexture(GL_TEXTURE_2D, M.Textures[I].Name);
      end;

      glUniform1i(locTex0, 0);

      if locTex1 <> -1 then
      begin
        if M.Textures.Count > 1 then
          glUniform1i(locTex1, 1)
        else
          glUniform1i(locTex1, 0);
      end;

      if locTex2 <> -1 then
      begin
        if M.Textures.Count > 1 then
          glUniform1i(locTex2, 2)
        else
          glUniform1i(locTex2, 0);
      end;
    end
    else
      glUniform1i(locTextures, 0);

    if not SelectionMode then
    begin
      glUniform4f(locColour, M.Colour[0], M.Colour[1], M.Colour[2],
        M.Colour[3]);

      if (M.Effect <> nil) and (idxEffectBlock <> -1) then
      begin
        glUniform1i(locUseEffect, 1);

        glBindBuffer(GL_UNIFORM_BUFFER, EffectBuffer);

        glBindBufferBase(GL_UNIFORM_BUFFER, 1, EffectBuffer);

        glBufferData(GL_UNIFORM_BUFFER, SizeOf(TMyEffectParms), @M.Effect.Parms,
          GL_DYNAMIC_DRAW);

          // not needed if binding is specific in the actual shader
          // in fact this causes a 1281? error.
//        glUniformBlockBinding(O.ShaderProgram, idxEffectBlock, 1);
      end
      else
      begin
        glUniform1i(locUseEffect, 0);
      end;
    end;

    if M.OpenGLData.EBO <> 0 then
    begin
      if M.OpenGLData.VertexAttributeSize = 3 then
      begin
        glEnableVertexAttribArray(IDX_POSITION);

        glBindBuffer(GL_ARRAY_BUFFER, M.OpenGLData.VBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, M.OpenGLData.EBO);

        glVertexAttribPointer(IDX_POSITION, M.OpenGLData.VertexAttributeSize,
          GL_FLOAT, GL_FALSE, 0, nil);

        if InstanceCount = 0 then
          glDrawElements(DrawMode, M.OpenGLData.EBOLength,
            GL_UNSIGNED_INT, NIL)
        else
          glDrawElementsInstanced(Drawmode, M.OpenGLData.EBOLength,
            GL_UNSIGNED_INT, NIL, InstanceCount);

        glDisableVertexAttribArray(IDX_POSITION);
      end

      else
      begin
        glEnableVertexAttribArray(IDX_POSITION);
        glEnableVertexAttribArray(IDX_NORMAL);
        glEnableVertexAttribArray(IDX_TEXCOORD);
        glEnableVertexAttribArray(IDX_EXTRA);

        glBindBuffer(GL_ARRAY_BUFFER, M.OpenGLData.VBO);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, M.OpenGLData.EBO);

        glVertexAttribPointer(IDX_POSITION, 3, GL_FLOAT, False,
          SizeOf(TVertexAttribute), GLVoid(0 * SizeOf(GLFloat)));
        glVertexAttribPointer(IDX_NORMAL, 3, GL_FLOAT, False,
          SizeOf(TVertexAttribute), GLVoid(3 * SizeOf(GLFloat)));
        glVertexAttribPointer(IDX_TEXCOORD, 2, GL_FLOAT, False,
          SizeOf(TVertexAttribute), GLVoid(6 * SizeOf(GLFloat)));
        glVertexAttribPointer(IDX_EXTRA, 1, GL_FLOAT, False,
          SizeOf(TVertexAttribute), GLVoid(8 * SizeOf(GLFloat)));

        if InstanceCount = 0 then
          glDrawElements(Drawmode, M.OpenGLData.EBOLength,
            GL_UNSIGNED_INT, NIL)
        else
          glDrawElementsInstanced(Drawmode, M.OpenGLData.EBOLength,
            GL_UNSIGNED_INT, NIL, InstanceCount);

        glDisableVertexAttribArray(IDX_EXTRA);
        glDisableVertexAttribArray(IDX_TEXCOORD);
        glDisableVertexAttribArray(IDX_NORMAL);
        glDisableVertexAttribArray(IDX_POSITION);
      end;
    end

    else
    begin
      glEnable(GL_VERTEX_ARRAY);

      if (Drawmode = GL_POINTS) and (O.Scale[0] < 10) then
        glPointSize(O.Scale[0])
      else
        glPointSize(1);

      glBindBuffer(GL_ARRAY_BUFFER, M.OpenGLData.VBO);
      glVertexPointer(M.OpenGLData.VertexAttributeSize, GL_FLOAT, 0, nil);

      if InstanceCount = 0 then
        glDrawArrays(Drawmode, 0, M.OpenGLData.VBOLength)
      else
        glDrawArraysInstanced(Drawmode, 0, M.OpenGLData.VBOLength,
          InstanceCount);

      glDisable(GL_VERTEX_ARRAY);
    end;
  end;

begin
  if O <> nil then
  begin
    if O.ShaderProgram <> 0 then
      ActivateShader(O.ShaderProgram)
    else
    begin
      if InstanceCount <> 0 then
        ActivateShader(MainInstancedShader)
      else
        ActivateShader(MainShader);
    end;

    // send elapsed time to any shader needing it
    if locET <> -1 then
    begin
      if O.ActivatedTC > 0 then
        glUniform1f(locET, (GetTickCount - O.ActivatedTC) / 1000)
      else
        glUniform1f(locET, 0);
    end;

    if locLights <> -1 then
    begin
//      glUniform1i(locLights, LIGHTS);
      glUniform1i(locLights, 3);

      if idxLightBlock <> -1 then
      begin
        glBindBuffer(GL_UNIFORM_BUFFER, LightBuffer);
        glBindBufferBase(GL_UNIFORM_BUFFER, 3, LightBuffer);
        glBufferData(GL_UNIFORM_BUFFER, SizeOf(TGLLight) * MAXLIGHTS, @LightArray[0],
          GL_DYNAMIC_DRAW);
      end
    end;

    if not InstancingEnabled or (InstanceCount = 0) then
    begin
      ModelMatrix := O.GetModelMatrix;
      glUniformMatrix4fv(locModel, 1, GL_FALSE, @ModelMatrix);
    end

    else
    begin
      if idxInstanceBlock <> -1 then
      begin
        glBindBuffer(GL_UNIFORM_BUFFER, InstanceBuffer);
        glBindBufferBase(GL_UNIFORM_BUFFER, 2, InstanceBuffer);
        glBufferData(GL_UNIFORM_BUFFER, SizeOf(TGLInstanceData) * InstanceCount, @InstanceArray[0],
          GL_DYNAMIC_DRAW);
      end

      else if locModel <> -1 then
        glUniformMatrix4fv(locModel, InstanceCount, GL_FALSE, @InstanceArray[0]);
    end;

    if SelectionMode then
    begin
      V := SceneManager.DynamicObjects.Objects.IndexOf(O);
      V3 := V and 255; // lsB
      V := V shr 8;
      V2 := V and 255; // middle byte 1
      V := V shr 8;
      V1 := V and 255; // msB
      glUniform1i(locid1, V1);
      glUniform1i(locid2, V2);
      glUniform1i(locid3, V3);
    end;

    if CollisionBoxDisplayMode then
    begin
      glUniform4f(locScale, O.Scale[0] * (O.Model.BBMax[0] - O.Model.BBMin[0]
        ), O.Scale[1] * (O.Model.BBMax[1] - O.Model.BBMin[1]),
        O.Scale[2] * (O.Model.BBMax[2] - O.Model.BBMin[2]), 1);

      for Mesh in CollisionBox.Model.Meshes do
      begin
        Mesh.Colour := O.Colour;
        Mesh.Colour[3] := 0.50;
        Mesh.Drawmode := GL_TRIANGLE_STRIP;
        DrawMesh(Mesh);

        Mesh.SetColour(0.0, 1.0, 0.0, 1.0);
        Mesh.Drawmode := GL_LINE_LOOP;
        DrawMesh(Mesh);
      end;
    end
    else
    begin
      glUniform4f(locScale, 1.0, 1.0, 1.0, 1.0);
      for Mesh in O.Model.Meshes do
        DrawMesh(Mesh);
    end;

    ErrorCheck;
  end;
end;

procedure TMainForm.PositionObject(SceneObject: TSceneObject);
var
  WaveHeight, TerrainHeight, Deck: Double;
function GetSlopeBetween(X1, Z1, X2, Z2: Double): Double;
var
  Z, A, B, C, D: Double;
begin
  A := GetWaveHeightAt(RunTime, X1, Z1);
  if Assigned(TSTerrain) then
  begin
    Z := TSTerrain.GetHeightAt(X1, Z1);
    if Z > A then
      A := Z;
  end;

  B := GetWaveHeightAt(RunTime, X2, Z2);
  if Assigned(TSTerrain) then
  begin
    Z := TSTerrain.GetHeightAt(X2, Z2);
    if Z > B then
      B := Z;
  end;

  C := B - A;
  D := Sqrt((X1 - X2) * (X1 - X2) + (Z1 - Z2) * (Z1 - Z2));

  Result := Arctan2(C, D);
end;

procedure Orient;
var
  M: TSceneModel;
  SA, CA: Double;
begin
  M := SceneObject.Model;

  SA := Sin(SceneObject.Rotation[1]);
  CA := Cos(SceneObject.Rotation[1]);

  SceneObject.Wobble[0] := 0.1 * (9 * SceneObject.Wobble[0] + GetSlopeBetween(
    SceneObject.Position[0] + M.BBMax[2] * SceneObject.Scale[2] * SA,
    SceneObject.Position[2] - M.BBMax[2] * SceneObject.Scale[2] * CA,
    SceneObject.Position[0] + M.BBMin[2] * SceneObject.Scale[2] * SA,
    SceneObject.Position[2] - M.BBMin[2] * SceneObject.Scale[2] * CA)
    );

 SceneObject.Wobble[2] := 0.1 * (9 * SceneObject.Wobble[2] + GetSlopeBetween(
    SceneObject.Position[0] + M.BBMax[0] * SceneObject.Scale[0] * CA,
    SceneObject.Position[2] - M.BBMax[0] * SceneObject.Scale[0] * SA,
    SceneObject.Position[0] + M.BBMin[0] * SceneObject.Scale[0] * CA,
    SceneObject.Position[2] - M.BBMin[0] * SceneObject.Scale[0] * SA)
    );
end;

begin
  if Assigned(TSTerrain) then
  begin
    WaveHeight := GetWaveHeightAt(RunTime, SceneObject.Position[0], SceneObject.Position[2]);
    TerrainHeight := TSTerrain.GetHeightAt(SceneObject.Position[0], SceneObject.Position[2]);
    Deck := Max(WaveHeight, TerrainHeight);
  end
  else
  begin
    WaveHeight := 0;
    TerrainHeight := 0;
    Deck := 0;
  end;

  if (Player.Velocity[1] <= 0.05) and (SceneObject.Position[1] + SceneObject.Shift[1] < WaveHeight + 0.5) then
  begin
    SceneObject.Shift[1] := SceneObject.Shift[1] * 0.9 + WaveHeight * 0.1;
    SceneObject.Position[1] := SceneObject.Position[1] * 0.1;
    SceneObject.Velocity[1] := 0.0;
    Orient;
  end

  else if (Player.Velocity[1] <= 0.05) and (SceneObject.Position[1] + SceneObject.Shift[1] < TerrainHeight + 0.5) then
  begin
    SceneObject.Shift[1] := SceneObject.Shift[1] * 0.1;
    SceneObject.Position[1] := SceneObject.Position[1] * 0.9 + TerrainHeight * 0.1;
    SceneObject.Velocity[1] := 0.0;
    Orient;
  end

  else
  begin
    // should be in the air of going up into the air
    // damp down any existing wobble
    SceneObject.Shift[1] := 0.9 * SceneObject.Shift[1];
    SceneObject.SetWobble(0.9 * SceneObject.Wobble[0], 0.9 * SceneObject.Wobble[1],
      0.9 * SceneObject.Wobble[2]);
  end;
end;

procedure TMainForm.DrawObjectlist(ObjectList: TSceneObjectList);
var
  O, LastO: TSceneObject;
  LastModel: TSceneModel;
  V, Z: TGLVectorf3;
  D: GLFloat;
  IC: Integer;
begin
  ActiveShader := -1;
  LastModel := nil;
  LastO := nil;
  IC := 0;

  if InstancingEnabled and ObjectList.Instanced then
    ObjectList.DoSort;

  // this is the current forward vector of the camera
  Z[0] := LookatMatrix[2, 0];
  Z[1] := LookatMatrix[2, 1];
  Z[2] := LookatMatrix[2, 2];

  for O in ObjectList.Objects do
  begin
    if StopNow then
      Break;
    if SelectionMode and O.Weightless then
      Continue;
    if O.Active then
      O.CheckLifespan;
    if not O.Active then
      Continue;

    // use dot product calculation to cull objects behind the camera
    if Culling and (ObjectList <> SceneManager.CoreObjects) then
    begin
      // calculate the vector to the object from the camera
      V[0] := O.Position[0] + O.ModelOffset[0] - LookatMatrix[3, 0];
      V[1] := O.Position[1] + O.ModelOffset[1] - LookatMatrix[3, 1];
      V[2] := O.Position[2] + O.ModelOffset[2] - LookatMatrix[3, 2];

      D := -Dot(V, Z);

      // if more than a few m behind camera or more than a certain distance away cull it
      if (D < -5) or (D > 500) then
        Continue;
    end;

    if not MiniMapMode and (ObjectList = SceneManager.DynamicObjects) and not O.Weightless
    then
      PositionObject(O);

    if InstancingEnabled and ObjectList.Instanced and not CollisionBoxDisplayMode then
    begin
      if (IC >= MAXINSTANCES - 1) or ((LastO <> nil) and (LastModel <> O.Model)) then
      begin
        DrawObject(LastO, IC);
        IC := 0;
      end;

      InstanceArray[IC].ModelMatrix := O.GetModelMatrix;
//      InstanceArray[IC].Colour := O.Colour;
      Inc(IC);

      LastO := O;
      LastModel := O.Model;
    end
    else
      DrawObject(O, 0);

    ErrorCheck;
  end;

  if InstancingEnabled and ObjectList.Instanced and (IC <> 0) and (LastO <> nil) then
    DrawObject(LastO, IC);
end;

procedure TMainForm.DrawObjectlistLabels(Objects: TSceneObjectList);
var
  D: GLFloat;
  O: TSceneObject;
  V, Z: TGLVectorf3;
begin
  ActiveShader := -1;

  // this is the current forward vector of the camera
  Z[0] := LookatMatrix[2, 0];
  Z[1] := LookatMatrix[2, 1];
  Z[2] := LookatMatrix[2, 2];

  for O in Objects.Objects do
  begin
    if StopNow then
      Break;

    if O = Player then
      Continue;

    if not O.Active then
      Continue;

    if SelectionMode and O.Weightless then
      Continue;

    if O.Name <> '' then
    begin
      // calculate the vector to the object from the camera
      V[0] := O.Position[0] + O.ModelOffset[0] - LookatMatrix[3, 0];
      V[1] := O.Position[1] + O.ModelOffset[1] - LookatMatrix[3, 1];
      V[2] := O.Position[2] + O.ModelOffset[2] - LookatMatrix[3, 2];

      D := -Dot(V, Z);

      if (D > 0) and (D < 500) then
      begin
        Dymo.Model.Meshes[0].SetColour(1.0, 1.0, 1.0, 0.5);
        Dymo.SetPosition(O.Position[0], O.Position[1] + O.Shift[1] + 4.0,
          O.Position[2]);

        // turn label to face the camera
        Dymo.SetRotation(-ArcTan2(O.Position[1] - LookatMatrix[3, 1], D),
          ArcTan2(O.Position[2] - LookatMatrix[3, 2], O.Position[0] - LookatMatrix[3, 0]) +
          PI / 2, 0);

        DistanceFont.Create3DLabel(O.Name, Dymo, taCenter);

        DrawObject(Dymo, 0);
      end;
    end;
  end;
end;

procedure TMainForm.Draw2DLabel(Text: String; X, Y, Height: GLFloat;
  Alignment: TAlignment; Colour: TGLVectorf4);
begin
  Dymo2D.Model.Meshes[0].Colour := Colour;
  Dymo2D.SetPosition(X, Y, 0.0);
  Dymo2D.SetScale(Height);

  DistanceFont.Create2DLabel(Text, Dymo2D, Alignment);

  glDisable(GL_DEPTH_TEST);
  DrawObject(Dymo2D, 0);
  glEnable(GL_DEPTH_TEST);
end;

procedure TMainForm.GenerateTargets;
var
  X, Z: Double;
  O: TSceneObject;
  N: Integer;
begin
  SceneManager.DynamicObjects.Clear;

  for N := 1 to 10 * Level do
  begin
    O := TSceneObject.Create('Target ' + IntToStr(N));
    O.Model := SceneManager.GetModel('TARGET');
    O.Weightless := True;

    O.SetScale(2.0, 2.0, 2.0);
    X := GRIDSIZE * (Random - 0.5);
    Z := GRIDSIZE * (Random - 0.5);

    O.SetPosition(X, Max(TSTerrain.GetHeightAt(X, Z), 0.0) + 2.0, Z);
    O.SetVelocity(0, 0, Random * 20);
    O.SetRotation(0, Random * 2 * PI - PI, 0);
    O.SetSpin(0, (Random - 0.5) / 10, 0);
    O.SetBounds(GRIDSIZE / 2);
    SceneManager.DynamicObjects.Add(O);
  end;

  SceneManager.DynamicObjects.DoSort;
  TargetsRemaining := 10 * Level;
end;

procedure TMainForm.DoLuckyDip;
var
  X, Z: Double;
  O, P: TSceneObject;
begin
  if Random < 0.001 then
  begin
    O := TSceneObject.Create('STAR');
    O.Model := SceneManager.GetModel('STAR');
    O.SetColour(1.0, 1.0, 0.0, 0.0);

    X := GRIDSIZE * (Random - 0.5);
    Z := GRIDSIZE * (Random - 0.5);
    O.SetPosition(X, Max(TSTerrain.GetHeightAt(X, Z), 0.0) + 2.0, Z);

    O.SetScale(2);
    O.SetRotation(-PI / 2, Random * PI, 0);
    O.SetSpin(0.0, PI / 4, 0.0);
    O.Weightless := True;
    O.Activate(2000);
    SceneManager.DynamicObjects.Add(O);
  end;

  if Random < 0.01 then
  begin
    O := SceneManager.DynamicObjects.GetObjectByName('PLANE');

    // limit planes to one at a time ...
    if (O = nil) or not O.Active then
    begin
      if O = nil then
      begin
        O := TSceneObject.Create('PLANE');
        O.Model := SceneManager.GetModel('PLANE');
        O.SetColour(0.0, 1.0, 1.0, 0.0);
        SceneManager.DynamicObjects.Add(O);
      end;

      X := GRIDSIZE * (Random - 0.5);
      Z := GRIDSIZE * (Random - 0.5);

      O.SetPosition(X, 30, Z);
      O.SetBounds(GRIDSIZE / 2);
      O.SetScale(3);
      O.SetRotation(0, (Random - 0.5) * 2 * PI, 0);
      O.SetVelocity(50, 0, 0);
      O.SetSpin(0.0, (Random - 0.5) * PI / 10, 0.0);
      O.Weightless := True;
      O.Activate(6000);
    end;
  end;

  O := SceneManager.DynamicObjects.GetObjectByName('PLANE');
  if (O <> nil) and O.Active then
  begin
    if Random < 0.01 then
    begin
      P := TSceneObject.Create('BOMB');
      P.Model := SceneManager.GetModel('BOMB');
      P.InitUnit;
      P.Position := O.Position;
      P.SetBounds(GRIDSIZE / 2);
      P.SetVelocity(0.25 * O.Velocity[0], 0, 0.25 * O.Velocity[2]);
      P.Weightless := False;
      P.SetColour(1.0, 0.0, 0.0, 1.0);
      P.SetScale(0.5);
      SceneManager.TemporaryObjects.Add(P);
    end;
  end;
end;

procedure TMainForm.UpdateLights;
begin
  // Light 0 represents the ambient lighting and needs no position
  LightArray[0].Colour[0] := 2.0;
  LightArray[0].Colour[1] := 2.0;
  LightArray[0].Colour[2] := 2.0;

  // Lights 1 onwards represent point lights
  LightArray[1].Colour[0] := 3.0;
  LightArray[1].Colour[1] := 3.0;
  LightArray[1].Colour[2] := 3.0;

  LightArray[1].Position[0] := GRIDSIZE;
  LightArray[1].Position[1] := 2 * GRIDSIZE;
  LightArray[1].Position[2] := GRIDSIZE;

  if MAXLIGHTS > 2 then
  begin
    LightArray[2].Colour[0] := 1.0;
    LightArray[2].Colour[1] := 1.0;
    LightArray[2].Colour[2] := 1.0;

    LightArray[2].Position[0] := LookatMatrix[3][0];
    LightArray[2].Position[1] := LookatMatrix[3][1] + 5.0;
    LightArray[2].Position[2] := LookatMatrix[3][2];

//    LightArray[2].Position[0] := 0.0;
//    LightArray[2].Position[1] := 1000 * cos(RunTime);
//    LightArray[2].Position[2] := 1000 * sin(RunTime);

    LightArray[3].Colour[0] := 0.0;
    LightArray[3].Colour[1] := 3.0;
    LightArray[3].Colour[2] := 0.0;

    LightArray[3].Position[0] := 1000 * cos(RunTime);
    LightArray[3].Position[1] := 0;
    LightArray[3].Position[2] := 1000 * sin(RunTime);

    LightArray[4].Colour[0] := 0.0;
    LightArray[4].Colour[1] := 0.0;
    LightArray[4].Colour[2] := 3.0;

    LightArray[4].Position[0] := 1000 * cos(RunTime);
    LightArray[4].Position[1] := 1000 * sin(RunTime);
    LightArray[4].Position[2] := 0;
  end;
end;

end.
