unit SceneManager;

interface

uses
  SceneObjects, dglOpenGL, Generics.Collections, Generics.Defaults,
  GLHelpers, Forms, SysUtils, Math, Windows;

type
  TSceneObjectList = class(TObject)
    Objects: TObjectList<TSceneObject>;
  public
    Instanced: Boolean;
    constructor Create(CreateInstanced: Boolean);
    destructor Destroy; override;
    procedure Add(O: TSceneObject);
    procedure Clear;
    function GetObjectByName(Aname: String): TSceneObject;
    procedure DoSort;
    function Comparer(const L, R: TSceneObject): Integer;
  end;

  TSceneManager = class(TObject)
    CoreObjects: TSceneObjectList;
    StaticObjects: TSceneObjectList;
    DynamicObjects: TSceneObjectList;
    TemporaryObjects: TSceneObjectList;

    ModelLibrary: TObjectDictionary<String, TSceneModel>;
    TextureLibrary: TDictionary<String, GLUInt>;

    function AddModel(ID: String): TSceneModel;
    function GetModel(ID: String): TSceneModel;
    function LoadModel(ID, AFileName: String; Normalisation: TObjectNormalisation): TSceneModel;
    function LoadColladaModel(ID, AFileName: String; Normalisation: TObjectNormalisation): TSceneModel;
    function LoadWaveFrontModel(ID, AFileName: String; Normalisation: TObjectNormalisation): TSceneModel;
    function LoadTexture(AFileName: String): GLUInt;

    constructor Create;
    destructor Destroy; override;

    procedure MoveObjects(DeltaTime: Double);
    procedure CleanLists;
  private
    procedure MoveObjectsInt(ObjectList: TSceneObjectList; DeltaTime: Double);
  end;

implementation

uses
  ColladaLoader, WaveFrontLoader;

constructor TSceneManager.Create;
begin
  Inherited;

  TextureLibrary := TDictionary<String, GLUInt>.Create;

  ModelLibrary := TObjectDictionary<String, TSceneModel>.Create([doOwnsValues]);

  CoreObjects := TSceneObjectList.Create(False);
  StaticObjects := TSceneObjectList.Create(True);
  DynamicObjects := TSceneObjectList.Create(True);
  TemporaryObjects := TSceneObjectList.Create(False);
end;

destructor TSceneManager.Destroy;
begin
  CoreObjects.Free;
  StaticObjects.Free;
  DynamicObjects.Free;
  TemporaryObjects.Free;

  ModelLibrary.Clear;
  ModelLibrary.Free;

  TextureLibrary.Clear;
  TextureLibrary.Free;

  Inherited;
end;

function TSceneManager.LoadTexture(AFileName: string): GLUInt;
var
  Tex: GLUInt;
begin
  if TextureLibrary.TryGetValue(AFileName, Tex) then
    Result := Tex
  else
  begin
    Tex := LoadGLTexture(AFileName);
    TextureLibrary.Add(AFileName, Tex);
    Result := Tex;
  end;
end;

function TSceneManager.AddModel(ID: String): TSceneModel;
var
  LM: TSceneModel;
begin
  if ModelLibrary.ContainsKey(ID) then
    ModelLibrary.TryGetValue(ID, LM)
  else
  begin
    LM := TSceneModel.Create(ID);
    ModelLibrary.Add(ID, LM);
  end;

  Result := LM;
end;

function TSceneManager.GetModel(ID: String): TSceneModel;
var
  LM: TSceneModel;
begin
  if ModelLibrary.ContainsKey(ID) then
    ModelLibrary.TryGetValue(ID, LM)
  else
    LM := nil;

  Result := LM;
end;

function TSceneManager.LoadModel(ID, AFileName: String; Normalisation: TObjectNormalisation): TSceneModel;
begin
  if ExtractFileExt(AFileName) = '.dae' then
    Result := LoadColladaModel(ID, AFileName, Normalisation)
  else if ExtractFileExt(AFileName) = '.obj' then
    Result := LoadWaveFrontModel(ID, AFileName, Normalisation)
  else
    Result := nil;
end;

function TSceneManager.LoadWaveFrontModel(ID, AFileName: String; Normalisation: TObjectNormalisation): TSceneModel;
var
  LM: TSceneModel;
  Mesh: TMesh;
  WO: TWaveFrontObject;
  WM: TWaveFrontMaterial;
  G: Integer;
begin
  if ModelLibrary.ContainsKey(ID) then
  begin
    ModelLibrary.TryGetValue(ID, LM);
  end

  else
  begin
    WO := TWaveFrontObject.Create;
    WO.Load(AFileName, Normalisation);

    LM := TSceneModel.Create(ID);
    LM.BBMin := WO.MinD;
    LM.BBMax := WO.MaxD;

    for G := 0 to WO.GroupCount - 1 do
    begin
      Mesh := TMesh.Create(ID + '/' + IntToStr(G));
      Mesh.AddVertices(@WO.Groups[G].Vertices[0], WO.Groups[G].VerticeCount);
      Mesh.AddIndexes(@WO.Groups[G].Indices[0], WO.Groups[G].IndexCount);

      WM := WO.GetMaterial(WO.Groups[G].Material);

      if WM = nil then
        WM := WO.Materials[0];

      if WM <> nil then
      begin
        if (WM.map_Kd <> '') then
        begin
          Mesh.AddTexture(LoadGLTexture(ExtractFilePath(ExtractFilePath(Application.ExeName) + 'models\' + AFileName) + WM.map_Kd), 1.0);
        end;

        Mesh.SetColour(WM.Kd[0], WM.Kd[1], WM.Kd[2], WM.d);

        Mesh.Effect := TMyEffect.Create;
        Mesh.Effect.Name := WM.Name;

        Mesh.Effect.Parms.Diffuse[0] := WM.Kd[0];
        Mesh.Effect.Parms.Diffuse[1] := WM.Kd[1];
        Mesh.Effect.Parms.Diffuse[2] := WM.Kd[2];

        Mesh.Effect.Parms.Ambient[0] := WM.Ka[0];
        Mesh.Effect.Parms.Ambient[1] := WM.Ka[1];
        Mesh.Effect.Parms.Ambient[2] := WM.Ka[2];

        Mesh.Effect.Parms.Specular[0] := WM.Ks[0];
        Mesh.Effect.Parms.Specular[1] := WM.Ks[1];
        Mesh.Effect.Parms.Specular[2] := WM.Ks[2];

        Mesh.Effect.Parms.Transparency := WM.d;
        Mesh.Effect.Parms.Shininess := WM.Ns;
      end;

      Mesh.Drawmode := GL_TRIANGLES;

      LM.AddMesh(Mesh);
    end;

    WO.Free;

    ModelLibrary.Add(ID, LM);
  end;

  Result := LM;
end;

function TSceneManager.LoadColladaModel(ID, AFileName: String; Normalisation: TObjectNormalisation): TSceneModel;
var
  Mat: TMaterial;
  Eff: TEffect;
  CM: TColladaMesh;
  CP: TColladaPatch;
  SG: TSceneGeometry;
  SC: TSceneController;
  I: Integer;
  LM: TSceneModel;
  Mesh: TMesh;
  SharedVBO: GLUInt;
  LVC, VC: Integer;
  VA: Array of TVertexAttribute;
  W, MaterialURL: String;
  Start, Count: Integer;
  Tex: GLUInt;
  TextureCache: TObjectDictionary<String, GLUInt>;

  procedure SetMaterials;
  var
    EffP: TEffectParm;
    I: Integer;
  begin
    if SG.Controller <> '' then
    begin
      MaterialURL := '#' + CP.Material;
    end
    else if SG.MaterialMap.TryGetValue(CP.Material, W) then
    begin
      MaterialURL := W;
    end;

    if MaterialURL <> '' then
    begin
      if CO.Materials.TryGetValue(Copy(MaterialURL, 2, 99), Mat) then
      begin
        if (Mat.EffectURL <> '') and CO.Effects.TryGetValue
          (Copy(Mat.EffectURL, 2, 99), Eff) then
        begin
          if Eff.Texture <> '' then
          begin
            if CO.Images.TryGetValue(Eff.Texture, W) then
            begin
              if TextureCache.ContainsKey(Eff.Texture) then
              begin
                TextureCache.TryGetValue(Eff.Texture, Tex);
                Mesh.AddTexture(Tex, 1.0);
              end
              else
              begin
                Tex := LoadGLTexture(ExtractFilePath(AFileName) + W);
                TextureCache.Add(Eff.Texture, Tex);
                Mesh.AddTexture(Tex, 1.0);
              end;
            end;
          end
          else
          begin
            for EffP in Eff.EffectParms do
            begin
              if EffP.Name = 'specular' then
              begin
                if Length(EffP.Floats) <> 0 then
                begin
                  for I := 0 to Length(EffP.Floats) - 1 do
                    Mesh.Colour[I] := EffP.Floats[I];
                end;
                break;
              end;
            end;
          end;
        end;
      end;
    end;
  end;

begin
  if ModelLibrary.ContainsKey(ID) then
  begin
    ModelLibrary.TryGetValue(ID, LM);
  end
  else
  begin
    TextureCache := TObjectDictionary<String, GLUInt>.Create;

    CO := TColladaObject.Create;
    CO.LoadFromDAE(ExtractFilePath(Application.ExeName) + 'Models\' + AFileName, onCentreBottom, nil);

    LM := TSceneModel.Create(ID);
    LM.BBMin := CO.MinD;
    LM.BBMax := CO.MaxD;

    for SG in CO.SceneGeometries do
    begin
      if SG.Controller <> '' then
      begin
        W := Copy(SG.Controller, 2, 99);
        if CO.SceneControllers.TryGetValue(W, SC) then
          W := Copy(SC.SkinSource, 2, 99);
      end
      else
        W := Copy(SG.ID, 2, 99);

      if not CO.Meshes.TryGetValue(W, CM) then
        Continue;

      VC := Length(CM.Vertices) div 3;
      SetLength(VA, VC);

      for I := 0 to Length(VA) - 1 do
      begin
        VA[I].PosX := CM.Vertices[3 * I];
        VA[I].PosY := CM.Vertices[3 * I + 1];
        VA[I].PosZ := CM.Vertices[3 * I + 2];

        if 3 * I + 2 < Length(CM.Normals) then
        begin
          VA[I].NormX := CM.Normals[3 * I];
          VA[I].NormY := CM.Normals[3 * I + 1];
          VA[I].NormZ := CM.Normals[3 * I + 2];
        end;

        if 2 * I + 1 < Length(CM.TexCoord) then
        begin
          VA[I].TexU := CM.TexCoord[2 * I];
          VA[I].TexV := 1 - CM.TexCoord[2 * I + 1];
        end;
      end;

      for CP in CM.Patches do
      begin
        if Length(CP.PosIndices) <> 0 then
        begin
          if CP.PatchType = ptPolyList then
          begin
            Start := 0;
            Count := 0;

            Mesh := TMesh.Create(CM.ID + '/' + IntToStr(CM.Patches.IndexOf(CP)));
            SetMaterials;
            Mesh.AddVertices(@VA[0], Length(VA));
            SharedVBO := Mesh.OpenGLData.VBO;
            LVC := CP.VCounts[0];

            for I := 0 to Length(CP.VCounts) - 1 do
            begin
              if CP.VCounts[I] <> LVC then
              begin
                if LVC = 3 then
                  Mesh.Drawmode := GL_TRIANGLES
                else
                  Mesh.Drawmode := GL_POLYGON;
                Mesh.AddIndexes(@CP.PosIndices[Start], Count);
                LM.Meshes.Add(Mesh);
                Start := Count;
                Count := 0;

                Mesh := TMesh.Create(CM.ID + '/' + IntToStr(CM.Patches.IndexOf(CP)) +
                  '/' + IntToStr(I));
                SetMaterials;
                Mesh.OpenGLData.VBO := SharedVBO;
                Mesh.OpenGLData.VBOLength := Length(VA);
              end;
              LVC := CP.VCounts[I];
              Count := Count + LVC;
            end;

            if Count <> 0 then
            begin
              if LVC = 3 then
                Mesh.Drawmode := GL_TRIANGLES
              else
                Mesh.Drawmode := GL_POLYGON;
              Mesh.AddIndexes(@CP.PosIndices[Start], Count);
              LM.Meshes.Add(Mesh);
            end;
          end
          else
          begin
            Mesh := TMesh.Create(CM.ID + '/' + IntToStr(CM.Patches.IndexOf(CP)));

            SetMaterials;

            Mesh.AddVertices(@VA[0], Length(VA));

            if CP.PatchType = ptLines then
              Mesh.Drawmode := GL_LINES
            else if CP.PatchType = ptPolygons then
              Mesh.Drawmode := GL_QUADS
            else if CP.PatchType = ptTriangles then
              Mesh.Drawmode := GL_TRIANGLES;

            Mesh.AddIndexes(@CP.PosIndices[0], Length(CP.PosIndices));

            LM.Meshes.Add(Mesh);
          end;
        end;
      end;
    end;

    CO.Free;
    TextureCache.Free;
    ModelLibrary.Add(ID, LM);
  end;

  Result := LM;
end;

procedure TSceneManager.MoveObjectsInt(ObjectList: TSceneObjectList; DeltaTime: Double);
var
  O: TSceneObject;
begin
  for O in ObjectList.Objects do
  begin
    if O.Active then
      O.Move(DeltaTime / 1000);
  end;
end;

procedure TSceneManager.MoveObjects(DeltaTime: Double);
begin
  MoveObjectsInt(CoreObjects, DeltaTime);
  MoveObjectsInt(DynamicObjects, DeltaTime);
  MoveObjectsInt(TemporaryObjects, DeltaTime);
end;

procedure TSceneManager.CleanLists;
  procedure ClearList(AList: TSceneObjectList);
  var
    I: Integer;
  begin
    for I := AList.Objects.Count - 1 downto 0 do
    begin
      if not AList.Objects[I].Active then
        AList.Objects.Delete(I);
    end;
  end;
begin
  ClearList(StaticObjects);
  ClearList(DynamicObjects);
  ClearList(TemporaryObjects);
end;

constructor TSceneObjectList.Create(CreateInstanced: Boolean);
begin
  Objects := TObjectList<TSceneObject>.Create(False);
  Instanced := CreateInstanced;
end;

destructor TSceneObjectList.Destroy;
var
  O: TSceneObject;
begin
  for O in Objects do
    O.Free;
  Objects.Free;

  inherited;
end;

function TSceneObjectList.GetObjectByName(Aname: String): TSceneObject;
var
  O: TSceneObject;
begin
  Result := nil;

  for O in Objects do
  begin
    if O.Name = Aname then
    begin
      Result := O;
      Break;
    end;
  end;
end;

procedure TSceneObjectList.Clear;
begin
  Objects.Clear;
end;

procedure TSceneObjectList.Add(O: TSceneObject);
begin
  Objects.Add(O);
end;

procedure TSceneObjectList.DoSort;
begin
  Objects.Sort(TComparer<TSceneObject>.Construct(Comparer));
end;

function TSceneObjectList.Comparer(const L, R: TSceneObject): Integer;
begin
  if L.Model.Name < R.Model.Name then
    Result := -1
  else if R.Model.Name > L.Model.Name then
    Result := 1
  else
    Result := 0;
end;

end.
