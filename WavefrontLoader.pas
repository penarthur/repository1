unit WavefrontLoader;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Generics.Collections,
  StrUtils, dglOpenGL, SceneObjects, Math;

type

  TWaveFrontMaterial = class(TObject)
    Name: String;
    Ns: GLFloat;
    Ka: TGLVector3f;
    Kd: TGLVector3f;
    Ks: TGLVector3f;
    d: GLFloat;
    map_Ka: String;
    map_Kd: String;
    map_Ks: String;
    map_Ns: String;
    map_d: String;
    map_bump: String;
  end;

  TWaveFrontGroup = class(TObject)
    Name: String;
    Material: String;
    VStart, VTStart, VNStart: Integer;
    VerticeCount: Integer;
    Vertices: TVertexAttributeArray;
    IndexCount: Integer;
    Indices: TIndexArray;
  end;

  TWaveFrontObject = class(TObject)
  private
    Source: String;
    V: Array of TGLVectorf3;
    VT: Array of TGLVectorf2;
    VN: Array of TGLVectorf3;
    VCount, VTCount, VNCount: Integer;
  public
    MinD, MaxD, Centre, Dimension: TGLVectorf3;
    GroupCount: Integer;
    Groups: Array of TWaveFrontGroup;
    MatCount: Integer;
    Materials: Array of TWaveFrontMaterial;
    procedure Load(AFilename: String; Normalisation: TObjectNormalisation);
    constructor Create;
    destructor Destroy; override;
    function GetMaterial(Material: String): TWaveFrontMaterial;
  end;

implementation

procedure TWaveFrontObject.Load(AFilename: String; Normalisation: TObjectNormalisation);
type
  TVertexMode = (vmUnknown, vmGlobal, vmGrouped);
const
  NUM = 1024;
  GNUM = 1024;
var
  F: TextFile;
  S: String;
  Verts: TArray<String>;
  Data: TArray<Integer>;
  UseMtl: String;
  Smoothing: String;
  GName: String;
  I, N: Integer;
  VertexMode: TVertexMode;

function SplitStrings(InStr: String; var Strings: Array of String): Integer;
var
  N, P, Q: Integer;
  W, S: String;
begin
  P := 1;
  N := 0;
  W := InStr.Replace(#10, #32);
  W := Trim(W);

  Repeat
    Q := PosEx(' ', W, P);
    if Q <> 0 then
      S := Copy(W, P, Q - P)
    else
      S := Copy(W, P, 999);

    if S <> '' then
    begin
      Strings[N] := S;
    end;

    Inc(N);

    if W[Q + 1] = ' ' then
      Inc(Q);

    P := Q + 1;
  Until Q = 0;

  Result := N;
end;

function SplitIntegers(InStr: String; var Integers: Array of Integer): Integer;
var
  N, P, Q: Integer;
  W, S: String;
begin
  P := 1;
  N := 0;
  W := InStr.Replace(#10, #32);

  Repeat
    Q := PosEx('/', W, P);
    if Q <> 0 then
      S := Copy(W, P, Q - P)
    else
      S := Copy(W, P, 999);

    if S <> '' then
      Integers[N] := StrToInt(S)
    else
      Integers[N] := 0;

    Inc(N);
    P := Q + 1;
  Until Q = 0;

  Result := N;
end;

function SplitFloats(InStr: String; var Floats: Array of GLFloat): Integer;
var
  N, P, Q: Integer;
  W, S: String;
begin
  P := 1;
  N := 0;
  W := InStr.Replace(#10, #32);
  W := Trim(W);

  Repeat
    Q := PosEx(' ', W, P);
    if Q <> 0 then
      S := Copy(W, P, Q - P)
    else
      S := Copy(W, P, 999);

    if S <> '' then
      Floats[N] := StrToFloat(S)
    else
      Floats[N] := 0;

    Inc(N);

    if W[Q + 1] = ' ' then
      Inc(Q);

    P := Q + 1;
  Until N = Length(Floats);

  Result := N;
end;

procedure TestMaxMin;
var
  D: Integer;
begin
  for D := 0 to 2 do
  begin
    if V[VCount][D] > MaxD[D] then
      MaxD[D] := V[VCount][D];
    if V[VCount][D] < MinD[D] then
      MinD[D] := V[VCount][D];
  end;
end;

procedure AddV;
begin
  if VertexMode = vmUnknown then
  begin
    if GroupCount = 0 then
      VertexMode := vmGlobal
    else
      VertexMode := vmGrouped;
  end;

  if VCount >= Length(V) then
    SetLength(V, Length(V) + NUM);
  SplitFloats(Copy(S, 3, 999), V[VCount]);
  TestMaxMin;
  Inc(VCount);
end;

procedure AddVT;
begin
  if VTCount >= Length(VT) then
    SetLength(VT, Length(VT) + NUM);
  SplitFloats(Copy(S, 4, 999), VT[VTCount]);
  Inc(VTCount);
end;

procedure AddVN;
begin
  if VNCount >= Length(VN) then
    SetLength(VN, Length(VN) + NUM);
  SplitFloats(Copy(S, 4, 999), VN[VNCount]);
  Inc(VNCount);
end;

procedure AddG(GroupName: String);
begin
  if VertexMode = vmUnknown then
    VertexMode := vmGrouped;

  if GroupCount >= Length(Groups) then
    SetLength(Groups, Length(Groups) + GNUM);

  Inc(GroupCount);

  Groups[GroupCount - 1] := TWaveFrontGroup.Create;
  Groups[GroupCount - 1].Name := GroupName;

  if VertexMode = vmGrouped then
  begin
//    Groups[GroupCount - 1].VStart := VCount;
//    Groups[GroupCount - 1].VTStart := VTCount;
//    Groups[GroupCount - 1].VNStart := VNCount;
    Groups[GroupCount - 1].VStart := 0;
    Groups[GroupCount - 1].VTStart := 0;
    Groups[GroupCount - 1].VNStart := 0;
  end
  else
  begin
    Groups[GroupCount - 1].VStart := 0;
    Groups[GroupCount - 1].VTStart := 0;
    Groups[GroupCount - 1].VNStart := 0;
  end;

  Groups[GroupCount - 1].VerticeCount := 0;
  SetLength(Groups[GroupCount - 1].Vertices, NUM);

  Groups[GroupCount - 1].IndexCount := 0;
  SetLength(Groups[GroupCount - 1].Indices, NUM);

  if (VertexMode = vmGlobal) and (UseMtl <> '') then
    Groups[GroupCount - 1].Material := UseMtl
  else
    Groups[GroupCount - 1].Material := '';
end;

procedure AddF;
var
  I, J, P, N, L: Integer;
  NumVerts: Integer;

procedure AddVert(I: Integer);
var
  DataLen: Integer;
begin
  DataLen := SplitIntegers(Verts[I], Data);

  if Data[0] < 0 then
    Beep;

  if DataLen >= 1 then
  begin
    N := Groups[GroupCount - 1].VerticeCount;

    if Data[0] <> 0 then
    begin
      if Data[0] > 0 then
        P := Data[0] - 1
      else
        P := VCount + Data[0];
      if P < Length(V) then
      begin
        Groups[GroupCount - 1].Vertices[N].PosX := V[P][0];
        Groups[GroupCount - 1].Vertices[N].PosY := V[P][1];
        Groups[GroupCount - 1].Vertices[N].PosZ := V[P][2];
      end;
    end;

    if Data[1] <> 0 then
    begin
      if Data[1] > 0 then
        P := Data[1] - 1
      else
        P := VTCount + Data[1];
      if P < Length(VT) then
      begin
        Groups[GroupCount - 1].Vertices[N].TexU := VT[P][0];
        Groups[GroupCount - 1].Vertices[N].TexV := VT[P][1];
      end;
    end;

    if Data[2] <> 0 then
    begin
      if Data[2] > 0 then
        P := Data[2] - 1
      else
        P := VNCount + Data[2];
      if P < Length(VN) then
      begin
        Groups[GroupCount - 1].Vertices[N].NormX := VN[P][0];
        Groups[GroupCount - 1].Vertices[N].NormY := VN[P][1];
        Groups[GroupCount - 1].Vertices[N].NormZ := VN[P][2];
      end;
    end;

    Groups[GroupCount - 1].Vertices[N].Extra := 10000 * Data[0] + 100 * Data[1] + Data[2];
    Inc(Groups[GroupCount - 1].VerticeCount);

    Groups[GroupCount - 1].Indices[N] := N;
    Inc(Groups[GroupCount - 1].IndexCount);
  end;
end;

begin
  NumVerts := SplitStrings(Copy(S, 3, 999), Verts);

  if Groups[GroupCount - 1].VerticeCount + NumVerts >= Length(Groups[GroupCount - 1].Vertices) then
    SetLength(Groups[GroupCount - 1].Vertices, Length(Groups[GroupCount - 1].Vertices) + NUM);

  if Groups[GroupCount - 1].IndexCount + NumVerts >= Length(Groups[GroupCount - 1].Indices) then
    SetLength(Groups[GroupCount - 1].Indices, Length(Groups[GroupCount - 1].Indices) + NUM);

  if NumVerts = 3 then
  begin
    // straightforward triangle
    AddVert(0);
    AddVert(1);
    AddVert(2);
  end

  else if NumVerts > 3 then
  begin
    // more than 3 vertexes is basically a triangle fan
    for L := 2 to NumVerts - 1 do
    begin
      AddVert(0);
      AddVert(L - 1);
      AddVert(L);
    end;
  end;
end;

procedure LoadMaterialLib;
var
  MFN: String;
  MF: TextFile;
  MS: String;
  MtlLib: String;
begin
  MtlLib := Copy(S, 8, 99);

  MFN := ExtractFilePath(ExtractFilePath(Application.ExeName) + 'Models\' + AFilename) + MtlLib;

  if not FileExists(MFN) then
    Exit;

  AssignFile(MF, MFN);
  Reset(MF);

  repeat
    ReadLn(MF, MS);

    if MS = '' then
      Continue;

    if Copy(MS, 1, 6) = 'newmtl' then
    begin
      Inc(MatCount);
      Materials[MatCount - 1] := TWaveFrontMaterial.Create;
      Materials[MatCount - 1].Name := Copy(MS, 8, 99);
      Materials[MatCount - 1].d := 1.0;
    end
    else if Copy(MS, 1, 2) = 'Ns' then
      Materials[MatCount - 1].Ns := StrToFloat(Copy(MS, 4, 99))
    else if Copy(MS, 1, 2) = 'Ka' then
      SplitFloats(Copy(MS, 4, 99), Materials[MatCount - 1].Ka)
    else if Copy(MS, 1, 2) = 'Kd' then
      SplitFloats(Copy(MS, 4, 99), Materials[MatCount - 1].Kd)
    else if Copy(MS, 1, 2) = 'Ks' then
      SplitFloats(Copy(MS, 4, 99), Materials[MatCount - 1].Ks)
    else if Copy(MS, 1, 2) = '' then
      Materials[MatCount - 1].d := StrToFloat(Copy(MS, 4, 99))
    else if Copy(MS, 1, 6) = 'map_Kd' then
      Materials[MatCount - 1].map_Kd := Copy(MS, 8, 99);
  until EOF(MF);

  CloseFile(MF);
end;

begin
  if not FileExists(ExtractFilePath(Application.ExeName) + 'Models\' + AFilename) then
    Exit;

  AssignFile(F, ExtractFilePath(Application.ExeName) + 'Models\' + AFilename);
  Reset(F);

  SetLength(V, NUM);
  SetLength(VT, NUM);
  SetLength(VN, NUM);

  SetLength(Materials, 64);
  SetLength(Groups, GNUM);
  SetLength(Verts, 99);
  SetLength(Data, 3);

  VCount := 0;
  VTCount := 0;
  VNCount := 0;
  GroupCount := 0;
  MatCount := 0;

  VertexMode := vmUnknown;

  while not EOF(F) do
  begin
    ReadLn(F, S);

    if Trim(S) <> '' then
    begin

      if Copy(S, 1, 1) = '#' then

      else if Copy(S, 1, 2) = 'v '  then
        AddV

      else if Copy(S, 1, 2) = 'vt'  then
        AddVT

      else if Copy(S, 1, 2) = 'vn'  then
        AddVN

      else if Copy(S, 1, 6) = 'mtllib' then
        LoadMaterialLib

      else if Copy(S, 1, 6) = 'usemtl' then
      begin
        UseMtl := Copy(S, 8, 99);
        if GroupCount <> 0 then
        begin
          // if no material defined for this group, set it or start a new group...
          if Groups[GroupCount - 1].Material <> '' then
            AddG(GName + '/' + UseMtl)
          else
            Groups[GroupCount - 1].Material := UseMtl;
        end;
      end

      else if S[1] = 's' then
      begin
        if Smoothing <> Trim(Copy(S, 3, 99)) then
        begin
          if GroupCount <> 0 then
          begin
            // if no material defined for this group, set it or start a new group...
            if Groups[GroupCount - 1].Material <> '' then
              AddG(GName + '/' + UseMtl)
            else
              Groups[GroupCount - 1].Material := UseMtl;
          end;
        end;
        Smoothing := Trim(Copy(S, 3, 99));
      end

      else if S[1] = 'g' then
      begin
        GName := Copy(S, 3, 99);
        AddG(GName);
      end

      else if S[1] = 'f' then
      begin
        if GroupCount = 0 then
          AddG(UseMtl);
        AddF;
      end;
    end;
  end;

  CloseFile(F);

  SetLength(V, VCount);
  SetLength(VT, VTCount);
  SetLength(VN, VNCount);
  SetLength(Groups, GroupCount);

  if Normalisation <> onNone then
  begin
    Centre[0] := (MaxD[0] + MinD[0]) / 2.0;
    Centre[1] := (MaxD[1] + MinD[1]) / 2.0;
    Centre[2] := (MaxD[2] + MinD[2]) / 2.0;

    Dimension[0] := MaxD[0] - MinD[0];
    Dimension[1] := MaxD[1] - MinD[1];
    Dimension[2] := MaxD[2] - MinD[2];

    for I := 0 to GroupCount - 1 do
    begin
      for N := 0 to Groups[I].VerticeCount - 1 do
      begin
        // normalise so lenth = 1 unit
        Groups[I].Vertices[N].PosX := (Groups[I].Vertices[N].PosX - Centre[0]) / Dimension[2];
        if Normalisation = onCentreBottom then
          Groups[I].Vertices[N].PosY := (Groups[I].Vertices[N].PosY - MinD[1]) / Dimension[2]
        else
          Groups[I].Vertices[N].PosY := (Groups[I].Vertices[N].PosY - Centre[1]) / Dimension[2];
        Groups[I].Vertices[N].PosZ := (Groups[I].Vertices[N].PosZ - Centre[2]) / Dimension[2];
      end;
    end;

    MaxD[0] := (MaxD[0] - Centre[0]) / Dimension[2];
    MinD[0] := (MinD[0] - Centre[0]) / Dimension[2];

    if Normalisation = onCentreBottom then
    begin
      MaxD[1] := (MaxD[1] - MinD[1]) / Dimension[1];
      MinD[1] := 0;
    end
    else
    begin
      MaxD[1] := (MaxD[1] - Centre[1]) / Dimension[2];
      MinD[1] := (MinD[1] - Centre[1]) / Dimension[2];
    end;

    MaxD[2] := (MaxD[2] - Centre[2]) / Dimension[2];
    MinD[2] := (MinD[2] - Centre[2]) / Dimension[2];
  end;
end;

function TWaveFrontObject.GetMaterial(Material: String): TWaveFrontMaterial;
var
  I: Integer;
begin
  Result := Materials[0];

  for I := 0 to MatCount - 1 do
  begin
    if Materials[I].Name = Material then
    begin
      Result := Materials[I];
      Break;
    end;
  end;
end;

constructor TWaveFrontObject.Create;
begin
  inherited;

  GroupCount := 0;

  MinD[0] := 999.99;
  MinD[1] := 999.99;
  MinD[2] := 999.99;

  MaxD[0] := -999.99;
  MaxD[1] := -999.99;
  MaxD[2] := -999.99;
end;

destructor TWaveFrontObject.Destroy;
var
  I: Integer;
begin
  for I := 0 to GroupCount - 1 do
    Groups[I].Free;

  for I := 0 to MatCount - 1 do
    Materials[I].Free;

  inherited;
end;

end.
