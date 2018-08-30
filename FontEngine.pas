unit FontEngine;

interface

uses SceneObjects, XmlDoc, XmlIntf, SysUtils, Windows, Forms,
  dglOpenGL, generics.collections, Math, Classes;

type
  TCharacter = class(TObject)
    codePoint, x, y, width, height, originX, originY, advance: Integer;
  end;

  TDistanceFont = class(TObject)
    name: string;
    size, width, height, characterCount: Integer;
    bold, italic: Boolean;

    characters: TObjectDictionary<Integer, TCharacter>;
    texture: GLUInt;

    constructor Create;
    destructor Destroy; override;

    function LoadFont(BaseFontName: String): Boolean;
    function Create3DLabel(AString: String; BillboardObject: TSceneObject; Align: TAlignment): Boolean;
    function Create2DLabel(AString: String; BillboardObject: TSceneObject; Align: TAlignment): Boolean;
  end;

var
  DistanceFont: TDistanceFont;

implementation

uses
  GlHelpers;

constructor TDistanceFont.Create;
begin
  characters := TObjectDictionary<Integer, TCharacter>.Create([doOwnsValues]);
end;

destructor TDIstanceFont.Destroy;
begin
  characters.Clear;
  characters.Free;

  inherited;
end;

function TDistanceFont.LoadFont(BaseFontName: String): Boolean;
var
  XMLDoc: IXMLDocument;
  XMLNode: IXMLNode;
  I: Integer;
  W: String;
  C: TCharacter;
begin
  Result := False;

  XMLDoc := LoadXMLDocument(ExtractFilePath(Application.ExeName) + 'textures\' + BaseFontName + '.xml');
  XMLDoc.Active := True;

  if XMLDoc <> nil then
  begin
    name := XMLDoc.DocumentElement.Attributes['name'];
    size := StrToInt(XMLDoc.DocumentElement.Attributes['size']);
    bold := XMLDoc.DocumentElement.Attributes['bold'] = 'true';
    italic := XMLDoc.DocumentElement.Attributes['bold'] = 'italic';
    width := StrToInt(XMLDoc.DocumentElement.Attributes['width']);
    height := StrToInt(XMLDoc.DocumentElement.Attributes['height']);

    characterCount := XMLDoc.DocumentElement.ChildNodes.Count;

    for I := 0 to XMLDoc.DocumentElement.ChildNodes.Count - 1 do
    begin
      XMLNode := XMLDoc.DocumentElement.ChildNodes[I];

      C := TCharacter.Create;

      W := XMLNode.Attributes['text'];
      C.codePoint := Ord(W[1]);

      C.x := StrToInt(XMLNode.Attributes['x']);
      C.y := StrToInt(XMLNode.Attributes['y']);
      C.width := StrToInt(XMLNode.Attributes['width']);
      C.height := StrToInt(XMLNode.Attributes['height']);
      C.originX := StrToInt(XMLNode.Attributes['origin-x']);
      C.originY := StrToInt(XMLNode.Attributes['origin-y']);
      C.advance := StrToInt(XMLNode.Attributes['advance']);

      characters.AddOrSetValue(C.codePoint, C);
    end;

    texture := LoadGLTexture(BaseFontName + '.png');

    if texture <> 0 then
      Result := True;
  end;

  XMLDoc := nil;
end;

function TDistanceFont.Create2DLabel(AString: String; BillboardObject: TSceneObject; Align: TAlignment): Boolean;
var
  X, Y, Z, W, Offset: GLFloat;
  I, P, Q: Integer;
  C: TCharacter;
  TempVA: TVertexAttributeArray;
  TempIA: TIndexArray;
begin
  SetLength(TempVA, 4 * Length(AString));
  SetLength(TempIA, 6 * Length(AString));

  X := BillboardObject.Position[0];
  Y := BillboardObject.Position[1];
  Z := BillboardObject.Position[2];
  W := 0;

  P := 0;
  Q := 0;

  for I := 1 to Length(AString) do
  begin
    if not characters.TryGetValue(Ord(AString[I]), C) then
      characters.TryGetValue(Ord('?'), C);

    TempVA[P].PosX := X - C.originX * BillboardObject.Scale[0] / size;
    TempVA[P].PosY := Y + C.originY * BillboardObject.Scale[1] / size;
    TempVA[P].PosZ := Z;
    TempVA[P].NormX := 0;
    TempVA[P].NormY := 0;
    TempVA[P].NormZ := -1;
    TempVA[P].TexU := C.x / width;
    TempVA[P].TexV := 1 - (C.y) / height;

    TempVA[P + 1].PosX := X + (C.width - C.originX) * BillboardObject.Scale[0] / size;
    TempVA[P + 1].PosY := Y + C.originY * BillboardObject.Scale[1] / size;
    TempVA[P + 1].PosZ := Z;
    TempVA[P + 1].NormX := 0;
    TempVA[P + 1].NormY := 0;
    TempVA[P + 1].NormZ := -1;
    TempVA[P + 1].TexU := (C.x + C.width) / width;
    TempVA[P + 1].TexV := 1 - (C.y) / height;

    TempVA[P + 2].PosX := X - C.originX * BillboardObject.Scale[0] / size;
    TempVA[P + 2].PosY := Y - (C.height - C.originY) * BillboardObject.Scale[1] / size;
    TempVA[P + 2].PosZ := Z;
    TempVA[P + 2].NormX := 0;
    TempVA[P + 2].NormY := 0;
    TempVA[P + 2].NormZ := -1;
    TempVA[P + 2].TexU := C.x / width;
    TempVA[P + 2].TexV := 1 - (C.y + C.height) / height;

    TempVA[P + 3].PosX := X + (C.width - C.originX) * BillboardObject.Scale[0] / size;
    TempVA[P + 3].PosY := Y - (C.height - C.originY) * BillboardObject.Scale[1] / size;
    TempVA[P + 3].PosZ := Z;
    TempVA[P + 3].NormX := 0;
    TempVA[P + 3].NormY := 0;
    TempVA[P + 3].NormZ := -1;
    TempVA[P + 3].TexU := (C.x + C.width) / width;
    TempVA[P + 3].TexV := 1 - (C.y + C.height) / height;

    TempIA[Q] := P + 0;
    TempIA[Q + 1] := P + 1;
    TempIA[Q + 2] := P + 3;

    TempIA[Q + 3] := P + 0;
    TempIA[Q + 4] := P + 3;
    TempIA[Q + 5] := P + 2;

    X := X + C.advance * BillboardObject.Scale[0] / size;
    W := W + C.advance * BillboardObject.Scale[0] / size;

    P := P + 4;
    Q := Q + 6;
  end;

  if Align = taCenter then
    Offset := W / 2
  else if Align = taRightJustify then
    Offset := W
  else
    Offset := 0;

  if Offset <> 0 then
    for I := 0 to Length(AString) * 4 - 1 do
      TempVA[I].PosX := TempVA[I].PosX - Offset;

  BillboardObject.Model.Meshes[0].AddVertices(@TempVA[0], Length(TempVA));
  BillboardObject.Model.Meshes[0].AddIndexes(@TempIA[0], Length(TempIA));
end;

function TDistanceFont.Create3DLabel(AString: String; BillboardObject: TSceneObject; Align: TAlignment): Boolean;
var
  X, Y, Z, W, Offset: GLFloat;
  I, P, Q: Integer;
  C: TCharacter;
  TempVA: TVertexAttributeArray;
  TempIA: TIndexArray;
begin
  SetLength(TempVA, 4 * Length(AString));
  SetLength(TempIA, 6 * Length(AString));

  X := 0;
  Y := 0;
  Z := 0;
  W := 0;

  P := 0;
  Q := 0;

  for I := 1 to Length(AString) do
  begin
    if not characters.TryGetValue(Ord(AString[I]), C) then
      characters.TryGetValue(Ord('?'), C);

    TempVA[P].PosX := X - C.originX * BillboardObject.Scale[0] / size;
    TempVA[P].PosY := Y + C.originY * BillboardObject.Scale[1] / size;
    TempVA[P].PosZ := Z;
    TempVA[P].NormX := 0;
    TempVA[P].NormY := 0;
    TempVA[P].NormZ := 1;
    TempVA[P].TexU := C.x / width;
    TempVA[P].TexV := 1 - (C.y) / height;

    TempVA[P + 1].PosX := X + (C.width - C.originX) * BillboardObject.Scale[0] / size;
    TempVA[P + 1].PosY := Y + C.originY * BillboardObject.Scale[1] / size;
    TempVA[P + 1].PosZ := Z;
    TempVA[P + 1].NormX := 0;
    TempVA[P + 1].NormY := 0;
    TempVA[P + 1].NormZ := 1;
    TempVA[P + 1].TexU := (C.x + C.width) / width;
    TempVA[P + 1].TexV := 1 - (C.y) / height;

    TempVA[P + 2].PosX := X - C.originX * BillboardObject.Scale[0] / size;
    TempVA[P + 2].PosY := Y - (C.height - C.originY) * BillboardObject.Scale[1] / size;
    TempVA[P + 2].PosZ := Z;
    TempVA[P + 2].NormX := 0;
    TempVA[P + 2].NormY := 0;
    TempVA[P + 2].NormZ := 1;
    TempVA[P + 2].TexU := C.x / width;
    TempVA[P + 2].TexV := 1 - (C.y + C.height) / height;

    TempVA[P + 3].PosX := X + (C.width - C.originX) * BillboardObject.Scale[0] / size;
    TempVA[P + 3].PosY := Y - (C.height - C.originY) * BillboardObject.Scale[1] / size;
    TempVA[P + 3].PosZ := Z;
    TempVA[P + 3].NormX := 0;
    TempVA[P + 3].NormY := 0;
    TempVA[P + 3].NormZ := 1;
    TempVA[P + 3].TexU := (C.x + C.width) / width;
    TempVA[P + 3].TexV := 1 - (C.y + C.height) / height;

    TempIA[Q] := P + 0;
    TempIA[Q + 1] := P + 1;
    TempIA[Q + 2] := P + 3;

    TempIA[Q + 3] := P + 0;
    TempIA[Q + 4] := P + 3;
    TempIA[Q + 5] := P + 2;

    X := X + Max(C.width, C.advance) * BillboardObject.Scale[0] / size;
    W := W + Max(C.width, C.advance) * BillboardObject.Scale[0] / size;

    P := P + 4;
    Q := Q + 6;
  end;

  if Align = taCenter then
    Offset := W / 2
  else if Align = taRightJustify then
    Offset := W
  else
    Offset := 0;

  if Offset <> 0 then
    for I := 0 to Length(AString) * 4 - 1 do
      TempVA[I].PosX := TempVA[I].PosX - Offset;

  BillboardObject.Model.Meshes[0].AddVertices(@TempVA[0], Length(TempVA));
  BillboardObject.Model.Meshes[0].AddIndexes(@TempIA[0], Length(TempIA));
end;

end.
