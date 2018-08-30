unit GLHelpers;

interface

uses
  System.SysUtils, System.Classes, System.Types, dglOpenGL;

type

TGLLight = record
  Position: TGLVectorf4;
  Colour: TGLVectorf4;
end;

TGLInstanceData = record
  ModelMatrix: TGLMatrixF4;
//   Colour: TGLVectorf4;
end;

var
  ErrNo, LastErrNo: Cardinal;

function LoadShader(AShader: glHandle; AFile: String): Boolean;
function BuildProgramObject(VertShaderName, FragShaderName, GeomShaderName
  : String): glHandle;
function LoadGLTexture(AFileName: String): GLUInt;
function ChangeMonitorResolution(Index, Width, Height: DWORD): Boolean;
function PerspectiveMatrix(VWid, VHgt: Integer): TGLMatrixF4;
function OrthogonalMatrix(VWid, VHgt: Integer): TGLMatrixF4;

function Dot(a, b: TVector3f): Double;
function Cross(a, b: TVector3f): TVector3f;
procedure Normalize(var AVector: TVector3f);
function Multiply(const A, B: TGLMatrixF4): TGLMatrixF4;
function Transpose(const A: TGLMatrixF4): TGLMatrixF4;

function MatrixInvert(M: TGLMatrixF4): TGLMatrixF4;
procedure InvertMatrix(var M: TGLMatrixF4);
procedure ScaleMatrix(var M: TGLMatrixF4; const factor: Single);

procedure ErrorCheck;

implementation

uses
  Windows, PNGImage, JPeg, Graphics, Forms, Dialogs;

const
  IdentityHmgMatrix: TGLMatrixF4 = ((1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0),
    (0, 0, 0, 1));

function LoadShader(AShader: glHandle; AFile: String): Boolean;
var
  ShaderLength: GLInt;
  FS: TFileStream;
  ShaderString: AnsiString;
  LogLength: GLInt;
  LogString: AnsiString;
  Success: ByteBool;
begin
  FS := TFileStream.Create(ExtractFilePath(Application.ExeName) + 'shaders\' +
    AFile, fmOpenRead);
  ShaderLength := FS.Size;
  SetLength(ShaderString, ShaderLength);
  FS.Read(ShaderString[1], ShaderLength);
  FS.Free;

  glShaderSource(AShader, 1, @ShaderString, @ShaderLength);
  glCompileShader(AShader);
  glGetShaderiv(AShader, GL_COMPILE_STATUS, @Success);

  if Success <> GL_TRUE then
  begin
    glGetShaderiv(AShader, GL_INFO_LOG_LENGTH, @LogLength);
    SetLength(LogString, LogLength);
    glGetShaderInfoLog(AShader, LogLength, @LogLength, @LogString[1]);
    ShowMessage('Error' + #13#10 + LogString);
    Result := False;
  end
  else
    Result := True;
end;

function LoadGLTexture(AFileName: String): GLUInt;
type
  TRGB24 = packed record
    B, G, R: Byte;
  end;

  TRGB24Array = packed array [0 .. MaxInt div SizeOf(TRGB24) - 1] of TRGB24;
  PRGB24Array = ^TRGB24Array;

  TRGBA = packed record // auxiliary type for this routine
    R, G, B, A: Byte;
  end;

  Ta = array of TRGBA;

var
  TextureName: GLUInt;
  PNGImage: TPngImage;
  BmpImage: TBitmap;
  JpegImage: TJPegImage;
  I, W, H, X, Y, P: Integer;
  Data: Array of Byte;
  Ptr, PB: PByte;
  Line: PRGB24Array;
  AlphaLine: PByteArray;
begin
  GlGenTextures(1, @TextureName);
  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, TextureName);

  if ExtractFileExt(AFileName) = '.jpg' then
  begin
    JpegImage := TJPegImage.Create;
    if ExtractFilePath(AFileName) = '' then
      JpegImage.LoadFromFile(ExtractFilePath(Application.ExeName) + 'textures\' +
        AFileName)
    else
      JpegImage.LoadFromFile(AFileName);

    W := JpegImage.Width;
    H := JpegImage.Height;

    BmpImage := TBitmap.Create;
    BmpImage.Assign(JpegImage);
    JpegImage.Free;

    SetLength(Data, 3 * W * H); // RGB

    for Y := 0 to H - 1 do
    begin
      PB := BmpImage.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        P := 3 * (Y * W + X);
        Data[P + 2] := PB^;
        Data[P + 1] := (PB + 1)^;
        Data[P] := (PB + 2)^;
        PB := PB + 3;
      end;
    end;

    GlPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    GlTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    GlTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    GlTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    GlTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, W, H, 0, GL_RGB, GL_UNSIGNED_BYTE,
      @Data[0]);

    BmpImage.Free;
  end

  else if ExtractFileExt(AFileName) = '.png' then
  begin
    PngImage := TPngImage.Create;
    PngImage.Transparent := True;
    PngImage.LoadFromFile(ExtractFilePath(Application.ExeName) + 'textures\' +
      AFileName);

    W := PngImage.Width;
    H := PngImage.Height;

    GetMem(Ptr, W * H * SizeOf(TRGBA));

    I := 0;
    for Y := 0 to H - 1 do
    begin
      Line := PngImage.Scanline[Y];
      AlphaLine := PngImage.AlphaScanline[Y];

      for X := W - 1 downto 0 do
      begin

        Ta(Ptr)[W * H - I - 1].R := Line[X].R;
        Ta(Ptr)[W * H - I - 1].G := Line[X].G;
        Ta(Ptr)[W * H - I - 1].B := Line[X].B;
        if AlphaLine <> nil then
        begin
          Ta(Ptr)[W * H - I - 1].A := AlphaLine[X];
        end
        else
        begin
          Ta(Ptr)[W * H - I - 1].A := 255;
        end;

        Inc(I);
      end;
    end;

    GlPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    GlTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    GlTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

    GlTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    GlTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, W, H, 0, GL_RGBA, GL_UNSIGNED_BYTE,
      Ptr);

    PngImage.Free;

    FreeMem(Ptr);
  end;

  Result := TextureName;
end;

function BuildProgramObject(VertShaderName, FragShaderName, GeomShaderName
  : String): glHandle;
var
  TempP, TempS: glHandle;
  Success: ByteBool;
  LogLength: GLInt;
  LogString: AnsiString;
begin
  TempP := glCreateProgram;

  if VertShaderName <> '' then
  begin
    TempS := glCreateShader(GL_VERTEX_SHADER);
    LoadShader(TempS, VertShaderName);
    glAttachShader(TempP, TempS);
  end;

  if FragShaderName <> '' then
  begin
    TempS := glCreateShader(GL_FRAGMENT_SHADER);
    LoadShader(TempS, FragShaderName);
    glAttachShader(TempP, TempS);
  end;

  if GeomShaderName <> '' then
  begin
    TempS := glCreateShader(GL_GEOMETRY_SHADER);
    LoadShader(TempS, GeomShaderName);
    glAttachShader(TempP, TempS);
  end;

  glLinkProgram(TempP);
  glGetProgramiv(TempP, GL_LINK_STATUS, @Success);
  if Success = GL_FALSE then
  begin
    glGetProgramiv(TempP, GL_INFO_LOG_LENGTH, @LogLength);
    SetLength(LogString, LogLength);
    glGetProgramInfoLog(TempP, LogLength, @LogLength, @LogString[1]);
    ShowMessage('Error 3 ' + #13#10 + LogString);
    Result := 0
  end
  else
    Result := TempP;
end;

function ChangeMonitorResolution(Index, Width, Height: DWORD)
  : Boolean;
var
  DeviceMode: TDeviceMode;
  DisplayDevice: TDisplayDevice;
begin
  Result := False;
  ZeroMemory(@DisplayDevice, SizeOf(DisplayDevice));
  DisplayDevice.cb := SizeOf(TDisplayDevice);
  // get the name of a device by the given index
  if EnumDisplayDevices(nil, Index, DisplayDevice, 0) then
  begin
    ZeroMemory(@DeviceMode, SizeOf(DeviceMode));
    DeviceMode.dmSize := SizeOf(TDeviceMode);
    DeviceMode.dmPelsWidth := Width;
    DeviceMode.dmPelsHeight := Height;
    DeviceMode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT;
    // check if it's possible to set a given resolution; if so, then...
    if (ChangeDisplaySettingsEx(PChar(@DisplayDevice.DeviceName[0]), DeviceMode,
      0, CDS_TEST, nil) = DISP_CHANGE_SUCCESSFUL) then
      // change the resolution temporarily (if you use CDS_UPDATEREGISTRY
      // value for the penultimate parameter, the graphics mode will also
      // be saved to the registry under the user's profile; for more info
      // see the ChangeDisplaySettingsEx reference, dwflags parameter)
      Result := ChangeDisplaySettingsEx(PChar(@DisplayDevice.DeviceName[0]),
        DeviceMode, 0, 0, nil) = DISP_CHANGE_SUCCESSFUL;
  end;
end;

function PerspectiveMatrix(VWid, VHgt: Integer): TGLMatrixF4;
var
  N, F, R, T, B, L: GLFloat;
begin
  T := 1;

  N := 1;
  F := 2000;

  R := Abs(T * VWid / VHgt);

  B := -T;
  L := -R;

  // form OpenGL  super bible p 88/89
  // column major format
  // perspective
  Result[0, 0] := 2 * N / (R - L);
  Result[0, 1] := 0;
  Result[0, 2] := 0;
  Result[0, 3] := 0;

  Result[1, 0] := 0;
  Result[1, 1] := 2 * N / (T - B);
  Result[1, 2] := 0;
  Result[1, 3] := 0;

  Result[2, 0] := (R + L) / (R - L);
  Result[2, 1] := (T + B) / (T - B);
  Result[2, 2] := (N + F) / (N - F);
  Result[2, 3] := -1;

  Result[3, 0] := 0;
  Result[3, 1] := 0;
  Result[3, 2] := 2 * N * F / (N - F);
  Result[3, 3] := 0;
end;

function OrthogonalMatrix(VWid, VHgt: Integer): TGLMatrixF4;
var
  N, F, R, T, B, L: GLFloat;
begin
  T := 0.00095;

  N := 1;
  F := 1000;

  R := Abs(T * VWid / VHgt);

  B := -T;
  L := -R;

  // form OpenGL  super bible p 88/89
  // column major format
  // perspective
  Result[0, 0] := 2 * (R - L);
  Result[0, 1] := 0;
  Result[0, 2] := 0;
  Result[0, 3] := 0;

  Result[1, 0] := 0;
  Result[1, 1] := 2 * (T - B);
  Result[1, 2] := 0;
  Result[1, 3] := 0;

  Result[2, 0] := 0;
  Result[2, 1] := 0;
  Result[2, 2] := 2 / (N - F);
  Result[2, 3] := 0;

  Result[3, 0] := (L + R) / (L - R);
  Result[3, 1] := (B + T) / (B - T);
  Result[3, 2] := (N + F) / (N - F);
  Result[3, 3] := 1.0;
end;


// From system.Math.Vectors
//  Result.X := Self.Y * AVector.Z - Self.Z * AVector.Y;
//  Result.Y := Self.Z * AVector.X - Self.X * AVector.Z;
//  Result.Z := Self.X * AVector.Y - Self.Y * AVector.X;
//  Result.W := 1;

function Dot(a, b: TVector3f): Double;
begin
  Result := a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
end;

function Cross(a, b: TVector3f): TVector3f;
begin
  Result[0] := a[1] * b[2] - a[2] * b[1];
  Result[1] := a[2] * b[0] - a[0] * b[2];
  Result[2] := a[0] * b[1] - a[1] * b[0];
end;

procedure Normalize(var AVector: TVector3f);
var
  Len: Double;
begin
  Len := Sqr(AVector[0]) + Sqr(AVector[1]) + Sqr(AVector[2]);
  if Len > Epsilon then // if it's not a zero vector
  begin
    Len := Sqrt(Len);
    AVector[0] := AVector[0] / Len;
    AVector[1] := AVector[1] / Len;
    AVector[2] := AVector[2] / Len;
  end;
end;

function Multiply(const A, B: TGLMatrixF4): TGLMatrixF4;
begin
  Result[0][0] := (A[0][0] * B[0][0]) + (A[0][1] * B[1][0]) + (A[0][2] * B[2][0]
    ) + (A[0][3] * B[3][0]);
  Result[0][1] := (A[0][0] * B[0][1]) + (A[0][1] * B[1][1]) + (A[0][2] * B[2][1]
    ) + (A[0][3] * B[3][1]);
  Result[0][2] := (A[0][0] * B[0][2]) + (A[0][1] * B[1][2]) + (A[0][2] * B[2][2]
    ) + (A[0][3] * B[3][2]);
  Result[0][3] := (A[0][0] * B[0][3]) + (A[0][1] * B[1][3]) + (A[0][2] * B[2][3]
    ) + (A[0][3] * B[3][3]);

  Result[1][0] := (A[1][0] * B[0][0]) + (A[1][1] * B[1][0]) + (A[1][2] * B[2][0]
    ) + (A[1][3] * B[3][0]);
  Result[1][1] := (A[1][0] * B[0][1]) + (A[1][1] * B[1][1]) + (A[1][2] * B[2][1]
    ) + (A[1][3] * B[3][1]);
  Result[1][2] := (A[1][0] * B[0][2]) + (A[1][1] * B[1][2]) + (A[1][2] * B[2][2]
    ) + (A[1][3] * B[3][2]);
  Result[1][3] := (A[1][0] * B[0][3]) + (A[1][1] * B[1][3]) + (A[1][2] * B[2][3]
    ) + (A[1][3] * B[3][3]);

  Result[2][0] := (A[2][0] * B[0][0]) + (A[2][1] * B[1][0]) + (A[2][2] * B[2][0]
    ) + (A[2][3] * B[3][0]);
  Result[2][1] := (A[2][0] * B[0][1]) + (A[2][1] * B[1][1]) + (A[2][2] * B[2][1]
    ) + (A[2][3] * B[3][1]);
  Result[2][2] := (A[2][0] * B[0][2]) + (A[2][1] * B[1][2]) + (A[2][2] * B[2][2]
    ) + (A[2][3] * B[3][2]);
  Result[2][3] := (A[2][0] * B[0][3]) + (A[2][1] * B[1][3]) + (A[2][2] * B[2][3]
    ) + (A[2][3] * B[3][3]);

  Result[3][0] := (A[3][0] * B[0][0]) + (A[3][1] * B[1][0]) + (A[3][2] * B[2][0]
    ) + (A[3][3] * B[3][0]);
  Result[3][1] := (A[3][0] * B[0][1]) + (A[3][1] * B[1][1]) + (A[3][2] * B[2][1]
    ) + (A[3][3] * B[3][1]);
  Result[3][2] := (A[3][0] * B[0][2]) + (A[3][1] * B[1][2]) + (A[3][2] * B[2][2]
    ) + (A[3][3] * B[3][2]);
  Result[3][3] := (A[3][0] * B[0][3]) + (A[3][1] * B[1][3]) + (A[3][2] * B[2][3]
    ) + (A[3][3] * B[3][3]);
end;

function Transpose(const A: TGLMatrixF4): TGLMatrixF4;
begin
  Result[0][0] := A[0][0];
  Result[0][1] := A[1][0];
  Result[0][2] := A[2][0];
  Result[0][3] := A[3][0];

  Result[1][0] := A[0][1];
  Result[1][1] := A[1][1];
  Result[1][2] := A[2][1];
  Result[1][3] := A[3][1];

  Result[2][0] := A[0][2];
  Result[2][1] := A[1][2];
  Result[2][2] := A[2][2];
  Result[2][3] := A[3][2];

  Result[3][0] := A[0][3];
  Result[3][1] := A[1][3];
  Result[3][2] := A[2][3];
  Result[3][3] := A[3][3];
end;

function MatrixDetInternal(a1, a2, a3, b1, b2, b3, c1, c2,
  c3: Single): Single;
// internal version for the determinant of a 3x3 matrix
begin
  result := a1 * (b2 * c3 - b3 * c2) - b1 * (a2 * c3 - a3 * c2) + c1 *
    (a2 * b3 - a3 * b2);
end;

function MatrixDeterminant(M: TGLMatrixF4): Single;
begin
  result := M[0, 0] * MatrixDetInternal(M[1, 1], M[2, 1], M[3, 1], M[1, 2],
    M[2, 2], M[3, 2], M[1, 3], M[2, 3], M[3, 3]) - M[0, 1] *
    MatrixDetInternal(M[1, 0], M[2, 0], M[3, 0], M[1, 2], M[2, 2], M[3, 2],
    M[1, 3], M[2, 3], M[3, 3]) + M[0, 2] * MatrixDetInternal(M[1, 0], M[2, 0],
    M[3, 0], M[1, 1], M[2, 1], M[3, 1], M[1, 3], M[2, 3], M[3, 3]) - M[0, 3] *
    MatrixDetInternal(M[1, 0], M[2, 0], M[3, 0], M[1, 1], M[2, 1], M[3, 1],
    M[1, 2], M[2, 2], M[3, 2]);
end;

procedure AdjointMatrix(var M: TGLMatrixF4);
var
  a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4: Single;
begin
  a1 := M[0, 0];
  b1 := M[0, 1];
  c1 := M[0, 2];
  d1 := M[0, 3];
  a2 := M[1, 0];
  b2 := M[1, 1];
  c2 := M[1, 2];
  d2 := M[1, 3];
  a3 := M[2, 0];
  b3 := M[2, 1];
  c3 := M[2, 2];
  d3 := M[2, 3];
  a4 := M[3, 0];
  b4 := M[3, 1];
  c4 := M[3, 2];
  d4 := M[3, 3];

  // ro3 column labeling reversed since 3e transpose ro3s & columns
  M[0, 0] := MatrixDetInternal(b2, b3, b4, c2, c3, c4, d2, d3, d4);
  M[1, 0] := -MatrixDetInternal(a2, a3, a4, c2, c3, c4, d2, d3, d4);
  M[2, 0] := MatrixDetInternal(a2, a3, a4, b2, b3, b4, d2, d3, d4);
  M[3, 0] := -MatrixDetInternal(a2, a3, a4, b2, b3, b4, c2, c3, c4);

  M[0, 1] := -MatrixDetInternal(b1, b3, b4, c1, c3, c4, d1, d3, d4);
  M[1, 1] := MatrixDetInternal(a1, a3, a4, c1, c3, c4, d1, d3, d4);
  M[2, 1] := -MatrixDetInternal(a1, a3, a4, b1, b3, b4, d1, d3, d4);
  M[3, 1] := MatrixDetInternal(a1, a3, a4, b1, b3, b4, c1, c3, c4);

  M[0, 2] := MatrixDetInternal(b1, b2, b4, c1, c2, c4, d1, d2, d4);
  M[1, 2] := -MatrixDetInternal(a1, a2, a4, c1, c2, c4, d1, d2, d4);
  M[2, 2] := MatrixDetInternal(a1, a2, a4, b1, b2, b4, d1, d2, d4);
  M[3, 2] := -MatrixDetInternal(a1, a2, a4, b1, b2, b4, c1, c2, c4);

  M[0, 3] := -MatrixDetInternal(b1, b2, b3, c1, c2, c3, d1, d2, d3);
  M[1, 3] := MatrixDetInternal(a1, a2, a3, c1, c2, c3, d1, d2, d3);
  M[2, 3] := -MatrixDetInternal(a1, a2, a3, b1, b2, b3, d1, d2, d3);
  M[3, 3] := MatrixDetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3);
end;

procedure ScaleMatrix(var M: TGLMatrixF4; const factor: Single);
var
  i: Integer;
begin
  for i := 0 to 3 do
  begin
    M[i, 0] := M[i, 0] * factor;
    M[i, 1] := M[i, 1] * factor;
    M[i, 2] := M[i, 2] * factor;
    M[i, 3] := M[i, 3] * factor;
  end;
end;

procedure InvertMatrix(var M: TGLMatrixF4);
var
  det: Single;
begin
  det := MatrixDeterminant(M);
  if Abs(det) < EPSILON then
    M := IdentityHmgMatrix
  else
  begin
    AdjointMatrix(M);
    ScaleMatrix(M, 1 / det);
  end;
end;

function MatrixInvert(M: TGLMatrixF4): TGLMatrixF4;
begin
  Result := M;
  InvertMatrix(result);
end;

procedure ErrorCheck;
begin
  ErrNo := glGetError;
  if ErrNo <> GL_NO_ERROR then
  begin
    LastErrNo := ErrNo;
//    Beep;
  end;
end;


end.
