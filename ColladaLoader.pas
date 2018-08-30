unit ColladaLoader;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, SceneObjects,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Xml.xmldom, Xml.XMLIntf,
  Xml.XMLDoc, Generics.Collections, StrUtils, dglOpenGL, Math;

type
  TPatchType = (ptUndefined, ptTriangles, ptLines, ptPolygons, ptPolyList);
  TEffectType = (etUndefined, etLambert, etConstant, etPhong);

  TEffectParm = class(TObject)
    Name: String;
    Floats: TArray<GLFloat>;
  end;

  TEffect = class(TObject)
    ID: String;
    EffectType: TEffectType;
    Opaque: String;
    EffectParms: TObjectList<TEffectParm>;
    Transparency: GLFloat;
    Texture: String;
    constructor Create;
    destructor Destroy; override;
  end;

  TMaterial = class(TObject)
    ID: String;
    Name: String;
    EffectURL: String;
  end;

  TColladaPatch = class(TObject)
    ID: String;
    Material: String;
    PatchType: TPatchType;
    PosIndices: TArray<GLUInt>;
    NormalIndices: TArray<GLUInt>;
    TextureIndices: TArray<GLUInt>;
    VCounts: TArray<GLUInt>;
  end;

  TColladaMesh = class(TObject)
    ID: String;
    Name: String;
    Vertices: TArray<GLFloat>;
    Normals: TArray<GLFloat>;
    TexCoord: TArray<GLFloat>;
    Patches: TObjectList<TColladaPatch>;
    constructor Create;
    destructor Destroy; override;
  end;

  TSceneGeometry = class(TObject)
    ID: String;
    Controller: String;
    MaterialMap: TDictionary<String, String>;
    Matrix: TArray<GLFloat>;
    constructor Create;
    destructor Destroy; override;
  end;

  TSceneController = class(TObject)
    ID: String;
    SkinSource: String;
  end;

  TColladaObject = class(TObject)
    Source: String;
    Radius: Single;
    Meshes: TObjectDictionary<String, TColladaMesh>;
    Materials: TObjectDictionary<String, TMaterial>;
    SceneControllers: TObjectDictionary<String, TSceneController>;
    Effects: TObjectDictionary<String, TEffect>;
    Images: TObjectDictionary<String, String>;
    SceneGeometries: TObjectList<TSceneGeometry>;
    MinD, MaxD, Centre, Dimension: TGLVectorf3;
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromDAE(FileName: string; Normalisation: TObjectNormalisation; DebugMemo: TMemo = nil);
    procedure ProcessEffectNode(Node: IXMLNode);
    procedure ProcessMaterialNode(Node: IXMLNode);
    procedure ProcessGeometryNode(Node: IXMLNode);
    procedure ProcessVisualSceneNode(Node: IXMLNode);
    procedure ProcessImageNode(Node: IXMLNode);
    procedure ProcessControllerNode(Node: IXMLNode);
  end;

var
  CO: TColladaObject;

implementation

var
  Memo1: TMemo;

procedure SplitFloats(FloatStr: String; var Floats: TArray<GLFloat>);
var
  N, P, Q: Integer;
  W, S: String;
begin
  P := 1;
  N := 0;

  W := ReplaceStr(FloatStr, #10, #32);

  Repeat
    Q := PosEx(' ', W, P);
    if Q <> 0 then
      S := Copy(W, P, Q - P)
    else
      S := Copy(W, P, 999);

    if S <> '' then
    begin
      Floats[N] := StrToFloat(S);
    end;

    Inc(N);
    P := Q + 1;
  Until N = Length(Floats);
end;

procedure SplitIntegers(IntStr: String; var Integers: TArray<GLUInt>);
var
  N, P, Q: Integer;
  W, S: String;
begin
  P := 1;
  N := 0;
  W := IntStr.Replace(#10, #32);

  Repeat
    Q := PosEx(' ', W, P);
    if Q <> 0 then
      S := Copy(W, P, Q - P)
    else
      S := Copy(W, P, 999);

    if S <> '' then
    begin
      Integers[N] := StrToInt(S);
    end;

    Inc(N);
    P := Q + 1;
  Until N = Length(Integers);
end;

function GetMaxL(Floats: TArray<GLFloat>): Single;
var
  I: Integer;
  W, R: Single;
begin
  W := 0;

  for I := 0 to Length(Floats) div 3 - 1 do
  begin
    R := Sqrt(Floats[I] * Floats[I] + Floats[I + 1] * Floats[I + 1] +
      Floats[I + 2] * Floats[I + 2]);
    if R > W then
      W := R;
  end;

  Result := W;
end;

constructor TEffect.Create;
begin
  EffectParms := TObjectList<TEffectParm>.Create(True);
end;

destructor TEffect.Destroy;
begin
  EffectParms.Free;

  inherited;
end;

constructor TColladaObject.Create;
begin
  inherited;

  Meshes := TObjectDictionary<String, TColladaMesh>.Create([doOwnsValues]);
  Materials := TObjectDictionary<String, TMaterial>.Create([doOwnsValues]);
  Effects := TObjectDictionary<String, TEffect>.Create([doOwnsValues]);
  Images := TObjectDictionary<String, String>.Create;
  SceneControllers := TObjectDictionary<String, TSceneController>.Create([doOwnsValues]);
  SceneGeometries := TObjectList<TSceneGeometry>.Create(True);

  MinD[0] := 999.99;
  MinD[1] := 999.99;
  MinD[2] := 999.99;

  MaxD[0] := -999.99;
  MaxD[1] := -999.99;
  MaxD[2] := -999.99;
end;

destructor TColladaObject.Destroy;
begin
  Images.Free;
  Meshes.Free;
  Materials.Free;
  Effects.Free;
  SceneGeometries.Free;
  SceneControllers.Free;

  inherited;
end;

constructor TColladaMesh.Create;
begin
  inherited;

  Patches := TObjectList<TColladaPatch>.Create(True);
end;

destructor TColladaMesh.Destroy;
begin
  Patches.Free;

  inherited;
end;

constructor TSceneGeometry.Create;
begin
  inherited;

  Controller := '';
  MaterialMap := TDictionary<String, String>.Create;
end;

destructor TSceneGeometry.Destroy;
begin
  MaterialMap.Free;

  inherited;
end;

procedure NormaliseTexCoord(AnArray: TArray<GLFloat>);
var
  N: Integer;
  Maxi, Mini, Maxj, Minj, U, V: GLFloat;
begin
  Maxi := -9999999;
  Mini := 9999999;
  Maxj := -9999999;
  Minj := 9999999;

  for N := 0 to Length(AnArray) - 1 do
  begin
    if Odd(N) then
    begin
      if AnArray[N] < Minj then
        Minj := AnArray[N];
      if AnArray[N] > Maxj then
        Maxj := AnArray[N];
    end
    else
    begin
      if AnArray[N] < Mini then
        Mini := AnArray[N];
      if AnArray[N] > Maxi then
        Maxi := AnArray[N];
    end;
  end;

  if (Maxi > 1) or (Mini < 0) or (MaxJ > 1) or (MinJ < 0) then
  begin
    U := Maxi - Mini;
    V := Maxj - Minj;

    for N := 0 to Length(AnArray) - 1 do
    begin
      if Odd(N) then
        AnArray[N] := (AnArray[N] - Minj) / V
      else
        AnArray[N] := (AnArray[N] - Mini) / U;
    end;
  end;
end;

procedure TColladaObject.ProcessGeometryNode(Node: IXMLNode);
var
  MeshNode: IXMLNode;
  ANode, BNode: IXMLNode;
  I, J, K, L, N: Integer;
  Mesh: TColladaMesh;
  Patch: TColladaPatch;
  Work: TArray<GLUInt>;
  PositionID, NormalID, TexCoordID: String;
  PositionOffset, NormalOffset, TextureOffset, MaxOffset: Integer;
  S: String;
  VC0: Integer;

begin
  if Memo1 <> nil then
    Memo1.Lines.Add(Node.NodeName + ' ' + Node.Attributes['id']);

  Mesh := TColladaMesh.Create;

  Mesh.ID := Node.Attributes['id'];

  if Node.HasAttribute('name') then
    Mesh.Name := Node.Attributes['name'];

  MeshNode := Node.ChildNodes[0];

  // pass 1 = get POSITION and NORMAL IDS
  for I := 0 to MeshNode.ChildNodes.Count - 1 do
  begin
    ANode := MeshNode.ChildNodes[I];
    if (ANode.NodeName = 'vertices') or (ANode.NodeName = 'triangles') or
      (ANode.NodeName = 'polylist') then
    begin
      for J := 0 to ANode.ChildNodes.Count - 1 do
      begin
        if ANode.ChildNodes[J].Attributes['semantic'] = 'POSITION' then
          PositionID := ANode.ChildNodes[J].Attributes['source']
        else if ANode.ChildNodes[J].Attributes['semantic'] = 'NORMAL' then
          NormalID := ANode.ChildNodes[J].Attributes['source']
        else if ANode.ChildNodes[J].Attributes['semantic'] = 'TEXCOORD' then
          TexCoordID := ANode.ChildNodes[J].Attributes['source'];
      end;
    end;
  end;

  if PositionID = '' then
    Exit;

  for I := 0 to MeshNode.ChildNodes.Count - 1 do
  begin
    ANode := MeshNode.ChildNodes[I];
    if ANode.NodeName = 'source' then
    begin
      if ANode.ChildNodes[0].NodeName = 'float_array' then
      begin
        N := StrToInt(ANode.ChildNodes[0].Attributes['count']);

        if '#' + ANode.Attributes['id'] = PositionID then
        begin
          SetLength(Mesh.Vertices, N);
          SplitFloats(ANode.ChildNodes[0].Text, Mesh.Vertices);

          Radius := GetMaxL(Mesh.Vertices);
        end

        else if '#' + ANode.Attributes['id'] = NormalID then
        begin
          SetLength(Mesh.Normals, N);
          SplitFloats(ANode.ChildNodes[0].Text, Mesh.Normals);
        end

        else if '#' + ANode.Attributes['id'] = TexCoordID then
        begin
          SetLength(Mesh.TexCoord, N);
          SplitFloats(ANode.ChildNodes[0].Text, Mesh.TexCoord);

          NormaliseTexCoord(Mesh.TexCoord);
        end;
      end

      else if ANode.ChildNodes[0].NodeName = 'Name_Array' then
      begin

      end;
    end

    else if ANode.NodeName = 'vertices' then
    begin
      // handled specifically earlier
    end

    else if (ANode.NodeName = 'triangles') or (ANode.NodeName = 'lines') or
      (ANode.NodeName = 'polylist') then
    begin
      Patch := TColladaPatch.Create;
      Patch.ID := Node.Attributes['id'] + '/' + ANode.NodeName;

      if (ANode.NodeName = 'triangles') then
      begin
        Patch.PatchType := ptTriangles;
        N := 3 * StrToInt(ANode.Attributes['count']);
      end

      else if (ANode.NodeName = 'lines') then
      begin
        Patch.PatchType := ptLines;
        N := 2 * StrToInt(ANode.Attributes['count']);
      end

      else if (ANode.NodeName = 'polylist') then
      begin
        Patch.PatchType := ptPolyList;
        N := StrToInt(ANode.Attributes['count']);
      end;

      if ANode.HasAttribute('material') then
        Patch.Material := ANode.Attributes['material'];

      PositionOffset := -1;
      NormalOffset := -1;
      TextureOffset := -1;
      MaxOffset := -1;

      for J := 0 to ANode.ChildNodes.Count - 1 do
      begin
        BNode := ANode.ChildNodes[J];

        if BNode.NodeName = 'input' then
        begin
          if BNode.Attributes['semantic'] = 'VERTEX' then
            PositionOffset := StrToInt(BNode.Attributes['offset'])
          else if BNode.Attributes['semantic'] = 'NORMAL' then
            NormalOffset := StrToInt(BNode.Attributes['offset'])
          else if BNode.Attributes['semantic'] = 'TEXCOORD' then
            TextureOffset := StrToInt(BNode.Attributes['offset']);

          MaxOffset := Max(StrToInt(BNode.Attributes['offset']), MaxOffset);
        end

        else if BNode.NodeName = 'vcount' then
        begin
          // special case, get N vcounts
          SetLength(Patch.VCounts, N);
          SplitIntegers(BNode.Text, Patch.VCounts);
          S := BNode.Text;

          // then add them up to get the number of polygons
          VC0 := 0;
          for L := 0 to N - 1 do
            VC0 := VC0 + Patch.VCounts[L];

          // and set the vertex count to the calculated number
          N := VC0;
        end

        else if BNode.NodeName = 'p' then
        begin
          // special case when just vertices
          if MaxOffset = 0 then
          begin
            SetLength(Patch.PosIndices, N);
            SplitIntegers(BNode.Text, Patch.PosIndices);
          end

          else
          begin
            SetLength(Work, N * (MaxOffset + 1));
            SplitIntegers(BNode.Text, Work);

            if PositionOffset <> -1 then
              SetLength(Patch.PosIndices, N);
            if NormalOffset <> -1 then
              SetLength(Patch.NormalIndices, N);
            if TextureOffset <> -1 then
              SetLength(Patch.TextureIndices, N);

            for K := 0 to N - 1 do
            begin
              if PositionOffset <> -1 then
                Patch.PosIndices[K] :=
                  Work[K * (MaxOffset + 1) + PositionOffset];
              if NormalOffset <> -1 then
                Patch.NormalIndices[K] :=
                  Work[K * (MaxOffset + 1) + NormalOffset];
              if TextureOffset <> -1 then
                Patch.TextureIndices[K] :=
                  Work[K * (MaxOffset + 1) + TextureOffset];
            end;
          end;
        end;
      end;
      Mesh.Patches.Add(Patch);
    end;
  end;

  for I := 0 to Length(Mesh.Vertices) div 3 - 1 do
  begin
    for N := 0 to 2 do
    begin
      if Mesh.Vertices[3 * I + N] > MaxD[N] then
        MaxD[N] := Mesh.Vertices[3 * I + N];
      if Mesh.Vertices[3 * I + N] < MinD[N] then
        MinD[N] := Mesh.Vertices[3 * I + N];
    end;
  end;

  Meshes.Add(Mesh.ID, Mesh);
end;

procedure TColladaObject.ProcessMaterialNode(Node: IXMLNode);
var
  Material: TMaterial;
begin
  if Memo1 <> nil then
    Memo1.Lines.Add(Node.NodeName + ' ' + Node.Attributes['id']);

  Material := TMaterial.Create;
  Material.ID := Node.Attributes['id'];
  Material.Name := Node.Attributes['name'];
  Material.EffectURL := Node.ChildNodes[0].Attributes['url'];

  Materials.Add(Material.ID, Material);
end;

procedure TColladaObject.ProcessEffectNode(Node: IXMLNode);
var
  Effect: TEffect;
  EffectParm: TEffectParm;
  ANode, BNode, CNode, DNode: IXMLNode;
  I, J: Integer;
  Surface, Sampler2D: String;
begin
  Effect := TEffect.Create;
  Effect.ID := Node.Attributes['id'];
  Effect.Opaque := '';
  Effect.Transparency := 1.0;

  ANode := Node.ChildNodes[0];
  for I := 0 to ANode.ChildNodes.Count - 1 do
  begin
    BNode := ANode.ChildNodes[I];

    if BNode.NodeName = 'newparam' then
    begin
      if BNode.ChildNodes[0].NodeName = 'surface' then
        Surface := BNode.ChildNodes[0].ChildNodes[0].Text
      else if BNode.ChildNodes[0].NodeName = 'sampler2D' then
        Sampler2D := BNode.Attributes['sid'];
    end

    else if BNode.NodeName = 'technique' then
    begin
      CNode := BNode.ChildNodes[0];

      if CNode.NodeName = 'constant' then
        Effect.EffectType := etConstant
      else if CNode.NodeName = 'lambert' then
        Effect.EffectType := etLambert
      else if CNode.NodeName = 'phong' then
        Effect.EffectType := etPhong;

      for J := 0 to CNode.ChildNodes.Count - 1 do
      begin
        DNode := CNode.ChildNodes[J];

        if DNode.ChildNodes[0].NodeName = 'float' then
        begin
          EffectParm := TEffectParm.Create;
          EffectParm.Name := DNode.NodeName;
          SetLength(EffectParm.Floats, 1);
          EffectParm.Floats[0] := StrToFloat(DNode.ChildNodes[0].Text);
          Effect.EffectParms.Add(EffectParm);
        end

        else if DNode.ChildNodes[0].NodeName = 'color' then
        begin
          EffectParm := TEffectParm.Create;
          EffectParm.Name := DNode.NodeName;
          SetLength(EffectParm.Floats, 4);
          SplitFloats(DNode.ChildNodes[0].Text, EffectParm.Floats);
          Effect.EffectParms.Add(EffectParm);
        end

        else if DNode.ChildNodes[0].NodeName = 'texture' then
        begin
          if DNode.ChildNodes[0].Attributes['texture'] = Sampler2D then
            Effect.Texture := Surface;
        end;
      end;
    end;
  end;

  Effects.Add(Effect.ID, Effect);
end;

procedure TColladaObject.ProcessImageNode(Node: IXMLNode);
begin
  if Node.NodeName = 'image' then
  begin
    Images.Add(Node.Attributes['id'], Node.ChildNodes[0].Text);
  end;
end;

procedure TColladaObject.ProcessVisualSceneNode(Node: IXMLNode);
var
  SceneGeometry: TSceneGeometry;
  ANode, BNode, CNode, DNode, ENode: IXMLNode;
  I, J, K, L: Integer;
begin
  for I := 0 to Node.ChildNodes.Count - 1 do
  begin
    SceneGeometry := nil;

    ANode := Node.ChildNodes[I];
    if ANode.NodeName = 'node' then
    begin
      for J := 0 to ANode.ChildNodes.Count - 1 do
      begin
        BNode := ANode.ChildNodes[J];
        if BNode.NodeName = 'instance_geometry' then
        begin
          if SceneGeometry <> nil then
            SceneGeometries.Add(SceneGeometry);

          SceneGeometry := TSceneGeometry.Create;
          SceneGeometry.ID := BNode.Attributes['url'];

          if BNode.ChildNodes.Count <> 0 then
          begin
            for L := 0 to BNode.ChildNodes.Count - 1 do
            begin
              CNode := BNode.ChildNodes[L];
              if CNode.NodeName = 'bind_material' then
              begin
                DNode := CNode.ChildNodes[0];
                if DNode.NodeName = 'technique_common' then
                begin
                  for K := 0 to DNode.ChildNodes.Count - 1 do
                  begin
                    ENode := DNode.ChildNodes[K];
                    if ENode.NodeName = 'instance_material' then
                    begin
                      SceneGeometry.MaterialMap.Add(ENode.Attributes['symbol'],
                        ENode.Attributes['target']);
                    end;
                  end;
                end;
              end;
            end;
          end;
        end

        else if BNode.NodeName = 'instance_controller' then
        begin
          if SceneGeometry <> nil then
            SceneGeometries.Add(SceneGeometry);

          SceneGeometry := TSceneGeometry.Create;
          SceneGeometry.ID := ANode.Attributes['id'];

          if BNode.ChildNodes.Count <> 0 then
          begin
            for L := 0 to BNode.ChildNodes.Count - 1 do
            begin
              CNode := BNode.ChildNodes[L];
              if CNode.NodeName = 'bind_material' then
              begin
                DNode := CNode.ChildNodes[0];
                if DNode.NodeName = 'technique_common' then
                begin
                  for K := 0 to DNode.ChildNodes.Count - 1 do
                  begin
                    ENode := DNode.ChildNodes[K];
                    if ENode.NodeName = 'instance_material' then
                    begin
                      SceneGeometry.Controller := BNode.Attributes['url'];
                    end;
                  end;
                end;
              end;
            end;
          end;
//        end
//
//        else if BNode.NodeName = 'matrix' then
//        begin
//          if SceneGeometry = nil then
//            SceneGeometry := TSceneGeometry.Create;
//          SetLength(SceneGeometry.Matrix, 16);
//          SplitFloats(BNode.Text, SceneGeometry.Matrix);
        end;
      end;
    end;
    if SceneGeometry <> nil then
      SceneGeometries.Add(SceneGeometry);
  end;
end;

procedure TColladaObject.ProcessControllerNode(Node: IXMLNode);
var
  SceneController: TSceneController;
  ANode: IXMLNode;
  I: Integer;
begin
  for I := 0 to Node.ChildNodes.Count - 1 do
  begin
    ANode := Node.ChildNodes[I];
    if ANode.NodeName = 'skin' then
    begin
      SceneController := TSceneController.Create;
      SceneController.ID := Node.Attributes['id'];
      SceneController.SkinSource := ANode.Attributes['source'];
      SceneControllers.Add(SceneController.ID, SceneController);
    end;
  end;
end;

function FindSingleNode(Start: IXMLNode; Path: String): IXMLNode;
var
  ANode: IXMLNode;
  I, Index, P, Q: Integer;
  S, T: String;
begin
  ANode := Start;

  if Path[Length(Path)] <> '/' then
    S := Path + '/';
  if Pos('//', S) <> 0 then
    S := ReplaceStr(S, '//', '');

  Q := 1;

  Repeat
    P := PosEx('/', S, Q);
    if P <> 0 then
    begin
      T := Copy(S, Q, P - Q);

      Index := -1;
      for I := 0 to ANode.ChildNodes.Count - 1 do
      begin
        if ANode.ChildNodes[I].NodeName = T then
        begin
          Index := I;
          Break;
        end;
      end;

      if Index = -1 then
      begin
        ANode := nil;
        Break;
      end
      else
        ANode := ANode.ChildNodes[Index];
      Q := P + 1;
    end;
  Until Q >= Length(S);

  Result := ANode;
end;

procedure TColladaObject.LoadFromDAE(FileName: string; Normalisation: TObjectNormalisation; DebugMemo: TMemo = nil);
var
  XMLDoc: IXMLDocument;
  I: Integer;
  Node, ANode: IXMLNode;
  SceneID: String;
  Mesh: TColladaMesh;

begin
  Memo1 := DebugMemo;

  Source := ExtractFileName(FileName);

  XMLDoc := TXMLDocument.Create(nil);
  XMLDoc.LoadFromFile(FileName);
  XMLDoc.Active := True;

  Node := FindSingleNode(XMLDoc.DocumentElement, '//scene/instance_visual_scene');

  if Node <> nil then
  begin
    if Node.HasAttribute('url') then
      SceneID := Node.Attributes['url'];

    ANode := FindSingleNode(XMLDoc.DocumentElement, '//library_visual_scenes');
    for I := 0 to ANode.ChildNodes.Count - 1 do
      if '#' + ANode.ChildNodes[I].Attributes['id'] = SceneID then
        ProcessVisualSceneNode(ANode.ChildNodes[I]);

    ANode := FindSingleNode(XMLDoc.DocumentElement, '//library_images');
    if ANode <> nil then
      for I := 0 to ANode.ChildNodes.Count - 1 do
        ProcessImageNode(ANode.ChildNodes[I]);

    ANode := FindSingleNode(XMLDoc.DocumentElement, '//library_effects');
    if ANode <> nil then
      for I := 0 to ANode.ChildNodes.Count - 1 do
        ProcessEffectNode(ANode.ChildNodes[I]);

    ANode := FindSingleNode(XMLDoc.DocumentElement, '//library_materials');
    if ANode <> nil then
      for I := 0 to ANode.ChildNodes.Count - 1 do
        ProcessMaterialNode(ANode.ChildNodes[I]);

    ANode := FindSingleNode(XMLDoc.DocumentElement, '//library_geometries');
    if ANode <> nil then
      for I := 0 to ANode.ChildNodes.Count - 1 do
        ProcessGeometryNode(ANode.ChildNodes[I]);

    ANode := FindSingleNode(XMLDOc.DocumentElement, '//library_controllers');
    if ANode <> nil then
      for I := 0 to ANode.ChildNodes.Count - 1 do
        ProcessControllerNode(ANode.ChildNodes[I]);
  end;

  XMLDoc.Active := False;
  XMLDoc := nil;

  if Normalisation <> onNone then
  begin
    Centre[0] := (MaxD[0] + MinD[0]) / 2.0;
    Centre[1] := (MaxD[1] + MinD[1]) / 2.0;
    Centre[2] := (MaxD[2] + MinD[2]) / 2.0;

    Dimension[0] := MaxD[0] - MinD[0];
    Dimension[1] := MaxD[1] - MinD[1];
    Dimension[2] := MaxD[2] - MinD[2];

    for Mesh in Meshes.Values do
    begin
      for I := 0 to Length(Mesh.Vertices) div 3 - 1 do
      begin
        // normalise so lenth = 1 unit
        Mesh.Vertices[3 * I] := (Mesh.Vertices[3 * I] - Centre[0]) / Dimension[2];
        if Normalisation = onCentreBottom then
          Mesh.Vertices[3 * I + 1] := (Mesh.Vertices[3 * I + 1] - MinD[1]) / Dimension[2]
        else
          Mesh.Vertices[3 * I + 1] := (Mesh.Vertices[3 * I + 1] - Centre[1]) / Dimension[2];
        Mesh.Vertices[3 * I + 2] := (Mesh.Vertices[3 * I + 2] - Centre[2]) / Dimension[2];
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

end.
