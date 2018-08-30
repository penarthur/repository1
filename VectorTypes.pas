// (c) Copyright 1999, Dipl. Ing. Mike Lischke (public@lischke-online.de)

unit VectorTypes;
{$WARNINGS OFF}
interface

type
  TVector2d = array[0..1] of double;
  TVector2f = array[0..1] of single;
  TVector2i = array[0..1] of longint;
  TVector2ui = array[0..1] of longWord;
  TVector2s = array[0..1] of smallint;
  TVector2b = array[0..1] of byte;
  TVector2e = array[0..1] of Extended;
  TVector2w = array[0..1] of Word;
  TVector2p = array[0..1] of Pointer;

  TVector3d = array[0..2] of double;
  TVector3f = array[0..2] of single;
  TVector3i = array[0..2] of longint;
  TVector3ui = array[0..2] of longWord;
  TVector3s = array[0..2] of smallint;
  TVector3b = array[0..2] of byte;
  TVector3e = array[0..2] of Extended;
  TVector3w = array[0..2] of Word;
  TVector3p = array[0..2] of Pointer;

  TVector4d = array[0..3] of double;
  TVector4f = array[0..3] of single;
  TVector4i = array[0..3] of longint;
  TVector4ui = array[0..3] of longWord;
  TVector4s = array[0..3] of smallint;
  TVector4b = array[0..3] of byte;
  TVector4e = array[0..3] of Extended;
  TVector4w = array[0..3] of Word;
  TVector4p = array[0..3] of Pointer;

  TMatrix2d = array[0..1] of TVector2d;
  TMatrix2f = array[0..1] of TVector2f;
  TMatrix2i = array[0..1] of TVector2i;
  TMatrix2s = array[0..1] of TVector2s;
  TMatrix2b = array[0..1] of TVector2b;
  TMatrix2e = array[0..1] of TVector2e;
  TMatrix2w = array[0..1] of TVector2w;
  TMatrix2p = array[0..1] of TVector2p;

  TMatrix3d = array[0..2] of TVector3d;
  TMatrix3f = array[0..2] of TVector3f;
  TMatrix3i = array[0..2] of TVector3i;
  TMatrix3s = array[0..2] of TVector3s;
  TMatrix3b = array[0..2] of TVector3b;
  TMatrix3e = array[0..2] of TVector3e;
  TMatrix3w = array[0..2] of TVector3w;
  TMatrix3p = array[0..2] of TVector3p;

  TMatrix4d = array[0..3] of TVector4d;
  TMatrix4f = array[0..3] of TVector4f;
  TMatrix4i = array[0..3] of TVector4i;
  TMatrix4s = array[0..3] of TVector4s;
  TMatrix4b = array[0..3] of TVector4b;
  TMatrix4e = array[0..3] of TVector4e;
  TMatrix4w = array[0..3] of TVector4w;
  TMatrix4p = array[0..3] of TVector4p;

  TD3DVector = packed record
    case Integer of
      0 : (X: single;
           Y: single;
           Z: single);
      1 : (V: TVector3f);
  end;

  TD3DMatrix = packed record
    case Integer of
      0 : (_11, _12, _13, _14: single;
           _21, _22, _23, _24: single;
           _31, _32, _33, _34: single;
           _41, _42, _43, _44: single);
      1 : (M : TMatrix4f);
  end;

  TRect = packed record
    Left, Bottom, Right, Top: Double;
  end;

implementation

end.

