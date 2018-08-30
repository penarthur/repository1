unit VectorGeometry;

// This unit contains many needed types, functions and procedures for
// quaternion, vector and matrix arithmetics. It is specifically designed
// for geometric calculations within R3 (affine vector space)
// and R4 (homogeneous vector space).
//
// Note: The terms 'affine' or 'affine coordinates' are not really correct here
// because an 'affine transformation' describes generally a transformation which leads
// to a uniquely solvable system of equations and has nothing to do with the dimensionality
// of a vector. One could use 'projective coordinates' but this is also not really correct
// and since I haven't found a better name (or even any correct one), 'affine' is as good
// as any other one.
//
// Identifiers containing no dimensionality (like affine or homogeneous)
// and no datatype (integer..extended) are supposed as R4 representation
// with 'single' floating point type (examples are TVector, TMatrix,
// and TQuaternion). The default data type is 'single' ('GLFloat' for OpenGL)
// and used in all routines (except conversions and trigonometric functions).
//
// Routines with an open array as argument can either take Func([1,2,3,4,..]) or Func(Vect).
// The latter is prefered, since no extra stack operations is required.
// Note: Be careful while passing open array elements! If you pass more elements
// than there's room in the result the behaviour will be unpredictable.
//
// If not otherwise stated, all angles are given in radians
// (instead of degrees). Use RadToDeg or DegToRad to convert between them.
//
// Geometry.pas was assembled from different sources (like GraphicGems)
// and relevant books or based on self written code, respectivly.
//
// Note: Some aspects need to be considered when using Delphi and pure
// assembler code. Delphi esnures that the direction flag is always
// cleared while entering a function and expects it cleared on return.
// This is in particular important in routines with (CPU) string commands (MOVSD etc.)
// The registers EDI, ESI and EBX (as well as the stack management
// registers EBP and ESP) must not be changed! EAX, ECX and EDX are
// freely available and mostly used for parameter.
//
// Version 2.5
// last change : 04. January 2000
//
// (c) Copyright 1999, Dipl. Ing. Mike Lischke (public@lischke-online.de)

interface

{$WARNINGS OFF}

uses VectorTypes;

const
  cMaxArray = (MaxInt shr 4);

  // define for turning off assembly routines in this unit
  // *experimental* and incomplete
{$DEFINE GEOMETRY_NO_ASM}

type
  // data types needed for 3D graphics calculation,
  // included are 'C like' aliases for each type (to be
  // conformal with OpenGL types)
{$IFNDEF FPC}
  PByte = ^Byte;
  PWord = ^Word;
  PInteger = ^Integer;
  PCardinal = ^Cardinal;
  PSingle = ^Single;
  PDouble = ^Double;
  PExtended = ^Extended;
  PPointer = ^Pointer;
{$ENDIF}
  PFloat = ^Single;

  PTexPoint = ^TTexPoint;

  TTexPoint = packed record
    S, T: Single;
  end;

  // types to specify continous streams of a specific type
  // switch off range checking to access values beyond the limits
  PByteVector = ^TByteVector;
  PByteArray = PByteVector;
  TByteVector = array [0 .. cMaxArray] of Byte;

  PWordVector = ^TWordVector;
  TWordVector = array [0 .. cMaxArray] of Word;

  PIntegerVector = ^TIntegerVector;
  PIntegerArray = PIntegerVector;
  TIntegerVector = array [0 .. cMaxArray] of Integer;

  PFloatVector = ^TFloatVector;
  PFloatArray = PFloatVector;
  PSingleArray = PFloatArray;
  TFloatVector = array [0 .. cMaxArray] of Single;
  TSingleArray = array of Single;

  PDoubleVector = ^TDoubleVector;
  PDoubleArray = PDoubleVector;
  TDoubleVector = array [0 .. cMaxArray] of Double;

  PExtendedVector = ^TExtendedVector;
  PExtendedArray = PExtendedVector;
  TExtendedVector = array [0 .. cMaxArray] of Extended;

  PPointerVector = ^TPointerVector;
  PPointerArray = PPointerVector;
  TPointerVector = array [0 .. cMaxArray] of Pointer;

  PCardinalVector = ^TCardinalVector;
  PCardinalArray = PCardinalVector;
  TCardinalVector = array [0 .. cMaxArray] of Cardinal;

  PLongWordVector = ^TLongWordVector;
  PLongWordArray = PLongWordVector;
  TLongWordVector = array [0 .. cMaxArray] of LongWord;

  // common vector and matrix types with predefined limits
  // indices correspond like: x -> 0
  // y -> 1
  // z -> 2
  // w -> 3

  PHomogeneousByteVector = ^THomogeneousByteVector;
  THomogeneousByteVector = TVector4b;

  PHomogeneousWordVector = ^THomogeneousWordVector;
  THomogeneousWordVector = TVector4w;

  PHomogeneousIntVector = ^THomogeneousIntVector;
  THomogeneousIntVector = TVector4i;

  PHomogeneousFltVector = ^THomogeneousFltVector;
  THomogeneousFltVector = TVector4f;

  PHomogeneousDblVector = ^THomogeneousDblVector;
  THomogeneousDblVector = TVector4d;

  PHomogeneousExtVector = ^THomogeneousExtVector;
  THomogeneousExtVector = TVector4e;

  PHomogeneousPtrVector = ^THomogeneousPtrVector;
  THomogeneousPtrVector = TVector4p;

  PAffineByteVector = ^TAffineByteVector;
  TAffineByteVector = TVector3b;

  PAffineWordVector = ^TAffineWordVector;
  TAffineWordVector = TVector3w;

  PAffineIntVector = ^TAffineIntVector;
  TAffineIntVector = TVector3i;

  PAffineFltVector = ^TAffineFltVector;
  TAffineFltVector = TVector3f;

  PAffineDblVector = ^TAffineDblVector;
  TAffineDblVector = TVector3d;

  PAffineExtVector = ^TAffineExtVector;
  TAffineExtVector = TVector3e;

  PAffinePtrVector = ^TAffinePtrVector;
  TAffinePtrVector = TVector3p;

  // some simplified names
  PVector = ^TVector;
  TVector = THomogeneousFltVector;

  PHomogeneousVector = ^THomogeneousVector;
  THomogeneousVector = THomogeneousFltVector;

  PAffineVector = ^TAffineVector;
  TAffineVector = TVector3f;

  PVertex = ^TVertex;
  TVertex = TAffineVector;

  // arrays of vectors
  PAffineVectorArray = ^TAffineVectorArray;
  TAffineVectorArray = array [0 .. MaxInt shr 4] of TAffineVector;

  TIntegerArray = array [0 .. MaxInt shr 4] of Integer;

  PVectorArray = ^TVectorArray;
  TVectorArray = array [0 .. MaxInt shr 5] of TVector;

  PTexPointArray = ^TTexPointArray;
  TTexPointArray = array [0 .. MaxInt shr 4] of TTexPoint;

  // matrices
  THomogeneousByteMatrix = TMatrix4b;

  THomogeneousWordMatrix = array [0 .. 3] of THomogeneousWordVector;

  THomogeneousIntMatrix = TMatrix4i;

  THomogeneousFltMatrix = TMatrix4f;

  THomogeneousDblMatrix = TMatrix4d;

  THomogeneousExtMatrix = array [0 .. 3] of THomogeneousExtVector;

  TAffineByteMatrix = TMatrix3b;

  TAffineWordMatrix = array [0 .. 2] of TAffineWordVector;

  TAffineIntMatrix = TMatrix3i;

  TAffineFltMatrix = TMatrix3f;

  TAffineDblMatrix = TMatrix3d;

  TAffineExtMatrix = array [0 .. 2] of TAffineExtVector;

  // some simplified names
  PMatrix = ^TMatrix;
  TMatrix = THomogeneousFltMatrix;

  TMatrixArray = array [0 .. MaxInt shr 7] of TMatrix;
  PMatrixArray = ^TMatrixArray;

  PHomogeneousMatrix = ^THomogeneousMatrix;
  THomogeneousMatrix = THomogeneousFltMatrix;

  PAffineMatrix = ^TAffineMatrix;
  TAffineMatrix = TAffineFltMatrix;

  { : A plane equation.<p>
    Defined by its equation A.x+B.y+C.z+D<p>, a plane can be mapped to the
    homogeneous space coordinates, and this is what we are doing here.<br>
    The typename is just here for easing up data manipulation. }
  THmgPlane = TVector;
  TDoubleHmgPlane = THomogeneousDblVector;

  // q = ([x, y, z], w)
  PQuaternion = ^TQuaternion;

  TQuaternion = record
    ImagPart: TAffineVector;
    RealPart: Single;
  end;

  PQuaternionArray = ^TQuaternionArray;
  TQuaternionArray = array [0 .. MaxInt shr 5] of TQuaternion;

  TRectangle = record
    Left, Top, Width, Height: Integer;
  end;

  TFrustum = record
    pLeft, pTop, pRight, pBottom, pNear, pFar: THmgPlane;
  end;

  TTransType = (ttScaleX, ttScaleY, ttScaleZ, ttShearXY, ttShearXZ, ttShearYZ,
    ttRotateX, ttRotateY, ttRotateZ, ttTranslateX, ttTranslateY, ttTranslateZ,
    ttPerspectiveX, ttPerspectiveY, ttPerspectiveZ, ttPerspectiveW);

  // used to describe a sequence of transformations in following order:
  // [Sx][Sy][Sz][ShearXY][ShearXZ][ShearZY][Rx][Ry][Rz][Tx][Ty][Tz][P(x,y,z,w)]
  // constants are declared for easier access (see MatrixDecompose below)
  TTransformations = array [TTransType] of Single;

  TPackedRotationMatrix = array [0 .. 2] of SmallInt;

const
  // useful constants

  // TexPoints (2D space)
  XTexPoint: TTexPoint = (S: 1; T: 0);
  YTexPoint: TTexPoint = (S: 0; T: 1);
  XYTexPoint: TTexPoint = (S: 1; T: 1);
  NullTexPoint: TTexPoint = (S: 0; T: 0);
  MidTexPoint: TTexPoint = (S: 0.5; T: 0.5);

  // standard vectors
  XVector: TAffineVector = (1, 0, 0);
  YVector: TAffineVector = (0, 1, 0);
  ZVector: TAffineVector = (0, 0, 1);
  XYVector: TAffineVector = (1, 1, 0);
  XZVector: TAffineVector = (1, 0, 1);
  YZVector: TAffineVector = (0, 1, 1);
  XYZVector: TAffineVector = (1, 1, 1);
  NullVector: TAffineVector = (0, 0, 0);
  MinusXVector: TAffineVector = (-1, 0, 0);
  MinusYVector: TAffineVector = (0, -1, 0);
  MinusZVector: TAffineVector = (0, 0, -1);
  // standard homogeneous vectors
  XHmgVector: THomogeneousVector = (1, 0, 0, 0);
  YHmgVector: THomogeneousVector = (0, 1, 0, 0);
  ZHmgVector: THomogeneousVector = (0, 0, 1, 0);
  WHmgVector: THomogeneousVector = (0, 0, 0, 1);
  XYHmgVector: THomogeneousVector = (1, 1, 0, 0);
  YZHmgVector: THomogeneousVector = (0, 1, 1, 0);
  XZHmgVector: THomogeneousVector = (1, 0, 1, 0);

  XYZHmgVector: THomogeneousVector = (1, 1, 1, 0);
  XYZWHmgVector: THomogeneousVector = (1, 1, 1, 1);
  NullHmgVector: THomogeneousVector = (0, 0, 0, 0);
  // standard homogeneous points
  XHmgPoint: THomogeneousVector = (1, 0, 0, 1);
  YHmgPoint: THomogeneousVector = (0, 1, 0, 1);
  ZHmgPoint: THomogeneousVector = (0, 0, 1, 1);
  WHmgPoint: THomogeneousVector = (0, 0, 0, 1);
  NullHmgPoint: THomogeneousVector = (0, 0, 0, 1);

  IdentityMatrix: TAffineMatrix = ((1, 0, 0), (0, 1, 0), (0, 0, 1));
  IdentityHmgMatrix: TMatrix = ((1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0),
    (0, 0, 0, 1));
  IdentityHmgDblMatrix: THomogeneousDblMatrix = ((1, 0, 0, 0), (0, 1, 0, 0),
    (0, 0, 1, 0), (0, 0, 0, 1));
  EmptyMatrix: TAffineMatrix = ((0, 0, 0), (0, 0, 0), (0, 0, 0));
  EmptyHmgMatrix: TMatrix = ((0, 0, 0, 0), (0, 0, 0, 0), (0, 0, 0, 0),
    (0, 0, 0, 0));

  // Quaternions

  IdentityQuaternion: TQuaternion = (ImagPart: (0, 0, 0); RealPart: 1);

  // some very small numbers
  EPSILON: Single = 1E-40;
  EPSILON2: Single = 1E-30;

  // ------------------------------------------------------------------------------
  // Vector functions
  // ------------------------------------------------------------------------------

function TexPointMake(const S, T: Single): TTexPoint; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
function AffineVectorMake(const x, y, z: Single): TAffineVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function AffineVectorMake(const v: TVector): TAffineVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetAffineVector(out v: TAffineVector; const x, y, z: Single);
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetVector(out v: TAffineVector; const x, y, z: Single); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetVector(out v: TAffineVector; const vSrc: TVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetVector(out v: TAffineVector; const vSrc: TAffineVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetVector(out v: TAffineDblVector; const vSrc: TAffineVector);
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetVector(out v: TAffineDblVector; const vSrc: TVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorMake(const v: TAffineVector; w: Single = 0): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorMake(const x, y, z: Single; w: Single = 0): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function PointMake(const x, y, z: Single): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function PointMake(const v: TAffineVector): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function PointMake(const v: TVector): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetVector(out v: TVector; const x, y, z: Single; w: Single = 0);
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetVector(out v: TVector; const av: TAffineVector; w: Single = 0);
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure SetVector(out v: TVector; const vSrc: TVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure MakePoint(out v: TVector; const x, y, z: Single); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure MakePoint(out v: TVector; const av: TAffineVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure MakePoint(out v: TVector; const av: TVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure MakeVector(out v: TAffineVector; const x, y, z: Single); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure MakeVector(out v: TVector; const x, y, z: Single); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure MakeVector(out v: TVector; const av: TAffineVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure MakeVector(out v: TVector; const av: TVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure RstVector(var v: TAffineVector); overload;
procedure RstVector(var v: TVector); overload;

// 2
function VectorEquals(const V1, V2: TVector2f): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector2i): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector2d): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector2s): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector2b): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// 3
// function VectorEquals(const V1, V2: TVector3f): Boolean; overload; //declared further
function VectorEquals(const V1, V2: TVector3i): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector3d): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector3s): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector3b): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// 4
// function VectorEquals(const V1, V2: TVector4f): Boolean; overload; //declared further
function VectorEquals(const V1, V2: TVector4i): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector4d): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector4s): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorEquals(const V1, V2: TVector4b): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// 3x3
function MatrixEquals(const Matrix1, Matrix2: TMatrix3f): Boolean; overload;
function MatrixEquals(const Matrix1, Matrix2: TMatrix3i): Boolean; overload;
function MatrixEquals(const Matrix1, Matrix2: TMatrix3d): Boolean; overload;
function MatrixEquals(const Matrix1, Matrix2: TMatrix3s): Boolean; overload;
function MatrixEquals(const Matrix1, Matrix2: TMatrix3b): Boolean; overload;

// 4x4
function MatrixEquals(const Matrix1, Matrix2: TMatrix4f): Boolean; overload;
function MatrixEquals(const Matrix1, Matrix2: TMatrix4i): Boolean; overload;
function MatrixEquals(const Matrix1, Matrix2: TMatrix4d): Boolean; overload;
function MatrixEquals(const Matrix1, Matrix2: TMatrix4s): Boolean; overload;
function MatrixEquals(const Matrix1, Matrix2: TMatrix4b): Boolean; overload;

// 2x
function Vector2fMake(const x, y: Single): TVector2f; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2iMake(const x, y: Longint): TVector2i; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2sMake(const x, y: SmallInt): TVector2s; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2dMake(const x, y: Double): TVector2d; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2bMake(const x, y: Byte): TVector2b; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2fMake(const Vector: TVector3f): TVector2f; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2iMake(const Vector: TVector3i): TVector2i; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2sMake(const Vector: TVector3s): TVector2s; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2dMake(const Vector: TVector3d): TVector2d; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2bMake(const Vector: TVector3b): TVector2b; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2fMake(const Vector: TVector4f): TVector2f; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2iMake(const Vector: TVector4i): TVector2i; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2sMake(const Vector: TVector4s): TVector2s; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2dMake(const Vector: TVector4d): TVector2d; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector2bMake(const Vector: TVector4b): TVector2b; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// 3x
function Vector3fMake(const x: Single; const y: Single = 0; const z: Single = 0)
  : TVector3f; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3iMake(const x: Longint; const y: Longint = 0;
  const z: Longint = 0): TVector3i; overload; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
function Vector3sMake(const x: SmallInt; const y: SmallInt = 0;
  const z: SmallInt = 0): TVector3s; overload; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
function Vector3dMake(const x: Double; const y: Double = 0; const z: Double = 0)
  : TVector3d; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3bMake(const x: Byte; const y: Byte = 0; const z: Byte = 0)
  : TVector3b; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3fMake(const Vector: TVector2f; const z: Single = 0): TVector3f;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3iMake(const Vector: TVector2i; const z: Longint = 0): TVector3i;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3sMake(const Vector: TVector2s; const z: SmallInt = 0)
  : TVector3s; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3dMake(const Vector: TVector2d; const z: Double = 0): TVector3d;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3bMake(const Vector: TVector2b; const z: Byte = 0): TVector3b;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3fMake(const Vector: TVector4f): TVector3f; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3iMake(const Vector: TVector4i): TVector3i; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3sMake(const Vector: TVector4s): TVector3s; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3dMake(const Vector: TVector4d): TVector3d; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector3bMake(const Vector: TVector4b): TVector3b; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// 4x
function Vector4fMake(const x: Single; const y: Single = 0; const z: Single = 0;
  const w: Single = 0): TVector4f; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4iMake(const x: Longint; const y: Longint = 0;
  const z: Longint = 0; const w: Longint = 0): TVector4i; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4sMake(const x: SmallInt; const y: SmallInt = 0;
  const z: SmallInt = 0; const w: SmallInt = 0): TVector4s; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4dMake(const x: Double; const y: Double = 0; const z: Double = 0;
  const w: Double = 0): TVector4d; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4bMake(const x: Byte; const y: Byte = 0; const z: Byte = 0;
  const w: Byte = 0): TVector4b; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4fMake(const Vector: TVector3f; const w: Single = 0): TVector4f;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4iMake(const Vector: TVector3i; const w: Longint = 0): TVector4i;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4sMake(const Vector: TVector3s; const w: SmallInt = 0)
  : TVector4s; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4dMake(const Vector: TVector3d; const w: Double = 0): TVector4d;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4bMake(const Vector: TVector3b; const w: Byte = 0): TVector4b;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4fMake(const Vector: TVector2f; const z: Single = 0;
  const w: Single = 0): TVector4f; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4iMake(const Vector: TVector2i; const z: Longint = 0;
  const w: Longint = 0): TVector4i; overload; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
function Vector4sMake(const Vector: TVector2s; const z: SmallInt = 0;
  const w: SmallInt = 0): TVector4s; overload; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
function Vector4dMake(const Vector: TVector2d; const z: Double = 0;
  const w: Double = 0): TVector4d; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function Vector4bMake(const Vector: TVector2b; const z: Byte = 0;
  const w: Byte = 0): TVector4b; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Vector comparison functions:
// ComparedVector
// 3f
function VectorMoreThen(const SourceVector, ComparedVector: TVector3f)
  : Boolean; overload;
function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector3f)
  : Boolean; overload;

function VectorLessThen(const SourceVector, ComparedVector: TVector3f)
  : Boolean; overload;
function VectorLessEqualThen(const SourceVector, ComparedVector: TVector3f)
  : Boolean; overload;
// 4f
function VectorMoreThen(const SourceVector, ComparedVector: TVector4f)
  : Boolean; overload;
function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector4f)
  : Boolean; overload;

function VectorLessThen(const SourceVector, ComparedVector: TVector4f)
  : Boolean; overload;
function VectorLessEqualThen(const SourceVector, ComparedVector: TVector4f)
  : Boolean; overload;
// 3i
function VectorMoreThen(const SourceVector, ComparedVector: TVector3i)
  : Boolean; overload;
function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector3i)
  : Boolean; overload;

function VectorLessThen(const SourceVector, ComparedVector: TVector3i)
  : Boolean; overload;
function VectorLessEqualThen(const SourceVector, ComparedVector: TVector3i)
  : Boolean; overload;
// 4i
function VectorMoreThen(const SourceVector, ComparedVector: TVector4i)
  : Boolean; overload;
function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector4i)
  : Boolean; overload;

function VectorLessThen(const SourceVector, ComparedVector: TVector4i)
  : Boolean; overload;
function VectorLessEqualThen(const SourceVector, ComparedVector: TVector4i)
  : Boolean; overload;

// 3s
function VectorMoreThen(const SourceVector, ComparedVector: TVector3s)
  : Boolean; overload;
function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector3s)
  : Boolean; overload;

function VectorLessThen(const SourceVector, ComparedVector: TVector3s)
  : Boolean; overload;
function VectorLessEqualThen(const SourceVector, ComparedVector: TVector3s)
  : Boolean; overload;
// 4s
function VectorMoreThen(const SourceVector, ComparedVector: TVector4s)
  : Boolean; overload;
function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector4s)
  : Boolean; overload;

function VectorLessThen(const SourceVector, ComparedVector: TVector4s)
  : Boolean; overload;
function VectorLessEqualThen(const SourceVector, ComparedVector: TVector4s)
  : Boolean; overload;

// ComparedNumber
// 3f
function VectorMoreThen(const SourceVector: TVector3f;
  const ComparedNumber: Single): Boolean; overload;
function VectorMoreEqualThen(const SourceVector: TVector3f;
  const ComparedNumber: Single): Boolean; overload;

function VectorLessThen(const SourceVector: TVector3f;
  const ComparedNumber: Single): Boolean; overload;
function VectorLessEqualThen(const SourceVector: TVector3f;
  const ComparedNumber: Single): Boolean; overload;
// 4f
function VectorMoreThen(const SourceVector: TVector4f;
  const ComparedNumber: Single): Boolean; overload;
function VectorMoreEqualThen(const SourceVector: TVector4f;
  const ComparedNumber: Single): Boolean; overload;

function VectorLessThen(const SourceVector: TVector4f;
  const ComparedNumber: Single): Boolean; overload;
function VectorLessEqualThen(const SourceVector: TVector4f;
  const ComparedNumber: Single): Boolean; overload;
// 3i
function VectorMoreThen(const SourceVector: TVector3i;
  const ComparedNumber: Single): Boolean; overload;
function VectorMoreEqualThen(const SourceVector: TVector3i;
  const ComparedNumber: Single): Boolean; overload;

function VectorLessThen(const SourceVector: TVector3i;
  const ComparedNumber: Single): Boolean; overload;
function VectorLessEqualThen(const SourceVector: TVector3i;
  const ComparedNumber: Single): Boolean; overload;
// 4i
function VectorMoreThen(const SourceVector: TVector4i;
  const ComparedNumber: Single): Boolean; overload;
function VectorMoreEqualThen(const SourceVector: TVector4i;
  const ComparedNumber: Single): Boolean; overload;

function VectorLessThen(const SourceVector: TVector4i;
  const ComparedNumber: Single): Boolean; overload;
function VectorLessEqualThen(const SourceVector: TVector4i;
  const ComparedNumber: Single): Boolean; overload;
// 3s
function VectorMoreThen(const SourceVector: TVector3s;
  const ComparedNumber: Single): Boolean; overload;
function VectorMoreEqualThen(const SourceVector: TVector3s;
  const ComparedNumber: Single): Boolean; overload;

function VectorLessThen(const SourceVector: TVector3s;
  const ComparedNumber: Single): Boolean; overload;
function VectorLessEqualThen(const SourceVector: TVector3s;
  const ComparedNumber: Single): Boolean; overload;
// 4s
function VectorMoreThen(const SourceVector: TVector4s;
  const ComparedNumber: Single): Boolean; overload;
function VectorMoreEqualThen(const SourceVector: TVector4s;
  const ComparedNumber: Single): Boolean; overload;

function VectorLessThen(const SourceVector: TVector4s;
  const ComparedNumber: Single): Boolean; overload;
function VectorLessEqualThen(const SourceVector: TVector4s;
  const ComparedNumber: Single): Boolean; overload;

// : Returns the sum of two affine vectors
function VectorAdd(const V1, V2: TAffineVector): TAffineVector; overload;
// : Adds two vectors and places result in vr
procedure VectorAdd(const V1, V2: TAffineVector;
  var vr: TAffineVector); overload;
procedure VectorAdd(const V1, V2: TAffineVector; vr: PAffineVector); overload;
// : Returns the sum of two homogeneous vectors
function VectorAdd(const V1, V2: TVector): TVector; overload;
procedure VectorAdd(const V1, V2: TVector; var vr: TVector); overload;
// : Sums up f to each component of the vector
function VectorAdd(const v: TAffineVector; const f: Single): TAffineVector;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Sums up f to each component of the vector
function VectorAdd(const v: TVector; const f: Single): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Adds V2 to V1, result is placed in V1
procedure AddVector(var V1: TAffineVector; const V2: TAffineVector); overload;
// : Adds V2 to V1, result is placed in V1
procedure AddVector(var V1: TAffineVector; const V2: TVector); overload;
// : Adds V2 to V1, result is placed in V1
procedure AddVector(var V1: TVector; const V2: TVector); overload;
// : Sums up f to each component of the vector
procedure AddVector(var v: TAffineVector; const f: Single); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Sums up f to each component of the vector
procedure AddVector(var v: TVector; const f: Single); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Adds V2 to V1, result is placed in V1. W coordinate is always 1.
procedure AddPoint(var V1: TVector; const V2: TVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Returns the sum of two homogeneous vectors. W coordinate is always 1.
function PointAdd(var V1: TVector; const V2: TVector): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Adds delta to nb texpoints in src and places result in dest
procedure TexPointArrayAdd(const src: PTexPointArray; const delta: TTexPoint;
  const nb: Integer; dest: PTexPointArray); overload;
procedure TexPointArrayScaleAndAdd(const src: PTexPointArray;
  const delta: TTexPoint; const nb: Integer; const scale: TTexPoint;
  dest: PTexPointArray); overload;
// : Adds delta to nb vectors in src and places result in dest
procedure VectorArrayAdd(const src: PAffineVectorArray;
  const delta: TAffineVector; const nb: Integer;
  dest: PAffineVectorArray); overload;

// : Returns V1-V2
function VectorSubtract(const V1, V2: TAffineVector): TAffineVector; overload;
// : Subtracts V2 from V1 and return value in result
procedure VectorSubtract(const V1, V2: TAffineVector;
  var result: TAffineVector); overload;
// : Subtracts V2 from V1 and return value in result
procedure VectorSubtract(const V1, V2: TAffineVector;
  var result: TVector); overload;
// : Subtracts V2 from V1 and return value in result
procedure VectorSubtract(const V1: TVector; V2: TAffineVector;
  var result: TVector); overload;
// : Returns V1-V2
function VectorSubtract(const V1, V2: TVector): TVector; overload;
// : Subtracts V2 from V1 and return value in result
procedure VectorSubtract(const V1, V2: TVector; var result: TVector); overload;
// : Subtracts V2 from V1 and return value in result
procedure VectorSubtract(const V1, V2: TVector;
  var result: TAffineVector); overload;
function VectorSubtract(const V1: TAffineVector; delta: Single): TAffineVector;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorSubtract(const V1: TVector; delta: Single): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Subtracts V2 from V1, result is placed in V1
procedure SubtractVector(var V1: TAffineVector;
  const V2: TAffineVector); overload;
// : Subtracts V2 from V1, result is placed in V1
procedure SubtractVector(var V1: TVector; const V2: TVector); overload;

// : Combine the first vector with the second : vr:=vr+v*f
procedure CombineVector(var vr: TAffineVector; const v: TAffineVector;
  var f: Single); overload;
procedure CombineVector(var vr: TAffineVector; const v: TAffineVector;
  pf: PFloat); overload;
// : Makes a linear combination of two texpoints
function TexPointCombine(const t1, t2: TTexPoint; f1, f2: Single): TTexPoint;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Makes a linear combination of two vectors and return the result
function VectorCombine(const V1, V2: TAffineVector; const f1, f2: Single)
  : TAffineVector; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Makes a linear combination of three vectors and return the result
function VectorCombine3(const V1, V2, V3: TAffineVector;
  const f1, f2, F3: Single): TAffineVector; overload; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
procedure VectorCombine3(const V1, V2, V3: TAffineVector;
  const f1, f2, F3: Single; var vr: TAffineVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Combine the first vector with the second : vr:=vr+v*f
procedure CombineVector(var vr: TVector; const v: TVector;
  var f: Single); overload;
// : Combine the first vector with the second : vr:=vr+v*f
procedure CombineVector(var vr: TVector; const v: TAffineVector;
  var f: Single); overload;
// : Makes a linear combination of two vectors and return the result
function VectorCombine(const V1, V2: TVector; const f1, f2: Single): TVector;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Makes a linear combination of two vectors and return the result
function VectorCombine(const V1: TVector; const V2: TAffineVector;
  const f1, f2: Single): TVector; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Makes a linear combination of two vectors and place result in vr
procedure VectorCombine(const V1: TVector; const V2: TAffineVector;
  const f1, f2: Single; var vr: TVector); overload; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
// : Makes a linear combination of two vectors and place result in vr
procedure VectorCombine(const V1, V2: TVector; const f1, f2: Single;
  var vr: TVector); overload;
// : Makes a linear combination of two vectors and place result in vr, F1=1.0
procedure VectorCombine(const V1, V2: TVector; const f2: Single;
  var vr: TVector); overload;
// : Makes a linear combination of three vectors and return the result
function VectorCombine3(const V1, V2, V3: TVector; const f1, f2, F3: Single)
  : TVector; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Makes a linear combination of three vectors and return the result
procedure VectorCombine3(const V1, V2, V3: TVector; const f1, f2, F3: Single;
  var vr: TVector); overload;

{ : Calculates the dot product between V1 and V2.<p>
  Result:=V1[X] * V2[X] + V1[Y] * V2[Y] + V1[Z] * V2[Z] }
function VectorDotProduct(const V1, V2: TAffineVector): Single; overload;
{ : Calculates the dot product between V1 and V2.<p>
  Result:=V1[X] * V2[X] + V1[Y] * V2[Y] + V1[Z] * V2[Z] }
function VectorDotProduct(const V1, V2: TVector): Single; overload;
{ : Calculates the dot product between V1 and V2.<p>
  Result:=V1[X] * V2[X] + V1[Y] * V2[Y] + V1[Z] * V2[Z] }
function VectorDotProduct(const V1: TVector; const V2: TAffineVector)
  : Single; overload;

{ : Projects p on the line defined by o and direction.<p>
  Performs VectorDotProduct(VectorSubtract(p, origin), direction), which,
  if direction is normalized, computes the distance between origin and the
  projection of p on the (origin, direction) line. }
function PointProject(const p, origin, direction: TAffineVector)
  : Single; overload;
function PointProject(const p, origin, direction: TVector): Single; overload;

// : Calculates the cross product between vector 1 and 2
function VectorCrossProduct(const V1, V2: TAffineVector)
  : TAffineVector; overload;
// : Calculates the cross product between vector 1 and 2
function VectorCrossProduct(const V1, V2: TVector): TVector; overload;
// : Calculates the cross product between vector 1 and 2, place result in vr
procedure VectorCrossProduct(const V1, V2: TVector; var vr: TVector); overload;
// : Calculates the cross product between vector 1 and 2, place result in vr
procedure VectorCrossProduct(const V1, V2: TAffineVector;
  var vr: TVector); overload;
// : Calculates the cross product between vector 1 and 2, place result in vr
procedure VectorCrossProduct(const V1, V2: TVector;
  var vr: TAffineVector); overload;
// : Calculates the cross product between vector 1 and 2, place result in vr
procedure VectorCrossProduct(const V1, V2: TAffineVector;
  var vr: TAffineVector); overload;

// : Calculates linear interpolation between start and stop at point t
function Lerp(const start, stop, T: Single): Single; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
// : Calculates angular interpolation between start and stop at point t
function AngleLerp(start, stop, T: Single): Single; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
{ : This is used for interpolating between 2 matrices. The result
  is used to reposition the model parts each frame. }
function MatrixLerp(const m1, m2: TMatrix; const delta: Single): TMatrix;

{ : Calculates the angular distance between two angles in radians.<p>
  Result is in the [0; PI] range. }
function DistanceBetweenAngles(angle1, angle2: Single): Single;

// : Calculates linear interpolation between texpoint1 and texpoint2 at point t
function TexPointLerp(const t1, t2: TTexPoint; T: Single): TTexPoint; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Calculates linear interpolation between vector1 and vector2 at point t
function VectorLerp(const V1, V2: TAffineVector; T: Single)
  : TAffineVector; overload;
// : Calculates linear interpolation between vector1 and vector2 at point t, places result in vr
procedure VectorLerp(const V1, V2: TAffineVector; T: Single;
  var vr: TAffineVector); overload;
// : Calculates linear interpolation between vector1 and vector2 at point t
function VectorLerp(const V1, V2: TVector; T: Single): TVector; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : Calculates linear interpolation between vector1 and vector2 at point t, places result in vr
procedure VectorLerp(const V1, V2: TVector; T: Single; var vr: TVector);
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorAngleLerp(const V1, V2: TAffineVector; T: Single)
  : TAffineVector; overload;
function VectorAngleCombine(const V1, V2: TAffineVector; f: Single)
  : TAffineVector; overload;

// : Calculates linear interpolation between vector arrays
procedure VectorArrayLerp(const src1, src2: PVectorArray; T: Single; n: Integer;
  dest: PVectorArray); overload;
procedure VectorArrayLerp(const src1, src2: PAffineVectorArray; T: Single;
  n: Integer; dest: PAffineVectorArray); overload;
procedure VectorArrayLerp(const src1, src2: PTexPointArray; T: Single;
  n: Integer; dest: PTexPointArray); overload;

type
  TGLInterpolationType = (itLinear, itPower, itSin, itSinAlt, itTan, itLn);

  { : There functions that do the same as "Lerp", but add some distortions. }
function InterpolatePower(const start, stop, delta: Single;
  const DistortionDegree: Single): Single;
function InterpolateLn(const start, stop, delta: Single;
  const DistortionDegree: Single): Single;

{ : Only valid where Delta belongs to [0..1] }
function InterpolateSin(const start, stop, delta: Single): Single;
function InterpolateTan(const start, stop, delta: Single): Single;

{ : "Alt" functions are valid everywhere }
function InterpolateSinAlt(const start, stop, delta: Single): Single;

function InterpolateCombinedFastPower(const OriginalStart, OriginalStop,
  OriginalCurrent: Single; const TargetStart, TargetStop: Single;
  const DistortionDegree: Single): Single;
function InterpolateCombinedSafe(const OriginalStart, OriginalStop,
  OriginalCurrent: Single; const TargetStart, TargetStop: Single;
  const DistortionDegree: Single;
  const InterpolationType: TGLInterpolationType): Single;
function InterpolateCombinedFast(const OriginalStart, OriginalStop,
  OriginalCurrent: Single; const TargetStart, TargetStop: Single;
  const DistortionDegree: Single;
  const InterpolationType: TGLInterpolationType): Single;
function InterpolateCombined(const start, stop, delta: Single;
  const DistortionDegree: Single;
  const InterpolationType: TGLInterpolationType): Single;

{ : Calculates the length of a vector following the equation sqrt(x*x+y*y). }
function VectorLength(const x, y: Single): Single; overload;
{ : Calculates the length of a vector following the equation sqrt(x*x+y*y+z*z). }
function VectorLength(const x, y, z: Single): Single; overload;
// : Calculates the length of a vector following the equation sqrt(x*x+y*y+z*z).
function VectorLength(const v: TAffineVector): Single; overload;
// : Calculates the length of a vector following the equation sqrt(x*x+y*y+z*z+w*w).
function VectorLength(const v: TVector): Single; overload;
{ : Calculates the length of a vector following the equation: sqrt(x*x+y*y+...).<p>
  Note: The parameter of this function is declared as open array. Thus
  there's no restriction about the number of the components of the vector. }
function VectorLength(const v: array of Single): Single; overload;

{ : Calculates norm of a vector which is defined as norm = x * x + y * y<p>
  Also known as "Norm 2" in the math world, this is sqr(VectorLength). }
function VectorNorm(const x, y: Single): Single; overload;
{ : Calculates norm of a vector which is defined as norm = x*x + y*y + z*z<p>
  Also known as "Norm 2" in the math world, this is sqr(VectorLength). }
function VectorNorm(const v: TAffineVector): Single; overload;
{ : Calculates norm of a vector which is defined as norm = x*x + y*y + z*z<p>
  Also known as "Norm 2" in the math world, this is sqr(VectorLength). }
function VectorNorm(const v: TVector): Single; overload;
{ : Calculates norm of a vector which is defined as norm = v[0]*v[0] + ...<p>
  Also known as "Norm 2" in the math world, this is sqr(VectorLength). }
function VectorNorm(var v: array of Single): Single; overload;

// : Transforms a vector to unit length
procedure NormalizeVector(var v: TAffineVector); overload;
// : Transforms a vector to unit length
procedure NormalizeVector(var v: TVector); overload;
// : Returns the vector transformed to unit length
function VectorNormalize(const v: TAffineVector): TAffineVector; overload;
// : Returns the vector transformed to unit length (w component dropped)
function VectorNormalize(const v: TVector): TVector; overload;

// : Transforms vectors to unit length
procedure NormalizeVectorArray(list: PAffineVectorArray; n: Integer); overload;

{ : Calculates the cosine of the angle between Vector1 and Vector2.<p>
  Result = DotProduct(V1, V2) / (Length(V1) * Length(V2)) }
function VectorAngleCosine(const V1, V2: TAffineVector): Single;overload;

{ : Calculates the cosine of the angle between Vector1 and Vector2.<p>
  Result = DotProduct(V1, V2) / (Length(V1) * Length(V2)) }
function VectorAngleCosine(const V1, V2: TVector): Single;overload;

// : Negates the vector
function VectorNegate(const v: TAffineVector): TAffineVector; overload;
function VectorNegate(const v: TVector): TVector; overload;

// : Negates the vector
procedure NegateVector(var v: TAffineVector); overload;
// : Negates the vector
procedure NegateVector(var v: TVector); overload;
// : Negates the vector
procedure NegateVector(var v: array of Single); overload;

// : Scales given vector by a factor
procedure ScaleVector(var v: TAffineVector; factor: Single); overload;
{ : Scales given vector by another vector.<p>
  v[x]:=v[x]*factor[x], v[y]:=v[y]*factor[y] etc. }
procedure ScaleVector(var v: TAffineVector;
  const factor: TAffineVector); overload;
// : Scales given vector by a factor
procedure ScaleVector(var v: TVector; factor: Single); overload;
{ : Scales given vector by another vector.<p>
  v[x]:=v[x]*factor[x], v[y]:=v[y]*factor[y] etc. }
procedure ScaleVector(var v: TVector; const factor: TVector); overload;
// : Returns a vector scaled by a factor
function VectorScale(const v: TAffineVector; factor: Single)
  : TAffineVector; overload;
// : Scales a vector by a factor and places result in vr
procedure VectorScale(const v: TAffineVector; factor: Single;
  var vr: TAffineVector); overload;
// : Returns a vector scaled by a factor
function VectorScale(const v: TVector; factor: Single): TVector; overload;
// : Scales a vector by a factor and places result in vr
procedure VectorScale(const v: TVector; factor: Single;
  var vr: TVector); overload;
// : Scales a vector by a factor and places result in vr
procedure VectorScale(const v: TVector; factor: Single;
  var vr: TAffineVector); overload;
// : Scales given vector by another vector
function VectorScale(const v: TAffineVector; const factor: TAffineVector)
  : TAffineVector; overload;
// : RScales given vector by another vector
function VectorScale(const v: TVector; const factor: TVector): TVector;
  overload;

{ : Divides given vector by another vector.<p>
  v[x]:=v[x]/divider[x], v[y]:=v[y]/divider[y] etc. }
procedure DivideVector(var v: TVector; const divider: TVector); overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
procedure DivideVector(var v: TAffineVector; const divider: TAffineVector);
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorDivide(const v: TVector; const divider: TVector): TVector;
  overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
function VectorDivide(const v: TAffineVector; const divider: TAffineVector)
  : TAffineVector; overload; {$IFDEF GLS_INLINE}inline; {$ENDIF}
// : True if all components are equal.
function TexpointEquals(const p1, p2: TTexPoint): Boolean;
// : True if all components are equal.
function RectEquals(const Rect1, Rect2: TRect): Boolean;
// : True if all components are equal.
function VectorEquals(const V1, V2: TVector): Boolean; overload;
// : True if all components are equal.
function VectorEquals(const V1, V2: TAffineVector): Boolean; overload;
// : True if X, Y and Z components are equal.
function AffineVectorEquals(const V1, V2: TVector): Boolean; overload;
// : True if x=y=z=0, w ignored
function VectorIsNull(const v: TVector): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
// : True if x=y=z=0, w ignored
function VectorIsNull(const v: TAffineVector): Boolean; overload;
{$IFDEF GLS_INLINE}inline; {$ENDIF}
{ : Calculates Abs(v1[x]-v2[x])+Abs(v1[y]-v2[y]), also know as "Norm1".<p> }
function VectorSpacing(const V1, V2: TTexPoint): Single; overload;
{ : Calculates Abs(v1[x]-v2[x])+Abs(v1[y]-v2[y])+..., also know as "Norm1".<p> }
function VectorSpacing(const V1, V2: TAffineVector): Single; overload;
{ : Calculates Abs(v1[x]-v2[x])+Abs(v1[y]-v2[y])+..., also know as "Norm1".<p> }
function VectorSpacing(const V1, V2: TVector): Single; overload;

{ : Calculates distance between two vectors.<p>
  ie. sqrt(sqr(v1[x]-v2[x])+...) }
function VectorDistance(const V1, V2: TAffineVector): Single; overload;
{ : Calculates distance between two vectors.<p>
  ie. sqrt(sqr(v1[x]-v2[x])+...) (w component ignored) }
function VectorDistance(const V1, V2: TVector): Single; overload;

{ : Calculates the "Norm 2" between two vectors.<p>
  ie. sqr(v1[x]-v2[x])+... }
function VectorDistance2(const V1, V2: TAffineVector): Single; overload;
{ : Calculates the "Norm 2" between two vectors.<p>
  ie. sqr(v1[x]-v2[x])+... (w component ignored) }
function VectorDistance2(const V1, V2: TVector): Single; overload;

{ : Calculates a vector perpendicular to N.<p>
  N is assumed to be of unit length, subtract out any component parallel to N }
function VectorPerpendicular(const v, n: TAffineVector): TAffineVector;
// : Reflects vector V against N (assumes N is normalized)
function VectorReflect(const v, n: TAffineVector): TAffineVector;
// : Rotates Vector about Axis with Angle radians
procedure RotateVector(var Vector: TVector; const axis: TAffineVector;
  angle: Single); overload;
// : Rotates Vector about Axis with Angle radians
procedure RotateVector(var Vector: TVector; const axis: TVector;
  angle: Single); overload;

// : Rotate given vector around the Y axis (alpha is in rad)
procedure RotateVectorAroundY(var v: TAffineVector; alpha: Single);
// : Returns given vector rotated around the X axis (alpha is in rad)
function VectorRotateAroundX(const v: TAffineVector; alpha: Single)
  : TAffineVector; overload;
// : Returns given vector rotated around the Y axis (alpha is in rad)
function VectorRotateAroundY(const v: TAffineVector; alpha: Single)
  : TAffineVector; overload;
// : Returns given vector rotated around the Y axis in vr (alpha is in rad)
procedure VectorRotateAroundY(const v: TAffineVector; alpha: Single;
  var vr: TAffineVector); overload;
// : Returns given vector rotated around the Z axis (alpha is in rad)
function VectorRotateAroundZ(const v: TAffineVector; alpha: Single)
  : TAffineVector; overload;

// : Vector components are replaced by their Abs value. }
procedure AbsVector(var v: TVector); overload; {$IFDEF GLS_INLINE}inline;
{$ENDIF}
// : Vector components are replaced by their Abs value. }
procedure AbsVector(var v: TAffineVector); overload;
// : Returns a vector with components replaced by their Abs value. }
function VectorAbs(const v: TVector): TVector; overload;
// : Returns a vector with components replaced by their Abs value. }
function VectorAbs(const v: TAffineVector): TAffineVector; overload;

// ------------------------------------------------------------------------------
// Matrix functions
// ------------------------------------------------------------------------------

procedure SetMatrix(var dest: THomogeneousDblMatrix;
  const src: TMatrix); overload;
procedure SetMatrix(var dest: TAffineMatrix; const src: TMatrix); overload;
procedure SetMatrix(var dest: TMatrix; const src: TAffineMatrix); overload;

procedure SetMatrixRow(var dest: TMatrix; rowNb: Integer;
  const aRow: TVector); overload;

// : Creates scale matrix
function CreateScaleMatrix(const v: TAffineVector): TMatrix; overload;
// : Creates scale matrix
function CreateScaleMatrix(const v: TVector): TMatrix; overload;
// : Creates translation matrix
function CreateTranslationMatrix(const v: TAffineVector): TMatrix; overload;
// : Creates translation matrix
function CreateTranslationMatrix(const v: TVector): TMatrix; overload;
{ : Creates a scale+translation matrix.<p>
  Scale is applied BEFORE applying offset }
function CreateScaleAndTranslationMatrix(const scale, offset: TVector)
  : TMatrix; overload;
// : Creates matrix for rotation about x-axis (angle in rad)
function CreateRotationMatrixX(const sine, cosine: Single): TMatrix; overload;
function CreateRotationMatrixX(const angle: Single): TMatrix; overload;
// : Creates matrix for rotation about y-axis (angle in rad)
function CreateRotationMatrixY(const sine, cosine: Single): TMatrix; overload;
function CreateRotationMatrixY(const angle: Single): TMatrix; overload;
// : Creates matrix for rotation about z-axis (angle in rad)
function CreateRotationMatrixZ(const sine, cosine: Single): TMatrix; overload;
function CreateRotationMatrixZ(const angle: Single): TMatrix; overload;
// : Creates a rotation matrix along the given Axis by the given Angle in radians.
function CreateRotationMatrix(const anAxis: TAffineVector; angle: Single)
  : TMatrix; overload;
function CreateRotationMatrix(const anAxis: TVector; angle: Single)
  : TMatrix; overload;
// : Creates a rotation matrix along the given Axis by the given Angle in radians.
function CreateAffineRotationMatrix(const anAxis: TAffineVector; angle: Single)
  : TAffineMatrix;

// : Multiplies two 3x3 matrices
function MatrixMultiply(const m1, m2: TAffineMatrix): TAffineMatrix; overload;
// : Multiplies two 4x4 matrices
function MatrixMultiply(const m1, m2: TMatrix): TMatrix; overload;
// : Multiplies M1 by M2 and places result in MResult
procedure MatrixMultiply(const m1, m2: TMatrix; var MResult: TMatrix); overload;

// : Transforms a homogeneous vector by multiplying it with a matrix
function VectorTransform(const v: TVector; const M: TMatrix): TVector; overload;
// : Transforms a homogeneous vector by multiplying it with a matrix
function VectorTransform(const v: TVector; const M: TAffineMatrix)
  : TVector; overload;
// : Transforms an affine vector by multiplying it with a matrix
function VectorTransform(const v: TAffineVector; const M: TMatrix)
  : TAffineVector; overload;
// : Transforms an affine vector by multiplying it with a matrix
function VectorTransform(const v: TAffineVector; const M: TAffineMatrix)
  : TAffineVector; overload;

// : Determinant of a 3x3 matrix
function MatrixDeterminant(const M: TAffineMatrix): Single; overload;
// : Determinant of a 4x4 matrix
function MatrixDeterminant(const M: TMatrix): Single; overload;

{ : Adjoint of a 4x4 matrix.<p>
  used in the computation of the inverse of a 4x4 matrix }
procedure AdjointMatrix(var M: TMatrix); overload;
{ : Adjoint of a 3x3 matrix.<p>
  used in the computation of the inverse of a 3x3 matrix }
procedure AdjointMatrix(var M: TAffineMatrix); overload;

// : Multiplies all elements of a 3x3 matrix with a factor
procedure ScaleMatrix(var M: TAffineMatrix; const factor: Single); overload;
// : Multiplies all elements of a 4x4 matrix with a factor
procedure ScaleMatrix(var M: TMatrix; const factor: Single); overload;

// : Adds the translation vector into the matrix
procedure TranslateMatrix(var M: TMatrix; const v: TAffineVector); overload;
procedure TranslateMatrix(var M: TMatrix; const v: TVector); overload;

{ : Normalize the matrix and remove the translation component.<p>
  The resulting matrix is an orthonormal matrix (Y direction preserved, then Z) }
procedure NormalizeMatrix(var M: TMatrix);

// : Computes transpose of 3x3 matrix
procedure TransposeMatrix(var M: TAffineMatrix); overload;
// : Computes transpose of 4x4 matrix
procedure TransposeMatrix(var M: TMatrix); overload;

// : Finds the inverse of a 4x4 matrix
procedure InvertMatrix(var M: TMatrix); overload;
function MatrixInvert(const M: TMatrix): TMatrix; overload;

// : Finds the inverse of a 3x3 matrix;
procedure InvertMatrix(var M: TAffineMatrix); overload;
function MatrixInvert(const M: TAffineMatrix): TAffineMatrix; overload;

{ : Finds the inverse of an angle preserving matrix.<p>
  Angle preserving matrices can combine translation, rotation and isotropic
  scaling, other matrices won't be properly inverted by this function. }
function AnglePreservingMatrixInvert(const mat: TMatrix): TMatrix;

{ : Decompose a non-degenerated 4x4 transformation matrix into the sequence of transformations that produced it.<p>
  Modified by ml then eg, original Author: Spencer W. Thomas, University of Michigan<p>
  The coefficient of each transformation is returned in the corresponding
  element of the vector Tran.<p>
  Returns true upon success, false if the matrix is singular. }
function MatrixDecompose(const M: TMatrix; var Tran: TTransformations): Boolean;

function CreateLookAtMatrix(const eye, center, normUp: TVector): TMatrix;
function CreateMatrixFromFrustum(const Left, Right, Bottom, Top, ZNearValue,
  ZFarValue: Single): TMatrix;
function CreatePerspectiveMatrix(FOV, Aspect, ZNearValue,
  ZFarValue: Single): TMatrix;
function CreateOrthoMatrix(Left, Right, Bottom, Top, ZNear,
  ZFar: Single): TMatrix;
function CreatePerspectiveMatrixSafe(FOV, Aspect, ZNearValue,
  ZFarValue: Single): TMatrix;
function CreatePickMatrix(x, y, deltax, deltay: Single;
  const viewport: TVector4i): TMatrix;
function Project(objectVector: TVector; const ViewProjMatrix: TMatrix;
  const viewport: TVector4i; out WindowVector: TVector): Boolean;
function UnProject(WindowVector: TVector; ViewProjMatrix: TMatrix;
  const viewport: TVector4i; out objectVector: TVector): Boolean;
// ------------------------------------------------------------------------------
// Plane functions
// ------------------------------------------------------------------------------

// : Computes the parameters of a plane defined by three points.
function PlaneMake(const p1, p2, p3: TAffineVector): THmgPlane; overload;
function PlaneMake(const p1, p2, p3: TVector): THmgPlane; overload;
// : Computes the parameters of a plane defined by a point and a normal.
function PlaneMake(const point, normal: TAffineVector): THmgPlane; overload;
function PlaneMake(const point, normal: TVector): THmgPlane; overload;
// : Converts from single to double representation
procedure SetPlane(var dest: TDoubleHmgPlane; const src: THmgPlane);

// : Normalize a plane so that point evaluation = plane distance. }
procedure NormalizePlane(var plane: THmgPlane);

{ : Calculates the cross-product between the plane normal and plane to point vector.<p>
  This functions gives an hint as to were the point is, if the point is in the
  half-space pointed by the vector, result is positive.<p>
  This function performs an homogeneous space dot-product. }
function PlaneEvaluatePoint(const plane: THmgPlane; const point: TAffineVector)
  : Single; overload;
function PlaneEvaluatePoint(const plane: THmgPlane; const point: TVector)
  : Single; overload;

{ : Calculate the normal of a plane defined by three points. }
function CalcPlaneNormal(const p1, p2, p3: TAffineVector)
  : TAffineVector; overload;
procedure CalcPlaneNormal(const p1, p2, p3: TAffineVector;
  var vr: TAffineVector); overload;
procedure CalcPlaneNormal(const p1, p2, p3: TVector;
  var vr: TAffineVector); overload;

{ : Returns true if point is in the half-space defined by a plane with normal.<p>
  The plane itself is not considered to be in the tested halfspace. }
function PointIsInHalfSpace(const point, planePoint, planeNormal: TVector)
  : Boolean; overload;
function PointIsInHalfSpace(const point, planePoint, planeNormal: TAffineVector)
  : Boolean; overload;

{ : Computes algebraic distance between point and plane.<p>
  Value will be positive if the point is in the halfspace pointed by the normal,
  negative on the other side. }
function PointPlaneDistance(const point, planePoint, planeNormal: TVector)
  : Single; overload;
function PointPlaneDistance(const point, planePoint, planeNormal: TAffineVector)
  : Single; overload;

{ : Computes closest point on a segment (a segment is a limited line). }
function PointSegmentClosestPoint(const point, segmentStart,
  segmentStop: TAffineVector): TAffineVector;
{ : Computes algebraic distance between segment and line (a segment is a limited line). }
function PointSegmentDistance(const point, segmentStart,
  segmentStop: TAffineVector): Single;
{ : Computes closest point on a line. }
function PointLineClosestPoint(const point, linePoint, lineDirection
  : TAffineVector): TAffineVector;
{ : Computes algebraic distance between point and line. }
function PointLineDistance(const point, linePoint, lineDirection
  : TAffineVector): Single;

{ : Computes the closest points (2) given two segments. }
procedure SegmentSegmentClosestPoint(const S0Start, S0Stop, S1Start,
  S1Stop: TAffineVector; var Segment0Closest, Segment1Closest: TAffineVector);

{ : Computes the closest distance between two segments. }
function SegmentSegmentDistance(const S0Start, S0Stop, S1Start,
  S1Stop: TAffineVector): Single;

// ------------------------------------------------------------------------------
// Quaternion functions
// ------------------------------------------------------------------------------

type
  TEulerOrder = (eulXYZ, eulXZY, eulYXZ, eulYZX, eulZXY, eulZYX);

  // : Creates a quaternion from the given values
function QuaternionMake(const Imag: array of Single; Real: Single): TQuaternion;
// : Returns the conjugate of a quaternion
function QuaternionConjugate(const Q: TQuaternion): TQuaternion;
// : Returns the magnitude of the quaternion
function QuaternionMagnitude(const Q: TQuaternion): Single;
// : Normalizes the given quaternion
procedure NormalizeQuaternion(var Q: TQuaternion);

// : Constructs a unit quaternion from two points on unit sphere
function QuaternionFromPoints(const V1, V2: TAffineVector): TQuaternion;
// : Converts a unit quaternion into two points on a unit sphere
procedure QuaternionToPoints(const Q: TQuaternion;
  var ArcFrom, ArcTo: TAffineVector);
// : Constructs a unit quaternion from a rotation matrix
function QuaternionFromMatrix(const mat: TMatrix): TQuaternion;
{ : Constructs a rotation matrix from (possibly non-unit) quaternion.<p>
  Assumes matrix is used to multiply column vector on the left:<br>
  vnew = mat vold.<p>
  Works correctly for right-handed coordinate system and right-handed rotations. }
function QuaternionToMatrix(quat: TQuaternion): TMatrix;
{ : Constructs an affine rotation matrix from (possibly non-unit) quaternion.<p> }
function QuaternionToAffineMatrix(quat: TQuaternion): TAffineMatrix;
// : Constructs quaternion from angle (in deg) and axis
function QuaternionFromAngleAxis(const angle: Single; const axis: TAffineVector)
  : TQuaternion;
// : Constructs quaternion from Euler angles
function QuaternionFromRollPitchYaw(const r, p, y: Single): TQuaternion;
// : Constructs quaternion from Euler angles in arbitrary order (angles in degrees)
function QuaternionFromEuler(const x, y, z: Single; eulerOrder: TEulerOrder)
  : TQuaternion;

{ : Returns quaternion product qL * qR.<p>
  Note: order is important!<p>
  To combine rotations, use the product QuaternionMuliply(qSecond, qFirst),
  which gives the effect of rotating by qFirst then qSecond. }
function QuaternionMultiply(const qL, qR: TQuaternion): TQuaternion;

{ : Spherical linear interpolation of unit quaternions with spins.<p>
  QStart, QEnd - start and end unit quaternions<br>
  t            - interpolation parameter (0 to 1)<br>
  Spin         - number of extra spin rotations to involve<br> }
function QuaternionSlerp(const QStart, QEnd: TQuaternion; Spin: Integer;
  T: Single): TQuaternion; overload;
function QuaternionSlerp(const source, dest: TQuaternion; const T: Single)
  : TQuaternion; overload;

// ------------------------------------------------------------------------------
// Logarithmic and exponential functions
// ------------------------------------------------------------------------------

{ : Return ln(1 + X),  accurate for X near 0. }
function LnXP1(x: Extended): Extended;
{ : Log base 10 of X }
function Log10(x: Extended): Extended;
{ : Log base 2 of X }
function Log2(x: Extended): Extended; overload;
{ : Log base 2 of X }
function Log2(x: Single): Single; overload;
{ : Log base N of X }
function LogN(Base, x: Extended): Extended;
{ : Raise base to an integer. }
function IntPower(Base: Extended; Exponent: Integer): Extended;
{ : Raise base to any power.<p>
  For fractional exponents, or |exponents| > MaxInt, base must be > 0. }
function Power(const Base, Exponent: Single): Single; overload;
{ : Raise base to an integer. }
function Power(Base: Single; Exponent: Integer): Single; overload;

// ------------------------------------------------------------------------------
// Trigonometric functions
// ------------------------------------------------------------------------------

function DegToRad(const Degrees: Extended): Extended; overload;
function DegToRad(const Degrees: Single): Single; overload;
function RadToDeg(const Radians: Extended): Extended; overload;
function RadToDeg(const Radians: Single): Single; overload;

// : Normalize to an angle in the [-PI; +PI] range
function NormalizeAngle(angle: Single): Single;
// : Normalize to an angle in the [-180; 180] range
function NormalizeDegAngle(angle: Single): Single;

// : Calculates sine and cosine from the given angle Theta
procedure SinCos(const Theta: Extended; out Sin, Cos: Extended); overload;
// : Calculates sine and cosine from the given angle Theta
procedure SinCos(const Theta: Double; out Sin, Cos: Double); overload;
// : Calculates sine and cosine from the given angle Theta
procedure SinCos(const Theta: Single; out Sin, Cos: Single); overload;
{ : Calculates sine and cosine from the given angle Theta and Radius.<p>
  sin and cos values calculated from theta are multiplicated by radius. }
procedure SinCos(const Theta, radius: Double; out Sin, Cos: Extended); overload;
{ : Calculates sine and cosine from the given angle Theta and Radius.<p>
  sin and cos values calculated from theta are multiplicated by radius. }
procedure SinCos(const Theta, radius: Double; out Sin, Cos: Double); overload;
{ : Calculates sine and cosine from the given angle Theta and Radius.<p>
  sin and cos values calculated from theta are multiplicated by radius. }
procedure SinCos(const Theta, radius: Single; out Sin, Cos: Single); overload;

{ : Fills up the two given dynamic arrays with sin cos values.<p>
  start and stop angles must be given in degrees, the number of steps is
  determined by the length of the given arrays. }
procedure PrepareSinCosCache(var S, c: array of Single;
  startAngle, stopAngle: Single);

function ArcCos(const x: Extended): Extended; overload;
function ArcCos(const x: Single): Single; overload;
function ArcSin(const x: Extended): Extended; overload;
function ArcSin(const x: Single): Single; overload;
function ArcTan2(const y, x: Extended): Extended; overload;
function ArcTan2(const y, x: Single): Single; overload;
{ : Fast ArcTan2 approximation, about 0.07 rads accuracy. }
function FastArcTan2(y, x: Single): Single;
function Tan(const x: Extended): Extended; overload;
function Tan(const x: Single): Single; overload;
function CoTan(const x: Extended): Extended; overload;
function CoTan(const x: Single): Single; overload;

// ------------------------------------------------------------------------------
// Hyperbolic Trigonometric functions
// ------------------------------------------------------------------------------

function Sinh(const x: Single): Single; overload;
function Sinh(const x: Double): Double; overload;
function Cosh(const x: Single): Single; overload;
function Cosh(const x: Double): Double; overload;

// ------------------------------------------------------------------------------
// Miscellanious math functions
// ------------------------------------------------------------------------------

{ : Computes 1/Sqrt(v).<p> }
function RSqrt(v: Single): Single;
{ : Computes 1/Sqrt(Sqr(x)+Sqr(y)). }
function RLength(x, y: Single): Single;
{ : Computes an integer sqrt approximation.<p> }
function ISqrt(i: Integer): Integer;
{ : Computes an integer length Result:=Sqrt(x*x+y*y). }
function ILength(x, y: Integer): Integer; overload;
function ILength(x, y, z: Integer): Integer; overload;

{$IFNDEF GEOMETRY_NO_ASM}
{ : Computes Exp(ST(0)) and leaves result on ST(0) }
procedure RegisterBasedExp;
{$ENDIF}
{ : Generates a random point on the unit sphere.<p>
  Point repartition is correctly isotropic with no privilegied direction. }
procedure RandomPointOnSphere(var p: TAffineVector);

{ : Rounds the floating point value to the closest integer.<p>
  Behaves like Round but returns a floating point value like Int. }
function RoundInt(v: Single): Single; overload;
function RoundInt(v: Extended): Extended; overload;

{$IFNDEF GEOMETRY_NO_ASM}
function Trunc(v: Single): Integer; overload;
function Trunc64(v: Extended): Int64; overload;
function Int(v: Single): Single; overload;
function Int(v: Extended): Extended; overload;
function Frac(v: Single): Single; overload;
function Frac(v: Extended): Extended; overload;
function Round(v: Single): Integer; overload;
function Round64(v: Single): Int64; overload;
function Round64(v: Extended): Int64; overload;
{$ELSE}
function Trunc(x: Extended): Int64;
function Round(x: Extended): Int64;
function Frac(x: Extended): Extended;
{$ENDIF}
function Ceil(v: Single): Integer; overload;
function Ceil64(v: Extended): Int64; overload;
function Floor(v: Single): Integer; overload;
function Floor64(v: Extended): Int64; overload;

{ : Multiples i by s and returns the rounded result.<p> }
function ScaleAndRound(i: Integer; var S: Single): Integer;

{ : Returns the sign of the x value using the (-1, 0, +1) convention }
function Sign(x: Single): Integer;

{ : Returns True if x is in [a; b] }
function IsInRange(const x, a, b: Single): Boolean; overload;
function IsInRange(const x, a, b: Double): Boolean; overload;

{ : Returns True if p is in the cube defined by d. }
function IsInCube(const p, d: TAffineVector): Boolean; overload;
function IsInCube(const p, d: TVector): Boolean; overload;

{ : Returns the minimum value of the array. }
function MinFloat(values: PSingleArray; nbItems: Integer): Single; overload;
function MinFloat(values: PDoubleArray; nbItems: Integer): Double; overload;
function MinFloat(values: PExtendedArray; nbItems: Integer): Extended; overload;
{ : Returns the minimum of given values. }
function MinFloat(const V1, V2: Single): Single; overload;
function MinFloat(const v: array of Single): Single; overload;
function MinFloat(const V1, V2: Double): Double; overload;
function MinFloat(const V1, V2: Extended): Extended; overload;
function MinFloat(const V1, V2, V3: Single): Single; overload;
function MinFloat(const V1, V2, V3: Double): Double; overload;
function MinFloat(const V1, V2, V3: Extended): Extended; overload;
{ : Returns the maximum value of the array. }
function MaxFloat(values: PSingleArray; nbItems: Integer): Single; overload;
function MaxFloat(values: PDoubleArray; nbItems: Integer): Double; overload;
function MaxFloat(values: PExtendedArray; nbItems: Integer): Extended; overload;
function MaxFloat(const v: array of Single): Single; overload;
{ : Returns the maximum of given values. }
function MaxFloat(const V1, V2: Single): Single; overload;
function MaxFloat(const V1, V2: Double): Double; overload;
function MaxFloat(const V1, V2: Extended): Extended; overload;
function MaxFloat(const V1, V2, V3: Single): Single; overload;
function MaxFloat(const V1, V2, V3: Double): Double; overload;
function MaxFloat(const V1, V2, V3: Extended): Extended; overload;

function MinInteger(const V1, V2: Integer): Integer; overload;
function MinInteger(const V1, V2: Cardinal): Cardinal; overload;
function MinInteger(const V1, V2, V3: Integer): Integer; overload;
function MinInteger(const V1, V2, V3: Cardinal): Cardinal; overload;

function MaxInteger(const V1, V2: Integer): Integer; overload;
function MaxInteger(const V1, V2: Cardinal): Cardinal; overload;
function MaxInteger(const V1, V2, V3: Integer): Integer; overload;
function MaxInteger(const V1, V2, V3: Cardinal): Cardinal; overload;

{ : Computes the triangle's area. }
function TriangleArea(const p1, p2, p3: TAffineVector): Single; overload;
{ : Computes the polygons's area.<p>
  Points must be coplanar. Polygon needs not be convex. }
function PolygonArea(const p: PAffineVectorArray; nSides: Integer)
  : Single; overload;
{ : Computes a 2D triangle's signed area.<p>
  Only X and Y coordinates are used, Z is ignored. }
function TriangleSignedArea(const p1, p2, p3: TAffineVector): Single; overload;
{ : Computes a 2D polygon's signed area.<p>
  Only X and Y coordinates are used, Z is ignored. Polygon needs not be convex. }
function PolygonSignedArea(const p: PAffineVectorArray; nSides: Integer)
  : Single; overload;

{ : Multiplies values in the array by factor.<p>
  This function is especially efficient for large arrays, it is not recommended
  for arrays that have less than 10 items.<br>
  Expected performance is 4 to 5 times that of a Deliph-compiled loop on AMD
  CPUs, and 2 to 3 when 3DNow! isn't available. }
procedure ScaleFloatArray(values: PSingleArray; nb: Integer;
  var factor: Single); overload;
procedure ScaleFloatArray(var values: TSingleArray; factor: Single); overload;

{ : Adds delta to values in the array.<p>
  Array size must be a multiple of four. }
procedure OffsetFloatArray(values: PSingleArray; nb: Integer;
  var delta: Single); overload;
procedure OffsetFloatArray(var values: array of Single; delta: Single);
  overload;
procedure OffsetFloatArray(valuesDest, valuesDelta: PSingleArray;
  nb: Integer); overload;

{ : Returns the max of the X, Y and Z components of a vector (W is ignored). }
function MaxXYZComponent(const v: TVector): Single; overload;
function MaxXYZComponent(const v: TAffineVector): Single; overload;
{ : Returns the min of the X, Y and Z components of a vector (W is ignored). }
function MinXYZComponent(const v: TVector): Single; overload;
function MinXYZComponent(const v: TAffineVector): Single; overload;
{ : Returns the max of the Abs(X), Abs(Y) and Abs(Z) components of a vector (W is ignored). }
function MaxAbsXYZComponent(v: TVector): Single;
{ : Returns the min of the Abs(X), Abs(Y) and Abs(Z) components of a vector (W is ignored). }
function MinAbsXYZComponent(v: TVector): Single;
{ : Replace components of v with the max of v or v1 component.<p>
  Maximum is computed per component. }
procedure MaxVector(var v: TVector; const V1: TVector); overload;
procedure MaxVector(var v: TAffineVector; const V1: TAffineVector); overload;
{ : Replace components of v with the min of v or v1 component.<p>
  Minimum is computed per component. }
procedure MinVector(var v: TVector; const V1: TVector); overload;
procedure MinVector(var v: TAffineVector; const V1: TAffineVector); overload;

{ : Sorts given array in ascending order.<p>
  NOTE : current implementation is a slow bubble sort... }
procedure SortArrayAscending(var a: array of Extended);

{ : Clamps aValue in the aMin-aMax interval.<p> }
function ClampValue(const aValue, aMin, aMax: Single): Single; overload;
{ : Clamps aValue in the aMin-INF interval.<p> }
function ClampValue(const aValue, aMin: Single): Single; overload;

{ : Returns the detected optimization mode.<p>
  Returned values is either 'FPU', '3DNow!' or 'SSE'. }
function GeometryOptimizationMode: String;

{ : Begins a FPU-only section.<p>
  You can use a FPU-only section to force use of FPU versions of the math
  functions, though typically slower than their SIMD counterparts, they have
  a higher precision (80 bits internally) that may be required in some cases.<p>
  Each BeginFPUOnlySection call must be balanced by a EndFPUOnlySection (calls
  can be nested). }
procedure BeginFPUOnlySection;
{ : Ends a FPU-only section.<p>
  See BeginFPUOnlySection. }
procedure EndFPUOnlySection;

// --------------------- Unstandardized functions after these lines
// --------------------- Unstandardized functions after these lines
// --------------------- Unstandardized functions after these lines
// --------------------- Unstandardized functions after these lines
// --------------------- Unstandardized functions after these lines

// mixed functions

{ : Turn a triplet of rotations about x, y, and z (in that order) into an equivalent rotation around a single axis (all in radians).<p> }
function ConvertRotation(const Angles: TAffineVector): TVector;

// miscellaneous functions

function MakeAffineDblVector(var v: array of Double): TAffineDblVector;
function MakeDblVector(var v: array of Double): THomogeneousDblVector;
function VectorAffineDblToFlt(const v: TAffineDblVector): TAffineVector;
function VectorDblToFlt(const v: THomogeneousDblVector): THomogeneousVector;
function VectorAffineFltToDbl(const v: TAffineVector): TAffineDblVector;
function VectorFltToDbl(const v: TVector): THomogeneousDblVector;

function PointInPolygon(var xp, yp: array of Single; x, y: Single): Boolean;

procedure DivMod(Dividend: Integer; Divisor: Word; var result, Remainder: Word);

// coordinate system manipulation functions

// : Rotates the given coordinate system (represented by the matrix) around its Y-axis
function Turn(const Matrix: TMatrix; angle: Single): TMatrix; overload;
// : Rotates the given coordinate system (represented by the matrix) around MasterUp
function Turn(const Matrix: TMatrix; const MasterUp: TAffineVector;
  angle: Single): TMatrix; overload;
// : Rotates the given coordinate system (represented by the matrix) around its X-axis
function Pitch(const Matrix: TMatrix; angle: Single): TMatrix; overload;
// : Rotates the given coordinate system (represented by the matrix) around MasterRight
function Pitch(const Matrix: TMatrix; const MasterRight: TAffineVector;
  angle: Single): TMatrix; overload;
// : Rotates the given coordinate system (represented by the matrix) around its Z-axis
function Roll(const Matrix: TMatrix; angle: Single): TMatrix; overload;
// : Rotates the given coordinate system (represented by the matrix) around MasterDirection
function Roll(const Matrix: TMatrix; const MasterDirection: TAffineVector;
  angle: Single): TMatrix; overload;

// intersection functions

{ : Compute the intersection point "res" of a line with a plane.<p>
  Return value:<ul>
  <li>0 : no intersection, line parallel to plane
  <li>1 : res is valid
  <li>-1 : line is inside plane
  </ul><br>
  Adapted from:<br>
  E.Hartmann, Computerunterstützte Darstellende Geometrie, B.G. Teubner Stuttgart 1988 }
function IntersectLinePlane(const point, direction: TVector;
  const plane: THmgPlane; intersectPoint: PVector = nil): Integer; overload;

{ : Compute intersection between a triangle and a box.<p>
  Returns True if an intersection was found. }
function IntersectTriangleBox(const p1, p2, p3, aMinExtent,
  aMaxExtent: TAffineVector): Boolean;

{ : Compute intersection between a Sphere and a box.<p>
  Up, Direction and Right must be normalized!
  Use CubDepht, CubeHeight and CubeWidth to scale TGLCube. }
function IntersectSphereBox(const SpherePos: TVector;
  const SphereRadius: Single; const BoxMatrix: TMatrix;
  const BoxScale: TAffineVector; intersectPoint: PAffineVector = nil;
  normal: PAffineVector = nil; depth: PSingle = nil): Boolean;

{ : Compute intersection between a ray and a plane.<p>
  Returns True if an intersection was found, the intersection point is placed
  in intersectPoint is the reference is not nil. }
function RayCastPlaneIntersect(const rayStart, rayVector: TVector;
  const planePoint, planeNormal: TVector; intersectPoint: PVector = nil)
  : Boolean; overload;
function RayCastPlaneXZIntersect(const rayStart, rayVector: TVector;
  const planeY: Single; intersectPoint: PVector = nil): Boolean; overload;

{ : Compute intersection between a ray and a triangle. }
function RayCastTriangleIntersect(const rayStart, rayVector: TVector;
  const p1, p2, p3: TAffineVector; intersectPoint: PVector = nil;
  intersectNormal: PVector = nil): Boolean; overload;
{ : Compute the min distance a ray will pass to a point.<p> }
function RayCastMinDistToPoint(const rayStart, rayVector: TVector;
  const point: TVector): Single;
{ : Determines if a ray will intersect with a given sphere.<p> }
function RayCastIntersectsSphere(const rayStart, rayVector: TVector;
  const sphereCenter: TVector; const SphereRadius: Single): Boolean; overload;
{ : Calculates the intersections between a sphere and a ray.<p>
  Returns 0 if no intersection is found (i1 and i2 untouched), 1 if one
  intersection was found (i1 defined, i2 untouched), and 2 is two intersections
  were found (i1 and i2 defined). }
function RayCastSphereIntersect(const rayStart, rayVector: TVector;
  const sphereCenter: TVector; const SphereRadius: Single; var i1, i2: TVector)
  : Integer; overload;
{ : Compute intersection between a ray and a box.<p>
  Returns True if an intersection was found, the intersection point is
  placed in intersectPoint if the reference is not nil. }
function RayCastBoxIntersect(const rayStart, rayVector, aMinExtent,
  aMaxExtent: TAffineVector; intersectPoint: PAffineVector = nil): Boolean;

{ : Computes the visible radius of a sphere in a perspective projection.<p>
  This radius can be used for occlusion culling (cone extrusion) or 2D
  intersection testing. }
function SphereVisibleRadius(distance, radius: Single): Single;

{ : Extracts a TFrustum for combined modelview and projection matrices. }
function ExtractFrustumFromModelViewProjection(const modelViewProj: TMatrix)
  : TFrustum;

// : Determines if volume is clipped or not
function IsVolumeClipped(const objPos: TAffineVector; const objRadius: Single;
  const Frustum: TFrustum): Boolean; overload;
function IsVolumeClipped(const objPos: TVector; const objRadius: Single;
  const Frustum: TFrustum): Boolean; overload;
function IsVolumeClipped(const min, max: TAffineVector; const Frustum: TFrustum)
  : Boolean; overload;

// misc funcs

{ : Creates a parallel projection matrix.<p>
  Transformed points will projected on the plane along the specified direction. }
function MakeParallelProjectionMatrix(const plane: THmgPlane;
  const dir: TVector): TMatrix;

{ : Creates a shadow projection matrix.<p>
  Shadows will be projected onto the plane defined by planePoint and planeNormal,
  from lightPos. }
function MakeShadowMatrix(const planePoint, planeNormal,
  lightPos: TVector): TMatrix;

{ : Builds a reflection matrix for the given plane.<p>
  Reflection matrix allow implementing planar reflectors in OpenGL (mirrors). }
function MakeReflectionMatrix(const planePoint, planeNormal
  : TAffineVector): TMatrix;

{ : Packs an homogeneous rotation matrix to 6 bytes.<p>
  The 6:64 (or 6:36) compression ratio is achieved by computing the quaternion
  associated to the matrix and storing its Imaginary components at 16 bits
  precision each.<br>
  Deviation is typically below 0.01% and around 0.1% in worst case situations.<p>
  Note: quaternion conversion is faster and more robust than an angle decomposition. }
function PackRotationMatrix(const mat: TMatrix): TPackedRotationMatrix;
{ : Restores a packed rotation matrix.<p>
  See PackRotationMatrix. }
function UnPackRotationMatrix(const packedMatrix
  : TPackedRotationMatrix): TMatrix;

{ : Calculates the barycentric coordinates for the point p on the triangle
  defined by the vertices v1, v2 and v3. That is, solves
  p = u * v1 + v * v2 + (1-u-v) * v3
  for u,v.
  Returns true if the point is inside the triangle, false otherwise.<p>
  NOTE: This function assumes that the point lies on the plane defined by the triangle.
  If this is not the case, the function will not work correctly! }
function BarycentricCoordinates(const V1, V2, V3, p: TAffineVector;
  var u, v: Single): Boolean;

const
  cPI: Single = 3.141592654;
  cPIdiv180: Single = 0.017453292;
  c180divPI: Single = 57.29577951;
  c2PI: Single = 6.283185307;
  cPIdiv2: Single = 1.570796326;
  cPIdiv4: Single = 0.785398163;
  c3PIdiv4: Single = 2.35619449;
  cInv2PI: Single = 1 / 6.283185307;
  cInv360: Single = 1 / 360;
  c180: Single = 180;
  c360: Single = 360;
  cOneHalf: Single = 0.5;
  cLn10: Single = 2.302585093;

  // Ranges of the IEEE floating point types, including denormals
  // with System.Math.pas compatible name
  MinSingle = 1.5E-45;
  MaxSingle = 3.4E+38;
  MinDouble = 5.0E-324;
  MaxDouble = 1.7E+308;
  MinExtended = 3.4E-4932;
  MaxExtended = 1.1E+4932;
  MinComp = -9.223372036854775807E+18;
  MaxComp = 9.223372036854775807E+18;

var
  // this var is adjusted during "initialization", current values are
  // + 0 : use standard optimized FPU code
  // + 1 : use 3DNow! optimized code (requires K6-2/3 CPU)
  // + 2 : use Intel SSE code (Pentium III, NOT IMPLEMENTED YET !)
  vSIMD: Byte = 0;

  // --------------------------------------------------------------
  // --------------------------------------------------------------
  // --------------------------------------------------------------
implementation

// --------------------------------------------------------------
// --------------------------------------------------------------
// --------------------------------------------------------------

uses System.SysUtils{$IFDEF GEOMETRY_NO_ASM}, System.Math{$ENDIF};

const
{$IFNDEF GEOMETRY_NO_ASM}
  // FPU status flags (high order byte)
  cwChop: Word = $1F3F;
{$ENDIF}
  // to be used as descriptive indices
  x = 0;
  y = 1;
  z = 2;
  w = 3;

  cZero: Single = 0.0;
  cOne: Single = 1.0;
  cOneDotFive: Single = 0.5;

  // OptimizationMode
  //
function GeometryOptimizationMode: String;
begin
  case vSIMD of
    0:
      result := 'FPU';
    1:
      result := '3DNow!';
    2:
      result := 'SSE';
  else
    result := '*ERR*';
  end;
end;

// BeginFPUOnlySection
//
var
  vOldSIMD: Byte;
  vFPUOnlySectionCounter: Integer;

procedure BeginFPUOnlySection;
begin
  if vFPUOnlySectionCounter = 0 then
    vOldSIMD := vSIMD;
  Inc(vFPUOnlySectionCounter);
  vSIMD := 0;
end;

// EndFPUOnlySection
//
procedure EndFPUOnlySection;
begin
  Dec(vFPUOnlySectionCounter);
  Assert(vFPUOnlySectionCounter >= 0);
  if vFPUOnlySectionCounter = 0 then
    vSIMD := vOldSIMD;
end;

// ------------------------------------------------------------------------------
// ----------------- vector functions -------------------------------------------
// ------------------------------------------------------------------------------

// TexPointMake
//
function TexPointMake(const S, T: Single): TTexPoint;
begin
  result.S := S;
  result.T := T;
end;

// AffineVectorMake
//
function AffineVectorMake(const x, y, z: Single): TAffineVector; overload;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
end;

// AffineVectorMake
//
function AffineVectorMake(const v: TVector): TAffineVector;
begin
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
end;

// SetAffineVector
//
procedure SetAffineVector(out v: TAffineVector; const x, y, z: Single);
  overload;
begin
  v[0] := x;
  v[1] := y;
  v[2] := z;
end;

// SetVector (affine)
//
procedure SetVector(out v: TAffineVector; const x, y, z: Single);
begin
  v[0] := x;
  v[1] := y;
  v[2] := z;
end;

// SetVector (affine-hmg)
//
procedure SetVector(out v: TAffineVector; const vSrc: TVector);
begin
  v[0] := vSrc[0];
  v[1] := vSrc[1];
  v[2] := vSrc[2];
end;

// SetVector (affine-affine)
//
procedure SetVector(out v: TAffineVector; const vSrc: TAffineVector);
begin
  v[0] := vSrc[0];
  v[1] := vSrc[1];
  v[2] := vSrc[2];
end;

// SetVector (affine double - affine single)
//
procedure SetVector(out v: TAffineDblVector; const vSrc: TAffineVector);
begin
  v[0] := vSrc[0];
  v[1] := vSrc[1];
  v[2] := vSrc[2];
end;

// SetVector (affine double - hmg single)
//
procedure SetVector(out v: TAffineDblVector; const vSrc: TVector);
begin
  v[0] := vSrc[0];
  v[1] := vSrc[1];
  v[2] := vSrc[2];
end;

// VectorMake
//
function VectorMake(const v: TAffineVector; w: Single = 0): TVector;
begin
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
  result[3] := w;
end;

// VectorMake
//
function VectorMake(const x, y, z: Single; w: Single = 0): TVector;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
  result[3] := w;
end;

// PointMake (xyz)
//
function PointMake(const x, y, z: Single): TVector; overload;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
  result[3] := 1;
end;

// PointMake (affine)
//
function PointMake(const v: TAffineVector): TVector; overload;
begin
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
  result[3] := 1;
end;

// PointMake (hmg)
//
function PointMake(const v: TVector): TVector; overload;
begin
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
  result[3] := 1;
end;

// SetVector
//
procedure SetVector(out v: TVector; const x, y, z: Single; w: Single = 0);
begin
  v[0] := x;
  v[1] := y;
  v[2] := z;
  v[3] := w;
end;

// SetVector
//
procedure SetVector(out v: TVector; const av: TAffineVector; w: Single = 0);
begin
  v[0] := av[0];
  v[1] := av[1];
  v[2] := av[2];
  v[3] := w;
end;

// SetVector
//
procedure SetVector(out v: TVector; const vSrc: TVector);
begin
  // faster than memcpy, move or ':=' on the TVector...
  v[0] := vSrc[0];
  v[1] := vSrc[1];
  v[2] := vSrc[2];
  v[3] := vSrc[3];
end;

// MakePoint
//
procedure MakePoint(out v: TVector; const x, y, z: Single);
begin
  v[0] := x;
  v[1] := y;
  v[2] := z;
  v[3] := 1;
end;

// MakePoint
//
procedure MakePoint(out v: TVector; const av: TAffineVector);
begin
  v[0] := av[0];
  v[1] := av[1];
  v[2] := av[2];
  v[3] := 1;
end;

// MakePoint
//
procedure MakePoint(out v: TVector; const av: TVector);
begin
  v[0] := av[0];
  v[1] := av[1];
  v[2] := av[2];
  v[3] := 1;
end;

// MakeVector
//
procedure MakeVector(out v: TAffineVector; const x, y, z: Single); overload;
begin
  v[0] := x;
  v[1] := y;
  v[2] := z;
end;

// MakeVector
//
procedure MakeVector(out v: TVector; const x, y, z: Single);
begin
  v[0] := x;
  v[1] := y;
  v[2] := z;
  v[3] := 0;
end;

// MakeVector
//
procedure MakeVector(out v: TVector; const av: TAffineVector);
begin
  v[0] := av[0];
  v[1] := av[1];
  v[2] := av[2];
  v[3] := 0;
end;

// MakeVector
//
procedure MakeVector(out v: TVector; const av: TVector);
begin
  v[0] := av[0];
  v[1] := av[1];
  v[2] := av[2];
  v[3] := 0;
end;

// RstVector (affine)
//
procedure RstVector(var v: TAffineVector);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  xor   edx, edx
  mov   [eax], edx
  mov   [eax+4], edx
  mov   [eax+8], edx
  {$ELSE}
begin
  v[0] := 0;
  v[1] := 0;
  v[2] := 0;
{$ENDIF}
end;

// RstVector (hmg)
//
procedure RstVector(var v: TVector);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  xor   edx, edx
  mov   [eax], edx
  mov   [eax+4], edx
  mov   [eax+8], edx
  mov   [eax+12], edx
  {$ELSE}
begin
  v[0] := 0;
  v[1] := 0;
  v[2] := 0;
  v[3] := 0;
{$ENDIF}
end;

// VectorAdd (func, affine)
//
function VectorAdd(const V1, V2: TAffineVector): TAffineVector;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FADD DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FADD DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FADD DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  {$ELSE}
begin
  result[0] := V1[0] + V2[0];
  result[1] := V1[1] + V2[1];
  result[2] := V1[2] + V2[2];
{$ENDIF}
end;

// VectorAdd (proc, affine)
//
procedure VectorAdd(const V1, V2: TAffineVector;
  var vr: TAffineVector); overload;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FADD DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FADD DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FADD DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  {$ELSE}
begin
  vr[0] := V1[0] + V2[0];
  vr[1] := V1[1] + V2[1];
  vr[2] := V1[2] + V2[2];
{$ENDIF}
end;

// VectorAdd (proc, affine)
//
procedure VectorAdd(const V1, V2: TAffineVector; vr: PAffineVector); overload;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FADD DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FADD DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FADD DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  {$ELSE}
begin
  vr^[0] := V1[0] + V2[0];
  vr^[1] := V1[1] + V2[1];
  vr^[2] := V1[2] + V2[2];
{$ENDIF}
end;

// VectorAdd (hmg)
//
function VectorAdd(const V1, V2: TVector): TVector;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// movq  mm0, [eax]
  db $0F,$0F,$02,$9E       /// pfadd mm0, [edx]
  db $0F,$7F,$01           /// movq  [ecx], mm0
  db $0F,$6F,$48,$08       /// movq  mm1, [eax+8]
  db $0F,$0F,$4A,$08,$9E   /// pfadd mm1, [edx+8]
  db $0F,$7F,$49,$08       /// movq  [ecx+8], mm1
  db $0F,$0E               /// femms
  ret

@@FPU:
  FLD  DWORD PTR [EAX]
  FADD DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FADD DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FADD DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  FLD  DWORD PTR [EAX+12]
  FADD DWORD PTR [EDX+12]
  FSTP DWORD PTR [ECX+12]
  {$ELSE}
begin
  result[0] := V1[0] + V2[0];
  result[1] := V1[1] + V2[1];
  result[2] := V1[2] + V2[2];
  result[3] := V1[3] + V2[3];
{$ENDIF}
end;

// VectorAdd (hmg, proc)
//
procedure VectorAdd(const V1, V2: TVector; var vr: TVector);
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// movq  mm0, [eax]
  db $0F,$0F,$02,$9E       /// pfadd mm0, [edx]
  db $0F,$7F,$01           /// movq  [ecx], mm0
  db $0F,$6F,$48,$08       /// movq  mm1, [eax+8]
  db $0F,$0F,$4A,$08,$9E   /// pfadd mm1, [edx+8]
  db $0F,$7F,$49,$08       /// movq  [ecx+8], mm1
  db $0F,$0E               /// femms
  ret

@@FPU:
  FLD  DWORD PTR [EAX]
  FADD DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FADD DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FADD DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  FLD  DWORD PTR [EAX+12]
  FADD DWORD PTR [EDX+12]
  FSTP DWORD PTR [ECX+12]
  {$ELSE}
begin
  vr[0] := V1[0] + V2[0];
  vr[1] := V1[1] + V2[1];
  vr[2] := V1[2] + V2[2];
  vr[3] := V1[3] + V2[3];
{$ENDIF}
end;

// VectorAdd (affine, single)
//
function VectorAdd(const v: TAffineVector; const f: Single): TAffineVector;
begin
  result[0] := v[0] + f;
  result[1] := v[1] + f;
  result[2] := v[2] + f;
end;

// VectorAdd (hmg, single)
//
function VectorAdd(const v: TVector; const f: Single): TVector;
begin
  result[0] := v[0] + f;
  result[1] := v[1] + f;
  result[2] := v[2] + f;
  result[3] := v[3] + f;
end;

// PointAdd (hmg, W = 1)
//
function PointAdd(var V1: TVector; const V2: TVector): TVector;
begin
  result[0] := V1[0] + V2[0];
  result[1] := V1[1] + V2[1];
  result[2] := V1[2] + V2[2];
  result[3] := 1;
end;

// AddVector (affine)
//
procedure AddVector(var V1: TAffineVector; const V2: TAffineVector);
// EAX contains address of V1
// EDX contains address of V2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FADD DWORD PTR [EDX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EAX+4]
  FADD DWORD PTR [EDX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EAX+8]
  FADD DWORD PTR [EDX+8]
  FSTP DWORD PTR [EAX+8]
  {$ELSE}
begin
  V1[0] := V1[0] + V2[0];
  V1[1] := V1[1] + V2[1];
  V1[2] := V1[2] + V2[2];
{$ENDIF}
end;

// AddVector (affine)
//
procedure AddVector(var V1: TAffineVector; const V2: TVector);
// EAX contains address of V1
// EDX contains address of V2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FADD DWORD PTR [EDX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EAX+4]
  FADD DWORD PTR [EDX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EAX+8]
  FADD DWORD PTR [EDX+8]
  FSTP DWORD PTR [EAX+8]
  {$ELSE}
begin
  V1[0] := V1[0] + V2[0];
  V1[1] := V1[1] + V2[1];
  V1[2] := V1[2] + V2[2];
{$ENDIF}
end;

// AddVector (hmg)
//
procedure AddVector(var V1: TVector; const V2: TVector);
// EAX contains address of V1
// EDX contains address of V2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// MOVQ  MM0, [EAX]
  db $0F,$0F,$02,$9E       /// PFADD MM0, [EDX]
  db $0F,$7F,$00           /// MOVQ  [EAX], MM0
  db $0F,$6F,$48,$08       /// MOVQ  MM1, [EAX+8]
  db $0F,$0F,$4A,$08,$9E   /// PFADD MM1, [EDX+8]
  db $0F,$7F,$48,$08       /// MOVQ  [EAX+8], MM1
  db $0F,$0E               /// FEMMS
  ret
@@FPU:
  FLD  DWORD PTR [EAX]
  FADD DWORD PTR [EDX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EAX+4]
  FADD DWORD PTR [EDX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EAX+8]
  FADD DWORD PTR [EDX+8]
  FSTP DWORD PTR [EAX+8]
  FLD  DWORD PTR [EAX+12]
  FADD DWORD PTR [EDX+12]
  FSTP DWORD PTR [EAX+12]
  {$ELSE}
begin
  V1[0] := V1[0] + V2[0];
  V1[1] := V1[1] + V2[1];
  V1[2] := V1[2] + V2[2];
  V1[3] := V1[3] + V2[3];
{$ENDIF}
end;

// AddVector (affine)
//
procedure AddVector(var v: TAffineVector; const f: Single);
begin
  v[0] := v[0] + f;
  v[1] := v[1] + f;
  v[2] := v[2] + f;
end;

// AddVector (hmg)
//
procedure AddVector(var v: TVector; const f: Single);
begin
  v[0] := v[0] + f;
  v[1] := v[1] + f;
  v[2] := v[2] + f;
  v[3] := v[3] + f;
end;

// AddPoint (hmg, W = 1)
//
procedure AddPoint(var V1: TVector; const V2: TVector);
begin
  V1[0] := V1[0] + V2[0];
  V1[1] := V1[1] + V2[1];
  V1[2] := V1[2] + V2[2];
  V1[3] := 1;
end;

// TexPointArrayAdd
//
procedure TexPointArrayAdd(const src: PTexPointArray; const delta: TTexPoint;
  const nb: Integer; dest: PTexPointArray); overload;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  or    ecx, ecx
  jz    @@End

  test  vSIMD, 1
  jnz   @@3DNow

  push edi
  mov   edi, dest

@@FPULoop:
  fld   dword ptr [eax]
  fadd  dword ptr [edx]
  fstp  dword ptr [edi]
  fld   dword ptr [eax+4]
  fadd  dword ptr [edx+4]
  fstp  dword ptr [edi+4]

  add   eax, 8
  add   edi, 8
  dec   ecx
  jnz   @@FPULoop

  pop edi
  jmp   @@End

@@3DNow:
  db $0F,$6F,$02           /// movq  mm0, [edx]
  mov   edx, dest

@@3DNowLoop:
  db $0F,$6F,$10           /// movq  mm2, [eax]
  db $0F,$0F,$D0,$9E       /// pfadd mm2, mm0
  db $0F,$7F,$12           /// movq  [edx], mm2

  add   eax, 8
  add   edx, 8
  dec   ecx
  jnz   @@3DNowLoop

  db $0F,$0E               /// femms

@@End:
  {$ELSE}
var
  i: Integer;
begin
  for i := 0 to nb - 1 do
  begin
    dest^[i].S := src^[i].S + delta.S;
    dest^[i].T := src^[i].T + delta.T;
  end;
{$ENDIF}
end;

// TexPointArrayScaleAndAdd
//
procedure TexPointArrayScaleAndAdd(const src: PTexPointArray;
  const delta: TTexPoint; const nb: Integer; const scale: TTexPoint;
  dest: PTexPointArray); overload;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  or    ecx, ecx
  jz    @@End

  test  vSIMD, 1
  jnz   @@3DNow

  push  edi
  push  esi
  mov   edi, dest
  mov   esi, scale

@@FPULoop:
  fld   dword ptr [eax]
  fmul  dword ptr [esi]
  fadd  dword ptr [edx]
  fstp  dword ptr [edi]
  fld   dword ptr [eax+4]
  fmul  dword ptr [esi+4]
  fadd  dword ptr [edx+4]
  fstp  dword ptr [edi+4]

  add   eax, 8
  add   edi, 8
  dec   ecx
  jnz   @@FPULoop

  pop   esi
  pop   edi
  jmp   @@End

@@3DNow:
  db $0F,$6F,$02           /// movq  mm0, [edx]
  mov   edx, scale
  db $0F,$6F,$0A           /// movq  mm1, [edx]
  mov   edx, dest

@@3DNowLoop:
  db $0F,$6F,$10           /// movq  mm2, [eax]
  db $0F,$0F,$D1,$B4       /// pfmul mm2, mm1
  db $0F,$0F,$D0,$9E       /// pfadd mm2, mm0
  db $0F,$7F,$12           /// movq  [edx], mm2

  add   eax, 8
  add   edx, 8
  dec   ecx
  jnz   @@3DNowLoop

  db $0F,$0E               /// femms
@@End:
  {$ELSE}
var
  i: Integer;
begin
  for i := 0 to nb - 1 do
  begin
    dest^[i].S := src^[i].S * scale.S + delta.S;
    dest^[i].T := src^[i].T * scale.T + delta.T;
  end;
{$ENDIF}
end;

// VectorArrayAdd
//
procedure VectorArrayAdd(const src: PAffineVectorArray;
  const delta: TAffineVector; const nb: Integer; dest: PAffineVectorArray);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  or    ecx, ecx
  jz    @@End

  test  vSIMD, 1
  jnz   @@3DNow

  push edi
  mov   edi, dest

@@FPULoop:
  fld   dword ptr [eax]
  fadd  dword ptr [edx]
  fstp  dword ptr [edi]
  fld   dword ptr [eax+4]
  fadd  dword ptr [edx+4]
  fstp  dword ptr [edi+4]
  fld   dword ptr [eax+8]
  fadd  dword ptr [edx+8]
  fstp  dword ptr [edi+8]

  add   eax, 12
  add   edi, 12
  dec   ecx
  jnz   @@FPULoop

  pop edi
  jmp   @@End

@@3DNow:
  db $0F,$6F,$02           /// movq  mm0, [edx]
  db $0F,$6E,$4A,$08       /// movd  mm1, [edx+8]
  mov   edx, dest

@@3DNowLoop:
  db $0F,$6F,$10           /// movq  mm2, [eax]
  db $0F,$6E,$58,$08       /// movd  mm3, [eax+8]
  db $0F,$0F,$D0,$9E       /// pfadd mm2, mm0
  db $0F,$0F,$D9,$9E       /// pfadd mm3, mm1
  db $0F,$7F,$12           /// movq  [edx], mm2
  db $0F,$7E,$5A,$08       /// movd  [edx+8], mm3

  add   eax, 12
  add   edx, 12
  dec   ecx
  jnz   @@3DNowLoop

  db $0F,$0E               /// femms

@@End:
  {$ELSE}
var
  i: Integer;
begin
  for i := 0 to nb - 1 do
  begin
    dest^[i][0] := src^[i][0] + delta[0];
    dest^[i][1] := src^[i][1] + delta[1];
    dest^[i][2] := src^[i][2] + delta[2];
  end;
{$ENDIF}
end;

// VectorSubtract (func, affine)
//
function VectorSubtract(const V1, V2: TAffineVector): TAffineVector;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  {$ELSE}
begin
  result[0] := V1[0] - V2[0];
  result[1] := V1[1] - V2[1];
  result[2] := V1[2] - V2[2];
{$ENDIF}
end;

// VectorSubtract (proc, affine)
//
procedure VectorSubtract(const V1, V2: TAffineVector;
  var result: TAffineVector); overload;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  {$ELSE}
begin
  result[0] := V1[0] - V2[0];
  result[1] := V1[1] - V2[1];
  result[2] := V1[2] - V2[2];
{$ENDIF}
end;

// VectorSubtract (proc, affine-hmg)
//
procedure VectorSubtract(const V1, V2: TAffineVector;
  var result: TVector); overload;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  xor   eax, eax
  mov   [ECX+12], eax
  {$ELSE}
begin
  result[0] := V1[0] - V2[0];
  result[1] := V1[1] - V2[1];
  result[2] := V1[2] - V2[2];
  result[3] := 0;
{$ENDIF}
end;

// VectorSubtract
//
procedure VectorSubtract(const V1: TVector; V2: TAffineVector;
  var result: TVector); overload;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  mov   edx, [eax+12]
  mov   [ECX+12], edx
  {$ELSE}
begin
  result[0] := V1[0] - V2[0];
  result[1] := V1[1] - V2[1];
  result[2] := V1[2] - V2[2];
  result[3] := V1[0];
{$ENDIF}
end;

// VectorSubtract (hmg)
//
function VectorSubtract(const V1, V2: TVector): TVector;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// MOVQ  MM0, [EAX]
  db $0F,$0F,$02,$9A       /// PFSUB MM0, [EDX]
  db $0F,$7F,$01           /// MOVQ  [ECX], MM0
  db $0F,$6F,$48,$08       /// MOVQ  MM1, [EAX+8]
  db $0F,$0F,$4A,$08,$9A   /// PFSUB MM1, [EDX+8]
  db $0F,$7F,$49,$08       /// MOVQ  [ECX+8], MM1
  db $0F,$0E               /// FEMMS
  ret
@@FPU:
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  FLD  DWORD PTR [EAX+12]
  FSUB DWORD PTR [EDX+12]
  FSTP DWORD PTR [ECX+12]
  {$ELSE}
begin
  result[0] := V1[0] - V2[0];
  result[1] := V1[1] - V2[1];
  result[2] := V1[2] - V2[2];
{$ENDIF}
end;

// VectorSubtract (proc, hmg)
//
procedure VectorSubtract(const V1, V2: TVector; var result: TVector);
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// MOVQ  MM0, [EAX]
  db $0F,$0F,$02,$9A       /// PFSUB MM0, [EDX]
  db $0F,$7F,$01           /// MOVQ  [ECX], MM0
  db $0F,$6F,$48,$08       /// MOVQ  MM1, [EAX+8]
  db $0F,$0F,$4A,$08,$9A   /// PFSUB MM1, [EDX+8]
  db $0F,$7F,$49,$08       /// MOVQ  [ECX+8], MM1
  db $0F,$0E               /// FEMMS
  ret
@@FPU:
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  FLD  DWORD PTR [EAX+12]
  FSUB DWORD PTR [EDX+12]
  FSTP DWORD PTR [ECX+12]
  {$ELSE}
begin
  result[0] := V1[0] - V2[0];
  result[1] := V1[1] - V2[1];
  result[2] := V1[2] - V2[2];
  result[3] := V1[3] - V2[3];
{$ENDIF}
end;

// VectorSubtract (proc, affine)
//
procedure VectorSubtract(const V1, V2: TVector;
  var result: TAffineVector); overload;
// EAX contains address of V1
// EDX contains address of V2
// ECX contains the result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [ECX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [ECX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [ECX+8]
  {$ELSE}
begin
  result[0] := V1[0] - V2[0];
  result[1] := V1[1] - V2[1];
  result[2] := V1[2] - V2[2];
{$ENDIF}
end;

// VectorSubtract (affine, single)
//
function VectorSubtract(const V1: TAffineVector; delta: Single): TAffineVector;
begin
  result[0] := V1[0] - delta;
  result[1] := V1[1] - delta;
  result[2] := V1[2] - delta;
end;

// VectorSubtract (hmg, single)
//
function VectorSubtract(const V1: TVector; delta: Single): TVector;
begin
  result[0] := V1[0] - delta;
  result[1] := V1[1] - delta;
  result[2] := V1[2] - delta;
  result[3] := V1[3] - delta;
end;

// SubtractVector (affine)
//
procedure SubtractVector(var V1: TAffineVector; const V2: TAffineVector);
// EAX contains address of V1
// EDX contains address of V2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [EAX+8]
  {$ELSE}
begin
  V1[0] := V1[0] - V2[0];
  V1[1] := V1[1] - V2[1];
  V1[2] := V1[2] - V2[2];
{$ENDIF}
end;

// SubtractVector (hmg)
//
procedure SubtractVector(var V1: TVector; const V2: TVector);
// EAX contains address of V1
// EDX contains address of V2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// MOVQ  MM0, [EAX]
  db $0F,$0F,$02,$9A       /// PFSUB MM0, [EDX]
  db $0F,$7F,$00           /// MOVQ  [EAX], MM0
  db $0F,$6F,$48,$08       /// MOVQ  MM1, [EAX+8]
  db $0F,$0F,$4A,$08,$9A   /// PFSUB MM1, [EDX+8]
  db $0F,$7F,$48,$08       /// MOVQ  [EAX+8], MM1
  db $0F,$0E               /// FEMMS
  ret
@@FPU:
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FSTP DWORD PTR [EAX+8]
  FLD  DWORD PTR [EAX+12]
  FSUB DWORD PTR [EDX+12]
  FSTP DWORD PTR [EAX+12]
  {$ELSE}
begin
  V1[0] := V1[0] - V2[0];
  V1[1] := V1[1] - V2[1];
  V1[2] := V1[2] - V2[2];
  V1[3] := V1[3] - V2[3];
{$ENDIF}
end;

// CombineVector (var)
//
procedure CombineVector(var vr: TAffineVector; const v: TAffineVector;
  var f: Single);
// EAX contains address of vr
// EDX contains address of v
// ECX contains address of f
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EDX]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EDX+4]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EDX+8]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+8]
  FSTP DWORD PTR [EAX+8]
  {$ELSE}
begin
  vr[0] := vr[0] + v[0] * f;
  vr[1] := vr[1] + v[1] * f;
  vr[2] := vr[2] + v[2] * f;
{$ENDIF}
end;

// CombineVector (pointer)
//
procedure CombineVector(var vr: TAffineVector; const v: TAffineVector;
  pf: PFloat);
// EAX contains address of vr
// EDX contains address of v
// ECX contains address of f
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EDX]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EDX+4]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EDX+8]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+8]
  FSTP DWORD PTR [EAX+8]
  {$ELSE}
begin
  vr[0] := vr[0] + v[0] * pf^;
  vr[1] := vr[1] + v[1] * pf^;
  vr[2] := vr[2] + v[2] * pf^;
{$ENDIF}
end;

// TexPointCombine
//
function TexPointCombine(const t1, t2: TTexPoint; f1, f2: Single): TTexPoint;
begin
  result.S := (f1 * t1.S) + (f2 * t2.S);
  result.T := (f1 * t1.T) + (f2 * t2.T);
end;

// VectorCombine
//
function VectorCombine(const V1, V2: TAffineVector; const f1, f2: Single)
  : TAffineVector;
begin
  result[x] := (f1 * V1[x]) + (f2 * V2[x]);
  result[y] := (f1 * V1[y]) + (f2 * V2[y]);
  result[z] := (f1 * V1[z]) + (f2 * V2[z]);
end;

// VectorCombine3 (func)
//
function VectorCombine3(const V1, V2, V3: TAffineVector;
  const f1, f2, F3: Single): TAffineVector;
begin
  result[x] := (f1 * V1[x]) + (f2 * V2[x]) + (F3 * V3[x]);
  result[y] := (f1 * V1[y]) + (f2 * V2[y]) + (F3 * V3[y]);
  result[z] := (f1 * V1[z]) + (f2 * V2[z]) + (F3 * V3[z]);
end;

// VectorCombine3 (vector)
//
procedure VectorCombine3(const V1, V2, V3: TAffineVector;
  const f1, f2, F3: Single; var vr: TAffineVector);
begin
  vr[x] := (f1 * V1[x]) + (f2 * V2[x]) + (F3 * V3[x]);
  vr[y] := (f1 * V1[y]) + (f2 * V2[y]) + (F3 * V3[y]);
  vr[z] := (f1 * V1[z]) + (f2 * V2[z]) + (F3 * V3[z]);
end;

// CombineVector
//
procedure CombineVector(var vr: TVector; const v: TVector;
  var f: Single); overload;
// EAX contains address of vr
// EDX contains address of v
// ECX contains address of f
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6E,$11           /// MOVD  MM2, [ECX]
  db $0F,$62,$D2           /// PUNPCKLDQ MM2, MM2
  db $0F,$6F,$02           /// MOVQ  MM0, [EDX]
  db $0F,$0F,$C2,$B4       /// PFMUL MM0, MM2
  db $0F,$0F,$00,$9E       /// PFADD MM0, [EAX]
  db $0F,$7F,$00           /// MOVQ  [EAX], MM0
  db $0F,$6F,$4A,$08       /// MOVQ  MM1, [EDX+8]
  db $0F,$0F,$CA,$B4       /// PFMUL MM1, MM2
  db $0F,$0F,$48,$08,$9E   /// PFADD MM1, [EAX+8]
  db $0F,$7F,$48,$08       /// MOVQ  [EAX+8], MM1
  db $0F,$0E               /// FEMMS
  ret
@@FPU:
  FLD  DWORD PTR [EDX]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EDX+4]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EDX+8]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+8]
  FSTP DWORD PTR [EAX+8]
  FLD  DWORD PTR [EDX+12]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+12]
  FSTP DWORD PTR [EAX+12]
  {$ELSE}
begin
  vr[0] := vr[0] + v[0] * f;
  vr[1] := vr[1] + v[1] * f;
  vr[2] := vr[2] + v[2] * f;
  vr[3] := vr[3] + v[3] * f;
{$ENDIF}
end;

// CombineVector
//
procedure CombineVector(var vr: TVector; const v: TAffineVector;
  var f: Single); overload;
// EAX contains address of vr
// EDX contains address of v
// ECX contains address of f
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EDX]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EDX+4]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+4]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EDX+8]
  FMUL DWORD PTR [ECX]
  FADD DWORD PTR [EAX+8]
  FSTP DWORD PTR [EAX+8]
  {$ELSE}
begin
  vr[0] := vr[0] + v[0] * f;
  vr[1] := vr[1] + v[1] * f;
  vr[2] := vr[2] + v[2] * f;
{$ENDIF}
end;

// VectorCombine
//
function VectorCombine(const V1, V2: TVector; const f1, f2: Single): TVector;
begin
  result[x] := (f1 * V1[x]) + (f2 * V2[x]);
  result[y] := (f1 * V1[y]) + (f2 * V2[y]);
  result[z] := (f1 * V1[z]) + (f2 * V2[z]);
  result[w] := (f1 * V1[w]) + (f2 * V2[w]);
end;

// VectorCombine
//
function VectorCombine(const V1: TVector; const V2: TAffineVector;
  const f1, f2: Single): TVector; overload;
begin
  result[x] := (f1 * V1[x]) + (f2 * V2[x]);
  result[y] := (f1 * V1[y]) + (f2 * V2[y]);
  result[z] := (f1 * V1[z]) + (f2 * V2[z]);
  result[w] := f1 * V1[w];
end;

// VectorCombine
//
procedure VectorCombine(const V1, V2: TVector; const f1, f2: Single;
  var vr: TVector); overload;
// EAX contains address of v1
// EDX contains address of v2
// ECX contains address of vr
// ebp+$c points to f1
// ebp+$8 points to f2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:    // 246354
  db $0F,$6E,$4D,$0C       /// MOVD  MM1, [EBP+$0C]
  db $0F,$62,$C9           /// PUNPCKLDQ MM1, MM1
  db $0F,$6E,$55,$08       /// MOVD  MM2, [EBP+$08]
  db $0F,$62,$D2           /// PUNPCKLDQ MM2, MM2

  db $0F,$6F,$18           /// MOVQ  MM3, [EAX]
  db $0F,$0F,$D9,$B4       /// PFMUL MM3, MM1
  db $0F,$6F,$22           /// MOVQ  MM4, [EDX]
  db $0F,$0F,$E2,$B4       /// PFMUL MM4, MM2
  db $0F,$0F,$DC,$9E       /// PFADD MM3, MM4
  db $0F,$7F,$19           /// MOVQ  [ECX], MM3

  db $0F,$6F,$68,$08       /// MOVQ  MM5, [EAX+8]
  db $0F,$0F,$E9,$B4       /// PFMUL MM5, MM1
  db $0F,$6F,$72,$08       /// MOVQ  MM6, [EDX+8]
  db $0F,$0F,$F2,$B4       /// PFMUL MM6, MM2
  db $0F,$0F,$EE,$9E       /// PFADD MM5, MM6
  db $0F,$7F,$69,$08       /// MOVQ  [ECX+8], MM5

  db $0F,$0E               /// FEMMS
  pop ebp
  ret $08

@@FPU:      // 327363
  FLD  DWORD PTR [EAX]
  FMUL DWORD PTR [EBP+$0C]
  FLD  DWORD PTR [EDX]
  FMUL DWORD PTR [EBP+$08]
  FADD
  FSTP DWORD PTR [ECX]

  FLD  DWORD PTR [EAX+4]
  FMUL DWORD PTR [EBP+$0C]
  FLD  DWORD PTR [EDX+4]
  FMUL DWORD PTR [EBP+$08]
  FADD
  FSTP DWORD PTR [ECX+4]

  FLD  DWORD PTR [EAX+8]
  FMUL DWORD PTR [EBP+$0C]
  FLD  DWORD PTR [EDX+8]
  FMUL DWORD PTR [EBP+$08]
  FADD
  FSTP DWORD PTR [ECX+8]

  FLD  DWORD PTR [EAX+12]
  FMUL DWORD PTR [EBP+$0C]
  FLD  DWORD PTR [EDX+12]
  FMUL DWORD PTR [EBP+$08]
  FADD
  FSTP DWORD PTR [ECX+12]
  {$ELSE}
begin
  vr[0] := (f1 * V1[0]) + (f2 * V2[0]);
  vr[1] := (f1 * V1[1]) + (f2 * V2[1]);
  vr[2] := (f1 * V1[2]) + (f2 * V2[2]);
  vr[3] := (f1 * V1[3]) + (f2 * V2[3]);
{$ENDIF}
end;

// VectorCombine (F1=1.0)
//
procedure VectorCombine(const V1, V2: TVector; const f2: Single;
  var vr: TVector); overload;
// EAX contains address of v1
// EDX contains address of v2
// ECX contains address of vr
// ebp+$8 points to f2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:    // 121559
  db $0F,$6E,$55,$08       /// MOVD  MM2, [EBP+$08]
  db $0F,$62,$D2           /// PUNPCKLDQ MM2, MM2

  db $0F,$6F,$22           /// MOVQ  MM4, [EDX]
  db $0F,$6F,$72,$08       /// MOVQ  MM6, [EDX+8]

  db $0F,$0F,$E2,$B4       /// PFMUL MM4, MM2
  db $0F,$0F,$F2,$B4       /// PFMUL MM6, MM2

  db $0F,$0F,$20,$9E       /// PFADD MM4, [EAX]
  db $0F,$0F,$70,$08,$9E   /// PFADD MM6, [EAX+8]

  db $0F,$7F,$21           /// MOVQ  [ECX], MM4
  db $0F,$7F,$71,$08       /// MOVQ  [ECX+8], MM6

  db $0F,$0E               /// FEMMS
  pop ebp
  ret $04

@@FPU:      // 171379
  FLD  DWORD PTR [EBP+$08]

  FLD  DWORD PTR [EDX]
  FMUL ST, ST(1)
  FADD DWORD PTR [EAX]
  FSTP DWORD PTR [ECX]

  FLD  DWORD PTR [EDX+4]
  FMUL ST, ST(1)
  FADD DWORD PTR [EAX+4]
  FSTP DWORD PTR [ECX+4]

  FLD  DWORD PTR [EDX+8]
  FMUL ST, ST(1)
  FADD DWORD PTR [EAX+8]
  FSTP DWORD PTR [ECX+8]

  FLD  DWORD PTR [EDX+12]
  FMULP
  FADD DWORD PTR [EAX+12]
  FSTP DWORD PTR [ECX+12]
  {$ELSE}
begin // 201283
  vr[0] := V1[0] + (f2 * V2[0]);
  vr[1] := V1[1] + (f2 * V2[1]);
  vr[2] := V1[2] + (f2 * V2[2]);
  vr[3] := V1[3] + (f2 * V2[3]);
{$ENDIF}
end;

// VectorCombine
//
procedure VectorCombine(const V1: TVector; const V2: TAffineVector;
  const f1, f2: Single; var vr: TVector);
begin
  vr[x] := (f1 * V1[x]) + (f2 * V2[x]);
  vr[y] := (f1 * V1[y]) + (f2 * V2[y]);
  vr[z] := (f1 * V1[z]) + (f2 * V2[z]);
  vr[w] := f1 * V1[w];
end;

// VectorCombine3
//
function VectorCombine3(const V1, V2, V3: TVector;
  const f1, f2, F3: Single): TVector;
begin
  result[x] := (f1 * V1[x]) + (f2 * V2[x]) + (F3 * V3[x]);
  result[y] := (f1 * V1[y]) + (f2 * V2[y]) + (F3 * V3[y]);
  result[z] := (f1 * V1[z]) + (f2 * V2[z]) + (F3 * V3[z]);
  result[w] := (f1 * V1[w]) + (f2 * V2[w]) + (F3 * V3[w]);
end;

// VectorCombine3
//
procedure VectorCombine3(const V1, V2, V3: TVector; const f1, f2, F3: Single;
  var vr: TVector);
// EAX contains address of v1
// EDX contains address of v2
// ECX contains address of v3
// EBX contains address of vr
// ebp+$14 points to f1
// ebp+$10 points to f2
// ebp+$0c points to f3
begin
{$IFNDEF GEOMETRY_NO_ASM}
  asm
    test vSIMD, 1
    jz @@FPU
  @@3DNow:    // 197
    db $0F,$6E,$4D,$14       /// MOVD  MM1, [EBP+$14]
    db $0F,$62,$C9           /// PUNPCKLDQ MM1, MM1
    db $0F,$6E,$55,$10       /// MOVD  MM2, [EBP+$10]
    db $0F,$62,$D2           /// PUNPCKLDQ MM2, MM2
    db $0F,$6E,$5D,$0C       /// MOVD  MM3, [EBP+$0C]
    db $0F,$62,$DB           /// PUNPCKLDQ MM3, MM3

    db $0F,$6F,$20           /// MOVQ  MM4, [EAX]
    db $0F,$0F,$E1,$B4       /// PFMUL MM4, MM1
    db $0F,$6F,$2A           /// MOVQ  MM5, [EDX]
    db $0F,$0F,$EA,$B4       /// PFMUL MM5, MM2
    db $0F,$0F,$E5,$9E       /// PFADD MM4, MM5
    db $0F,$6F,$31           /// MOVQ  MM6, [ECX]
    db $0F,$0F,$F3,$B4       /// PFMUL MM6, MM3
    db $0F,$0F,$E6,$9E       /// PFADD MM4, MM6
    db $0F,$7F,$23           /// MOVQ  [EBX], MM4

    db $0F,$6F,$78,$08       /// MOVQ  MM7, [EAX+8]
    db $0F,$0F,$F9,$B4       /// PFMUL MM7, MM1
    db $0F,$6F,$42,$08       /// MOVQ  MM0, [EDX+8]
    db $0F,$0F,$C2,$B4       /// PFMUL MM0, MM2
    db $0F,$0F,$F8,$9E       /// PFADD MM7, MM0
    db $0F,$6F,$69,$08       /// MOVQ  MM5, [ECX+8]
    db $0F,$0F,$EB,$B4       /// PFMUL MM5, MM3
    db $0F,$0F,$FD,$9E       /// PFADD MM7, MM5
    db $0F,$7F,$7B,$08       /// MOVQ  [EBX+8], MM7

    db $0F,$0E               /// FEMMS
    pop ebx
    pop ebp
    ret $10
  @@FPU:      // 263
  end;
{$ENDIF}
  vr[x] := (f1 * V1[x]) + (f2 * V2[x]) + (F3 * V3[x]);
  vr[y] := (f1 * V1[y]) + (f2 * V2[y]) + (F3 * V3[y]);
  vr[z] := (f1 * V1[z]) + (f2 * V2[z]) + (F3 * V3[z]);
  vr[w] := (f1 * V1[w]) + (f2 * V2[w]) + (F3 * V3[w]);
end;

// VectorDotProduct (affine)
//
function VectorDotProduct(const V1, V2: TAffineVector): Single;
// EAX contains address of V1
// EDX contains address of V2
// result is stored in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [eax]
  FMUL DWORD PTR [edx]
  FLD DWORD PTR [eax+4]
  FMUL DWORD PTR [edx+4]
  faddp
  FLD DWORD PTR [eax+8]
  FMUL DWORD PTR [edx+8]
  faddp
end;
{$ELSE}
begin
  result := V1[0] * V2[0] + V1[1] * V2[1] + V1[2] * V2[2];
end;
{$ENDIF}

// VectorDotProduct (hmg)
//
function VectorDotProduct(const V1, V2: TVector): Single;
// EAX contains address of V1
// EDX contains address of V2
// result is stored in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]
  FMUL DWORD PTR [EDX]
  FLD DWORD PTR [EAX + 4]
  FMUL DWORD PTR [EDX + 4]
  FADDP
  FLD DWORD PTR [EAX + 8]
  FMUL DWORD PTR [EDX + 8]
  FADDP
  FLD DWORD PTR [EAX + 12]
  FMUL DWORD PTR [EDX + 12]
  FADDP
  {$ELSE}
begin
  result := V1[0] * V2[0] + V1[1] * V2[1] + V1[2] * V2[2] + V1[3] * V2[3];
{$ENDIF}
end;

// VectorDotProduct
//
function VectorDotProduct(const V1: TVector; const V2: TAffineVector): Single;
// EAX contains address of V1
// EDX contains address of V2
// result is stored in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]
  FMUL DWORD PTR [EDX]
  FLD DWORD PTR [EAX + 4]
  FMUL DWORD PTR [EDX + 4]
  FADDP
  FLD DWORD PTR [EAX + 8]
  FMUL DWORD PTR [EDX + 8]
  FADDP
  {$ELSE}
begin
  result := V1[0] * V2[0] + V1[1] * V2[1] + V1[2] * V2[2];
{$ENDIF}
end;

// PointProject (affine)
//
function PointProject(const p, origin, direction: TAffineVector): Single;
// EAX -> p, EDX -> origin, ECX -> direction
{$IFNDEF GEOMETRY_NO_ASM}
asm
  fld   dword ptr [eax]
  fsub  dword ptr [edx]
  fmul  dword ptr [ecx]
  fld   dword ptr [eax+4]
  fsub  dword ptr [edx+4]
  fmul  dword ptr [ecx+4]
  fadd
  fld   dword ptr [eax+8]
  fsub  dword ptr [edx+8]
  fmul  dword ptr [ecx+8]
  fadd
  {$ELSE}
begin
  result := direction[0] * (p[0] - origin[0]) + direction[1] * (p[1] - origin[1]
    ) + direction[2] * (p[2] - origin[2]);
{$ENDIF}
end;

// PointProject (vector)
//
function PointProject(const p, origin, direction: TVector): Single;
// EAX -> p, EDX -> origin, ECX -> direction
{$IFNDEF GEOMETRY_NO_ASM}
asm
  fld   dword ptr [eax]
  fsub  dword ptr [edx]
  fmul  dword ptr [ecx]
  fld   dword ptr [eax+4]
  fsub  dword ptr [edx+4]
  fmul  dword ptr [ecx+4]
  fadd
  fld   dword ptr [eax+8]
  fsub  dword ptr [edx+8]
  fmul  dword ptr [ecx+8]
  fadd
  {$ELSE}
begin
  result := direction[0] * (p[0] - origin[0]) + direction[1] * (p[1] - origin[1]
    ) + direction[2] * (p[2] - origin[2]);
{$ENDIF}
end;

// VectorCrossProduct
//
function VectorCrossProduct(const V1, V2: TAffineVector): TAffineVector;
begin
  result[x] := V1[y] * V2[z] - V1[z] * V2[y];
  result[y] := V1[z] * V2[x] - V1[x] * V2[z];
  result[z] := V1[x] * V2[y] - V1[y] * V2[x];
end;

// VectorCrossProduct
//
function VectorCrossProduct(const V1, V2: TVector): TVector;
begin
  result[x] := V1[y] * V2[z] - V1[z] * V2[y];
  result[y] := V1[z] * V2[x] - V1[x] * V2[z];
  result[z] := V1[x] * V2[y] - V1[y] * V2[x];
  result[w] := 0;
end;

// VectorCrossProduct
//
procedure VectorCrossProduct(const V1, V2: TVector; var vr: TVector);
begin
  vr[x] := V1[y] * V2[z] - V1[z] * V2[y];
  vr[y] := V1[z] * V2[x] - V1[x] * V2[z];
  vr[z] := V1[x] * V2[y] - V1[y] * V2[x];
  vr[w] := 0;
end;

// VectorCrossProduct
//
procedure VectorCrossProduct(const V1, V2: TAffineVector;
  var vr: TVector); overload;
begin
  vr[x] := V1[y] * V2[z] - V1[z] * V2[y];
  vr[y] := V1[z] * V2[x] - V1[x] * V2[z];
  vr[z] := V1[x] * V2[y] - V1[y] * V2[x];
  vr[w] := 0;
end;

// VectorCrossProduct
//
procedure VectorCrossProduct(const V1, V2: TVector;
  var vr: TAffineVector); overload;
begin
  vr[x] := V1[y] * V2[z] - V1[z] * V2[y];
  vr[y] := V1[z] * V2[x] - V1[x] * V2[z];
  vr[z] := V1[x] * V2[y] - V1[y] * V2[x];
end;

// VectorCrossProduct
//
procedure VectorCrossProduct(const V1, V2: TAffineVector;
  var vr: TAffineVector); overload;
begin
  vr[x] := V1[y] * V2[z] - V1[z] * V2[y];
  vr[y] := V1[z] * V2[x] - V1[x] * V2[z];
  vr[z] := V1[x] * V2[y] - V1[y] * V2[x];
end;

// Lerp
//
function Lerp(const start, stop, T: Single): Single;
begin
  result := start + (stop - start) * T;
end;

// Angle Lerp
//
function AngleLerp(start, stop, T: Single): Single;
var
  d: Single;
begin
  start := NormalizeAngle(start);
  stop := NormalizeAngle(stop);
  d := stop - start;
  if d > PI then
  begin
    // positive d, angle on opposite side, becomes negative i.e. changes direction
    d := -d - c2PI;
  end
  else if d < -PI then
  begin
    // negative d, angle on opposite side, becomes positive i.e. changes direction
    d := d + c2PI;
  end;
  result := start + d * T;
end;

// DistanceBetweenAngles
//
function DistanceBetweenAngles(angle1, angle2: Single): Single;
begin
  angle1 := NormalizeAngle(angle1);
  angle2 := NormalizeAngle(angle2);
  result := Abs(angle2 - angle1);
  if result > PI then
    result := c2PI - result;
end;

// TexPointLerp
//
function TexPointLerp(const t1, t2: TTexPoint; T: Single): TTexPoint; overload;
begin
  result.S := t1.S + (t2.S - t1.S) * T;
  result.T := t1.T + (t2.T - t1.T) * T;
end;

// VectorAffineLerp
//
function VectorLerp(const V1, V2: TAffineVector; T: Single): TAffineVector;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  fld   t

  fld   dword ptr [eax+0]
  fld   dword ptr [edx+0]
  fsub  st(0), st(1)
  fmul  st(0), st(2)
  faddp
  fstp  dword ptr [ecx+0]

  fld   dword ptr [eax+4]
  fld   dword ptr [edx+4]
  fsub  st(0), st(1)
  fmul  st(0), st(2)
  faddp
  fstp  dword ptr [ecx+4]

  fld   dword ptr [eax+8]
  fld   dword ptr [edx+8]
  fsub  st(0), st(1)
  fmul  st(0), st(2)
  faddp
  fstp  dword ptr [ecx+8]

  ffree st(0)
  {$ELSE}
begin
  result[x] := V1[x] + (V2[x] - V1[x]) * T;
  result[y] := V1[y] + (V2[y] - V1[y]) * T;
  result[z] := V1[z] + (V2[z] - V1[z]) * T;
{$ENDIF}
end;

// VectorLerp
//
procedure VectorLerp(const V1, V2: TAffineVector; T: Single;
  var vr: TAffineVector);
// EAX contains address of v1
// EDX contains address of v2
// EBX contains address of t
// ECX contains address of vr
{$IFNDEF GEOMETRY_NO_ASM}
asm
  fld   t

  fld   dword ptr [eax+0]
  fld   dword ptr [edx+0]
  fsub  st(0), st(1)
  fmul  st(0), st(2)
  faddp
  fstp  dword ptr [ecx+0]

  fld   dword ptr [eax+4]
  fld   dword ptr [edx+4]
  fsub  st(0), st(1)
  fmul  st(0), st(2)
  faddp
  fstp  dword ptr [ecx+4]

  fld   dword ptr [eax+8]
  fld   dword ptr [edx+8]
  fsub  st(0), st(1)
  fmul  st(0), st(2)
  faddp
  fstp  dword ptr [ecx+8]

  ffree st(0)
  {$ELSE}
begin
  vr[x] := V1[x] + (V2[x] - V1[x]) * T;
  vr[y] := V1[y] + (V2[y] - V1[y]) * T;
  vr[z] := V1[z] + (V2[z] - V1[z]) * T;
{$ENDIF}
end;

// VectorLerp
//
function VectorLerp(const V1, V2: TVector; T: Single): TVector;
begin
  result[x] := V1[x] + (V2[x] - V1[x]) * T;
  result[y] := V1[y] + (V2[y] - V1[y]) * T;
  result[z] := V1[z] + (V2[z] - V1[z]) * T;
  result[w] := V1[w] + (V2[w] - V1[w]) * T;
end;

// VectorLerp
//
procedure VectorLerp(const V1, V2: TVector; T: Single; var vr: TVector);
begin
  vr[x] := V1[x] + (V2[x] - V1[x]) * T;
  vr[y] := V1[y] + (V2[y] - V1[y]) * T;
  vr[z] := V1[z] + (V2[z] - V1[z]) * T;
  vr[w] := V1[w] + (V2[w] - V1[w]) * T;
end;

// VectorAngleLerp
//
function VectorAngleLerp(const V1, V2: TAffineVector; T: Single): TAffineVector;
var
  q1, q2, qR: TQuaternion;
  M: TMatrix;
  Tran: TTransformations;
begin
  if VectorEquals(V1, V2) then
  begin
    result := V1;
  end
  else
  begin
    q1 := QuaternionFromEuler(VectorGeometry.RadToDeg(V1[0]),
      VectorGeometry.RadToDeg(V1[1]), VectorGeometry.RadToDeg(V1[2]), eulZYX);
    q2 := QuaternionFromEuler(VectorGeometry.RadToDeg(V2[0]),
      VectorGeometry.RadToDeg(V2[1]), VectorGeometry.RadToDeg(V2[2]), eulZYX);
    qR := QuaternionSlerp(q1, q2, T);
    M := QuaternionToMatrix(qR);
    MatrixDecompose(M, Tran);
    result[0] := Tran[ttRotateX];
    result[1] := Tran[ttRotateY];
    result[2] := Tran[ttRotateZ];
  end;
end;

// VectorAngleCombine
//
function VectorAngleCombine(const V1, V2: TAffineVector; f: Single)
  : TAffineVector;
begin
  result := VectorCombine(V1, V2, 1, f);
end;

// VectorArrayLerp_3DNow (hmg)
//
{$IFNDEF GEOMETRY_NO_ASM}

procedure VectorArrayLerp_3DNow(const src1, src2: PVectorArray; T: Single;
  n: Integer; dest: PVectorArray); stdcall; overload;
var
  pt: ^Single;
begin
  pt := @T;
  asm
    push ebx
    push edi

    mov   eax, src1
    mov   edx, src2
    mov   ecx, n
    mov   ebx, dest
    mov   edi, pt

    db $0F,$0E               /// femms

    db $0F,$6E,$3F           /// movd     mm7, [edi]
    db $0F,$62,$FF           /// punpckldq mm7, mm7

  @@Loop:
    db $0F,$6F,$00           /// movq     mm0, [eax]
    db $0F,$6F,$50,$08       /// movq     mm2, [eax+8]
    db $0F,$6F,$C8           /// movq     mm1, mm0
    db $0F,$6F,$DA           /// movq     mm3, mm2
    db $0F,$0F,$02,$AA       /// pfsubr   mm0, [edx]
    db $0F,$0F,$52,$08,$AA   /// pfsubr   mm2, [edx+8]
    db $0F,$0D,$4B,$20       /// prefetchw [ebx+32]
    db $0F,$0F,$C7,$B4       /// pfmul    mm0, mm7
    db $0F,$0F,$D7,$B4       /// pfmul    mm2, mm7
    add   eax, 16
    add   edx, 16
    db $0F,$0D,$40,$20       /// prefetch [eax+32]
    db $0F,$0F,$C1,$9E       /// pfadd    mm0, mm1
    db $0F,$0F,$D3,$9E       /// pfadd    mm2, mm3
    db $0F,$0D,$42,$20       /// prefetch [edx+32]
    db $0F,$7F,$03           /// movq     [ebx], mm0
    db $0F,$7F,$53,$08       /// movq     [ebx+8], mm2

    add   ebx, 16

    dec   ecx
    jnz @@Loop

    db $0F,$0E               /// femms

    pop edi
    pop ebx
  end;
end;
{$ENDIF}

// VectorArrayLerp (hmg)
//
procedure VectorArrayLerp(const src1, src2: PVectorArray; T: Single; n: Integer;
  dest: PVectorArray);
var
  i: Integer;
begin
{$IFNDEF GEOMETRY_NO_ASM}
  if vSIMD = 1 then
    VectorArrayLerp_3DNow(src1, src2, T, n, dest)
  else {$ENDIF} begin
    for i := 0 to n - 1 do
    begin
      dest^[i][0] := src1^[i][0] + (src2^[i][0] - src1^[i][0]) * T;
      dest^[i][1] := src1^[i][1] + (src2^[i][1] - src1^[i][1]) * T;
      dest^[i][2] := src1^[i][2] + (src2^[i][2] - src1^[i][2]) * T;
      dest^[i][3] := src1^[i][3] + (src2^[i][3] - src1^[i][3]) * T;
    end;
  end;
end;

// VectorArrayLerp_3DNow (affine)
//
{$IFNDEF GEOMETRY_NO_ASM}

procedure VectorArrayLerp_3DNow(const src1, src2: PAffineVectorArray; T: Single;
  n: Integer; dest: PAffineVectorArray); stdcall; overload;
var
  pt: ^Single;
begin
  pt := @T;
  asm
    push ebx
    push edi

    mov   eax, src1
    mov   edx, src2
    mov   ecx, n

    cmp   ecx, 1
    jbe   @@End

    shr   ecx, 1
    mov   ebx, dest
    mov   edi, pt

    db $0F,$0E               /// femms

    db $0F,$6E,$3F           /// movd     mm7, [edi]
    db $0F,$62,$FF           /// punpckldq mm7, mm7

  @@Loop:
    db $0F,$6F,$00           /// movq     mm0, [eax]
    db $0F,$6F,$50,$08       /// movq     mm2, [eax+8]
    db $0F,$6F,$60,$10       /// movq     mm4, [eax+16]
    db $0F,$6F,$C8           /// movq     mm1, mm0
    db $0F,$6F,$DA           /// movq     mm3, mm2
    db $0F,$6F,$EC           /// movq     mm5, mm4
    db $0F,$0F,$02,$AA       /// pfsubr   mm0, [edx]
    db $0F,$0F,$52,$08,$AA   /// pfsubr   mm2, [edx+8]
    db $0F,$0F,$62,$10,$AA   /// pfsubr   mm4, [edx+16]
    db $0F,$0D,$4B,$40       /// prefetchw [ebx+64]
    db $0F,$0F,$C7,$B4       /// pfmul    mm0, mm7
    db $0F,$0F,$D7,$B4       /// pfmul    mm2, mm7
    db $0F,$0F,$E7,$B4       /// pfmul    mm4, mm7
    db $0F,$0D,$40,$40       /// prefetch [eax+64]
    add   eax, 24
    add   edx, 24
    db $0F,$0F,$C1,$9E       /// pfadd    mm0, mm1
    db $0F,$0F,$D3,$9E       /// pfadd    mm2, mm3
    db $0F,$0F,$E5,$9E       /// pfadd    mm4, mm5
    db $0F,$0D,$42,$40       /// prefetch [edx+64]
    db $0F,$7F,$03           /// movq     [ebx], mm0
    db $0F,$7F,$53,$08       /// movq     [ebx+8], mm2
    db $0F,$7F,$63,$10       /// movq     [ebx+16], mm4

    add   ebx, 24

    dec   ecx
    jnz @@Loop

    db $0F,$0E               /// femms

  @@End:
    pop edi
    pop ebx
  end;
  if (n and 1) = 1 then
    VectorLerp(src1[n - 1], src2[n - 1], T, dest[n - 1]);
end;
{$ENDIF}

// VectorArrayLerp (affine)
//
procedure VectorArrayLerp(const src1, src2: PAffineVectorArray; T: Single;
  n: Integer; dest: PAffineVectorArray);
var
  i: Integer;
begin
{$IFNDEF GEOMETRY_NO_ASM}
  if vSIMD = 1 then
    VectorArrayLerp_3DNow(src1, src2, T, n, dest)
  else {$ENDIF} begin
    for i := 0 to n - 1 do
    begin
      dest^[i][0] := src1^[i][0] + (src2^[i][0] - src1^[i][0]) * T;
      dest^[i][1] := src1^[i][1] + (src2^[i][1] - src1^[i][1]) * T;
      dest^[i][2] := src1^[i][2] + (src2^[i][2] - src1^[i][2]) * T;
    end;
  end;
end;

procedure VectorArrayLerp(const src1, src2: PTexPointArray; T: Single;
  n: Integer; dest: PTexPointArray);
var
  i: Integer;
begin
  for i := 0 to n - 1 do
  begin
    dest^[i].S := src1^[i].S + (src2^[i].S - src1^[i].S) * T;
    dest^[i].T := src1^[i].T + (src2^[i].T - src1^[i].T) * T;
  end;
end;

// InterpolateCombined
//
function InterpolateCombined(const start, stop, delta: Single;
  const DistortionDegree: Single;
  const InterpolationType: TGLInterpolationType): Single;
begin
  case InterpolationType of
    itLinear:
      result := Lerp(start, stop, delta);
    itPower:
      result := InterpolatePower(start, stop, delta, DistortionDegree);
    itSin:
      result := InterpolateSin(start, stop, delta);
    itSinAlt:
      result := InterpolateSinAlt(start, stop, delta);
    itTan:
      result := InterpolateTan(start, stop, delta);
    itLn:
      result := InterpolateLn(start, stop, delta, DistortionDegree);
  else
    begin
      result := -1;
      Assert(False);
    end;
  end;
end;

// InterpolateCombinedFastPower
//
function InterpolateCombinedFastPower(const OriginalStart, OriginalStop,
  OriginalCurrent: Single; const TargetStart, TargetStop: Single;
  const DistortionDegree: Single): Single;
begin
  result := InterpolatePower(TargetStart, TargetStop,
    (OriginalCurrent - OriginalStart) / (OriginalStop - OriginalStart),
    DistortionDegree);
end;

// InterpolateCombinedSafe
//
function InterpolateCombinedSafe(const OriginalStart, OriginalStop,
  OriginalCurrent: Single; const TargetStart, TargetStop: Single;
  const DistortionDegree: Single;
  const InterpolationType: TGLInterpolationType): Single;
var
  ChangeDelta: Single;
begin
  if OriginalStop = OriginalStart then
    result := TargetStart
  else
  begin
    ChangeDelta := (OriginalCurrent - OriginalStart) /
      (OriginalStop - OriginalStart);
    result := InterpolateCombined(TargetStart, TargetStop, ChangeDelta,
      DistortionDegree, InterpolationType);
  end;
end;

// InterpolateCombinedFast
//
function InterpolateCombinedFast(const OriginalStart, OriginalStop,
  OriginalCurrent: Single; const TargetStart, TargetStop: Single;
  const DistortionDegree: Single;
  const InterpolationType: TGLInterpolationType): Single;
var
  ChangeDelta: Single;
begin
  ChangeDelta := (OriginalCurrent - OriginalStart) /
    (OriginalStop - OriginalStart);
  result := InterpolateCombined(TargetStart, TargetStop, ChangeDelta,
    DistortionDegree, InterpolationType);
end;

// InterpolateLn
//
function InterpolateLn(const start, stop, delta: Single;
  const DistortionDegree: Single): Single;
begin
  result := (stop - start) * Ln(1 + delta * DistortionDegree) /
    Ln(1 + DistortionDegree) + start;
end;

// InterpolateSinAlt
//
function InterpolateSinAlt(const start, stop, delta: Single): Single;
begin
  result := (stop - start) * delta * Sin(delta * PI / 2) + start;
end;

// InterpolateSin
//
function InterpolateSin(const start, stop, delta: Single): Single;
begin
  result := (stop - start) * Sin(delta * PI / 2) + start;
end;

// InterpolateTan
//
function InterpolateTan(const start, stop, delta: Single): Single;
begin
  result := (stop - start) * VectorGeometry.Tan(delta * PI / 4) + start;
end;

// InterpolatePower
//
function InterpolatePower(const start, stop, delta: Single;
  const DistortionDegree: Single): Single;
begin
  if (Round(DistortionDegree) <> DistortionDegree) and (delta < 0) then
    result := (stop - start) * VectorGeometry.Power(delta,
      Round(DistortionDegree)) + start
  else
    result := (stop - start) * VectorGeometry.Power(delta,
      DistortionDegree) + start;
end;

// MatrixLerp
//
function MatrixLerp(const m1, m2: TMatrix; const delta: Single): TMatrix;
var
  i, J: Integer;
begin
  for J := 0 to 3 do
    for i := 0 to 3 do
      result[i][J] := m1[i][J] + (m2[i][J] - m1[i][J]) * delta;
end;

// VectorLength (array)
//
function VectorLength(const v: array of Single): Single;
// EAX contains address of V
// EDX contains the highest index of V
// the result is returned in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLDZ                           // initialize sum
@@Loop:
  FLD  DWORD PTR [EAX  +  4 * EDX] // load a component
  FMUL ST, ST
  FADDP
  SUB  EDX, 1
  JNL  @@Loop
  FSQRT
  {$ELSE}
var
  i: Integer;
begin
  result := 0;
  for i := Low(v) to High(v) do
    result := result + Sqr(v[i]);
  result := Sqrt(result);
{$ENDIF}
end;

// VectorLength  (x, y)
//
function VectorLength(const x, y: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD X
  FMUL ST, ST
  FLD Y
  FMUL ST, ST
  FADD
  FSQRT
  {$ELSE}
begin
  result := Sqrt(x * x + y * y);
{$ENDIF}
end;

// VectorLength (x, y, z)
//
function VectorLength(const x, y, z: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD X
  FMUL ST, ST
  FLD Y
  FMUL ST, ST
  FADD
  FLD Z
  FMUL ST, ST
  FADD
  FSQRT
  {$ELSE}
begin
  result := Sqrt(x * x + y * y + z * z);
{$ENDIF}
end;

// VectorLength
//
function VectorLength(const v: TAffineVector): Single;
// EAX contains address of V
// result is passed in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FMUL ST, ST
  FLD  DWORD PTR [EAX+4]
  FMUL ST, ST
  FADDP
  FLD  DWORD PTR [EAX+8]
  FMUL ST, ST
  FADDP
  FSQRT
  {$ELSE}
begin
  result := Sqrt(VectorNorm(v));
{$ENDIF}
end;

// VectorLength
//
function VectorLength(const v: TVector): Single;
// EAX contains address of V
// result is passed in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FMUL ST, ST
  FLD  DWORD PTR [EAX+4]
  FMUL ST, ST
  FADDP
  FLD  DWORD PTR [EAX+8]
  FMUL ST, ST
  FADDP
  FSQRT
  {$ELSE}
begin
  result := Sqrt(VectorNorm(v));
{$ENDIF}
end;

// VectorNorm
//
function VectorNorm(const x, y: Single): Single;
begin
  result := Sqr(x) + Sqr(y);
end;

// VectorNorm (affine)
//
function VectorNorm(const v: TAffineVector): Single;
// EAX contains address of V
// result is passed in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX];
  FMUL ST, ST
  FLD DWORD PTR [EAX+4];
  FMUL ST, ST
  FADD
  FLD DWORD PTR [EAX+8];
  FMUL ST, ST
  FADD
  {$ELSE}
begin
  result := v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
{$ENDIF}
end;

// VectorNorm (hmg)
//
function VectorNorm(const v: TVector): Single;
// EAX contains address of V
// result is passed in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX];
  FMUL ST, ST
  FLD DWORD PTR [EAX+4];
  FMUL ST, ST
  FADD
  FLD DWORD PTR [EAX+8];
  FMUL ST, ST
  FADD
  {$ELSE}
begin
  result := v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
{$ENDIF}
end;

// VectorNorm
//
function VectorNorm(var v: array of Single): Single;
// EAX contains address of V
// EDX contains highest index in V
// result is passed in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLDZ                           // initialize sum
@@Loop:
  FLD  DWORD PTR [EAX + 4 * EDX] // load a component
  FMUL ST, ST                    // make square
  FADDP                          // add previous calculated sum
  SUB  EDX, 1
  JNL  @@Loop
  {$ELSE}
var
  i: Integer;
begin
  result := 0;
  for i := Low(v) to High(v) do
    result := result + v[i] * v[i];
{$ENDIF}
end;

// NormalizeVector (affine)
//
procedure NormalizeVector(var v: TAffineVector);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// movq        mm0,[eax]
  db $0F,$6E,$48,$08       /// movd        mm1,[eax+8]
  db $0F,$6F,$E0           /// movq        mm4,mm0
  db $0F,$6F,$D9           /// movq        mm3,mm1
  db $0F,$0F,$C0,$B4       /// pfmul       mm0,mm0
  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C0,$AE       /// pfacc       mm0,mm0
  db $0F,$0F,$C1,$9E       /// pfadd       mm0,mm1
  db $0F,$0F,$C8,$97       /// pfrsqrt     mm1,mm0
  db $0F,$6F,$D1           /// movq        mm2,mm1

  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C8,$A7       /// pfrsqit1    mm1,mm0
  db $0F,$0F,$CA,$B6       /// pfrcpit2    mm1,mm2
  db $0F,$62,$C9           /// punpckldq   mm1,mm1
  db $0F,$0F,$D9,$B4       /// pfmul       mm3,mm1
  db $0F,$0F,$E1,$B4       /// pfmul       mm4,mm1
  db $0F,$7E,$58,$08       /// movd        [eax+8],mm3
  db $0F,$7F,$20           /// movq        [eax],mm4
@@norm_end:
  db $0F,$0E               /// femms
  ret

@@FPU:
  mov   ecx, eax
  FLD  DWORD PTR [ECX]
  FMUL ST, ST
  FLD  DWORD PTR [ECX+4]
  FMUL ST, ST
  FADD
  FLD  DWORD PTR [ECX+8]
  FMUL ST, ST
  FADD
  FLDZ
  FCOMP
  FNSTSW AX
  sahf
  jz @@result
  FSQRT
  FLD1
  FDIVR
@@result:
  FLD  ST
  FMUL DWORD PTR [ECX]
  FSTP DWORD PTR [ECX]
  FLD  ST
  FMUL DWORD PTR [ECX+4]
  FSTP DWORD PTR [ECX+4]
  FMUL DWORD PTR [ECX+8]
  FSTP DWORD PTR [ECX+8]
  {$ELSE}
var
  invLen: Single;
  vn: Single;
begin
  vn := VectorNorm(v);
  if vn > 0 then
  begin
    invLen := RSqrt(vn);
    v[0] := v[0] * invLen;
    v[1] := v[1] * invLen;
    v[2] := v[2] * invLen;
  end;
{$ENDIF}
end;

// VectorNormalize
//
function VectorNormalize(const v: TAffineVector): TAffineVector;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// movq        mm0,[eax]
  db $0F,$6E,$48,$08       /// movd        mm1,[eax+8]
  db $0F,$6F,$E0           /// movq        mm4,mm0
  db $0F,$6F,$D9           /// movq        mm3,mm1
  db $0F,$0F,$C0,$B4       /// pfmul       mm0,mm0
  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C0,$AE       /// pfacc       mm0,mm0
  db $0F,$0F,$C1,$9E       /// pfadd       mm0,mm1
  db $0F,$0F,$C8,$97       /// pfrsqrt     mm1,mm0
  db $0F,$6F,$D1           /// movq        mm2,mm1

  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C8,$A7       /// pfrsqit1    mm1,mm0
  db $0F,$0F,$CA,$B6       /// pfrcpit2    mm1,mm2
  db $0F,$62,$C9           /// punpckldq   mm1,mm1
  db $0F,$0F,$D9,$B4       /// pfmul       mm3,mm1
  db $0F,$0F,$E1,$B4       /// pfmul       mm4,mm1
  db $0F,$7E,$5A,$08       /// movd        [edx+8],mm3
  db $0F,$7F,$22           /// movq        [edx],mm4
@@norm_end:
  db $0F,$0E               /// femms
  ret

@@FPU:
  mov   ecx, eax
  FLD  DWORD PTR [ECX]
  FMUL ST, ST
  FLD  DWORD PTR [ECX+4]
  FMUL ST, ST
  FADD
  FLD  DWORD PTR [ECX+8]
  FMUL ST, ST
  FADD
  FLDZ
  FCOMP
  FNSTSW AX
  sahf
  jz @@result
  FSQRT
  FLD1
  FDIVR
@@result:
  FLD  ST
  FMUL DWORD PTR [ECX]
  FSTP DWORD PTR [EDX]
  FLD  ST
  FMUL DWORD PTR [ECX+4]
  FSTP DWORD PTR [EDX+4]
  FMUL DWORD PTR [ECX+8]
  FSTP DWORD PTR [EDX+8]
  {$ELSE}
var
  invLen: Single;
  vn: Single;
begin
  vn := VectorNorm(v);
  if vn = 0 then
    SetVector(result, v)
  else
  begin
    invLen := RSqrt(vn);
    result[0] := v[0] * invLen;
    result[1] := v[1] * invLen;
    result[2] := v[2] * invLen;
  end;
{$ENDIF}
end;

// NormalizeVectorArray
//
procedure NormalizeVectorArray(list: PAffineVectorArray; n: Integer);
// EAX contains list
// EDX contains n
{$IFNDEF GEOMETRY_NO_ASM}
asm
  OR    EDX, EDX
  JZ    @@End
  test vSIMD, 1
  jz @@FPU
@@3DNowLoop:
  db $0F,$6F,$00           /// movq        mm0,[eax]
  db $0F,$6E,$48,$08       /// movd        mm1,[eax+8]
  db $0F,$6F,$E0           /// movq        mm4,mm0
  db $0F,$6F,$D9           /// movq        mm3,mm1
  db $0F,$0F,$C0,$B4       /// pfmul       mm0,mm0
  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C0,$AE       /// pfacc       mm0,mm0
  db $0F,$0F,$C1,$9E       /// pfadd       mm0,mm1
  db $0F,$0F,$C8,$97       /// pfrsqrt     mm1,mm0
  db $0F,$6F,$D1           /// movq        mm2,mm1

  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C8,$A7       /// pfrsqit1    mm1,mm0
  db $0F,$0F,$CA,$B6       /// pfrcpit2    mm1,mm2
  db $0F,$62,$C9           /// punpckldq   mm1,mm1
  db $0F,$0F,$D9,$B4       /// pfmul       mm3,mm1
  db $0F,$0F,$E1,$B4       /// pfmul       mm4,mm1
  db $0F,$7E,$58,$08       /// movd        [eax+8],mm3
  db $0F,$7F,$20           /// movq        [eax],mm4
@@norm_end:
  db $0F,$0E               /// femms
  add   eax, 12
  db $0F,$0D,$40,$60       /// PREFETCH    [EAX+96]
  dec   edx
  jnz   @@3DNowLOOP
  ret

@@FPU:
  mov   ecx, eax
@@FPULoop:
  FLD   DWORD PTR [ECX]
  FMUL  ST, ST
  FLD   DWORD PTR [ECX+4]
  FMUL  ST, ST
  FADD
  FLD   DWORD PTR [ECX+8]
  FMUL  ST, ST
  FADD
  FLDZ
  FCOMP
  FNSTSW AX
  sahf
  jz @@result
  FSQRT
  FLD1
  FDIVR
@@result:
  FLD   ST
  FMUL  DWORD PTR [ECX]
  FSTP  DWORD PTR [ECX]
  FLD   ST
  FMUL  DWORD PTR [ECX+4]
  FSTP  DWORD PTR [ECX+4]
  FMUL  DWORD PTR [ECX+8]
  FSTP  DWORD PTR [ECX+8]
  ADD   ECX, 12
  DEC   EDX
  JNZ   @@FPULOOP
@@End:
  {$ELSE}
var
  i: Integer;
begin
  for i := 0 to n - 1 do
    NormalizeVector(list^[i]);
{$ENDIF}
end;

// NormalizeVector (hmg)
//
procedure NormalizeVector(var v: TVector);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// movq        mm0,[eax]
  db $0F,$6E,$48,$08       /// movd        mm1,[eax+8]
  db $0F,$6F,$E0           /// movq        mm4,mm0
  db $0F,$6F,$D9           /// movq        mm3,mm1
  db $0F,$0F,$C0,$B4       /// pfmul       mm0,mm0
  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C0,$AE       /// pfacc       mm0,mm0
  db $0F,$0F,$C1,$9E       /// pfadd       mm0,mm1
  db $0F,$0F,$C8,$97       /// pfrsqrt     mm1,mm0
  db $0F,$6F,$D1           /// movq        mm2,mm1

  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C8,$A7       /// pfrsqit1    mm1,mm0
  db $0F,$0F,$CA,$B6       /// pfrcpit2    mm1,mm2
  db $0F,$62,$C9           /// punpckldq   mm1,mm1
  db $0F,$0F,$D9,$B4       /// pfmul       mm3,mm1
  db $0F,$0F,$E1,$B4       /// pfmul       mm4,mm1
  db $0F,$7E,$58,$08       /// movd        [eax+8],mm3
  db $0F,$7F,$20           /// movq        [eax],mm4
@@norm_end:
  db $0F,$0E               /// femms
  xor   edx, edx
  mov   [eax+12], edx
  ret

@@FPU:
  mov   ecx, eax
  FLD  DWORD PTR [ECX]
  FMUL ST, ST
  FLD  DWORD PTR [ECX+4]
  FMUL ST, ST
  FADD
  FLD  DWORD PTR [ECX+8]
  FMUL ST, ST
  FADD
  FLDZ
  FCOMP
  FNSTSW AX
  sahf
  jz @@result
  FSQRT
  FLD1
  FDIVR
@@result:
  FLD  ST
  FMUL DWORD PTR [ECX]
  FSTP DWORD PTR [ECX]
  FLD  ST
  FMUL DWORD PTR [ECX+4]
  FSTP DWORD PTR [ECX+4]
  FMUL DWORD PTR [ECX+8]
  FSTP DWORD PTR [ECX+8]
  xor   edx, edx
  mov   [ecx+12], edx
  {$ELSE}
var
  invLen: Single;
  vn: Single;
begin
  vn := VectorNorm(v);
  if vn > 0 then
  begin
    invLen := RSqrt(vn);
    v[0] := v[0] * invLen;
    v[1] := v[1] * invLen;
    v[2] := v[2] * invLen;
  end;
  v[3] := 0;
{$ENDIF}
end;

// VectorNormalize (hmg, func)
//
function VectorNormalize(const v: TVector): TVector;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6F,$00           /// movq        mm0,[eax]
  db $0F,$6E,$48,$08       /// movd        mm1,[eax+8]
  db $0F,$6F,$E0           /// movq        mm4,mm0
  db $0F,$6F,$D9           /// movq        mm3,mm1
  db $0F,$0F,$C0,$B4       /// pfmul       mm0,mm0
  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C0,$AE       /// pfacc       mm0,mm0
  db $0F,$0F,$C1,$9E       /// pfadd       mm0,mm1
  db $0F,$0F,$C8,$97       /// pfrsqrt     mm1,mm0
  db $0F,$6F,$D1           /// movq        mm2,mm1

  db $0F,$0F,$C9,$B4       /// pfmul       mm1,mm1
  db $0F,$0F,$C8,$A7       /// pfrsqit1    mm1,mm0
  db $0F,$0F,$CA,$B6       /// pfrcpit2    mm1,mm2
  db $0F,$62,$C9           /// punpckldq   mm1,mm1
  db $0F,$0F,$D9,$B4       /// pfmul       mm3,mm1
  db $0F,$0F,$E1,$B4       /// pfmul       mm4,mm1
  db $0F,$7E,$5A,$08       /// movd        [edx+8],mm3
  db $0F,$7F,$22           /// movq        [edx],mm4
@@norm_end:
  db $0F,$0E               /// femms
  xor   eax, eax
  mov   [edx+12], eax
  ret

@@FPU:
  mov	ecx, eax
  FLD  DWORD PTR [ECX]
  FMUL ST, ST
  FLD  DWORD PTR [ECX+4]
  FMUL ST, ST
  FADD
  FLD  DWORD PTR [ECX+8]
  FMUL ST, ST
  FADD
  FLDZ
  FCOMP
  FNSTSW AX
  sahf
  jz @@result
  FSQRT
  FLD1
  FDIVR
@@result:
  FLD  ST
  FMUL DWORD PTR [ECX]
  FSTP DWORD PTR [EDX]
  FLD  ST
  FMUL DWORD PTR [ECX+4]
  FSTP DWORD PTR [EDX+4]
  FMUL DWORD PTR [ECX+8]
  FSTP DWORD PTR [EDX+8]
  xor   ecx, ecx
  mov   [edx+12], ecx
  {$ELSE}
var
  invLen: Single;
  vn: Single;
begin
  vn := VectorNorm(v);
  if vn = 0 then
    SetVector(result, v)
  else
  begin
    invLen := RSqrt(vn);
    result[0] := v[0] * invLen;
    result[1] := v[1] * invLen;
    result[2] := v[2] * invLen;
  end;
  result[3] := 0;
{$ENDIF}
end;

// VectorAngleCosine
//
function VectorAngleCosine(const V1, V2: TAffineVector): Single;
// EAX contains address of Vector1
// EDX contains address of Vector2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]           // V1[0]
  FLD ST                        // double V1[0]
  FMUL ST, ST                   // V1[0]^2 (prep. for divisor)
  FLD DWORD PTR [EDX]           // V2[0]
  FMUL ST(2), ST                // ST(2):=V1[0] * V2[0]
  FMUL ST, ST                   // V2[0]^2 (prep. for divisor)
  FLD DWORD PTR [EAX + 4]       // V1[1]
  FLD ST                        // double V1[1]
  FMUL ST, ST                   // ST(0):=V1[1]^2
  FADDP ST(3), ST               // ST(2):=V1[0]^2 + V1[1] *  * 2
  FLD DWORD PTR [EDX + 4]       // V2[1]
  FMUL ST(1), ST                // ST(1):=V1[1] * V2[1]
  FMUL ST, ST                   // ST(0):=V2[1]^2
  FADDP ST(2), ST               // ST(1):=V2[0]^2 + V2[1]^2
  FADDP ST(3), ST               // ST(2):=V1[0] * V2[0] + V1[1] * V2[1]
  FLD DWORD PTR [EAX + 8]       // load V2[1]
  FLD ST                        // same calcs go here
  FMUL ST, ST                   // (compare above)
  FADDP ST(3), ST
  FLD DWORD PTR [EDX + 8]
  FMUL ST(1), ST
  FMUL ST, ST
  FADDP ST(2), ST
  FADDP ST(3), ST
  FMULP                         // ST(0):=(V1[0]^2 + V1[1]^2 + V1[2]) *
  // (V2[0]^2 + V2[1]^2 + V2[2])
  FSQRT                         // sqrt(ST(0))
  FDIVP                         // ST(0):=Result:=ST(1) / ST(0)
  // the result is expected in ST(0), if it's invalid, an error is raised
  {$ELSE}
begin
  result := VectorDotProduct(V1, V2) / (VectorLength(V1) * VectorLength(V2));
{$ENDIF}
end;

function VectorAngleCosine(const V1, V2: TVector): Single;
// EAX contains address of Vector1
// EDX contains address of Vector2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]           // V1[0]
  FLD ST                        // double V1[0]
  FMUL ST, ST                   // V1[0]^2 (prep. for divisor)
  FLD DWORD PTR [EDX]           // V2[0]
  FMUL ST(2), ST                // ST(2):=V1[0] * V2[0]
  FMUL ST, ST                   // V2[0]^2 (prep. for divisor)
  FLD DWORD PTR [EAX + 4]       // V1[1]
  FLD ST                        // double V1[1]
  FMUL ST, ST                   // ST(0):=V1[1]^2
  FADDP ST(3), ST               // ST(2):=V1[0]^2 + V1[1] *  * 2
  FLD DWORD PTR [EDX + 4]       // V2[1]
  FMUL ST(1), ST                // ST(1):=V1[1] * V2[1]
  FMUL ST, ST                   // ST(0):=V2[1]^2
  FADDP ST(2), ST               // ST(1):=V2[0]^2 + V2[1]^2
  FADDP ST(3), ST               // ST(2):=V1[0] * V2[0] + V1[1] * V2[1]
  FLD DWORD PTR [EAX + 8]       // load V2[1]
  FLD ST                        // same calcs go here
  FMUL ST, ST                   // (compare above)
  FADDP ST(3), ST
  FLD DWORD PTR [EDX + 8]
  FMUL ST(1), ST
  FMUL ST, ST
  FADDP ST(2), ST
  FADDP ST(3), ST
  FMULP                         // ST(0):=(V1[0]^2 + V1[1]^2 + V1[2]) *
  // (V2[0]^2 + V2[1]^2 + V2[2])
  FSQRT                         // sqrt(ST(0))
  FDIVP                         // ST(0):=Result:=ST(1) / ST(0)
  // the result is expected in ST(0), if it's invalid, an error is raised
  {$ELSE}
begin
  result := VectorDotProduct(V1, V2) / (VectorLength(V1) * VectorLength(V2));
{$ENDIF}
end;

// VectorNegate (affine)
//
function VectorNegate(const v: TAffineVector): TAffineVector;
// EAX contains address of v
// EDX contains address of Result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]
  FCHS
  FSTP DWORD PTR [EDX]
  FLD DWORD PTR [EAX+4]
  FCHS
  FSTP DWORD PTR [EDX+4]
  FLD DWORD PTR [EAX+8]
  FCHS
  FSTP DWORD PTR [EDX+8]
  {$ELSE}
begin
  result[0] := -v[0];
  result[1] := -v[1];
  result[2] := -v[2];
{$ENDIF}
end;

// VectorNegate (hmg)
//
function VectorNegate(const v: TVector): TVector;
// EAX contains address of v
// EDX contains address of Result
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]
  FCHS
  FSTP DWORD PTR [EDX]
  FLD DWORD PTR [EAX+4]
  FCHS
  FSTP DWORD PTR [EDX+4]
  FLD DWORD PTR [EAX+8]
  FCHS
  FSTP DWORD PTR [EDX+8]
  FLD DWORD PTR [EAX+12]
  FCHS
  FSTP DWORD PTR [EDX+12]
  {$ELSE}
begin
  result[0] := -v[0];
  result[1] := -v[1];
  result[2] := -v[2];
  result[3] := -v[3];
{$ENDIF}
end;

// NegateVector
//
procedure NegateVector(var v: TAffineVector);
// EAX contains address of v
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]
  FCHS
  FSTP DWORD PTR [EAX]
  FLD DWORD PTR [EAX+4]
  FCHS
  FSTP DWORD PTR [EAX+4]
  FLD DWORD PTR [EAX+8]
  FCHS
  FSTP DWORD PTR [EAX+8]
  {$ELSE}
begin
  v[0] := -v[0];
  v[1] := -v[1];
  v[2] := -v[2];
{$ENDIF}
end;

// NegateVector
//
procedure NegateVector(var v: TVector);
// EAX contains address of v
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]
  FCHS
  FSTP DWORD PTR [EAX]
  FLD DWORD PTR [EAX+4]
  FCHS
  FSTP DWORD PTR [EAX+4]
  FLD DWORD PTR [EAX+8]
  FCHS
  FSTP DWORD PTR [EAX+8]
  FLD DWORD PTR [EAX+12]
  FCHS
  FSTP DWORD PTR [EAX+12]
  {$ELSE}
begin
  v[0] := -v[0];
  v[1] := -v[1];
  v[2] := -v[2];
  v[3] := -v[3];
{$ENDIF}
end;

// NegateVector
//
procedure NegateVector(var v: array of Single);
// EAX contains address of V
// EDX contains highest index in V
{$IFNDEF GEOMETRY_NO_ASM}
asm
@@Loop:
  FLD DWORD PTR [EAX + 4 * EDX]
  FCHS
  WAIT
  FSTP DWORD PTR [EAX + 4 * EDX]
  DEC EDX
  JNS @@Loop
  {$ELSE}
var
  i: Integer;
begin
  for i := Low(v) to High(v) do
    v[i] := -v[i];
{$ENDIF}
end;

// ScaleVector (affine)
//
procedure ScaleVector(var v: TAffineVector; factor: Single);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EAX+4]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EAX+8]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EAX+8]
  {$ELSE}
begin
  v[0] := v[0] * factor;
  v[1] := v[1] * factor;
  v[2] := v[2] * factor;
{$ENDIF}
end;

// ScaleVector (hmg)
//
procedure ScaleVector(var v: TVector; factor: Single);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test     vSIMD, 1
  jz @@FPU

@@3DNow:      // 121824

  db $0F,$6E,$4D,$08       /// movd        mm1, [ebp+8]
  db $0F,$62,$C9           /// punpckldq   mm1, mm1

  db $0F,$6F,$00           /// movq        mm0, [eax]
  db $0F,$6F,$50,$08       /// movq        mm2, [eax+8]
  db $0F,$0F,$C1,$B4       /// pfmul       mm0, mm1
  db $0F,$0F,$D1,$B4       /// pfmul       mm2, mm1
  db $0F,$7F,$00           /// movq        [eax], mm0
  db $0F,$7F,$50,$08       /// movq        [eax+8], mm2

  db $0F,$0E               /// femms

  pop   ebp
  ret   $04

@@FPU:        // 155843
  FLD  DWORD PTR [EBP+8]

  FLD  DWORD PTR [EAX]
  FMUL ST, ST(1)
  FSTP DWORD PTR [EAX]
  FLD  DWORD PTR [EAX+4]
  FMUL ST, ST(1)
  FSTP DWORD PTR [EAX+4]
  FLD  DWORD PTR [EAX+8]
  FMUL ST, ST(1)
  FSTP DWORD PTR [EAX+8]
  FLD  DWORD PTR [EAX+12]
  FMULP
  FSTP DWORD PTR [EAX+12]
  {$ELSE}
begin
  v[0] := v[0] * factor;
  v[1] := v[1] * factor;
  v[2] := v[2] * factor;
  v[3] := v[3] * factor;
{$ENDIF}
end;

// ScaleVector (affine vector)
//
procedure ScaleVector(var v: TAffineVector; const factor: TAffineVector);
begin
  v[0] := v[0] * factor[0];
  v[1] := v[1] * factor[1];
  v[2] := v[2] * factor[2];
end;

// ScaleVector (hmg vector)
//
procedure ScaleVector(var v: TVector; const factor: TVector);
begin
  v[0] := v[0] * factor[0];
  v[1] := v[1] * factor[1];
  v[2] := v[2] * factor[2];
  v[3] := v[3] * factor[3];
end;

// VectorScale (affine)
//
function VectorScale(const v: TAffineVector; factor: Single): TAffineVector;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX]
  FLD  DWORD PTR [EAX+4]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+4]
  FLD  DWORD PTR [EAX+8]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+8]
  {$ELSE}
begin
  result[0] := v[0] * factor;
  result[1] := v[1] * factor;
  result[2] := v[2] * factor;
{$ENDIF}
end;

// VectorScale (proc, affine)
//
procedure VectorScale(const v: TAffineVector; factor: Single;
  var vr: TAffineVector);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX]
  FLD  DWORD PTR [EAX+4]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+4]
  FLD  DWORD PTR [EAX+8]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+8]
  {$ELSE}
begin
  vr[0] := v[0] * factor;
  vr[1] := v[1] * factor;
  vr[2] := v[2] * factor;
{$ENDIF}
end;

// VectorScale (hmg)
//
function VectorScale(const v: TVector; factor: Single): TVector;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX]
  FLD  DWORD PTR [EAX+4]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+4]
  FLD  DWORD PTR [EAX+8]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+8]
  FLD  DWORD PTR [EAX+12]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+12]
  {$ELSE}
begin
  result[0] := v[0] * factor;
  result[1] := v[1] * factor;
  result[2] := v[2] * factor;
  result[3] := v[3] * factor;
{$ENDIF}
end;

// VectorScale (proc, hmg)
//
procedure VectorScale(const v: TVector; factor: Single; var vr: TVector);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX]
  FLD  DWORD PTR [EAX+4]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+4]
  FLD  DWORD PTR [EAX+8]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+8]
  FLD  DWORD PTR [EAX+12]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+12]
  {$ELSE}
begin
  vr[0] := v[0] * factor;
  vr[1] := v[1] * factor;
  vr[2] := v[2] * factor;
  vr[3] := v[3] * factor;
{$ENDIF}
end;

// VectorScale (proc, hmg-affine)
//
procedure VectorScale(const v: TVector; factor: Single; var vr: TAffineVector);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX]
  FLD  DWORD PTR [EAX+4]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+4]
  FLD  DWORD PTR [EAX+8]
  FMUL DWORD PTR [EBP+8]
  FSTP DWORD PTR [EDX+8]
  {$ELSE}
begin
  vr[0] := v[0] * factor;
  vr[1] := v[1] * factor;
  vr[2] := v[2] * factor;
{$ENDIF}
end;

// VectorScale (func, affine)
//
function VectorScale(const v: TAffineVector; const factor: TAffineVector)
  : TAffineVector;
begin
  result[0] := v[0] * factor[0];
  result[1] := v[1] * factor[1];
  result[2] := v[2] * factor[2];
end;

// VectorScale (func, hmg)
//
function VectorScale(const v: TVector; const factor: TVector): TVector;
begin
  result[0] := v[0] * factor[0];
  result[1] := v[1] * factor[1];
  result[2] := v[2] * factor[2];
  result[3] := v[3] * factor[3];
end;

// DivideVector
//
procedure DivideVector(var v: TVector; const divider: TVector);
begin
  v[0] := v[0] / divider[0];
  v[1] := v[1] / divider[1];
  v[2] := v[2] / divider[2];
  v[3] := v[3] / divider[3];
end;

// DivideVector
//
procedure DivideVector(var v: TAffineVector;
  const divider: TAffineVector); overload;
begin
  v[0] := v[0] / divider[0];
  v[1] := v[1] / divider[1];
  v[2] := v[2] / divider[2];
end;

// VectorDivide
//
function VectorDivide(const v: TVector; const divider: TVector)
  : TVector; overload;
begin
  result[0] := v[0] / divider[0];
  result[1] := v[1] / divider[1];
  result[2] := v[2] / divider[2];
  result[3] := v[3] / divider[3];
end;

// VectorDivide
//
function VectorDivide(const v: TAffineVector; const divider: TAffineVector)
  : TAffineVector; overload;
begin
  result[0] := v[0] / divider[0];
  result[1] := v[1] / divider[1];
  result[2] := v[2] / divider[2];
end;

// TexpointEquals
//
function TexpointEquals(const p1, p2: TTexPoint): Boolean;
begin
  result := (p1.S = p2.S) and (p1.T = p2.T);
end;

// RectEquals
//
function RectEquals(const Rect1, Rect2: TRect): Boolean;
begin
  result := (Rect1.Left = Rect2.Left) and (Rect1.Right = Rect2.Right) and
    (Rect1.Top = Rect2.Top) and (Rect1.Bottom = Rect2.Left);
end;

// VectorEquals (hmg vector)
//
function VectorEquals(const V1, V2: TVector): Boolean;
// EAX contains address of v1
// EDX contains highest of v2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  mov ecx, [edx]
  cmp ecx, [eax]
  jne @@Diff
  mov ecx, [edx+$4]
  cmp ecx, [eax+$4]
  jne @@Diff
  mov ecx, [edx+$8]
  cmp ecx, [eax+$8]
  jne @@Diff
  mov ecx, [edx+$C]
  cmp ecx, [eax+$C]
  jne @@Diff
@@Equal:
  mov eax, 1
  ret
@@Diff:
  xor eax, eax
  {$ELSE}
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]) and
    (V1[3] = V2[3]);
{$ENDIF}
end;

// VectorEquals (affine vector)
//
function VectorEquals(const V1, V2: TAffineVector): Boolean;
// EAX contains address of v1
// EDX contains highest of v2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  mov ecx, [edx]
  cmp ecx, [eax]
  jne @@Diff
  mov ecx, [edx+$4]
  cmp ecx, [eax+$4]
  jne @@Diff
  mov ecx, [edx+$8]
  cmp ecx, [eax+$8]
  jne @@Diff
@@Equal:
  mov al, 1
  ret
@@Diff:
  xor eax, eax
@@End:
  {$ELSE}
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]);
{$ENDIF}
end;

// AffineVectorEquals (hmg vector)
//
function AffineVectorEquals(const V1, V2: TVector): Boolean;
// EAX contains address of v1
// EDX contains highest of v2
{$IFNDEF GEOMETRY_NO_ASM}
asm
  mov ecx, [edx]
  cmp ecx, [eax]
  jne @@Diff
  mov ecx, [edx+$4]
  cmp ecx, [eax+$4]
  jne @@Diff
  mov ecx, [edx+$8]
  cmp ecx, [eax+$8]
  jne @@Diff
@@Equal:
  mov eax, 1
  ret
@@Diff:
  xor eax, eax
  {$ELSE}
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]);
{$ENDIF}
end;

// VectorIsNull (hmg)
//
function VectorIsNull(const v: TVector): Boolean;
begin
  result := ((v[0] = 0) and (v[1] = 0) and (v[2] = 0));
end;

// VectorIsNull (affine)
//
function VectorIsNull(const v: TAffineVector): Boolean; overload;
begin
  result := ((v[0] = 0) and (v[1] = 0) and (v[2] = 0));
end;

// VectorSpacing (texpoint)
//
function VectorSpacing(const V1, V2: TTexPoint): Single; overload;
// EAX contains address of v1
// EDX contains highest of v2
// Result  is passed on the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FABS
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FABS
  FADD
  {$ELSE}
begin
  result := Abs(V2.S - V1.S) + Abs(V2.T - V1.T);
{$ENDIF}
end;

// VectorSpacing (affine)
//
function VectorSpacing(const V1, V2: TAffineVector): Single;
// EAX contains address of v1
// EDX contains highest of v2
// Result  is passed on the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FABS
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FABS
  FADD
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FABS
  FADD
  {$ELSE}
begin
  result := Abs(V2[0] - V1[0]) + Abs(V2[1] - V1[1]) + Abs(V2[2] - V1[2]);
{$ENDIF}
end;

// VectorSpacing (Hmg)
//
function VectorSpacing(const V1, V2: TVector): Single;
// EAX contains address of v1
// EDX contains highest of v2
// Result  is passed on the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FABS
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FABS
  FADD
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FABS
  FADD
  FLD  DWORD PTR [EAX+12]
  FSUB DWORD PTR [EDX+12]
  FABS
  FADD
  {$ELSE}
begin
  result := Abs(V2[0] - V1[0]) + Abs(V2[1] - V1[1]) + Abs(V2[2] - V1[2]) +
    Abs(V2[3] - V1[3]);
{$ENDIF}
end;

// VectorDistance (affine)
//
function VectorDistance(const V1, V2: TAffineVector): Single;
// EAX contains address of v1
// EDX contains highest of v2
// Result  is passed on the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FMUL ST, ST
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FMUL ST, ST
  FADD
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FMUL ST, ST
  FADD
  FSQRT
  {$ELSE}
begin
  result := Sqrt(Sqr(V2[0] - V1[0]) + Sqr(V2[1] - V1[1]) + Sqr(V2[2] - V1[2]));
{$ENDIF}
end;

// VectorDistance (hmg)
//
function VectorDistance(const V1, V2: TVector): Single;
// EAX contains address of v1
// EDX contains highest of v2
// Result  is passed on the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FMUL ST, ST
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FMUL ST, ST
  FADD
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FMUL ST, ST
  FADD
  FSQRT
  {$ELSE}
begin
  result := Sqrt(Sqr(V2[0] - V1[0]) + Sqr(V2[1] - V1[1]) + Sqr(V2[2] - V1[2]));
{$ENDIF}
end;

// VectorDistance2 (affine)
//
function VectorDistance2(const V1, V2: TAffineVector): Single;
// EAX contains address of v1
// EDX contains highest of v2
// Result is passed on the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FMUL ST, ST
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FMUL ST, ST
  FADD
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FMUL ST, ST
  FADD
  {$ELSE}
begin
  result := Sqr(V2[0] - V1[0]) + Sqr(V2[1] - V1[1]) + Sqr(V2[2] - V1[2]);
{$ENDIF}
end;

// VectorDistance2 (hmg)
//
function VectorDistance2(const V1, V2: TVector): Single;
// EAX contains address of v1
// EDX contains highest of v2
// Result is passed on the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSUB DWORD PTR [EDX]
  FMUL ST, ST
  FLD  DWORD PTR [EAX+4]
  FSUB DWORD PTR [EDX+4]
  FMUL ST, ST
  FADD
  FLD  DWORD PTR [EAX+8]
  FSUB DWORD PTR [EDX+8]
  FMUL ST, ST
  FADD
  {$ELSE}
begin
  result := Sqr(V2[0] - V1[0]) + Sqr(V2[1] - V1[1]) + Sqr(V2[2] - V1[2]);
{$ENDIF}
end;

// VectorPerpendicular
//
function VectorPerpendicular(const v, n: TAffineVector): TAffineVector;
var
  dot: Single;
begin
  dot := VectorDotProduct(v, n);
  result[x] := v[x] - dot * n[x];
  result[y] := v[y] - dot * n[y];
  result[z] := v[z] - dot * n[z];
end;

// VectorReflect
//
function VectorReflect(const v, n: TAffineVector): TAffineVector;
begin
  result := VectorCombine(v, n, 1, -2 * VectorDotProduct(v, n));
end;

// RotateVector
//
procedure RotateVector(var Vector: TVector; const axis: TAffineVector;
  angle: Single);
var
  rotMatrix: TMatrix4f;
begin
  rotMatrix := CreateRotationMatrix(axis, angle);
  Vector := VectorTransform(Vector, rotMatrix);
end;

// RotateVector
//
procedure RotateVector(var Vector: TVector; const axis: TVector;
  angle: Single); overload;
var
  rotMatrix: TMatrix4f;
begin
  rotMatrix := CreateRotationMatrix(PAffineVector(@axis)^, angle);
  Vector := VectorTransform(Vector, rotMatrix);
end;

// RotateVectorAroundY
//
procedure RotateVectorAroundY(var v: TAffineVector; alpha: Single);
var
  c, S, v0: Single;
begin
  VectorGeometry.SinCos(alpha, S, c);
  v0 := v[0];
  v[0] := c * v0 + S * v[2];
  v[2] := c * v[2] - S * v0;
end;

// VectorRotateAroundX (func)
//
function VectorRotateAroundX(const v: TAffineVector; alpha: Single)
  : TAffineVector;
var
  c, S: Single;
begin
  VectorGeometry.SinCos(alpha, S, c);
  result[0] := v[0];
  result[1] := c * v[1] + S * v[2];
  result[2] := c * v[2] - S * v[1];
end;

// VectorRotateAroundY (func)
//
function VectorRotateAroundY(const v: TAffineVector; alpha: Single)
  : TAffineVector;
var
  c, S: Single;
begin
  VectorGeometry.SinCos(alpha, S, c);
  result[1] := v[1];
  result[0] := c * v[0] + S * v[2];
  result[2] := c * v[2] - S * v[0];
end;

// VectorRotateAroundY (proc)
//
procedure VectorRotateAroundY(const v: TAffineVector; alpha: Single;
  var vr: TAffineVector);
var
  c, S: Single;
begin
  VectorGeometry.SinCos(alpha, S, c);
  vr[1] := v[1];
  vr[0] := c * v[0] + S * v[2];
  vr[2] := c * v[2] - S * v[0];
end;

// VectorRotateAroundZ (func)
//
function VectorRotateAroundZ(const v: TAffineVector; alpha: Single)
  : TAffineVector;
var
  c, S: Single;
begin
  VectorGeometry.SinCos(alpha, S, c);
  result[0] := c * v[0] + S * v[1];
  result[1] := c * v[1] - S * v[0];
  result[2] := v[2];
end;

// AbsVector (hmg)
//
procedure AbsVector(var v: TVector);
begin
  v[0] := Abs(v[0]);
  v[1] := Abs(v[1]);
  v[2] := Abs(v[2]);
  v[3] := Abs(v[3]);
end;

// AbsVector (affine)
//
procedure AbsVector(var v: TAffineVector);
begin
  v[0] := Abs(v[0]);
  v[1] := Abs(v[1]);
  v[2] := Abs(v[2]);
end;

// VectorAbs (hmg)
//
function VectorAbs(const v: TVector): TVector;
begin
  result[0] := Abs(v[0]);
  result[1] := Abs(v[1]);
  result[2] := Abs(v[2]);
  result[3] := Abs(v[3]);
end;

// VectorAbs (affine)
//
function VectorAbs(const v: TAffineVector): TAffineVector;
begin
  result[0] := Abs(v[0]);
  result[1] := Abs(v[1]);
  result[2] := Abs(v[2]);
end;

// SetMatrix (single->double)
//
procedure SetMatrix(var dest: THomogeneousDblMatrix; const src: TMatrix);
var
  i: Integer;
begin
  for i := x to w do
  begin
    dest[i, x] := src[i, x];
    dest[i, y] := src[i, y];
    dest[i, z] := src[i, z];
    dest[i, w] := src[i, w];
  end;
end;

// SetMatrix (hmg->affine)
//
procedure SetMatrix(var dest: TAffineMatrix; const src: TMatrix);
begin
  dest[0, 0] := src[0, 0];
  dest[0, 1] := src[0, 1];
  dest[0, 2] := src[0, 2];
  dest[1, 0] := src[1, 0];
  dest[1, 1] := src[1, 1];
  dest[1, 2] := src[1, 2];
  dest[2, 0] := src[2, 0];
  dest[2, 1] := src[2, 1];
  dest[2, 2] := src[2, 2];
end;

// SetMatrix (affine->hmg)
//
procedure SetMatrix(var dest: TMatrix; const src: TAffineMatrix);
begin
  dest[0, 0] := src[0, 0];
  dest[0, 1] := src[0, 1];
  dest[0, 2] := src[0, 2];
  dest[0, 3] := 0;
  dest[1, 0] := src[1, 0];
  dest[1, 1] := src[1, 1];
  dest[1, 2] := src[1, 2];
  dest[1, 3] := 0;
  dest[2, 0] := src[2, 0];
  dest[2, 1] := src[2, 1];
  dest[2, 2] := src[2, 2];
  dest[2, 3] := 0;
  dest[3, 0] := 0;
  dest[3, 1] := 0;
  dest[3, 2] := 0;
  dest[3, 3] := 1;
end;

// SetMatrixRow
//
procedure SetMatrixRow(var dest: TMatrix; rowNb: Integer; const aRow: TVector);
begin
  dest[0, rowNb] := aRow[0];
  dest[1, rowNb] := aRow[1];
  dest[2, rowNb] := aRow[2];
  dest[3, rowNb] := aRow[3];
end;

// CreateScaleMatrix (affine)
//
function CreateScaleMatrix(const v: TAffineVector): TMatrix;
begin
  result := IdentityHmgMatrix;
  result[x, x] := v[x];
  result[y, y] := v[y];
  result[z, z] := v[z];
end;

// CreateScaleMatrix (Hmg)
//
function CreateScaleMatrix(const v: TVector): TMatrix;
begin
  result := IdentityHmgMatrix;
  result[x, x] := v[x];
  result[y, y] := v[y];
  result[z, z] := v[z];
end;

// CreateTranslationMatrix (affine)
//
function CreateTranslationMatrix(const v: TAffineVector): TMatrix;
begin
  result := IdentityHmgMatrix;
  result[w, x] := v[x];
  result[w, y] := v[y];
  result[w, z] := v[z];
end;

// CreateTranslationMatrix (hmg)
//
function CreateTranslationMatrix(const v: TVector): TMatrix;
begin
  result := IdentityHmgMatrix;
  result[w, x] := v[x];
  result[w, y] := v[y];
  result[w, z] := v[z];
end;

// CreateScaleAndTranslationMatrix
//
function CreateScaleAndTranslationMatrix(const scale, offset: TVector): TMatrix;
begin
  result := IdentityHmgMatrix;
  result[x, x] := scale[x];
  result[w, x] := offset[x];
  result[y, y] := scale[y];
  result[w, y] := offset[y];
  result[z, z] := scale[z];
  result[w, z] := offset[z];
end;

// CreateRotationMatrixX
//
function CreateRotationMatrixX(const sine, cosine: Single): TMatrix;
begin
  result := EmptyHmgMatrix;
  result[x, x] := 1;
  result[y, y] := cosine;
  result[y, z] := sine;
  result[z, y] := -sine;
  result[z, z] := cosine;
  result[w, w] := 1;
end;

// CreateRotationMatrixX
//
function CreateRotationMatrixX(const angle: Single): TMatrix;
var
  S, c: Single;
begin
  VectorGeometry.SinCos(angle, S, c);
  result := CreateRotationMatrixX(S, c);
end;

// CreateRotationMatrixY
//
function CreateRotationMatrixY(const sine, cosine: Single): TMatrix;
begin
  result := EmptyHmgMatrix;
  result[x, x] := cosine;
  result[x, z] := -sine;
  result[y, y] := 1;
  result[z, x] := sine;
  result[z, z] := cosine;
  result[w, w] := 1;
end;

// CreateRotationMatrixY
//
function CreateRotationMatrixY(const angle: Single): TMatrix;
var
  S, c: Single;
begin
  VectorGeometry.SinCos(angle, S, c);
  result := CreateRotationMatrixY(S, c);
end;

// CreateRotationMatrixZ
//
function CreateRotationMatrixZ(const sine, cosine: Single): TMatrix;
begin
  result := EmptyHmgMatrix;
  result[x, x] := cosine;
  result[x, y] := sine;
  result[y, x] := -sine;
  result[y, y] := cosine;
  result[z, z] := 1;
  result[w, w] := 1;
end;

// CreateRotationMatrixZ
//
function CreateRotationMatrixZ(const angle: Single): TMatrix;
var
  S, c: Single;
begin
  VectorGeometry.SinCos(angle, S, c);
  result := CreateRotationMatrixZ(S, c);
end;

// CreateRotationMatrix (affine)
//
function CreateRotationMatrix(const anAxis: TAffineVector;
  angle: Single): TMatrix;
var
  axis: TAffineVector;
  cosine, sine, one_minus_cosine: Single;
begin
  VectorGeometry.SinCos(angle, sine, cosine);
  one_minus_cosine := 1 - cosine;
  axis := VectorNormalize(anAxis);

  result[x, x] := (one_minus_cosine * axis[0] * axis[0]) + cosine;
  result[x, y] := (one_minus_cosine * axis[0] * axis[1]) - (axis[2] * sine);
  result[x, z] := (one_minus_cosine * axis[2] * axis[0]) + (axis[1] * sine);
  result[x, w] := 0;

  result[y, x] := (one_minus_cosine * axis[0] * axis[1]) + (axis[2] * sine);
  result[y, y] := (one_minus_cosine * axis[1] * axis[1]) + cosine;
  result[y, z] := (one_minus_cosine * axis[1] * axis[2]) - (axis[0] * sine);
  result[y, w] := 0;

  result[z, x] := (one_minus_cosine * axis[2] * axis[0]) - (axis[1] * sine);
  result[z, y] := (one_minus_cosine * axis[1] * axis[2]) + (axis[0] * sine);
  result[z, z] := (one_minus_cosine * axis[2] * axis[2]) + cosine;
  result[z, w] := 0;

  result[w, x] := 0;
  result[w, y] := 0;
  result[w, z] := 0;
  result[w, w] := 1;
end;

// CreateRotationMatrix (hmg)
//
function CreateRotationMatrix(const anAxis: TVector; angle: Single): TMatrix;
begin
  result := CreateRotationMatrix(PAffineVector(@anAxis)^, angle);
end;

// CreateAffineRotationMatrix
//
function CreateAffineRotationMatrix(const anAxis: TAffineVector; angle: Single)
  : TAffineMatrix;
var
  axis: TAffineVector;
  cosine, sine, one_minus_cosine: Single;
begin
  VectorGeometry.SinCos(angle, sine, cosine);
  one_minus_cosine := 1 - cosine;
  axis := VectorNormalize(anAxis);

  result[x, x] := (one_minus_cosine * Sqr(axis[0])) + cosine;
  result[x, y] := (one_minus_cosine * axis[0] * axis[1]) - (axis[2] * sine);
  result[x, z] := (one_minus_cosine * axis[2] * axis[0]) + (axis[1] * sine);

  result[y, x] := (one_minus_cosine * axis[0] * axis[1]) + (axis[2] * sine);
  result[y, y] := (one_minus_cosine * Sqr(axis[1])) + cosine;
  result[y, z] := (one_minus_cosine * axis[1] * axis[2]) - (axis[0] * sine);

  result[z, x] := (one_minus_cosine * axis[2] * axis[0]) - (axis[1] * sine);
  result[z, y] := (one_minus_cosine * axis[1] * axis[2]) + (axis[0] * sine);
  result[z, z] := (one_minus_cosine * Sqr(axis[2])) + cosine;
end;

// MatrixMultiply (3x3 func)
//
function MatrixMultiply(const m1, m2: TAffineMatrix): TAffineMatrix;
begin
{$IFNDEF GEOMETRY_NO_ASM}
  if vSIMD = 1 then
  begin
    asm
      db $0F,$0E               /// femms
      xchg eax, ecx

      db $0F,$6E,$7A,$08       /// movd        mm7,[edx+8]
      db $0F,$6E,$72,$20       /// movd        mm6,[edx+32]
      db $0F,$62,$7A,$14       /// punpckldq   mm7,[edx+20]
      db $0F,$6F,$01           /// movq        mm0,[ecx]
      db $0F,$6E,$59,$08       /// movd        mm3,[ecx+8]
      db $0F,$6F,$C8           /// movq        mm1,mm0
      db $0F,$0F,$C7,$B4       /// pfmul       mm0,mm7
      db $0F,$6F,$D1           /// movq        mm2,mm1
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$0F,$0A,$B4       /// pfmul       mm1,[edx]
      db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
      db $0F,$0F,$52,$0C,$B4   /// pfmul       mm2,[edx+12]
      db $0F,$0F,$C0,$AE       /// pfacc       mm0,mm0
      db $0F,$6F,$E3           /// movq        mm4,mm3
      db $0F,$62,$DB           /// punpckldq   mm3,mm3
      db $0F,$0F,$5A,$18,$B4   /// pfmul       mm3,[edx+24]
      db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
      db $0F,$0F,$E6,$B4       /// pfmul       mm4,mm6
      db $0F,$6F,$69,$0C       /// movq        mm5,[ecx+12]
      db $0F,$0F,$D3,$9E       /// pfadd       mm2,mm3
      db $0F,$6E,$59,$14       /// movd        mm3,[ecx+20]
      db $0F,$0F,$E0,$9E       /// pfadd       mm4,mm0
      db $0F,$6F,$CD           /// movq        mm1,mm5
      db $0F,$7F,$10           /// movq        [eax],mm2
      db $0F,$0F,$EF,$B4       /// pfmul       mm5,mm7
      db $0F,$7E,$60,$08       /// movd        [eax+8],mm4
      db $0F,$6F,$D1           /// movq        mm2,mm1
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$6F,$41,$18       /// movq        mm0,[ecx+24]
      db $0F,$0F,$0A,$B4       /// pfmul       mm1,[edx]
      db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
      db $0F,$0F,$52,$0C,$B4   /// pfmul       mm2,[edx+12]
      db $0F,$0F,$ED,$AE       /// pfacc       mm5,mm5
      db $0F,$6F,$E3           /// movq        mm4,mm3
      db $0F,$62,$DB           /// punpckldq   mm3,mm3
      db $0F,$0F,$5A,$18,$B4   /// pfmul       mm3,[edx+24]
      db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
      db $0F,$0F,$E6,$B4       /// pfmul       mm4,mm6
      db $0F,$6F,$C8           /// movq        mm1,mm0
      db $0F,$0F,$D3,$9E       /// pfadd       mm2,mm3
      db $0F,$6E,$59,$20       /// movd        mm3,[ecx+32]
      db $0F,$0F,$E5,$9E       /// pfadd       mm4,mm5
      db $0F,$0F,$C7,$B4       /// pfmul       mm0,mm7
      db $0F,$7F,$50,$0C       /// movq        [eax+12],mm2
      db $0F,$6F,$D1           /// movq        mm2,mm1
      db $0F,$7E,$60,$14       /// movd        [eax+20],mm4
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$0F,$0A,$B4       /// pfmul       mm1,[edx]
      db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
      db $0F,$0F,$52,$0C,$B4   /// pfmul       mm2,[edx+12]
      db $0F,$0F,$C0,$AE       /// pfacc       mm0,mm0
      db $0F,$0F,$F3,$B4       /// pfmul       mm6,mm3
      db $0F,$62,$DB           /// punpckldq   mm3,mm3
      db $0F,$0F,$5A,$18,$B4   /// pfmul       mm3,[edx+24]
      db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
      db $0F,$0F,$F0,$9E       /// pfadd       mm6,mm0
      db $0F,$0F,$D3,$9E       /// pfadd       mm2,mm3

      db $0F,$7E,$70,$20       /// movd        [eax+32],mm6
      db $0F,$7F,$50,$18       /// movq        [eax+24],mm2
      db $0F,$0E               /// femms
    end;
  end
  else {$ENDIF} begin
    result[x, x] := m1[x, x] * m2[x, x] + m1[x, y] * m2[y, x] + m1[x, z]
      * m2[z, x];
    result[x, y] := m1[x, x] * m2[x, y] + m1[x, y] * m2[y, y] + m1[x, z]
      * m2[z, y];
    result[x, z] := m1[x, x] * m2[x, z] + m1[x, y] * m2[y, z] + m1[x, z]
      * m2[z, z];
    result[y, x] := m1[y, x] * m2[x, x] + m1[y, y] * m2[y, x] + m1[y, z]
      * m2[z, x];
    result[y, y] := m1[y, x] * m2[x, y] + m1[y, y] * m2[y, y] + m1[y, z]
      * m2[z, y];
    result[y, z] := m1[y, x] * m2[x, z] + m1[y, y] * m2[y, z] + m1[y, z]
      * m2[z, z];
    result[z, x] := m1[z, x] * m2[x, x] + m1[z, y] * m2[y, x] + m1[z, z]
      * m2[z, x];
    result[z, y] := m1[z, x] * m2[x, y] + m1[z, y] * m2[y, y] + m1[z, z]
      * m2[z, y];
    result[z, z] := m1[z, x] * m2[x, z] + m1[z, y] * m2[y, z] + m1[z, z]
      * m2[z, z];
  end;
end;

// MatrixMultiply (4x4, func)
//
function MatrixMultiply(const m1, m2: TMatrix): TMatrix;
begin
{$IFNDEF GEOMETRY_NO_ASM}
  if vSIMD = 1 then
  begin
    asm
      xchg eax, ecx
      db $0F,$6F,$01           /// movq        mm0,[ecx]
      db $0F,$6F,$49,$08       /// movq        mm1,[ecx+8]
      db $0F,$6F,$22           /// movq        mm4,[edx]
      db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
      db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
      db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
      db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
      db $0F,$62,$C0           /// punpckldq   mm0,mm0
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
      db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
      db $0F,$0F,$42,$08,$B4   /// pfmul       mm0, [edx+8]
      db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
      db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
      db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
      db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
      db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
      db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
      db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
      db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
      db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
      db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
      db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
      db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
      db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
      db $0F,$6F,$41,$10       /// movq        mm0,[ecx+16]
      db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2
      db $0F,$6F,$49,$18       /// movq        mm1,[ecx+24]
      db $0F,$7F,$38           /// movq        [eax],mm7
      db $0F,$6F,$22           /// movq        mm4,[edx]
      db $0F,$7F,$58,$08       /// movq        [eax+8],mm3

      db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
      db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
      db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
      db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
      db $0F,$62,$C0           /// punpckldq   mm0,mm0
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
      db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
      db $0F,$0F,$42,$08,$B4   /// pfmul       mm0,[edx+8]
      db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
      db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
      db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
      db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
      db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
      db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
      db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
      db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
      db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
      db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
      db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
      db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
      db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
      db $0F,$6F,$41,$20       /// movq        mm0,[ecx+32]
      db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2
      db $0F,$6F,$49,$28       /// movq        mm1,[ecx+40]
      db $0F,$7F,$78,$10       /// movq        [eax+16],mm7
      db $0F,$6F,$22           /// movq        mm4,[edx]
      db $0F,$7F,$58,$18       /// movq        [eax+24],mm3

      db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
      db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
      db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
      db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
      db $0F,$62,$C0           /// punpckldq   mm0,mm0
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
      db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
      db $0F,$0F,$42,$08,$B4   /// pfmul       mm0,[edx+8]
      db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
      db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
      db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
      db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
      db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
      db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
      db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
      db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
      db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
      db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
      db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
      db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
      db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
      db $0F,$6F,$41,$30       /// movq        mm0,[ecx+48]
      db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2
      db $0F,$6F,$49,$38       /// movq        mm1,[ecx+56]
      db $0F,$7F,$78,$20       /// movq        [eax+32],mm7
      db $0F,$6F,$22           /// movq        mm4,[edx]
      db $0F,$7F,$58,$28       /// movq        [eax+40],mm3

      db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
      db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
      db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
      db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
      db $0F,$62,$C0           /// punpckldq   mm0,mm0
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
      db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
      db $0F,$0F,$42,$08,$B4   /// pfmul       mm0,[edx+8]
      db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
      db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
      db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
      db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
      db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
      db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
      db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
      db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
      db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
      db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
      db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
      db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
      db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
      db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2
      db $0F,$7F,$78,$30       /// movq        [eax+48],mm7
      db $0F,$7F,$58,$38       /// movq        [eax+56],mm3
      db $0F,$0E               /// femms
    end;
  end
  else {$ENDIF} begin
    result[x, x] := m1[x, x] * m2[x, x] + m1[x, y] * m2[y, x] + m1[x, z] *
      m2[z, x] + m1[x, w] * m2[w, x];
    result[x, y] := m1[x, x] * m2[x, y] + m1[x, y] * m2[y, y] + m1[x, z] *
      m2[z, y] + m1[x, w] * m2[w, y];
    result[x, z] := m1[x, x] * m2[x, z] + m1[x, y] * m2[y, z] + m1[x, z] *
      m2[z, z] + m1[x, w] * m2[w, z];
    result[x, w] := m1[x, x] * m2[x, w] + m1[x, y] * m2[y, w] + m1[x, z] *
      m2[z, w] + m1[x, w] * m2[w, w];
    result[y, x] := m1[y, x] * m2[x, x] + m1[y, y] * m2[y, x] + m1[y, z] *
      m2[z, x] + m1[y, w] * m2[w, x];
    result[y, y] := m1[y, x] * m2[x, y] + m1[y, y] * m2[y, y] + m1[y, z] *
      m2[z, y] + m1[y, w] * m2[w, y];
    result[y, z] := m1[y, x] * m2[x, z] + m1[y, y] * m2[y, z] + m1[y, z] *
      m2[z, z] + m1[y, w] * m2[w, z];
    result[y, w] := m1[y, x] * m2[x, w] + m1[y, y] * m2[y, w] + m1[y, z] *
      m2[z, w] + m1[y, w] * m2[w, w];
    result[z, x] := m1[z, x] * m2[x, x] + m1[z, y] * m2[y, x] + m1[z, z] *
      m2[z, x] + m1[z, w] * m2[w, x];
    result[z, y] := m1[z, x] * m2[x, y] + m1[z, y] * m2[y, y] + m1[z, z] *
      m2[z, y] + m1[z, w] * m2[w, y];
    result[z, z] := m1[z, x] * m2[x, z] + m1[z, y] * m2[y, z] + m1[z, z] *
      m2[z, z] + m1[z, w] * m2[w, z];
    result[z, w] := m1[z, x] * m2[x, w] + m1[z, y] * m2[y, w] + m1[z, z] *
      m2[z, w] + m1[z, w] * m2[w, w];
    result[w, x] := m1[w, x] * m2[x, x] + m1[w, y] * m2[y, x] + m1[w, z] *
      m2[z, x] + m1[w, w] * m2[w, x];
    result[w, y] := m1[w, x] * m2[x, y] + m1[w, y] * m2[y, y] + m1[w, z] *
      m2[z, y] + m1[w, w] * m2[w, y];
    result[w, z] := m1[w, x] * m2[x, z] + m1[w, y] * m2[y, z] + m1[w, z] *
      m2[z, z] + m1[w, w] * m2[w, z];
    result[w, w] := m1[w, x] * m2[x, w] + m1[w, y] * m2[y, w] + m1[w, z] *
      m2[z, w] + m1[w, w] * m2[w, w];
  end;
end;

// MatrixMultiply (4x4, proc)
//
procedure MatrixMultiply(const m1, m2: TMatrix; var MResult: TMatrix);
begin
  MResult := MatrixMultiply(m1, m2);
end;

// VectorTransform
//
function VectorTransform(const v: TVector; const M: TMatrix): TVector;
begin
{$IFNDEF GEOMETRY_NO_ASM}
  if vSIMD = 1 then
  begin
    asm
      db $0F,$6F,$00           /// movq        mm0,[eax]
      db $0F,$6F,$48,$08       /// movq        mm1,[eax+8]
      db $0F,$6F,$22           /// movq        mm4,[edx]
      db $0F,$6A,$D0           /// punpckhdq   mm2,mm0
      db $0F,$6F,$6A,$10       /// movq        mm5,[edx+16]
      db $0F,$62,$C0           /// punpckldq   mm0,mm0
      db $0F,$6F,$72,$20       /// movq        mm6,[edx+32]
      db $0F,$0F,$E0,$B4       /// pfmul       mm4,mm0
      db $0F,$6F,$7A,$30       /// movq        mm7,[edx+48]
      db $0F,$6A,$D2           /// punpckhdq   mm2,mm2
      db $0F,$6A,$D9           /// punpckhdq   mm3,mm1
      db $0F,$0F,$EA,$B4       /// pfmul       mm5,mm2
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$0F,$42,$08,$B4   /// pfmul       mm0,[edx+8]
      db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
      db $0F,$0F,$52,$18,$B4   /// pfmul       mm2,[edx+24]
      db $0F,$0F,$F1,$B4       /// pfmul       mm6,mm1
      db $0F,$0F,$EC,$9E       /// pfadd       mm5,mm4
      db $0F,$0F,$4A,$28,$B4   /// pfmul       mm1,[edx+40]
      db $0F,$0F,$D0,$9E       /// pfadd       mm2,mm0
      db $0F,$0F,$FB,$B4       /// pfmul       mm7,mm3
      db $0F,$0F,$F5,$9E       /// pfadd       mm6,mm5
      db $0F,$0F,$5A,$38,$B4   /// pfmul       mm3,[edx+56]
      db $0F,$0F,$D1,$9E       /// pfadd       mm2,mm1
      db $0F,$0F,$FE,$9E       /// pfadd       mm7,mm6
      db $0F,$0F,$DA,$9E       /// pfadd       mm3,mm2

      db $0F,$7F,$39           /// movq        [ecx],mm7
      db $0F,$7F,$59,$08       /// movq        [ecx+8],mm3
      db $0F,$0E               /// femms
    end
  end
  else {$ENDIF} begin
    result[x] := v[x] * M[x, x] + v[y] * M[y, x] + v[z] * M[z, x] + v[w]
      * M[w, x];
    result[y] := v[x] * M[x, y] + v[y] * M[y, y] + v[z] * M[z, y] + v[w]
      * M[w, y];
    result[z] := v[x] * M[x, z] + v[y] * M[y, z] + v[z] * M[z, z] + v[w]
      * M[w, z];
    result[w] := v[x] * M[x, w] + v[y] * M[y, w] + v[z] * M[z, w] + v[w]
      * M[w, w];
  end;
end;

// VectorTransform
//
function VectorTransform(const v: TVector; const M: TAffineMatrix): TVector;
begin
  result[x] := v[x] * M[x, x] + v[y] * M[y, x] + v[z] * M[z, x];
  result[y] := v[x] * M[x, y] + v[y] * M[y, y] + v[z] * M[z, y];
  result[z] := v[x] * M[x, z] + v[y] * M[y, z] + v[z] * M[z, z];
  result[w] := v[w];
end;

// VectorTransform
//
function VectorTransform(const v: TAffineVector; const M: TMatrix)
  : TAffineVector;
begin
  result[x] := v[x] * M[x, x] + v[y] * M[y, x] + v[z] * M[z, x] + M[w, x];
  result[y] := v[x] * M[x, y] + v[y] * M[y, y] + v[z] * M[z, y] + M[w, y];
  result[z] := v[x] * M[x, z] + v[y] * M[y, z] + v[z] * M[z, z] + M[w, z];
end;

// VectorTransform
//
function VectorTransform(const v: TAffineVector; const M: TAffineMatrix)
  : TAffineVector;
begin
{$IFNDEF GEOMETRY_NO_ASM}
  if vSIMD = 1 then
  begin
    asm
      db $0F,$6F,$00           /// movq        mm0,[eax]
      db $0F,$6E,$48,$08       /// movd        mm1,[eax+8]
      db $0F,$6E,$62,$08       /// movd        mm4,[edx+8]
      db $0F,$6F,$D8           /// movq        mm3,mm0
      db $0F,$6E,$52,$20       /// movd        mm2,[edx+32]
      db $0F,$62,$C0           /// punpckldq   mm0,mm0
      db $0F,$62,$62,$14       /// punpckldq   mm4,[edx+20]
      db $0F,$0F,$02,$B4       /// pfmul       mm0,[edx]
      db $0F,$6A,$DB           /// punpckhdq   mm3,mm3
      db $0F,$0F,$D1,$B4       /// pfmul       mm2,mm1
      db $0F,$62,$C9           /// punpckldq   mm1,mm1
      db $0F,$0F,$20,$B4       /// pfmul       mm4,[eax]
      db $0F,$0F,$5A,$0C,$B4   /// pfmul       mm3,[edx+12]
      db $0F,$0F,$4A,$18,$B4   /// pfmul       mm1,[edx+24]
      db $0F,$0F,$E4,$AE       /// pfacc       mm4,mm4
      db $0F,$0F,$D8,$9E       /// pfadd       mm3,mm0
      db $0F,$0F,$E2,$9E       /// pfadd       mm4,mm2
      db $0F,$0F,$D9,$9E       /// pfadd       mm3,mm1

      db $0F,$7E,$61,$08       /// movd        [ecx+8],mm4
      db $0F,$7F,$19           /// movq        [ecx],mm3
      db $0F,$0E               /// femms
    end;
  end
  else {$ENDIF} begin
    result[x] := v[x] * M[x, x] + v[y] * M[y, x] + v[z] * M[z, x];
    result[y] := v[x] * M[x, y] + v[y] * M[y, y] + v[z] * M[z, y];
    result[z] := v[x] * M[x, z] + v[y] * M[y, z] + v[z] * M[z, z];
  end;
end;

// MatrixDeterminant (affine)
//
function MatrixDeterminant(const M: TAffineMatrix): Single;
begin
  result := M[x, x] * (M[y, y] * M[z, z] - M[z, y] * M[y, z]) - M[x, y] *
    (M[y, x] * M[z, z] - M[z, x] * M[y, z]) + M[x, z] *
    (M[y, x] * M[z, y] - M[z, x] * M[y, y]);
end;

// MatrixDetInternal
//
function MatrixDetInternal(const a1, a2, a3, b1, b2, b3, c1, c2,
  c3: Single): Single;
// internal version for the determinant of a 3x3 matrix
begin
  result := a1 * (b2 * c3 - b3 * c2) - b1 * (a2 * c3 - a3 * c2) + c1 *
    (a2 * b3 - a3 * b2);
end;

// MatrixDeterminant (hmg)
//
function MatrixDeterminant(const M: TMatrix): Single;
begin
  result := M[x, x] * MatrixDetInternal(M[y, y], M[z, y], M[w, y], M[y, z],
    M[z, z], M[w, z], M[y, w], M[z, w], M[w, w]) - M[x, y] *
    MatrixDetInternal(M[y, x], M[z, x], M[w, x], M[y, z], M[z, z], M[w, z],
    M[y, w], M[z, w], M[w, w]) + M[x, z] * MatrixDetInternal(M[y, x], M[z, x],
    M[w, x], M[y, y], M[z, y], M[w, y], M[y, w], M[z, w], M[w, w]) - M[x, w] *
    MatrixDetInternal(M[y, x], M[z, x], M[w, x], M[y, y], M[z, y], M[w, y],
    M[y, z], M[z, z], M[w, z]);
end;

// AdjointMatrix
//
procedure AdjointMatrix(var M: TMatrix);
var
  a1, a2, a3, a4, b1, b2, b3, b4, c1, c2, c3, c4, d1, d2, d3, d4: Single;
begin
  a1 := M[x, x];
  b1 := M[x, y];
  c1 := M[x, z];
  d1 := M[x, w];
  a2 := M[y, x];
  b2 := M[y, y];
  c2 := M[y, z];
  d2 := M[y, w];
  a3 := M[z, x];
  b3 := M[z, y];
  c3 := M[z, z];
  d3 := M[z, w];
  a4 := M[w, x];
  b4 := M[w, y];
  c4 := M[w, z];
  d4 := M[w, w];

  // row column labeling reversed since we transpose rows & columns
  M[x, x] := MatrixDetInternal(b2, b3, b4, c2, c3, c4, d2, d3, d4);
  M[y, x] := -MatrixDetInternal(a2, a3, a4, c2, c3, c4, d2, d3, d4);
  M[z, x] := MatrixDetInternal(a2, a3, a4, b2, b3, b4, d2, d3, d4);
  M[w, x] := -MatrixDetInternal(a2, a3, a4, b2, b3, b4, c2, c3, c4);

  M[x, y] := -MatrixDetInternal(b1, b3, b4, c1, c3, c4, d1, d3, d4);
  M[y, y] := MatrixDetInternal(a1, a3, a4, c1, c3, c4, d1, d3, d4);
  M[z, y] := -MatrixDetInternal(a1, a3, a4, b1, b3, b4, d1, d3, d4);
  M[w, y] := MatrixDetInternal(a1, a3, a4, b1, b3, b4, c1, c3, c4);

  M[x, z] := MatrixDetInternal(b1, b2, b4, c1, c2, c4, d1, d2, d4);
  M[y, z] := -MatrixDetInternal(a1, a2, a4, c1, c2, c4, d1, d2, d4);
  M[z, z] := MatrixDetInternal(a1, a2, a4, b1, b2, b4, d1, d2, d4);
  M[w, z] := -MatrixDetInternal(a1, a2, a4, b1, b2, b4, c1, c2, c4);

  M[x, w] := -MatrixDetInternal(b1, b2, b3, c1, c2, c3, d1, d2, d3);
  M[y, w] := MatrixDetInternal(a1, a2, a3, c1, c2, c3, d1, d2, d3);
  M[z, w] := -MatrixDetInternal(a1, a2, a3, b1, b2, b3, d1, d2, d3);
  M[w, w] := MatrixDetInternal(a1, a2, a3, b1, b2, b3, c1, c2, c3);
end;

// AdjointMatrix (affine)
//
procedure AdjointMatrix(var M: TAffineMatrix);
var
  a1, a2, a3, b1, b2, b3, c1, c2, c3: Single;
begin
  a1 := M[x, x];
  a2 := M[x, y];
  a3 := M[x, z];
  b1 := M[y, x];
  b2 := M[y, y];
  b3 := M[y, z];
  c1 := M[z, x];
  c2 := M[z, y];
  c3 := M[z, z];
  M[x, x] := (b2 * c3 - c2 * b3);
  M[y, x] := -(b1 * c3 - c1 * b3);
  M[z, x] := (b1 * c2 - c1 * b2);

  M[x, y] := -(a2 * c3 - c2 * a3);
  M[y, y] := (a1 * c3 - c1 * a3);
  M[z, y] := -(a1 * c2 - c1 * a2);

  M[x, z] := (a2 * b3 - b2 * a3);
  M[y, z] := -(a1 * b3 - b1 * a3);
  M[z, z] := (a1 * b2 - b1 * a2);
end;

// ScaleMatrix (affine)
//
procedure ScaleMatrix(var M: TAffineMatrix; const factor: Single);
var
  i: Integer;
begin
  for i := 0 to 2 do
  begin
    M[i, 0] := M[i, 0] * factor;
    M[i, 1] := M[i, 1] * factor;
    M[i, 2] := M[i, 2] * factor;
  end;
end;

// ScaleMatrix (hmg)
//
procedure ScaleMatrix(var M: TMatrix; const factor: Single);
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

// TranslateMatrix (affine vec)
//
procedure TranslateMatrix(var M: TMatrix; const v: TAffineVector);
begin
  M[3][0] := M[3][0] + v[0];
  M[3][1] := M[3][1] + v[1];
  M[3][2] := M[3][2] + v[2];
end;

// TranslateMatrix
//
procedure TranslateMatrix(var M: TMatrix; const v: TVector);
begin
  M[3][0] := M[3][0] + v[0];
  M[3][1] := M[3][1] + v[1];
  M[3][2] := M[3][2] + v[2];
end;

// NormalizeMatrix
//
procedure NormalizeMatrix(var M: TMatrix);
begin
  M[0][3] := 0;
  NormalizeVector(M[0]);
  M[1][3] := 0;
  NormalizeVector(M[1]);
  M[2] := VectorCrossProduct(M[0], M[1]);
  M[0] := VectorCrossProduct(M[1], M[2]);
  M[3] := WHmgVector;
end;

// TransposeMatrix
//
procedure TransposeMatrix(var M: TAffineMatrix);
var
  f: Single;
begin
  f := M[0, 1];
  M[0, 1] := M[1, 0];
  M[1, 0] := f;
  f := M[0, 2];
  M[0, 2] := M[2, 0];
  M[2, 0] := f;
  f := M[1, 2];
  M[1, 2] := M[2, 1];
  M[2, 1] := f;
end;

// TransposeMatrix
//
procedure TransposeMatrix(var M: TMatrix);
var
  f: Single;
begin
  f := M[0, 1];
  M[0, 1] := M[1, 0];
  M[1, 0] := f;
  f := M[0, 2];
  M[0, 2] := M[2, 0];
  M[2, 0] := f;
  f := M[0, 3];
  M[0, 3] := M[3, 0];
  M[3, 0] := f;
  f := M[1, 2];
  M[1, 2] := M[2, 1];
  M[2, 1] := f;
  f := M[1, 3];
  M[1, 3] := M[3, 1];
  M[3, 1] := f;
  f := M[2, 3];
  M[2, 3] := M[3, 2];
  M[3, 2] := f;
end;

// InvertMatrix
//
procedure InvertMatrix(var M: TMatrix);
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

// MatrixInvert
//
function MatrixInvert(const M: TMatrix): TMatrix;
begin
  result := M;
  InvertMatrix(result);
end;

// InvertMatrix (affine)
//
procedure InvertMatrix(var M: TAffineMatrix);
var
  det: Single;
begin
  det := MatrixDeterminant(M);
  if Abs(det) < EPSILON then
    M := IdentityMatrix
  else
  begin
    AdjointMatrix(M);
    ScaleMatrix(M, 1 / det);
  end;
end;

// MatrixInvert (affine)
//
function MatrixInvert(const M: TAffineMatrix): TAffineMatrix;
begin
  result := M;
  InvertMatrix(result);
end;

// transpose_scale_m33
//
procedure transpose_scale_m33(const src: TMatrix; var dest: TMatrix;
  var scale: Single);
// EAX src
// EDX dest
// ECX scale
begin
{$IFNDEF GEOMETRY_NO_ASM}
  asm
    // dest[0][0]:=scale*src[0][0];
    fld   dword ptr [ecx]
    fld   st(0)
    fmul  dword ptr [eax]
    fstp  dword ptr [edx]
    // dest[1][0]:=scale*src[0][1];
    fld   st(0)
    fmul  dword ptr [eax+4]
    fstp  dword ptr [edx+16]
    // dest[2][0]:=scale*src[0][2];
    fmul  dword ptr [eax+8]
    fstp  dword ptr [edx+32]

    // dest[0][1]:=scale*src[1][0];
    fld   dword ptr [ecx]
    fld   st(0)
    fmul  dword ptr [eax+16]
    fstp  dword ptr [edx+4]
    // dest[1][1]:=scale*src[1][1];
    fld   st(0)
    fmul  dword ptr [eax+20]
    fstp  dword ptr [edx+20]
    // dest[2][1]:=scale*src[1][2];
    fmul  dword ptr [eax+24]
    fstp  dword ptr [edx+36]

    // dest[0][2]:=scale*src[2][0];
    fld   dword ptr [ecx]
    fld   st(0)
    fmul  dword ptr [eax+32]
    fstp  dword ptr [edx+8]
    // dest[1][2]:=scale*src[2][1];
    fld   st(0)
    fmul  dword ptr [eax+36]
    fstp  dword ptr [edx+24]
    // dest[2][2]:=scale*src[2][2];
    fmul  dword ptr [eax+40]
    fstp  dword ptr [edx+40]
  end;
{$ELSE}
  dest[0][0] := scale * src[0][0];
  dest[1][0] := scale * src[0][1];
  dest[2][0] := scale * src[0][2];
  dest[0][1] := scale * src[1][0];
  dest[1][1] := scale * src[1][1];
  dest[2][1] := scale * src[1][2];
  dest[0][2] := scale * src[2][0];
  dest[1][2] := scale * src[2][1];
  dest[2][2] := scale * src[2][2];
{$ENDIF}
end;

// AnglePreservingMatrixInvert
//
function AnglePreservingMatrixInvert(const mat: TMatrix): TMatrix;
var
  scale: Single;
begin
  scale := VectorNorm(mat[0]);

  // Is the submatrix A singular?
  if Abs(scale) < EPSILON then
  begin
    // Matrix M has no inverse
    result := IdentityHmgMatrix;
    Exit;
  end
  else
  begin
    // Calculate the inverse of the square of the isotropic scale factor
    scale := 1.0 / scale;
  end;

  // Fill in last row while CPU is busy with the division
  result[0][3] := 0.0;
  result[1][3] := 0.0;
  result[2][3] := 0.0;
  result[3][3] := 1.0;

  // Transpose and scale the 3 by 3 upper-left submatrix
  transpose_scale_m33(mat, result, scale);

  // Calculate -(transpose(A) / s*s) C
  result[3][0] := -(result[0][0] * mat[3][0] + result[1][0] * mat[3][1] +
    result[2][0] * mat[3][2]);
  result[3][1] := -(result[0][1] * mat[3][0] + result[1][1] * mat[3][1] +
    result[2][1] * mat[3][2]);
  result[3][2] := -(result[0][2] * mat[3][0] + result[1][2] * mat[3][1] +
    result[2][2] * mat[3][2]);
end;

// MatrixDecompose
//
function MatrixDecompose(const M: TMatrix; var Tran: TTransformations): Boolean;
var
  i, J: Integer;
  LocMat, pmat, invpmat: TMatrix;
  prhs, psol: TVector;
  row0, row1, row2: TAffineVector;
  f: Single;
begin
  result := False;
  LocMat := M;
  // normalize the matrix
  if LocMat[w, w] = 0 then
    Exit;
  for i := 0 to 3 do
    for J := 0 to 3 do
      LocMat[i, J] := LocMat[i, J] / LocMat[w, w];

  // pmat is used to solve for perspective, but it also provides
  // an easy way to test for singularity of the upper 3x3 component.

  pmat := LocMat;
  for i := 0 to 2 do
    pmat[i, w] := 0;
  pmat[w, w] := 1;

  if MatrixDeterminant(pmat) = 0 then
    Exit;

  // First, isolate perspective.  This is the messiest.
  if (LocMat[x, w] <> 0) or (LocMat[y, w] <> 0) or (LocMat[z, w] <> 0) then
  begin
    // prhs is the right hand side of the equation.
    prhs[x] := LocMat[x, w];
    prhs[y] := LocMat[y, w];
    prhs[z] := LocMat[z, w];
    prhs[w] := LocMat[w, w];

    // Solve the equation by inverting pmat and multiplying
    // prhs by the inverse.  (This is the easiest way, not
    // necessarily the best.)

    invpmat := pmat;
    InvertMatrix(invpmat);
    TransposeMatrix(invpmat);
    psol := VectorTransform(prhs, invpmat);

    // stuff the answer away
    Tran[ttPerspectiveX] := psol[x];
    Tran[ttPerspectiveY] := psol[y];
    Tran[ttPerspectiveZ] := psol[z];
    Tran[ttPerspectiveW] := psol[w];

    // clear the perspective partition
    LocMat[x, w] := 0;
    LocMat[y, w] := 0;
    LocMat[z, w] := 0;
    LocMat[w, w] := 1;
  end
  else
  begin
    // no perspective
    Tran[ttPerspectiveX] := 0;
    Tran[ttPerspectiveY] := 0;
    Tran[ttPerspectiveZ] := 0;
    Tran[ttPerspectiveW] := 0;
  end;

  // next take care of translation (easy)
  for i := 0 to 2 do
  begin
    Tran[TTransType(Ord(ttTranslateX) + i)] := LocMat[w, i];
    LocMat[w, i] := 0;
  end;

  // now get scale and shear
  SetVector(row0, LocMat[0]);
  SetVector(row1, LocMat[1]);
  SetVector(row2, LocMat[2]);

  // compute X scale factor and normalize first row
  Tran[ttScaleX] := VectorNorm(row0);
  ScaleVector(row0, RSqrt(Tran[ttScaleX]));

  // compute XY shear factor and make 2nd row orthogonal to 1st
  Tran[ttShearXY] := VectorDotProduct(row0, row1);
  f := -Tran[ttShearXY];
  CombineVector(row1, row0, f);

  // now, compute Y scale and normalize 2nd row
  Tran[ttScaleY] := VectorNorm(row1);
  ScaleVector(row1, RSqrt(Tran[ttScaleY]));
  Tran[ttShearXY] := Tran[ttShearXY] / Tran[ttScaleY];

  // compute XZ and YZ shears, orthogonalize 3rd row
  Tran[ttShearXZ] := VectorDotProduct(row0, row2);
  f := -Tran[ttShearXZ];
  CombineVector(row2, row0, f);
  Tran[ttShearYZ] := VectorDotProduct(row1, row2);
  f := -Tran[ttShearYZ];
  CombineVector(row2, row1, f);

  // next, get Z scale and normalize 3rd row
  Tran[ttScaleZ] := VectorNorm(row2);
  ScaleVector(row2, RSqrt(Tran[ttScaleZ]));
  Tran[ttShearXZ] := Tran[ttShearXZ] / Tran[ttScaleZ];
  Tran[ttShearYZ] := Tran[ttShearYZ] / Tran[ttScaleZ];

  // At this point, the matrix (in rows[]) is orthonormal.
  // Check for a coordinate system flip.  If the determinant
  // is -1, then negate the matrix and the scaling factors.
  if VectorDotProduct(row0, VectorCrossProduct(row1, row2)) < 0 then
  begin
    for i := 0 to 2 do
      Tran[TTransType(Ord(ttScaleX) + i)] :=
        -Tran[TTransType(Ord(ttScaleX) + i)];
    NegateVector(row0);
    NegateVector(row1);
    NegateVector(row2);
  end;

  // now, get the rotations out, as described in the gem
  Tran[ttRotateY] := VectorGeometry.ArcSin(-row0[z]);
  if Cos(Tran[ttRotateY]) <> 0 then
  begin
    Tran[ttRotateX] := VectorGeometry.ArcTan2(row1[z], row2[z]);
    Tran[ttRotateZ] := VectorGeometry.ArcTan2(row0[y], row0[x]);
  end
  else
  begin
    Tran[ttRotateX] := VectorGeometry.ArcTan2(row1[x], row1[y]);
    Tran[ttRotateZ] := 0;
  end;
  // All done!
  result := True;
end;

function CreateLookAtMatrix(const eye, center, normUp: TVector): TMatrix;
var
  XAxis, YAxis, ZAxis, negEye: TVector;
begin
  ZAxis := VectorSubtract(center, eye);
  NormalizeVector(ZAxis);
  XAxis := VectorCrossProduct(ZAxis, normUp);
  NormalizeVector(XAxis);
  YAxis := VectorCrossProduct(XAxis, ZAxis);
  result[0] := XAxis;
  result[1] := YAxis;
  result[2] := ZAxis;
  NegateVector(result[2]);
  result[3] := NullHmgPoint;
  TransposeMatrix(result);
  negEye := eye;
  NegateVector(negEye);
  negEye[3] := 1;
  negEye := VectorTransform(negEye, result);
  result[3] := negEye;
end;

function CreateMatrixFromFrustum(const Left, Right, Bottom, Top, ZNearValue,
  ZFarValue: Single): TMatrix;
begin

  result[0][0] := 2 * ZNearValue / (Right - Left);
  result[0][1] := 0;
  result[0][2] := 0;
  result[0][3] := 0;

  result[1][0] := 0;
  result[1][1] := 2 * ZNearValue / (Top - Bottom);
  result[1][2] := 0;
  result[1][3] := 0;

  result[2][0] := (Right + Left) / (Right - Left);
  result[2][1] := (Top + Bottom) / (Top - Bottom);
  result[2][2] := -(ZFarValue + ZNearValue) / (ZFarValue - ZNearValue);
  result[2][3] := -1;

  result[3][0] := 0;
  result[3][1] := 0;
  result[3][2] := -2 * ZFarValue * ZNearValue / (ZFarValue - ZNearValue);
  result[3][3] := 0;
end;

function CreatePerspectiveMatrix(FOV, Aspect, ZNearValue,
  ZFarValue: Single): TMatrix;
var
  x, y: Single;
begin
  FOV := MinFloat(179.9, MaxFloat(0, FOV));
  y := ZNearValue * VectorGeometry.Tan(VectorGeometry.DegToRad(FOV) * 0.5);
  x := y * Aspect;
  result := CreateMatrixFromFrustum(-x, x, -y, y, ZNearValue, ZFarValue);
end;

function CreatePerspectiveMatrixSafe(FOV, Aspect, ZNearValue,
  ZFarValue: Single): TMatrix;
var
  x, y: Single;
begin
  FOV := MinFloat(179.9, MaxFloat(0, FOV));
  y := ZNearValue * VectorGeometry.Tan(VectorGeometry.DegToRad(FOV) * 0.5);
  x := y * Aspect;

  result[0][0] := ZNearValue / x;
  result[0][1] := 0;
  result[0][2] := 0;
  result[0][3] := 0;

  result[1][0] := 0;
  result[1][1] := ZNearValue / y;
  result[1][2] := 0;
  result[1][3] := 0;

  result[2][0] := 0;
  result[2][1] := 0;
  result[2][2] := -(ZFarValue + ZNearValue) / (ZFarValue - ZNearValue);
  result[2][3] := -1;

  result[3][0] := 0;
  result[3][1] := 0;
  result[3][2] := -2 * ZFarValue * ZNearValue / (ZFarValue - ZNearValue);
  result[3][3] := 0;
end;

function CreateOrthoMatrix(Left, Right, Bottom, Top, ZNear,
  ZFar: Single): TMatrix;
begin
  result[0][0] := 2 / (Right - Left);
  result[0][1] := 0;
  result[0][2] := 0;
  result[0][3] := 0;

  result[1][0] := 0;
  result[1][1] := 2 / (Top - Bottom);
  result[1][2] := 0;
  result[1][3] := 0;

  result[2][0] := 0;
  result[2][1] := 0;
  result[2][2] := -2 / (ZFar - ZNear);
  result[2][3] := 0;

  result[3][0] := (Left + Right) / (Left - Right);
  result[3][1] := (Bottom + Top) / (Bottom - Top);
  result[3][2] := (ZNear + ZFar) / (ZNear - ZFar);
  result[3][3] := 1;
end;

function CreatePickMatrix(x, y, deltax, deltay: Single;
  const viewport: TVector4i): TMatrix;
begin
  if (deltax <= 0) or (deltay <= 0) then
  begin
    result := IdentityHmgMatrix;
    Exit;
  end;
  // Translate and scale the picked region to the entire window
  result := CreateTranslationMatrix
    (AffineVectorMake((viewport[2] - 2 * (x - viewport[0])) / deltax,
    (viewport[3] - 2 * (y - viewport[1])) / deltay, 0.0));
  result[0][0] := viewport[2] / deltax;
  result[1][1] := viewport[3] / deltay;
end;

function Project(objectVector: TVector; const ViewProjMatrix: TMatrix;
  const viewport: TVector4i; out WindowVector: TVector): Boolean;
begin
  result := False;
  objectVector[3] := 1.0;
  WindowVector := VectorTransform(objectVector, ViewProjMatrix);
  if WindowVector[3] = 0.0 then
    Exit;
  WindowVector[0] := WindowVector[0] / WindowVector[3];
  WindowVector[1] := WindowVector[1] / WindowVector[3];
  WindowVector[2] := WindowVector[2] / WindowVector[3];
  // Map x, y and z to range 0-1
  WindowVector[0] := WindowVector[0] * 0.5 + 0.5;
  WindowVector[1] := WindowVector[1] * 0.5 + 0.5;
  WindowVector[2] := WindowVector[2] * 0.5 + 0.5;

  // Map x,y to viewport
  WindowVector[0] := WindowVector[0] * viewport[2] + viewport[0];
  WindowVector[1] := WindowVector[1] * viewport[3] + viewport[1];
  result := True;
end;

function UnProject(WindowVector: TVector; ViewProjMatrix: TMatrix;
  const viewport: TVector4i; out objectVector: TVector): Boolean;
begin
  result := False;
  InvertMatrix(ViewProjMatrix);
  WindowVector[3] := 1.0;
  // Map x and y from window coordinates
  WindowVector[0] := (WindowVector[0] - viewport[0]) / viewport[2];
  WindowVector[1] := (WindowVector[1] - viewport[1]) / viewport[3];
  // Map to range -1 to 1
  WindowVector[0] := WindowVector[0] * 2 - 1;
  WindowVector[1] := WindowVector[1] * 2 - 1;
  WindowVector[2] := WindowVector[2] * 2 - 1;
  objectVector := VectorTransform(WindowVector, ViewProjMatrix);
  if objectVector[3] = 0.0 then
    Exit;
  objectVector[0] := objectVector[0] / objectVector[3];
  objectVector[1] := objectVector[1] / objectVector[3];
  objectVector[2] := objectVector[2] / objectVector[3];
  result := True;
end;

// CalcPlaneNormal (func, affine)
//
function CalcPlaneNormal(const p1, p2, p3: TAffineVector): TAffineVector;
var
  V1, V2: TAffineVector;
begin
  VectorSubtract(p2, p1, V1);
  VectorSubtract(p3, p1, V2);
  VectorCrossProduct(V1, V2, result);
  NormalizeVector(result);
end;

// CalcPlaneNormal (proc, affine)
//
procedure CalcPlaneNormal(const p1, p2, p3: TAffineVector;
  var vr: TAffineVector);
var
  V1, V2: TAffineVector;
begin
  VectorSubtract(p2, p1, V1);
  VectorSubtract(p3, p1, V2);
  VectorCrossProduct(V1, V2, vr);
  NormalizeVector(vr);
end;

// CalcPlaneNormal (proc, hmg)
//
procedure CalcPlaneNormal(const p1, p2, p3: TVector;
  var vr: TAffineVector); overload;
var
  V1, V2: TVector;
begin
  VectorSubtract(p2, p1, V1);
  VectorSubtract(p3, p1, V2);
  VectorCrossProduct(V1, V2, vr);
  NormalizeVector(vr);
end;

// PlaneMake (point + normal, affine)
//
function PlaneMake(const point, normal: TAffineVector): THmgPlane;
begin
  PAffineVector(@result)^ := normal;
  result[3] := -VectorDotProduct(point, normal);
end;

// PlaneMake (point + normal, hmg)
//
function PlaneMake(const point, normal: TVector): THmgPlane;
begin
  PAffineVector(@result)^ := PAffineVector(@normal)^;
  result[3] := -VectorDotProduct(PAffineVector(@point)^,
    PAffineVector(@normal)^);
end;

// PlaneMake (3 points, affine)
//
function PlaneMake(const p1, p2, p3: TAffineVector): THmgPlane;
begin
  CalcPlaneNormal(p1, p2, p3, PAffineVector(@result)^);
  result[3] := -VectorDotProduct(p1, PAffineVector(@result)^);
end;

// PlaneMake (3 points, hmg)
//
function PlaneMake(const p1, p2, p3: TVector): THmgPlane;
begin
  CalcPlaneNormal(p1, p2, p3, PAffineVector(@result)^);
  result[3] := -VectorDotProduct(p1, PAffineVector(@result)^);
end;

// SetPlane
//
procedure SetPlane(var dest: TDoubleHmgPlane; const src: THmgPlane);
begin
  dest[0] := src[0];
  dest[1] := src[1];
  dest[2] := src[2];
  dest[3] := src[3];
end;

// NormalizePlane
//
procedure NormalizePlane(var plane: THmgPlane);
var
  n: Single;
begin
  n := RSqrt(plane[0] * plane[0] + plane[1] * plane[1] + plane[2] * plane[2]);
  ScaleVector(plane, n);
end;

// PlaneEvaluatePoint (affine)
//
function PlaneEvaluatePoint(const plane: THmgPlane;
  const point: TAffineVector): Single;
// EAX contains address of plane
// EDX contains address of point
// result is stored in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]
  FMUL DWORD PTR [EDX]
  FLD DWORD PTR [EAX + 4]
  FMUL DWORD PTR [EDX + 4]
  FADDP
  FLD DWORD PTR [EAX + 8]
  FMUL DWORD PTR [EDX + 8]
  FADDP
  FLD DWORD PTR [EAX + 12]
  FADDP
  {$ELSE}
begin
  result := plane[0] * point[0] + plane[1] * point[1] + plane[2] * point[2]
    + plane[3];
{$ENDIF}
end;

// PlaneEvaluatePoint (hmg)
//
function PlaneEvaluatePoint(const plane: THmgPlane;
  const point: TVector): Single;
// EAX contains address of plane
// EDX contains address of point
// result is stored in ST(0)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD DWORD PTR [EAX]
  FMUL DWORD PTR [EDX]
  FLD DWORD PTR [EAX + 4]
  FMUL DWORD PTR [EDX + 4]
  FADDP
  FLD DWORD PTR [EAX + 8]
  FMUL DWORD PTR [EDX + 8]
  FADDP
  FLD DWORD PTR [EAX + 12]
  FADDP
  {$ELSE}
begin
  result := plane[0] * point[0] + plane[1] * point[1] + plane[2] * point[2]
    + plane[3];
{$ENDIF}
end;

// PointIsInHalfSpace
//
function PointIsInHalfSpace(const point, planePoint,
  planeNormal: TVector): Boolean;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  fld   dword ptr [eax]         // 27
  fsub  dword ptr [edx]
  fmul  dword ptr [ecx]
  fld   dword ptr [eax+4]
  fsub  dword ptr [edx+4]
  fmul  dword ptr [ecx+4]
  faddp
  fld   dword ptr [eax+8]
  fsub  dword ptr [edx+8]
  fmul  dword ptr [ecx+8]
  faddp
  ftst
  fstsw ax
  sahf
  setnbe al
  ffree st(0)
  {$ELSE}
begin
  result := (PointPlaneDistance(point, planePoint, planeNormal) > 0); // 44
{$ENDIF}
end;

// PointIsInHalfSpace
//
function PointIsInHalfSpace(const point, planePoint,
  planeNormal: TAffineVector): Boolean;
begin
  result := (PointPlaneDistance(point, planePoint, planeNormal) > 0);
end;

// PointPlaneDistance
//
function PointPlaneDistance(const point, planePoint,
  planeNormal: TVector): Single;
begin
  result := (point[0] - planePoint[0]) * planeNormal[0] +
    (point[1] - planePoint[1]) * planeNormal[1] + (point[2] - planePoint[2]) *
    planeNormal[2];
end;

// PointPlaneDistance
//
function PointPlaneDistance(const point, planePoint,
  planeNormal: TAffineVector): Single;
begin
  result := (point[0] - planePoint[0]) * planeNormal[0] +
    (point[1] - planePoint[1]) * planeNormal[1] + (point[2] - planePoint[2]) *
    planeNormal[2];
end;

// PointLineClosestPoint
//
function PointLineClosestPoint(const point, linePoint, lineDirection
  : TAffineVector): TAffineVector;
var
  w: TAffineVector;
  c1, c2, b: Single;
begin
  w := VectorSubtract(point, linePoint);

  c1 := VectorDotProduct(w, lineDirection);
  c2 := VectorDotProduct(lineDirection, lineDirection);
  b := c1 / c2;

  VectorAdd(linePoint, VectorScale(lineDirection, b), result);
end;

// PointLineDistance
//
function PointLineDistance(const point, linePoint, lineDirection
  : TAffineVector): Single;
var
  pb: TAffineVector;
begin
  pb := PointLineClosestPoint(point, linePoint, lineDirection);
  result := VectorDistance(point, pb);
end;

// PointSegmentClosestPoint
//
function PointSegmentClosestPoint(const point, segmentStart,
  segmentStop: TAffineVector): TAffineVector;
var
  w, lineDirection: TAffineVector;
  c1, c2, b: Single;
begin
  lineDirection := VectorSubtract(segmentStop, segmentStart);
  w := VectorSubtract(point, segmentStart);

  c1 := VectorDotProduct(w, lineDirection);
  c2 := VectorDotProduct(lineDirection, lineDirection);
  b := ClampValue(c1 / c2, 0, 1);

  VectorAdd(segmentStart, VectorScale(lineDirection, b), result);
end;

// PointSegmentDistance
//
function PointSegmentDistance(const point, segmentStart,
  segmentStop: TAffineVector): Single;
var
  pb: TAffineVector;
begin
  pb := PointSegmentClosestPoint(point, segmentStart, segmentStop);
  result := VectorDistance(point, pb);
end;

// http://geometryalgorithms.com/Archive/algorithm_0104/algorithm_0104B.htm
// SegmentSegmentClosestPoint
//
procedure SegmentSegmentClosestPoint(const S0Start, S0Stop, S1Start,
  S1Stop: TAffineVector; var Segment0Closest, Segment1Closest: TAffineVector);
const
  cSMALL_NUM = 0.000000001;
var
  u, v, w: TAffineVector;
  a, b, c, smalld, e, largeD, sc, sn, sD, tc, tN, tD: Single;
begin
  VectorSubtract(S0Stop, S0Start, u);
  VectorSubtract(S1Stop, S1Start, v);
  VectorSubtract(S0Start, S1Start, w);

  a := VectorDotProduct(u, u);
  b := VectorDotProduct(u, v);
  c := VectorDotProduct(v, v);
  smalld := VectorDotProduct(u, w);
  e := VectorDotProduct(v, w);
  largeD := a * c - b * b;

  sD := largeD;
  tD := largeD;

  if largeD < cSMALL_NUM then
  begin
    sn := 0.0;
    sD := 1.0;
    tN := e;
    tD := c;
  end
  else
  begin
    sn := (b * e - c * smalld);
    tN := (a * e - b * smalld);
    if (sn < 0.0) then
    begin
      sn := 0.0;
      tN := e;
      tD := c;
    end
    else if (sn > sD) then
    begin
      sn := sD;
      tN := e + b;
      tD := c;
    end;
  end;

  if (tN < 0.0) then
  begin
    tN := 0.0;
    // recompute sc for this edge
    if (-smalld < 0.0) then
      sn := 0.0
    else if (-smalld > a) then
      sn := sD
    else
    begin
      sn := -smalld;
      sD := a;
    end;
  end
  else if (tN > tD) then
  begin
    tN := tD;
    // recompute sc for this edge
    if ((-smalld + b) < 0.0) then
      sn := 0
    else if ((-smalld + b) > a) then
      sn := sD
    else
    begin
      sn := (-smalld + b);
      sD := a;
    end;
  end;

  // finally do the division to get sc and tc
  // sc := (abs(sN) < SMALL_NUM ? 0.0 : sN / sD);
  if Abs(sn) < cSMALL_NUM then
    sc := 0
  else
    sc := sn / sD;

  // tc := (abs(tN) < SMALL_NUM ? 0.0 : tN / tD);
  if Abs(tN) < cSMALL_NUM then
    tc := 0
  else
    tc := tN / tD;

  // get the difference of the two closest points
  // Vector   dP = w + (sc * u) - (tc * v);  // = S0(sc) - S1(tc)

  Segment0Closest := VectorAdd(S0Start, VectorScale(u, sc));
  Segment1Closest := VectorAdd(S1Start, VectorScale(v, tc));
end;

// SegmentSegmentDistance
//
function SegmentSegmentDistance(const S0Start, S0Stop, S1Start,
  S1Stop: TAffineVector): Single;
var
  Pb0, PB1: TAffineVector;
begin
  SegmentSegmentClosestPoint(S0Start, S0Stop, S1Start, S1Stop, Pb0, PB1);
  result := VectorDistance(Pb0, PB1);
end;

// QuaternionMake
//
function QuaternionMake(const Imag: array of Single; Real: Single): TQuaternion;
// EAX contains address of Imag
// ECX contains address to result vector
// EDX contains highest index of Imag
// Real part is passed on the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  PUSH EDI
  PUSH ESI
  MOV EDI, ECX
  MOV ESI, EAX
  MOV ECX, EDX
  INC ECX
  REP MOVSD
  MOV EAX, [Real]
  MOV [EDI], EAX
  POP ESI
  POP EDI
  {$ELSE}
var
  n: Integer;
begin
  n := Length(Imag);
  if n >= 1 then
    result.ImagPart[0] := Imag[0];
  if n >= 2 then
    result.ImagPart[1] := Imag[1];
  if n >= 3 then
    result.ImagPart[2] := Imag[2];
  result.RealPart := Real;
{$ENDIF}
end;

// QuaternionConjugate
//
function QuaternionConjugate(const Q: TQuaternion): TQuaternion;
begin
  result.ImagPart[0] := -Q.ImagPart[0];
  result.ImagPart[1] := -Q.ImagPart[1];
  result.ImagPart[2] := -Q.ImagPart[2];
  result.RealPart := Q.RealPart;
end;

// QuaternionMagnitude
//
function QuaternionMagnitude(const Q: TQuaternion): Single;
begin
  result := Sqrt(VectorNorm(Q.ImagPart) + Sqr(Q.RealPart));
end;

// NormalizeQuaternion
//
procedure NormalizeQuaternion(var Q: TQuaternion);
var
  M, f: Single;
begin
  M := QuaternionMagnitude(Q);
  if M > EPSILON2 then
  begin
    f := 1 / M;
    ScaleVector(Q.ImagPart, f);
    Q.RealPart := Q.RealPart * f;
  end
  else
    Q := IdentityQuaternion;
end;

// QuaternionFromPoints
//
function QuaternionFromPoints(const V1, V2: TAffineVector): TQuaternion;
begin
  result.ImagPart := VectorCrossProduct(V1, V2);
  result.RealPart := Sqrt((VectorDotProduct(V1, V2) + 1) / 2);
end;

// QuaternionFromMatrix
//
function QuaternionFromMatrix(const mat: TMatrix): TQuaternion;
// the matrix must be a rotation matrix!
var
  traceMat, S, invS: Double;
begin
  traceMat := 1 + mat[0, 0] + mat[1, 1] + mat[2, 2];
  if traceMat > EPSILON2 then
  begin
    S := Sqrt(traceMat) * 2;
    invS := 1 / S;
    result.ImagPart[0] := (mat[1, 2] - mat[2, 1]) * invS;
    result.ImagPart[1] := (mat[2, 0] - mat[0, 2]) * invS;
    result.ImagPart[2] := (mat[0, 1] - mat[1, 0]) * invS;
    result.RealPart := 0.25 * S;
  end
  else if (mat[0, 0] > mat[1, 1]) and (mat[0, 0] > mat[2, 2]) then
  begin // Row 0:
    S := Sqrt(MaxFloat(EPSILON2, cOne + mat[0, 0] - mat[1, 1] - mat[2, 2])) * 2;
    invS := 1 / S;
    result.ImagPart[0] := 0.25 * S;
    result.ImagPart[1] := (mat[0, 1] + mat[1, 0]) * invS;
    result.ImagPart[2] := (mat[2, 0] + mat[0, 2]) * invS;
    result.RealPart := (mat[1, 2] - mat[2, 1]) * invS;
  end
  else if (mat[1, 1] > mat[2, 2]) then
  begin // Row 1:
    S := Sqrt(MaxFloat(EPSILON2, cOne + mat[1, 1] - mat[0, 0] - mat[2, 2])) * 2;
    invS := 1 / S;
    result.ImagPart[0] := (mat[0, 1] + mat[1, 0]) * invS;
    result.ImagPart[1] := 0.25 * S;
    result.ImagPart[2] := (mat[1, 2] + mat[2, 1]) * invS;
    result.RealPart := (mat[2, 0] - mat[0, 2]) * invS;
  end
  else
  begin // Row 2:
    S := Sqrt(MaxFloat(EPSILON2, cOne + mat[2, 2] - mat[0, 0] - mat[1, 1])) * 2;
    invS := 1 / S;
    result.ImagPart[0] := (mat[2, 0] + mat[0, 2]) * invS;
    result.ImagPart[1] := (mat[1, 2] + mat[2, 1]) * invS;
    result.ImagPart[2] := 0.25 * S;
    result.RealPart := (mat[0, 1] - mat[1, 0]) * invS;
  end;
  NormalizeQuaternion(result);
end;

// QuaternionMultiply
//
function QuaternionMultiply(const qL, qR: TQuaternion): TQuaternion;
var
  Temp: TQuaternion;
begin
  Temp.RealPart := qL.RealPart * qR.RealPart - qL.ImagPart[x] * qR.ImagPart[x] -
    qL.ImagPart[y] * qR.ImagPart[y] - qL.ImagPart[z] * qR.ImagPart[z];
  Temp.ImagPart[x] := qL.RealPart * qR.ImagPart[x] + qL.ImagPart[x] *
    qR.RealPart + qL.ImagPart[y] * qR.ImagPart[z] - qL.ImagPart[z] *
    qR.ImagPart[y];
  Temp.ImagPart[y] := qL.RealPart * qR.ImagPart[y] + qL.ImagPart[y] *
    qR.RealPart + qL.ImagPart[z] * qR.ImagPart[x] - qL.ImagPart[x] *
    qR.ImagPart[z];
  Temp.ImagPart[z] := qL.RealPart * qR.ImagPart[z] + qL.ImagPart[z] *
    qR.RealPart + qL.ImagPart[x] * qR.ImagPart[y] - qL.ImagPart[y] *
    qR.ImagPart[x];
  result := Temp;
end;

// QuaternionToMatrix
//
function QuaternionToMatrix(quat: TQuaternion): TMatrix;
var
  w, x, y, z, xx, xy, xz, xw, yy, yz, yw, zz, zw: Single;
begin
  NormalizeQuaternion(quat);
  w := quat.RealPart;
  x := quat.ImagPart[0];
  y := quat.ImagPart[1];
  z := quat.ImagPart[2];
  xx := x * x;
  xy := x * y;
  xz := x * z;
  xw := x * w;
  yy := y * y;
  yz := y * z;
  yw := y * w;
  zz := z * z;
  zw := z * w;
  result[0, 0] := 1 - 2 * (yy + zz);
  result[1, 0] := 2 * (xy - zw);
  result[2, 0] := 2 * (xz + yw);
  result[3, 0] := 0;
  result[0, 1] := 2 * (xy + zw);
  result[1, 1] := 1 - 2 * (xx + zz);
  result[2, 1] := 2 * (yz - xw);
  result[3, 1] := 0;
  result[0, 2] := 2 * (xz - yw);
  result[1, 2] := 2 * (yz + xw);
  result[2, 2] := 1 - 2 * (xx + yy);
  result[3, 2] := 0;
  result[0, 3] := 0;
  result[1, 3] := 0;
  result[2, 3] := 0;
  result[3, 3] := 1;
end;

// QuaternionToAffineMatrix
//
function QuaternionToAffineMatrix(quat: TQuaternion): TAffineMatrix;
var
  w, x, y, z, xx, xy, xz, xw, yy, yz, yw, zz, zw: Single;
begin
  NormalizeQuaternion(quat);
  w := quat.RealPart;
  x := quat.ImagPart[0];
  y := quat.ImagPart[1];
  z := quat.ImagPart[2];
  xx := x * x;
  xy := x * y;
  xz := x * z;
  xw := x * w;
  yy := y * y;
  yz := y * z;
  yw := y * w;
  zz := z * z;
  zw := z * w;
  result[0, 0] := 1 - 2 * (yy + zz);
  result[1, 0] := 2 * (xy - zw);
  result[2, 0] := 2 * (xz + yw);
  result[0, 1] := 2 * (xy + zw);
  result[1, 1] := 1 - 2 * (xx + zz);
  result[2, 1] := 2 * (yz - xw);
  result[0, 2] := 2 * (xz - yw);
  result[1, 2] := 2 * (yz + xw);
  result[2, 2] := 1 - 2 * (xx + yy);
end;

// QuaternionFromAngleAxis
//
function QuaternionFromAngleAxis(const angle: Single; const axis: TAffineVector)
  : TQuaternion;
var
  f, S, c: Single;
begin
  VectorGeometry.SinCos(VectorGeometry.DegToRad(angle * cOneDotFive), S, c);
  result.RealPart := c;
  f := S / VectorLength(axis);
  result.ImagPart[0] := axis[0] * f;
  result.ImagPart[1] := axis[1] * f;
  result.ImagPart[2] := axis[2] * f;
end;

// QuaternionFromRollPitchYaw
//
function QuaternionFromRollPitchYaw(const r, p, y: Single): TQuaternion;
var
  qp, qy: TQuaternion;
begin
  result := QuaternionFromAngleAxis(r, ZVector);
  qp := QuaternionFromAngleAxis(p, XVector);
  qy := QuaternionFromAngleAxis(y, YVector);

  result := QuaternionMultiply(qp, result);
  result := QuaternionMultiply(qy, result);
end;

// QuaternionFromEuler
//
function QuaternionFromEuler(const x, y, z: Single; eulerOrder: TEulerOrder)
  : TQuaternion;
// input angles in degrees
var
  gimbalLock: Boolean;
  quat1, quat2: TQuaternion;

  function EulerToQuat(const x, y, z: Single; eulerOrder: TEulerOrder)
    : TQuaternion;
  const
    cOrder: array [Low(TEulerOrder) .. High(TEulerOrder)] of array [1 .. 3]
      of Byte = ((1, 2, 3), (1, 3, 2), (2, 1, 3), // eulXYZ, eulXZY, eulYXZ,
      (3, 1, 2), (2, 3, 1), (3, 2, 1)); // eulYZX, eulZXY, eulZYX
  var
    Q: array [1 .. 3] of TQuaternion;
  begin
    Q[cOrder[eulerOrder][1]] := QuaternionFromAngleAxis(x, XVector);
    Q[cOrder[eulerOrder][2]] := QuaternionFromAngleAxis(y, YVector);
    Q[cOrder[eulerOrder][3]] := QuaternionFromAngleAxis(z, ZVector);
    result := QuaternionMultiply(Q[2], Q[3]);
    result := QuaternionMultiply(Q[1], result);
  end;

const
  SMALL_ANGLE = 0.001;
begin
  NormalizeDegAngle(x);
  NormalizeDegAngle(y);
  NormalizeDegAngle(z);
  case eulerOrder of
    eulXYZ, eulZYX:
      gimbalLock := Abs(Abs(y) - 90.0) <= EPSILON2; // cos(Y) = 0;
    eulYXZ, eulZXY:
      gimbalLock := Abs(Abs(x) - 90.0) <= EPSILON2; // cos(X) = 0;
    eulXZY, eulYZX:
      gimbalLock := Abs(Abs(z) - 90.0) <= EPSILON2; // cos(Z) = 0;
  else
    Assert(False);
    gimbalLock := False;
  end;
  if gimbalLock then
  begin
    case eulerOrder of
      eulXYZ, eulZYX:
        quat1 := EulerToQuat(x, y - SMALL_ANGLE, z, eulerOrder);
      eulYXZ, eulZXY:
        quat1 := EulerToQuat(x - SMALL_ANGLE, y, z, eulerOrder);
      eulXZY, eulYZX:
        quat1 := EulerToQuat(x, y, z - SMALL_ANGLE, eulerOrder);
    end;
    case eulerOrder of
      eulXYZ, eulZYX:
        quat2 := EulerToQuat(x, y + SMALL_ANGLE, z, eulerOrder);
      eulYXZ, eulZXY:
        quat2 := EulerToQuat(x + SMALL_ANGLE, y, z, eulerOrder);
      eulXZY, eulYZX:
        quat2 := EulerToQuat(x, y, z + SMALL_ANGLE, eulerOrder);
    end;
    result := QuaternionSlerp(quat1, quat2, 0.5);
  end
  else
  begin
    result := EulerToQuat(x, y, z, eulerOrder);
  end;
end;

// QuaternionToPoints
//
procedure QuaternionToPoints(const Q: TQuaternion;
  var ArcFrom, ArcTo: TAffineVector);
var
  S, invS: Single;
begin
  S := Q.ImagPart[x] * Q.ImagPart[x] + Q.ImagPart[y] * Q.ImagPart[y];
  if S = 0 then
    SetAffineVector(ArcFrom, 0, 1, 0)
  else
  begin
    invS := RSqrt(S);
    SetAffineVector(ArcFrom, -Q.ImagPart[y] * invS, Q.ImagPart[x] * invS, 0);
  end;
  ArcTo[x] := Q.RealPart * ArcFrom[x] - Q.ImagPart[z] * ArcFrom[y];
  ArcTo[y] := Q.RealPart * ArcFrom[y] + Q.ImagPart[z] * ArcFrom[x];
  ArcTo[z] := Q.ImagPart[x] * ArcFrom[y] - Q.ImagPart[y] * ArcFrom[x];
  if Q.RealPart < 0 then
    SetAffineVector(ArcFrom, -ArcFrom[x], -ArcFrom[y], 0);
end;

// LnXP1
//
function LnXP1(x: Extended): Extended;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLDLN2
  MOV     AX, WORD PTR X+8  // exponent
  FLD     X
  CMP     AX, $3FFD         // .4225
  JB      @@1
  FLD1
  FADD
  FYL2X
  JMP     @@2
@@1:
  FYL2XP1
@@2:
  FWAIT
  {$ELSE}
begin
  result := System.Math.LnXP1(x);
{$ENDIF}
end;

// Log10
//
function Log10(x: Extended): Extended;
// Log.10(X):=Log.2(X) * Log.10(2)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLDLG2     { Log base ten of 2 }
  FLD     X
  FYL2X
  {$ELSE}
begin
  result := System.Math.Log10(x);
{$ENDIF}
end;

// Log2
//
function Log2(x: Extended): Extended;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD1
  FLD     X
  FYL2X
  {$ELSE}
begin
  result := System.Math.Log2(x);
{$ENDIF}
end;

// Log2
//
function Log2(x: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD1
  FLD     X
  FYL2X
  {$ELSE}
begin
{$HINTS OFF}
  result := System.Math.Log2(x);
{$HINTS ON}
{$ENDIF}
end;

// LogN
//
function LogN(Base, x: Extended): Extended;
// Log.N(X):=Log.2(X) / Log.2(N)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD1
  FLD     X
  FYL2X
  FLD1
  FLD     Base
  FYL2X
  FDIV
  {$ELSE}
begin
  result := System.Math.LogN(Base, x);
{$ENDIF}
end;

// IntPower
//
function IntPower(Base: Extended; Exponent: Integer): Extended;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  mov     ecx, eax
  cdq
  fld1                      { Result:=1 }
  xor     eax, edx
  sub     eax, edx          { eax:=Abs(Exponent) }
  jz      @@3
  fld     Base
  jmp     @@2
@@1:    fmul    ST, ST            { X:=Base * Base }
@@2:    shr     eax,1
  jnc     @@1
  fmul    ST(1),ST          { Result:=Result * X }
  jnz     @@1
  fstp    st                { pop X from FPU stack }
  cmp     ecx, 0
  jge     @@3
  fld1
  fdivrp                    { Result:=1 / Result }
@@3:
  {$ELSE}
begin
  result := System.Math.IntPower(Abs(Base), Exponent);
{$ENDIF}
end;

// Power
//
function Power(const Base, Exponent: Single): Single;
begin
{$HINTS OFF}
  if Exponent = cZero then
    result := cOne
  else if (Base = cZero) and (Exponent > cZero) then
    result := cZero
  else if RoundInt(Exponent) = Exponent then
    result := Power(Base, Integer(Round(Exponent)))
  else
    result := Exp(Exponent * Ln(Base));
{$HINTS ON}
end;

// Power (int exponent)
//
function Power(Base: Single; Exponent: Integer): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  mov     ecx, eax
  cdq
  fld1                      { Result:=1 }
  xor     eax, edx
  sub     eax, edx          { eax:=Abs(Exponent) }
  jz      @@3
  fld     Base
  jmp     @@2
@@1:    fmul    ST, ST            { X:=Base * Base }
@@2:    shr     eax,1
  jnc     @@1
  fmul    ST(1),ST          { Result:=Result * X }
  jnz     @@1
  fstp    st                { pop X from FPU stack }
  cmp     ecx, 0
  jge     @@3
  fld1
  fdivrp                    { Result:=1 / Result }
@@3:
  {$ELSE}
begin
{$HINTS OFF}
  result := System.Math.Power(Abs(Base), Exponent);
{$HINTS ON}
{$ENDIF}
end;

// DegToRad (extended)
//
function DegToRad(const Degrees: Extended): Extended;
begin
  result := Degrees * (PI / 180);
end;

// DegToRad (single)
//
function DegToRad(const Degrees: Single): Single;
// Result:=Degrees * cPIdiv180;
// don't laugh, Delphi's compiler manages to make a nightmare of this one
// with pushs, pops, etc. in its default compile... (this one is twice faster !)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EBP+8]
  FMUL cPIdiv180
  {$ELSE}
begin
  result := Degrees * cPIdiv180;
{$ENDIF}
end;

// RadToDeg (extended)
//
function RadToDeg(const Radians: Extended): Extended;
begin
  result := Radians * (180 / PI);
end;

// RadToDeg (single)
//
function RadToDeg(const Radians: Single): Single;
// Result:=Radians * c180divPI;
// don't laugh, Delphi's compiler manages to make a nightmare of this one
// with pushs, pops, etc. in its default compile... (this one is twice faster !)
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EBP+8]
  FMUL c180divPI
  {$ELSE}
begin
  result := Radians * c180divPI;
{$ENDIF}
end;

// NormalizeAngle
//
function NormalizeAngle(angle: Single): Single;
begin
  result := angle - Int(angle * cInv2PI) * c2PI;
  if result > PI then
    result := result - 2 * PI
  else if result < -PI then
    result := result + 2 * PI;
end;

// NormalizeDegAngle
//
function NormalizeDegAngle(angle: Single): Single;
begin
  result := angle - Int(angle * cInv360) * c360;
  if result > c180 then
    result := result - c360
  else if result < -c180 then
    result := result + c360;
end;

// SinCos (Extended)
//
procedure SinCos(const Theta: Extended; out Sin, Cos: Extended);
// EAX contains address of Sin
// EDX contains address of Cos
// Theta is passed over the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  Theta
  FSINCOS
  FSTP TBYTE PTR [EDX]    // cosine
  FSTP TBYTE PTR [EAX]    // sine
  {$ELSE}
begin
  System.Math.SinCos(Theta, Sin, Cos);
{$ENDIF}
end;

// SinCos (Double)
//
procedure SinCos(const Theta: Double; out Sin, Cos: Double);
// EAX contains address of Sin
// EDX contains address of Cos
// Theta is passed over the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  Theta
  FSINCOS
  FSTP QWORD PTR [EDX]    // cosine
  FSTP QWORD PTR [EAX]    // sine
  {$ELSE}
var
  S, c: Extended;
begin
  System.Math.SinCos(Theta, S, c);
{$HINTS OFF}
  Sin := S;
  Cos := c;
{$HINTS ON}
{$ENDIF}
end;

// SinCos (Single)
//
procedure SinCos(const Theta: Single; out Sin, Cos: Single);
// EAX contains address of Sin
// EDX contains address of Cos
// Theta is passed over the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  Theta
  FSINCOS
  FSTP DWORD PTR [EDX]    // cosine
  FSTP DWORD PTR [EAX]    // sine
  {$ELSE}
var
  S, c: Extended;
begin
  System.Math.SinCos(Theta, S, c);
{$HINTS OFF}
  Sin := S;
  Cos := c;
{$HINTS ON}
{$ENDIF}
end;

// SinCos (Extended w radius)
//
procedure SinCos(const Theta, radius: Double; out Sin, Cos: Extended);
// EAX contains address of Sin
// EDX contains address of Cos
// Theta is passed over the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  theta
  FSINCOS
  FMUL radius
  FSTP TBYTE PTR [EDX]    // cosine
  FMUL radius
  FSTP TBYTE PTR [EAX]    // sine
  {$ELSE}
var
  S, c: Extended;
begin
  System.Math.SinCos(Theta, S, c);
  Sin := S * radius;
  Cos := c * radius;
{$ENDIF}
end;

// SinCos (Double w radius)
//
procedure SinCos(const Theta, radius: Double; out Sin, Cos: Double);
// EAX contains address of Sin
// EDX contains address of Cos
// Theta is passed over the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  theta
  FSINCOS
  FMUL radius
  FSTP QWORD PTR [EDX]    // cosine
  FMUL radius
  FSTP QWORD PTR [EAX]    // sine
  {$ELSE}
var
  S, c: Extended;
begin
  System.Math.SinCos(Theta, S, c);
  Sin := S * radius;
  Cos := c * radius;
{$ENDIF}
end;

// SinCos (Single w radius)
//
procedure SinCos(const Theta, radius: Single; out Sin, Cos: Single);
// EAX contains address of Sin
// EDX contains address of Cos
// Theta is passed over the stack
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  theta
  FSINCOS
  FMUL radius
  FSTP DWORD PTR [EDX]    // cosine
  FMUL radius
  FSTP DWORD PTR [EAX]    // sine
  {$ELSE}
var
  S, c: Extended;
begin
  System.Math.SinCos(Theta, S, c);
  Sin := S * radius;
  Cos := c * radius;
{$ENDIF}
end;

// PrepareSinCosCache
//
procedure PrepareSinCosCache(var S, c: array of Single;
  startAngle, stopAngle: Single);
var
  i: Integer;
  d, alpha, beta: Single;
begin
  Assert((High(S) = High(c)) and (Low(S) = Low(c)));
  stopAngle := stopAngle + 1E-5;
  if High(S) > Low(S) then
    d := cPIdiv180 * (stopAngle - startAngle) / (High(S) - Low(S))
  else
    d := 0;

  if High(S) - Low(S) < 1000 then
  begin
    // Fast computation (approx 5.5x)
    alpha := 2 * Sqr(Sin(d * 0.5));
    beta := Sin(d);
    VectorGeometry.SinCos(startAngle * cPIdiv180, S[Low(S)], c[Low(S)]);
    for i := Low(S) to High(S) - 1 do
    begin
      // Make use of the incremental formulae:
      // cos (theta+delta) = cos(theta) - [alpha*cos(theta) + beta*sin(theta)]
      // sin (theta+delta) = sin(theta) - [alpha*sin(theta) - beta*cos(theta)]
      c[i + 1] := c[i] - alpha * c[i] - beta * S[i];
      S[i + 1] := S[i] - alpha * S[i] + beta * c[i];
    end;
  end
  else
  begin
    // Slower, but maintains precision when steps are small
    startAngle := startAngle * cPIdiv180;
    for i := Low(S) to High(S) do
      VectorGeometry.SinCos((i - Low(S)) * d + startAngle, S[i], c[i]);
  end;
end;

// ArcCos (Extended)
//
function ArcCos(const x: Extended): Extended;
begin
  result := VectorGeometry.ArcTan2(Sqrt(1 - Sqr(x)), x);
end;

// ArcCos (Single)
//
function ArcCos(const x: Single): Single;
// Result:=ArcTan2(Sqrt(c1 - X * X), X);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD   X
  FMUL  ST, ST
  FSUBR cOne
  FSQRT
  FLD   X
  FPATAN
  {$ELSE}
begin
{$HINTS OFF}
  result := System.Math.ArcCos(x);
{$HINTS ON}
{$ENDIF}
end;

// ArcSin (Extended)
//
function ArcSin(const x: Extended): Extended;
begin
  result := VectorGeometry.ArcTan2(x, Sqrt(1 - Sqr(x)))
end;

// ArcSin (Single)
//
function ArcSin(const x: Single): Single;
// Result:=ArcTan2(X, Sqrt(1 - X * X))
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD   X
  FLD   ST
  FMUL  ST, ST
  FSUBR cOne
  FSQRT
  FPATAN
  {$ELSE}
begin
{$HINTS OFF}
  result := System.Math.ArcSin(x);
{$HINTS ON}
{$ENDIF}
end;

// ArcTan2 (Extended)
//
function ArcTan2(const y, x: Extended): Extended;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  Y
  FLD  X
  FPATAN
  {$ELSE}
begin
  result := System.Math.ArcTan2(y, x);
{$ENDIF}
end;

// ArcTan2 (Single)
//
function ArcTan2(const y, x: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  Y
  FLD  X
  FPATAN
  {$ELSE}
begin
{$HINTS OFF}
  result := System.Math.ArcTan2(y, x);
{$HINTS ON}
{$ENDIF}
end;

// FastArcTan2
//
function FastArcTan2(y, x: Single): Single;
// accuracy of about 0.07 rads
const
  cEpsilon: Single = 1E-10;
var
  abs_y: Single;
begin
  abs_y := Abs(y) + cEpsilon; // prevent 0/0 condition
  if y < 0 then
  begin
    if x >= 0 then
      result := cPIdiv4 * (x - abs_y) / (x + abs_y) - cPIdiv4
    else
      result := cPIdiv4 * (x + abs_y) / (abs_y - x) - c3PIdiv4;
  end
  else
  begin
    if x >= 0 then
      result := cPIdiv4 - cPIdiv4 * (x - abs_y) / (x + abs_y)
    else
      result := c3PIdiv4 - cPIdiv4 * (x + abs_y) / (abs_y - x);
  end;
end;

// Tan (Extended)
//
function Tan(const x: Extended): Extended;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  X
  FPTAN
  FSTP ST(0)      // FPTAN pushes 1.0 after result
  {$ELSE}
begin
  result := System.Math.Tan(x);
{$ENDIF}
end;

// Tan (Single)
//
function Tan(const x: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  X
  FPTAN
  FSTP ST(0)      // FPTAN pushes 1.0 after result
  {$ELSE}
begin
{$HINTS OFF}
  result := System.Math.Tan(x);
{$HINTS ON}
{$ENDIF}
end;

// CoTan (Extended)
//
function CoTan(const x: Extended): Extended;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  X
  FPTAN
  FDIVRP
  {$ELSE}
begin
  result := System.Math.CoTan(x);
{$ENDIF}
end;

// CoTan (Single)
//
function CoTan(const x: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  X
  FPTAN
  FDIVRP
  {$ELSE}
begin
{$HINTS OFF}
  result := System.Math.CoTan(x);
{$HINTS ON}
{$ENDIF}
end;

// Sinh
//
function Sinh(const x: Single): Single;
{$IFDEF GEOMETRY_NO_ASM}
begin
  result := 0.5 * (Exp(x) - Exp(-x));
{$ELSE}
asm
  fld   x
  call  RegisterBasedExp
  fld   x
  fchs
  call  RegisterBasedExp
  fsub
  fmul  cOneDotFive
  {$ENDIF}
end;

// Sinh
//
function Sinh(const x: Double): Double;
{$IFDEF GEOMETRY_NO_ASM}
begin
  result := 0.5 * (Exp(x) - Exp(-x));
{$ELSE}
asm
  fld   x
  call  RegisterBasedExp
  fld   x
  fchs
  call  RegisterBasedExp
  fsub
  fmul  cOneDotFive
  {$ENDIF}
end;

// Cosh
//
function Cosh(const x: Single): Single;
{$IFDEF GEOMETRY_NO_ASM}
begin
  result := 0.5 * (Exp(x) + Exp(-x));
{$ELSE}
asm
  fld   x
  call  RegisterBasedExp
  fld   x
  fchs
  call  RegisterBasedExp
  fadd
  fmul  cOneDotFive
  {$ENDIF}
end;

// Cosh
//
function Cosh(const x: Double): Double;
{$IFDEF GEOMETRY_NO_ASM}
begin
  result := 0.5 * (Exp(x) + Exp(-x));
{$ELSE}
asm
  fld   x
  call  RegisterBasedExp
  fld   x
  fchs
  call  RegisterBasedExp
  fadd
  fmul  cOneDotFive
  {$ENDIF}
end;

// RSqrt
//
function RSqrt(v: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU
@@3DNow:
  lea eax, [ebp+8]
  db $0F,$6E,$00           /// movd mm0, [eax]
  db $0F,$0F,$C8,$97       /// pfrsqrt  mm1, mm0

  db $0F,$6F,$D1           /// movq     mm2, mm1
  db $0F,$0F,$C9,$B4       /// pfmul    mm1, mm1
  db $0F,$0F,$C8,$A7       /// pfrsqit1 mm1, mm0
  db $0F,$0F,$CA,$B6       /// pfrcpit2 mm1, mm2

  db $0F,$7E,$08           /// movd [eax], mm1
  db $0F,$0E               /// femms
  fld dword ptr [eax]
  jmp @@End

@@FPU:
  fld v
  fsqrt
  fld1
  fdivr
@@End:
  {$ELSE}
begin
  result := 1 / Sqrt(v);
{$ENDIF}
end;

// ISqrt
//
function ISqrt(i: Integer): Integer;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  push     eax
  test     vSIMD, 1
  jz @@FPU
@@3DNow:
  db $0F,$6E,$04,$24       /// movd     mm0, [esp]
  db $0F,$0F,$C8,$0D       /// pi2fd    mm1, mm0
  db $0F,$0F,$D1,$97       /// pfrsqrt  mm2, mm1
  db $0F,$0F,$DA,$96       /// pfrcp    mm3, mm2
  db $0F,$0F,$E3,$1D       /// pf2id    mm4, mm3
  db $0F,$7E,$24,$24       /// movd     [esp], mm4
  db $0F,$0E               /// femms
  pop      eax
  ret
@@FPU:
  fild     dword ptr [esp]
  fsqrt
  fistp    dword ptr [esp]
  pop      eax
  {$ELSE}
begin
{$HINTS OFF}
  result := Round(Sqrt(i));
{$HINTS ON}
{$ENDIF}
end;

// ILength
//
function ILength(x, y: Integer): Integer;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  push     edx
  push     eax
  fild     dword ptr [esp]
  fmul     ST(0), ST(0)
  fild     dword ptr [esp+4]
  fmul     ST(0), ST(0)
  faddp
  fsqrt
  fistp    dword ptr [esp+4]
  pop      edx
  pop      eax
  {$ELSE}
begin
{$HINTS OFF}
  result := Round(Sqrt(x * x + y * y));
{$HINTS ON}
{$ENDIF}
end;

// ILength
//
function ILength(x, y, z: Integer): Integer;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  push     ecx
  push     edx
  push     eax
  fild     dword ptr [esp]
  fmul     ST(0), ST(0)
  fild     dword ptr [esp+4]
  fmul     ST(0), ST(0)
  faddp
  fild     dword ptr [esp+8]
  fmul     ST(0), ST(0)
  faddp
  fsqrt
  fistp    dword ptr [esp+8]
  pop      ecx
  pop      edx
  pop      eax
  {$ELSE}
begin
{$HINTS OFF}
  result := Round(Sqrt(x * x + y * y + z * z));
{$HINTS ON}
{$ENDIF}
end;

// RLength
//
function RLength(x, y: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  fld  x
  fmul x
  fld  y
  fmul y
  fadd
  fsqrt
  fld1
  fdivr
  {$ELSE}
begin
  result := 1 / Sqrt(x * x + y * y);
{$ENDIF}
end;

// RegisterBasedExp
//
{$IFNDEF GEOMETRY_NO_ASM}

procedure RegisterBasedExp;
asm   // Exp(x) = 2^(x.log2(e))
  fldl2e
  fmul
  fld      st(0)
  frndint
  fsub     st(1), st
  fxch     st(1)
  f2xm1
  fld1
  fadd
  fscale
  fstp     st(1)
end;
{$ENDIF}

// RandomPointOnSphere
//
procedure RandomPointOnSphere(var p: TAffineVector);
var
  T, w: Single;
begin
  p[2] := 2 * Random - 1;
  T := 2 * PI * Random;
  w := Sqrt(1 - p[2] * p[2]);
  SinCos(T, w, p[1], p[0]);
end;

// RoundInt (single)
//
function RoundInt(v: Single): Single;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD     v
  FRNDINT
  {$ELSE}
begin
{$HINTS OFF}
  result := Int(v + cOneDotFive);
{$HINTS ON}
{$ENDIF}
end;

// RoundInt (extended)
//
function RoundInt(v: Extended): Extended;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD     v
  FRNDINT
  {$ELSE}
begin
  result := Int(v + 0.5);
{$ENDIF}
end;

{$IFNDEF GEOMETRY_NO_ASM}

// Trunc64 (extended)
//
function Trunc64(v: Extended): Int64;
asm
  SUB     ESP,12
  FSTCW   [ESP]
  FLDCW   cwChop
  FLD     v
  FISTP   qword ptr [ESP+4]
  FLDCW   [ESP]
  POP     ECX
  POP     EAX
  POP     EDX
end;

// Trunc (single)
//
function Trunc(v: Single): Integer;
asm
  SUB     ESP,8
  FSTCW   [ESP]
  FLDCW   cwChop
  FLD     v
  FISTP   dword ptr [ESP+4]
  FLDCW   [ESP]
  POP     ECX
  POP     EAX
end;

// Int (Extended)
//
function Int(v: Extended): Extended;
asm
  SUB     ESP,4
  FSTCW   [ESP]
  FLDCW   cwChop
  FLD     v
  FRNDINT
  FLDCW   [ESP]
  ADD     ESP,4
end;

// Int (Single)
//
function Int(v: Single): Single;
asm
  SUB     ESP,4
  FSTCW   [ESP]
  FLDCW   cwChop
  FLD     v
  FRNDINT
  FLDCW   [ESP]
  ADD     ESP,4
end;

// Frac (Extended)
//
function Frac(v: Extended): Extended;
asm
  SUB     ESP,4
  FSTCW   [ESP]
  FLDCW   cwChop
  FLD     v
  FLD     ST
  FRNDINT
  FSUB
  FLDCW   [ESP]
  ADD     ESP,4
end;

// Frac (Extended)
//
function Frac(v: Single): Single;
asm
  SUB     ESP,4
  FSTCW   [ESP]
  FLDCW   cwChop
  FLD     v
  FLD     ST
  FRNDINT
  FSUB
  FLDCW   [ESP]
  ADD     ESP,4
end;

// Round64 (Single);
//
function Round64(v: Single): Int64;
asm
  SUB     ESP,8
  FLD     v
  FISTP   qword ptr [ESP]
  POP     EAX
  POP     EDX
end;

// Round64 (Extended);
//
function Round64(v: Extended): Int64;
asm
  FLD      v
  FISTP    qword ptr [v]           // use v as storage to place the result
  MOV      EAX, dword ptr [v]
  MOV      EDX, dword ptr [v+4]
end;

// Round (Single);
//
function Round(v: Single): Integer;
asm
  FLD     v
  FISTP   DWORD PTR [v]     // use v as storage to place the result
  MOV     EAX, [v]
end;

{$ELSE}

function Trunc(x: Extended): Int64;
begin
  result := System.Trunc(x);
end;

function Round(x: Extended): Int64;
begin
  result := System.Round(x);
end;

function Frac(x: Extended): Extended;
begin
  result := System.Frac(x);
end;

{$ENDIF}

// Ceil64 (Extended)
//
function Ceil64(v: Extended): Int64; overload;
begin
  if Frac(v) > 0 then
    result := Trunc(v) + 1
  else
    result := Trunc(v);
end;

// Ceil (Single)
//
function Ceil(v: Single): Integer; overload;
begin
{$HINTS OFF}
  if Frac(v) > 0 then
    result := Trunc(v) + 1
  else
    result := Trunc(v);
{$HINTS ON}
end;

// Floor64 (Extended)
//
function Floor64(v: Extended): Int64; overload;
begin
  if v < 0 then
    result := Trunc(v) - 1
  else
    result := Trunc(v);
end;

// Floor (Single)
//
function Floor(v: Single): Integer; overload;
begin
{$HINTS OFF}
  if v < 0 then
    result := Trunc(v) - 1
  else
    result := Trunc(v);
{$HINTS ON}
end;

// Sign
//
function Sign(x: Single): Integer;
begin
  if x < 0 then
    result := -1
  else if x > 0 then
    result := 1
  else
    result := 0;
end;

// ScaleAndRound
//
function ScaleAndRound(i: Integer; var S: Single): Integer;
{$IFNDEF GEOMETRY_NO_ASM}
asm
  push  eax
  fild  dword ptr [esp]
  fmul  dword ptr [edx]
  fistp dword ptr [esp]
  pop   eax
  {$ELSE}
begin
{$HINTS OFF}
  result := Round(i * S);
{$HINTS ON}
{$ENDIF}
end;

// IsInRange (single)
//
function IsInRange(const x, a, b: Single): Boolean;
begin
  if a < b then
    result := (a <= x) and (x <= b)
  else
    result := (b <= x) and (x <= a);
end;

// IsInRange (double)
//
function IsInRange(const x, a, b: Double): Boolean;
begin
  if a < b then
    result := (a <= x) and (x <= b)
  else
    result := (b <= x) and (x <= a);
end;

// IsInCube (affine)
//
function IsInCube(const p, d: TAffineVector): Boolean; overload;
begin
  result := ((p[0] >= -d[0]) and (p[0] <= d[0])) and
    ((p[1] >= -d[1]) and (p[1] <= d[1])) and
    ((p[2] >= -d[2]) and (p[2] <= d[2]));
end;

// IsInCube (hmg)
//
function IsInCube(const p, d: TVector): Boolean; overload;
begin
  result := ((p[0] >= -d[0]) and (p[0] <= d[0])) and
    ((p[1] >= -d[1]) and (p[1] <= d[1])) and
    ((p[2] >= -d[2]) and (p[2] <= d[2]));
end;

// MinFloat (single)
//
function MinFloat(values: PSingleArray; nbItems: Integer): Single;
var
  i, k: Integer;
begin
  if nbItems > 0 then
  begin
    k := 0;
    for i := 1 to nbItems - 1 do
      if values^[i] < values^[k] then
        k := i;
    result := values^[k];
  end
  else
    result := 0;
end;

// MinFloat (double)
//
function MinFloat(values: PDoubleArray; nbItems: Integer): Double;
var
  i, k: Integer;
begin
  if nbItems > 0 then
  begin
    k := 0;
    for i := 1 to nbItems - 1 do
      if values^[i] < values^[k] then
        k := i;
    result := values^[k];
  end
  else
    result := 0;
end;

// MinFloat (extended)
//
function MinFloat(values: PExtendedArray; nbItems: Integer): Extended;
var
  i, k: Integer;
begin
  if nbItems > 0 then
  begin
    k := 0;
    for i := 1 to nbItems - 1 do
      if values^[i] < values^[k] then
        k := i;
    result := values^[k];
  end
  else
    result := 0;
end;

// MinFloat (array)
//
function MinFloat(const v: array of Single): Single;
var
  i: Integer;
begin
  if Length(v) > 0 then
  begin
    result := v[0];
    for i := 1 to High(v) do
      if v[i] < result then
        result := v[i];
  end
  else
    result := 0;
end;

// MinFloat (single 2)
//
function MinFloat(const V1, V2: Single): Single;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 < V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MinFloat (double 2)
//
function MinFloat(const V1, V2: Double): Double;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 < V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MinFloat (extended 2)
//
function MinFloat(const V1, V2: Extended): Extended;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 < V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MinFloat
//
function MinFloat(const V1, V2, V3: Single): Single;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 <= V2 then
    if V1 <= V3 then
      result := V1
    else if V3 <= V2 then
      result := V3
    else
      result := V2
  else if V2 <= V3 then
    result := V2
  else if V3 <= V1 then
    result := V3
  else
    result := V1;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  fld     v3
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MinFloat (double)
//
function MinFloat(const V1, V2, V3: Double): Double;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 <= V2 then
    if V1 <= V3 then
      result := V1
    else if V3 <= V2 then
      result := V3
    else
      result := V2
  else if V2 <= V3 then
    result := V2
  else if V3 <= V1 then
    result := V3
  else
    result := V1;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  fld     v3
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MinFloat
//
function MinFloat(const V1, V2, V3: Extended): Extended;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 <= V2 then
    if V1 <= V3 then
      result := V1
    else if V3 <= V2 then
      result := V3
    else
      result := V2
  else if V2 <= V3 then
    result := V2
  else if V3 <= V1 then
    result := V3
  else
    result := V1;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  fld     v3
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DB,$C1                 /// fcmovnb st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MaxFloat (single)
//
function MaxFloat(values: PSingleArray; nbItems: Integer): Single; overload;
var
  i, k: Integer;
begin
  if nbItems > 0 then
  begin
    k := 0;
    for i := 1 to nbItems - 1 do
      if values^[i] > values^[k] then
        k := i;
    result := values^[k];
  end
  else
    result := 0;
end;

// MaxFloat (double)
//
function MaxFloat(values: PDoubleArray; nbItems: Integer): Double; overload;
var
  i, k: Integer;
begin
  if nbItems > 0 then
  begin
    k := 0;
    for i := 1 to nbItems - 1 do
      if values^[i] > values^[k] then
        k := i;
    result := values^[k];
  end
  else
    result := 0;
end;

// MaxFloat (extended)
//
function MaxFloat(values: PExtendedArray; nbItems: Integer): Extended; overload;
var
  i, k: Integer;
begin
  if nbItems > 0 then
  begin
    k := 0;
    for i := 1 to nbItems - 1 do
      if values^[i] > values^[k] then
        k := i;
    result := values^[k];
  end
  else
    result := 0;
end;

// MaxFloat
//
function MaxFloat(const v: array of Single): Single;
var
  i: Integer;
begin
  if Length(v) > 0 then
  begin
    result := v[0];
    for i := 1 to High(v) do
      if v[i] > result then
        result := v[i];
  end
  else
    result := 0;
end;

// MaxFloat
//
function MaxFloat(const V1, V2: Single): Single;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 > V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DA,$C1                 /// fcmovb  st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MaxFloat
//
function MaxFloat(const V1, V2: Double): Double;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 > V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DA,$C1                 /// fcmovb  st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MaxFloat
//
function MaxFloat(const V1, V2: Extended): Extended;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 > V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DA,$C1                 /// fcmovb  st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MaxFloat
//
function MaxFloat(const V1, V2, V3: Single): Single;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 >= V2 then
    if V1 >= V3 then
      result := V1
    else if V3 >= V2 then
      result := V3
    else
      result := V2
  else if V2 >= V3 then
    result := V2
  else if V3 >= V1 then
    result := V3
  else
    result := V1;
{$ELSE}
asm
  fld     v1
  fld     v2
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DA,$C1                 /// fcmovb  st(0), st(1)
  ffree   st(1)
  fld     v3
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DA,$C1                 /// fcmovb  st(0), st(1)
  ffree   st(1)
  {$ENDIF}
end;

// MaxFloat
//
function MaxFloat(const V1, V2, V3: Double): Double;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 >= V2 then
    if V1 >= V3 then
      result := V1
    else if V3 >= V2 then
      result := V3
    else
      result := V2
  else if V2 >= V3 then
    result := V2
  else if V3 >= V1 then
    result := V3
  else
    result := V1;
{$ELSE}
asm
  fld     v1
  fld     v2
  fld     v3
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DA,$C1                 /// fcmovb  st(0), st(1)
  db $DB,$F2                 /// fcomi   st(0), st(2)
  db $DA,$C2                 /// fcmovb  st(0), st(2)
  ffree   st(2)
  ffree   st(1)
  {$ENDIF}
end;

// MaxFloat
//
function MaxFloat(const V1, V2, V3: Extended): Extended;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 >= V2 then
    if V1 >= V3 then
      result := V1
    else if V3 >= V2 then
      result := V3
    else
      result := V2
  else if V2 >= V3 then
    result := V2
  else if V3 >= V1 then
    result := V3
  else
    result := V1;
{$ELSE}
asm
  fld     v1
  fld     v2
  fld     v3
  db $DB,$F1                 /// fcomi   st(0), st(1)
  db $DA,$C1                 /// fcmovb  st(0), st(1)
  db $DB,$F2                 /// fcomi   st(0), st(2)
  db $DA,$C2                 /// fcmovb  st(0), st(2)
  ffree   st(2)
  ffree   st(1)
  {$ENDIF}
end;

// MinInteger (2 int)
//
function MinInteger(const V1, V2: Integer): Integer;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 < V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  cmp   eax, edx
  db $0F,$4F,$C2             /// cmovg eax, edx
  {$ENDIF}
end;

// MinInteger (2 card)
//
function MinInteger(const V1, V2: Cardinal): Cardinal;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 < V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  cmp   eax, edx
  db $0F,$47,$C2             /// cmova eax, edx
  {$ENDIF}
end;

// MinInteger
//
function MinInteger(const V1, V2, V3: Integer): Integer;
begin
  if V1 <= V2 then
    if V1 <= V3 then
      result := V1
    else if V3 <= V2 then
      result := V3
    else
      result := V2
  else if V2 <= V3 then
    result := V2
  else if V3 <= V1 then
    result := V3
  else
    result := V1;
end;

// MinInteger
//
function MinInteger(const V1, V2, V3: Cardinal): Cardinal;
begin
  if V1 <= V2 then
    if V1 <= V3 then
      result := V1
    else if V3 <= V2 then
      result := V3
    else
      result := V2
  else if V2 <= V3 then
    result := V2
  else if V3 <= V1 then
    result := V3
  else
    result := V1;
end;

// MaxInteger (2 int)
//
function MaxInteger(const V1, V2: Integer): Integer;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 > V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  cmp   eax, edx
  db $0F,$4C,$C2             /// cmovl eax, edx
  {$ENDIF}
end;

// MaxInteger (2 card)
//
function MaxInteger(const V1, V2: Cardinal): Cardinal;
{$IFDEF GEOMETRY_NO_ASM}
begin
  if V1 > V2 then
    result := V1
  else
    result := V2;
{$ELSE}
asm
  cmp   eax, edx
  db $0F,$42,$C2             /// cmovb eax, edx
  {$ENDIF}
end;

// MaxInteger
//
function MaxInteger(const V1, V2, V3: Integer): Integer;
begin
  if V1 >= V2 then
    if V1 >= V3 then
      result := V1
    else if V3 >= V2 then
      result := V3
    else
      result := V2
  else if V2 >= V3 then
    result := V2
  else if V3 >= V1 then
    result := V3
  else
    result := V1;
end;

// MaxInteger
//
function MaxInteger(const V1, V2, V3: Cardinal): Cardinal;
begin
  if V1 >= V2 then
    if V1 >= V3 then
      result := V1
    else if V3 >= V2 then
      result := V3
    else
      result := V2
  else if V2 >= V3 then
    result := V2
  else if V3 >= V1 then
    result := V3
  else
    result := V1;
end;

// TriangleArea
//
function TriangleArea(const p1, p2, p3: TAffineVector): Single;
begin
  result := 0.5 * VectorLength(VectorCrossProduct(VectorSubtract(p2, p1),
    VectorSubtract(p3, p1)));
end;

// PolygonArea
//
function PolygonArea(const p: PAffineVectorArray; nSides: Integer): Single;
var
  r: TAffineVector;
  i: Integer;
  p1, p2, p3: PAffineVector;
begin
  result := 0;
  if nSides > 2 then
  begin
    RstVector(r);
    p1 := @p[0];
    p2 := @p[1];
    for i := 2 to nSides - 1 do
    begin
      p3 := @p[i];
      AddVector(r, VectorCrossProduct(VectorSubtract(p2^, p1^),
        VectorSubtract(p3^, p1^)));
      p2 := p3;
    end;
    result := VectorLength(r) * 0.5;
  end;
end;

// TriangleSignedArea
//
function TriangleSignedArea(const p1, p2, p3: TAffineVector): Single;
begin
  result := 0.5 * ((p2[0] - p1[0]) * (p3[1] - p1[1]) - (p3[0] - p1[0]) *
    (p2[1] - p1[1]));
end;

// PolygonSignedArea
//
function PolygonSignedArea(const p: PAffineVectorArray;
  nSides: Integer): Single;
var
  i: Integer;
  p1, p2, p3: PAffineVector;
begin
  result := 0;
  if nSides > 2 then
  begin
    p1 := @(p^[0]);
    p2 := @(p^[1]);
    for i := 2 to nSides - 1 do
    begin
      p3 := @(p^[i]);
      result := result + (p2^[0] - p1^[0]) * (p3^[1] - p1^[1]) -
        (p3^[0] - p1^[0]) * (p2^[1] - p1^[1]);
      p2 := p3;
    end;
    result := result * 0.5;
  end;
end;

// ScaleFloatArray (raw)
//
procedure ScaleFloatArray(values: PSingleArray; nb: Integer;
  var factor: Single);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU

  push  edx
  shr   edx, 2
  or    edx, edx
  jz    @@FPU

  db $0F,$6E,$39           /// movd        mm7, [ecx]
  db $0F,$62,$FF           /// punpckldq   mm7, mm7

@@3DNowLoop:
  db $0F,$0D,$48,$40       /// prefetchw [eax+64]
  db $0F,$6F,$00           /// movq  mm0, [eax]
  db $0F,$6F,$48,$08       /// movq  mm1, [eax+8]
  db $0F,$0F,$C7,$B4       /// pfmul mm0, mm7
  db $0F,$0F,$CF,$B4       /// pfmul mm1, mm7
  db $0F,$7F,$00           /// movq  [eax], mm0
  db $0F,$7F,$48,$08       /// movq  [eax+8], mm1

  add   eax, 16
  dec   edx
  jnz   @@3DNowLoop

  pop   edx
  and   edx, 3
  db $0F,$0E               /// femms

@@FPU:
  push  edx
  shr   edx, 1
  or    edx, edx
  jz    @@FPULone

@@FPULoop:
  fld   dword ptr [eax]
  fmul  dword ptr [ecx]
  fstp  dword ptr [eax]
  fld   dword ptr [eax+4]
  fmul  dword ptr [ecx]
  fstp  dword ptr [eax+4]

  add   eax, 8
  dec   edx
  jnz   @@FPULoop

@@FPULone:
  pop   edx
  test  edx, 1
  jz    @@End

  fld   dword ptr [eax]
  fmul  dword ptr [ecx]
  fstp  dword ptr [eax]

@@End:
  {$ELSE}
var
  i: Integer;
begin
  for i := 0 to nb - 1 do
    values^[i] := values^[i] * factor;
{$ENDIF}
end;

// ScaleFloatArray (array)
//
procedure ScaleFloatArray(var values: TSingleArray; factor: Single);
begin
  if Length(values) > 0 then
    ScaleFloatArray(@values[0], Length(values), factor);
end;

// OffsetFloatArray (raw)
//
procedure OffsetFloatArray(values: PSingleArray; nb: Integer;
  var delta: Single);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test vSIMD, 1
  jz @@FPU

  push  edx
  shr   edx, 2
  or    edx, edx
  jz    @@FPU

  db $0F,$6E,$39           /// movd  mm7, [ecx]
  db $0F,$62,$FF           /// punpckldq   mm7, mm7

@@3DNowLoop:
  db $0F,$0D,$48,$40       /// prefetchw [eax+64]
  db $0F,$6F,$00           /// movq  mm0, [eax]
  db $0F,$6F,$48,$08       /// movq  mm1, [eax+8]
  db $0F,$0F,$C7,$9E       /// pfadd mm0, mm7
  db $0F,$0F,$CF,$9E       /// pfadd mm1, mm7
  db $0F,$7F,$00           /// movq  [eax], mm0
  db $0F,$7F,$48,$08       /// movq  [eax+8], mm1

  add   eax, 16
  dec   edx
  jnz   @@3DNowLoop

  pop   edx
  and   edx, 3
  db $0F,$0E               /// femms

@@FPU:
  push  edx
  shr   edx, 1
  or    edx, edx
  jz    @@FPULone

@@FPULoop:
  fld   dword ptr [eax]
  fadd  dword ptr [ecx]
  fstp  dword ptr [eax]
  fld   dword ptr [eax+4]
  fadd  dword ptr [ecx]
  fstp  dword ptr [eax+4]

  add   eax, 8
  dec   edx
  jnz   @@FPULoop

@@FPULone:
  pop   edx
  test  edx, 1
  jz    @@End

  fld   dword ptr [eax]
  fadd  dword ptr [ecx]
  fstp  dword ptr [eax]

@@End:
  {$ELSE}
var
  i: Integer;
begin
  for i := 0 to nb - 1 do
    values^[i] := values^[i] + delta;
{$ENDIF}
end;

// ScaleFloatArray (array)
//
procedure OffsetFloatArray(var values: array of Single; delta: Single);
begin
  if Length(values) > 0 then
    ScaleFloatArray(@values[0], Length(values), delta);
end;

// OffsetFloatArray (raw, raw)
//
procedure OffsetFloatArray(valuesDest, valuesDelta: PSingleArray; nb: Integer);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  test  ecx, ecx
  jz    @@End

@@FPULoop:
  dec   ecx
  fld   dword ptr [eax+ecx*4]
  fadd  dword ptr [edx+ecx*4]
  fstp  dword ptr [eax+ecx*4]
  jnz   @@FPULoop

@@End:
  {$ELSE}
var
  i: Integer;
begin
  for i := 0 to nb - 1 do
    valuesDest^[i] := valuesDest^[i] + valuesDelta^[i];
{$ENDIF}
end;

// MaxXYZComponent
//
function MaxXYZComponent(const v: TVector): Single; overload;
begin
  result := MaxFloat(v[0], v[1], v[2]);
end;

// MaxXYZComponent
//
function MaxXYZComponent(const v: TAffineVector): Single; overload;
begin
  result := MaxFloat(v[0], v[1], v[2]);
end;

// MinXYZComponent
//
function MinXYZComponent(const v: TVector): Single; overload;
begin
  if v[0] <= v[1] then
    if v[0] <= v[2] then
      result := v[0]
    else if v[2] <= v[1] then
      result := v[2]
    else
      result := v[1]
  else if v[1] <= v[2] then
    result := v[1]
  else if v[2] <= v[0] then
    result := v[2]
  else
    result := v[0];
end;

// MinXYZComponent
//
function MinXYZComponent(const v: TAffineVector): Single; overload;
begin
  result := MinFloat(v[0], v[1], v[2]);
end;

// MaxAbsXYZComponent
//
function MaxAbsXYZComponent(v: TVector): Single;
begin
  AbsVector(v);
  result := MaxXYZComponent(v);
end;

// MinAbsXYZComponent
//
function MinAbsXYZComponent(v: TVector): Single;
begin
  AbsVector(v);
  result := MinXYZComponent(v);
end;

// MaxVector (hmg)
//
procedure MaxVector(var v: TVector; const V1: TVector);
begin
  if V1[0] > v[0] then
    v[0] := V1[0];
  if V1[1] > v[1] then
    v[1] := V1[1];
  if V1[2] > v[2] then
    v[2] := V1[2];
  if V1[3] > v[3] then
    v[3] := V1[3];
end;

// MaxVector (affine)
//
procedure MaxVector(var v: TAffineVector; const V1: TAffineVector); overload;
begin
  if V1[0] > v[0] then
    v[0] := V1[0];
  if V1[1] > v[1] then
    v[1] := V1[1];
  if V1[2] > v[2] then
    v[2] := V1[2];
end;

// MinVector (hmg)
//
procedure MinVector(var v: TVector; const V1: TVector);
begin
  if V1[0] < v[0] then
    v[0] := V1[0];
  if V1[1] < v[1] then
    v[1] := V1[1];
  if V1[2] < v[2] then
    v[2] := V1[2];
  if V1[3] < v[3] then
    v[3] := V1[3];
end;

// MinVector (affine)
//
procedure MinVector(var v: TAffineVector; const V1: TAffineVector);
begin
  if V1[0] < v[0] then
    v[0] := V1[0];
  if V1[1] < v[1] then
    v[1] := V1[1];
  if V1[2] < v[2] then
    v[2] := V1[2];
end;

// SortArrayAscending (extended)
//
procedure SortArrayAscending(var a: array of Extended);
var
  i, J, M: Integer;
  buf: Extended;
begin
  for i := Low(a) to High(a) - 1 do
  begin
    M := i;
    for J := i + 1 to High(a) do
      if a[J] < a[M] then
        M := J;
    if M <> i then
    begin
      buf := a[M];
      a[M] := a[i];
      a[i] := buf;
    end;
  end;
end;

// ClampValue (min-max)
//
function ClampValue(const aValue, aMin, aMax: Single): Single;
// begin
{$IFNDEF GEOMETRY_NO_ASM}
asm   // 118
  fld   aValue
  fcom  aMin
  fstsw ax
  sahf
  jb    @@ReturnMin
@@CompMax:
  fcom  aMax
  fstsw ax
  sahf
  jnbe  @@ReturnMax
  pop   ebp
  ret   $0C

@@ReturnMax:
  fld   aMax
  jmp @@End
@@ReturnMin:
  fld   aMin
@@End:
  ffree st(1)
end;
{$ELSE}
begin // 134
  if aValue < aMin then
    result := aMin
  else if aValue > aMax then
    result := aMax
  else
    result := aValue;
end;
{$ENDIF}

// ClampValue (min-)
//
function ClampValue(const aValue, aMin: Single): Single;
begin
  if aValue < aMin then
    result := aMin
  else
    result := aValue;
end;

// MakeAffineDblVector
//
function MakeAffineDblVector(var v: array of Double): TAffineDblVector;
begin
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
end;

// MakeDblVector
//
function MakeDblVector(var v: array of Double): THomogeneousDblVector;
// creates a vector from given values
// EAX contains address of V
// ECX contains address to result vector
// EDX contains highest index of V
{$IFNDEF GEOMETRY_NO_ASM}
asm
  PUSH EDI
  PUSH ESI
  MOV EDI, ECX
  MOV ESI, EAX
  MOV ECX, 8
  REP MOVSD
  POP ESI
  POP EDI
  {$ELSE}
begin
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
  result[3] := v[3];
{$ENDIF}
end;

// PointInPolygon
//
function PointInPolygon(var xp, yp: array of Single; x, y: Single): Boolean;
// The code below is from Wm. Randolph Franklin <wrf@ecse.rpi.edu>
// with some minor modifications for speed.  It returns 1 for strictly
// interior points, 0 for strictly exterior, and 0 or 1 for points on
// the boundary.
var
  i, J: Integer;
begin
  result := False;
  if High(xp) = High(yp) then
  begin
    J := High(xp);
    for i := 0 to High(xp) do
    begin
      if ((((yp[i] <= y) and (y < yp[J])) or ((yp[J] <= y) and (y < yp[i]))) and
        (x < (xp[J] - xp[i]) * (y - yp[i]) / (yp[J] - yp[i]) + xp[i])) then
        result := not result;
      J := i;
    end;
  end;
end;

// DivMod
//
procedure DivMod(Dividend: Integer; Divisor: Word; var result, Remainder: Word);
{$IFNDEF GEOMETRY_NO_ASM}
asm
  push  ebx
  mov   ebx, edx
  mov   edx, eax
  shr   edx, 16
  div   bx
  mov   ebx, remainder
  mov   [ecx], ax
  mov   [ebx], dx
  pop   ebx
  {$ELSE}
begin
  result := Dividend div Divisor;
  Remainder := Dividend mod Divisor;
{$ENDIF}
end;

// ConvertRotation
//
function ConvertRotation(const Angles: TAffineVector): TVector;

{ Rotation of the Angle t about the axis (X, Y, Z) is given by:

  | X^2 + (1-X^2) Cos(t),    XY(1-Cos(t))  +  Z Sin(t), XZ(1-Cos(t))-Y Sin(t) |
  M = | XY(1-Cos(t))-Z Sin(t), Y^2 + (1-Y^2) Cos(t),      YZ(1-Cos(t)) + X Sin(t) |
  | XZ(1-Cos(t)) + Y Sin(t), YZ(1-Cos(t))-X Sin(t),   Z^2 + (1-Z^2) Cos(t)    |

  Rotation about the three axes (Angles a1, a2, a3) can be represented as
  the product of the individual rotation matrices:

  | 1  0       0       | | Cos(a2) 0 -Sin(a2) | |  Cos(a3) Sin(a3) 0 |
  | 0  Cos(a1) Sin(a1) | * | 0       1  0       | * | -Sin(a3) Cos(a3) 0 |
  | 0 -Sin(a1) Cos(a1) | | Sin(a2) 0  Cos(a2) | |  0       0       1 |
  Mx                       My                     Mz

  We now want to solve for X, Y, Z, and t given 9 equations in 4 unknowns.
  Using the diagonal elements of the two matrices, we get:

  X^2 + (1-X^2) Cos(t) = M[0][0]
  Y^2 + (1-Y^2) Cos(t) = M[1][1]
  Z^2 + (1-Z^2) Cos(t) = M[2][2]

  Adding the three equations, we get:

  X^2  +  Y^2  +  Z^2 - (M[0][0]  +  M[1][1]  +  M[2][2]) =
  - (3 - X^2 - Y^2 - Z^2) Cos(t)

  Since (X^2  +  Y^2  +  Z^2) = 1, we can rewrite as:

  Cos(t) = (1 - (M[0][0]  +  M[1][1]  +  M[2][2])) / 2

  Solving for t, we get:

  t = Acos(((M[0][0]  +  M[1][1]  +  M[2][2]) - 1) / 2)

  We can substitute t into the equations for X^2, Y^2, and Z^2 above
  to get the values for X, Y, and Z.  To find the proper signs we note
  that:

  2 X Sin(t) = M[1][2] - M[2][1]
  2 Y Sin(t) = M[2][0] - M[0][2]
  2 Z Sin(t) = M[0][1] - M[1][0]
}
var
  Axis1, Axis2: TVector3f;
  M, m1, m2: TMatrix;
  cost, cost1, sint, s1, s2, s3: Single;
  i: Integer;
begin
  // see if we are only rotating about a single Axis
  if Abs(Angles[x]) < EPSILON then
  begin
    if Abs(Angles[y]) < EPSILON then
    begin
      SetVector(result, 0, 0, 1, Angles[z]);
      Exit;
    end
    else if Abs(Angles[z]) < EPSILON then
    begin
      SetVector(result, 0, 1, 0, Angles[y]);
      Exit;
    end
  end
  else if (Abs(Angles[y]) < EPSILON) and (Abs(Angles[z]) < EPSILON) then
  begin
    SetVector(result, 1, 0, 0, Angles[x]);
    Exit;
  end;

  // make the rotation matrix
  Axis1 := XVector;
  M := CreateRotationMatrix(Axis1, Angles[x]);

  Axis2 := YVector;
  m2 := CreateRotationMatrix(Axis2, Angles[y]);
  m1 := MatrixMultiply(M, m2);

  Axis2 := ZVector;
  m2 := CreateRotationMatrix(Axis2, Angles[z]);
  M := MatrixMultiply(m1, m2);

  cost := ((M[x, x] + M[y, y] + M[z, z]) - 1) / 2;
  if cost < -1 then
    cost := -1
  else if cost > 1 - EPSILON then
  begin
    // Bad Angle - this would cause a crash
    SetVector(result, XHmgVector);
    Exit;
  end;

  cost1 := 1 - cost;
  SetVector(result, Sqrt((M[x, x] - cost) / cost1),
    Sqrt((M[y, y] - cost) / cost1), Sqrt((M[z, z] - cost) / cost1),
    VectorGeometry.ArcCos(cost));

  sint := 2 * Sqrt(1 - cost * cost); // This is actually 2 Sin(t)

  // Determine the proper signs
  for i := 0 to 7 do
  begin
    if (i and 1) > 1 then
      s1 := -1
    else
      s1 := 1;
    if (i and 2) > 1 then
      s2 := -1
    else
      s2 := 1;
    if (i and 4) > 1 then
      s3 := -1
    else
      s3 := 1;
    if (Abs(s1 * result[x] * sint - M[y, z] + M[z, y]) < EPSILON2) and
      (Abs(s2 * result[y] * sint - M[z, x] + M[x, z]) < EPSILON2) and
      (Abs(s3 * result[z] * sint - M[x, y] + M[y, x]) < EPSILON2) then
    begin
      // We found the right combination of signs
      result[x] := result[x] * s1;
      result[y] := result[y] * s2;
      result[z] := result[z] * s3;
      Exit;
    end;
  end;
end;

// QuaternionSlerp
//
function QuaternionSlerp(const QStart, QEnd: TQuaternion; Spin: Integer;
  T: Single): TQuaternion;
var
  beta, // complementary interp parameter
  Theta, // Angle between A and B
  sint, cost, // sine, cosine of theta
  phi: Single; // theta plus spins
  bflip: Boolean; // use negativ t?
begin
  // cosine theta
  cost := VectorAngleCosine(QStart.ImagPart, QEnd.ImagPart);

  // if QEnd is on opposite hemisphere from QStart, use -QEnd instead
  if cost < 0 then
  begin
    cost := -cost;
    bflip := True;
  end
  else
    bflip := False;

  // if QEnd is (within precision limits) the same as QStart,
  // just linear interpolate between QStart and QEnd.
  // Can't do spins, since we don't know what direction to spin.

  if (1 - cost) < EPSILON then
    beta := 1 - T
  else
  begin
    // normal case
    Theta := VectorGeometry.ArcCos(cost);
    phi := Theta + Spin * PI;
    sint := Sin(Theta);
    beta := Sin(Theta - T * phi) / sint;
    T := Sin(T * phi) / sint;
  end;

  if bflip then
    T := -T;

  // interpolate
  result.ImagPart[x] := beta * QStart.ImagPart[x] + T * QEnd.ImagPart[x];
  result.ImagPart[y] := beta * QStart.ImagPart[y] + T * QEnd.ImagPart[y];
  result.ImagPart[z] := beta * QStart.ImagPart[z] + T * QEnd.ImagPart[z];
  result.RealPart := beta * QStart.RealPart + T * QEnd.RealPart;
end;

// QuaternionSlerp
//
function QuaternionSlerp(const source, dest: TQuaternion; const T: Single)
  : TQuaternion;
var
  to1: array [0 .. 4] of Single;
  omega, cosom, sinom, scale0, scale1: Extended;
  // t goes from 0 to 1
  // absolute rotations
begin
  // calc cosine
  cosom := source.ImagPart[0] * dest.ImagPart[0] + source.ImagPart[1] *
    dest.ImagPart[1] + source.ImagPart[2] * dest.ImagPart[2] + source.RealPart *
    dest.RealPart;
  // adjust signs (if necessary)
  if cosom < 0 then
  begin
    cosom := -cosom;
    to1[0] := -dest.ImagPart[0];
    to1[1] := -dest.ImagPart[1];
    to1[2] := -dest.ImagPart[2];
    to1[3] := -dest.RealPart;
  end
  else
  begin
    to1[0] := dest.ImagPart[0];
    to1[1] := dest.ImagPart[1];
    to1[2] := dest.ImagPart[2];
    to1[3] := dest.RealPart;
  end;
  // calculate coefficients
  if ((1.0 - cosom) > EPSILON2) then
  begin // standard case (slerp)
    omega := VectorGeometry.ArcCos(cosom);
    sinom := 1 / Sin(omega);
    scale0 := Sin((1.0 - T) * omega) * sinom;
    scale1 := Sin(T * omega) * sinom;
  end
  else
  begin // "from" and "to" quaternions are very close
    // ... so we can do a linear interpolation
    scale0 := 1.0 - T;
    scale1 := T;
  end;
  // calculate final values
  result.ImagPart[0] := scale0 * source.ImagPart[0] + scale1 * to1[0];
  result.ImagPart[1] := scale0 * source.ImagPart[1] + scale1 * to1[1];
  result.ImagPart[2] := scale0 * source.ImagPart[2] + scale1 * to1[2];
  result.RealPart := scale0 * source.RealPart + scale1 * to1[3];
  NormalizeQuaternion(result);
end;

// VectorDblToFlt
//
function VectorDblToFlt(const v: THomogeneousDblVector): THomogeneousVector;
// converts a vector containing double sized values into a vector with single sized values
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  QWORD PTR [EAX]
  FSTP DWORD PTR [EDX]
  FLD  QWORD PTR [EAX + 8]
  FSTP DWORD PTR [EDX + 4]
  FLD  QWORD PTR [EAX + 16]
  FSTP DWORD PTR [EDX + 8]
  FLD  QWORD PTR [EAX + 24]
  FSTP DWORD PTR [EDX + 12]
  {$ELSE}
begin
{$HINTS OFF}
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
  result[3] := v[3];
{$HINTS ON}
{$ENDIF}
end;

// VectorAffineDblToFlt
//
function VectorAffineDblToFlt(const v: TAffineDblVector): TAffineVector;
// converts a vector containing double sized values into a vector with single sized values
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  QWORD PTR [EAX]
  FSTP DWORD PTR [EDX]
  FLD  QWORD PTR [EAX + 8]
  FSTP DWORD PTR [EDX + 4]
  FLD  QWORD PTR [EAX + 16]
  FSTP DWORD PTR [EDX + 8]
  {$ELSE}
begin
{$HINTS OFF}
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
{$HINTS ON}
{$ENDIF}
end;

// VectorAffineFltToDbl
//
function VectorAffineFltToDbl(const v: TAffineVector): TAffineDblVector;
// converts a vector containing single sized values into a vector with double sized values
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSTP QWORD PTR [EDX]
  FLD  DWORD PTR [EAX + 4]
  FSTP QWORD PTR [EDX + 8]
  FLD  DWORD PTR [EAX + 8]
  FSTP QWORD PTR [EDX + 16]
  {$ELSE}
begin
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
{$ENDIF}
end;

// VectorFltToDbl
//
function VectorFltToDbl(const v: TVector): THomogeneousDblVector;
// converts a vector containing single sized values into a vector with double sized values
{$IFNDEF GEOMETRY_NO_ASM}
asm
  FLD  DWORD PTR [EAX]
  FSTP QWORD PTR [EDX]
  FLD  DWORD PTR [EAX + 4]
  FSTP QWORD PTR [EDX + 8]
  FLD  DWORD PTR [EAX + 8]
  FSTP QWORD PTR [EDX + 16]
  FLD  DWORD PTR [EAX + 12]
  FSTP QWORD PTR [EDX + 24]
  {$ELSE}
begin
  result[0] := v[0];
  result[1] := v[1];
  result[2] := v[2];
  result[3] := v[3];
{$ENDIF}
end;

// ----------------- coordinate system manipulation functions -----------------------------------------------------------

// Turn (Y axis)
//
function Turn(const Matrix: TMatrix; angle: Single): TMatrix;
begin
  result := MatrixMultiply(Matrix,
    CreateRotationMatrix(AffineVectorMake(Matrix[1][0], Matrix[1][1],
    Matrix[1][2]), angle));
end;

// Turn (direction)
//
function Turn(const Matrix: TMatrix; const MasterUp: TAffineVector;
  angle: Single): TMatrix;
begin
  result := MatrixMultiply(Matrix, CreateRotationMatrix(MasterUp, angle));
end;

// Pitch (X axis)
//
function Pitch(const Matrix: TMatrix; angle: Single): TMatrix;
begin
  result := MatrixMultiply(Matrix,
    CreateRotationMatrix(AffineVectorMake(Matrix[0][0], Matrix[0][1],
    Matrix[0][2]), angle));
end;

// Pitch (direction)
//
function Pitch(const Matrix: TMatrix; const MasterRight: TAffineVector;
  angle: Single): TMatrix; overload;
begin
  result := MatrixMultiply(Matrix, CreateRotationMatrix(MasterRight, angle));
end;

// Roll (Z axis)
//
function Roll(const Matrix: TMatrix; angle: Single): TMatrix;
begin
  result := MatrixMultiply(Matrix,
    CreateRotationMatrix(AffineVectorMake(Matrix[2][0], Matrix[2][1],
    Matrix[2][2]), angle));
end;

// Roll (direction)
//
function Roll(const Matrix: TMatrix; const MasterDirection: TAffineVector;
  angle: Single): TMatrix; overload;
begin
  result := MatrixMultiply(Matrix,
    CreateRotationMatrix(MasterDirection, angle));
end;

// RayCastPlaneIntersect (plane defined by point+normal)
//
function RayCastPlaneIntersect(const rayStart, rayVector: TVector;
  const planePoint, planeNormal: TVector;
  intersectPoint: PVector = nil): Boolean;
var
  sp: TVector;
  T, d: Single;
begin
  d := VectorDotProduct(rayVector, planeNormal);
  result := ((d > EPSILON2) or (d < -EPSILON2));
  if result and Assigned(intersectPoint) then
  begin
    VectorSubtract(planePoint, rayStart, sp);
    d := 1 / d; // will keep one FPU unit busy during dot product calculation
    T := VectorDotProduct(sp, planeNormal) * d;
    if T > 0 then
      VectorCombine(rayStart, rayVector, T, intersectPoint^)
    else
      result := False;
  end;
end;

// RayCastPlaneXZIntersect
//
function RayCastPlaneXZIntersect(const rayStart, rayVector: TVector;
  const planeY: Single; intersectPoint: PVector = nil): Boolean;
var
  T: Single;
begin
  if rayVector[1] = 0 then
    result := False
  else
  begin
    T := (rayStart[1] - planeY) / rayVector[1];
    if T < 0 then
    begin
      if Assigned(intersectPoint) then
        VectorCombine(rayStart, rayVector, T, intersectPoint^);
      result := True;
    end
    else
      result := False;
  end;
end;

// RayCastTriangleIntersect
//
function RayCastTriangleIntersect(const rayStart, rayVector: TVector;
  const p1, p2, p3: TAffineVector; intersectPoint: PVector = nil;
  intersectNormal: PVector = nil): Boolean;
var
  pvec: TAffineVector;
  V1, V2, qvec, tvec: TVector;
  T, u, v, det, invDet: Single;
begin
  VectorSubtract(p2, p1, V1);
  VectorSubtract(p3, p1, V2);
  VectorCrossProduct(rayVector, V2, pvec);
  det := VectorDotProduct(V1, pvec);
  if ((det < EPSILON2) and (det > -EPSILON2)) then
  begin // vector is parallel to triangle's plane
    result := False;
    Exit;
  end;
  invDet := cOne / det;
  VectorSubtract(rayStart, p1, tvec);
  u := VectorDotProduct(tvec, pvec) * invDet;
  if (u < 0) or (u > 1) then
    result := False
  else
  begin
    qvec := VectorCrossProduct(tvec, V1);
    v := VectorDotProduct(rayVector, qvec) * invDet;
    result := (v >= 0) and (u + v <= 1);
    if result then
    begin
      T := VectorDotProduct(V2, qvec) * invDet;
      if T > 0 then
      begin
        if intersectPoint <> nil then
          VectorCombine(rayStart, rayVector, T, intersectPoint^);
        if intersectNormal <> nil then
          VectorCrossProduct(V1, V2, intersectNormal^);
      end
      else
        result := False;
    end;
  end;
end;

// RayCastMinDistToPoint
//
function RayCastMinDistToPoint(const rayStart, rayVector: TVector;
  const point: TVector): Single;
var
  proj: Single;
begin
  proj := PointProject(point, rayStart, rayVector);
  if proj <= 0 then
    proj := 0; // rays don't go backward!
  result := VectorDistance(point, VectorCombine(rayStart, rayVector, 1, proj));
end;

// RayCastIntersectsSphere
//
function RayCastIntersectsSphere(const rayStart, rayVector: TVector;
  const sphereCenter: TVector; const SphereRadius: Single): Boolean;
var
  proj: Single;
begin
  proj := PointProject(sphereCenter, rayStart, rayVector);
  if proj <= 0 then
    proj := 0; // rays don't go backward!
  result := (VectorDistance2(sphereCenter, VectorCombine(rayStart, rayVector, 1,
    proj)) <= Sqr(SphereRadius));
end;

// RayCastSphereIntersect
//
function RayCastSphereIntersect(const rayStart, rayVector: TVector;
  const sphereCenter: TVector; const SphereRadius: Single;
  var i1, i2: TVector): Integer;
var
  proj, d2: Single;
  id2: Integer;
  projPoint: TVector;
begin
  proj := PointProject(sphereCenter, rayStart, rayVector);
  VectorCombine(rayStart, rayVector, proj, projPoint);
  d2 := SphereRadius * SphereRadius - VectorDistance2(sphereCenter, projPoint);
  id2 := PInteger(@d2)^;
  if id2 >= 0 then
  begin
    if id2 = 0 then
    begin
      if PInteger(@proj)^ > 0 then
      begin
        VectorCombine(rayStart, rayVector, proj, i1);
        result := 1;
        Exit;
      end;
    end
    else if id2 > 0 then
    begin
      d2 := Sqrt(d2);
      if proj >= d2 then
      begin
        VectorCombine(rayStart, rayVector, proj - d2, i1);
        VectorCombine(rayStart, rayVector, proj + d2, i2);
        result := 2;
        Exit;
      end
      else if proj + d2 >= 0 then
      begin
        VectorCombine(rayStart, rayVector, proj + d2, i1);
        result := 1;
        Exit;
      end;
    end;
  end;
  result := 0;
end;

// RayCastBoxIntersect
//
function RayCastBoxIntersect(const rayStart, rayVector, aMinExtent,
  aMaxExtent: TAffineVector; intersectPoint: PAffineVector = nil): Boolean;
var
  i, planeInd: Integer;
  ResAFV, MaxDist, plane: TAffineVector;
  isMiddle: array [0 .. 2] of Boolean;
begin
  // Find plane.
  result := True;
  for i := 0 to 2 do
    if rayStart[i] < aMinExtent[i] then
    begin
      plane[i] := aMinExtent[i];
      isMiddle[i] := False;
      result := False;
    end
    else if rayStart[i] > aMaxExtent[i] then
    begin
      plane[i] := aMaxExtent[i];
      isMiddle[i] := False;
      result := False;
    end
    else
    begin
      isMiddle[i] := True;
    end;
  if result then
  begin
    // rayStart inside box.
    if intersectPoint <> nil then
      intersectPoint^ := rayStart;
  end
  else
  begin
    // Distance to plane.
    planeInd := 0;
    for i := 0 to 2 do
      if isMiddle[i] or (rayVector[i] = 0) then
        MaxDist[i] := -1
      else
      begin
        MaxDist[i] := (plane[i] - rayStart[i]) / rayVector[i];
        if MaxDist[i] > 0 then
        begin
          if MaxDist[planeInd] < MaxDist[i] then
            planeInd := i;
          result := True;
        end;
      end;
    // Inside box ?
    if result then
    begin
      for i := 0 to 2 do
        if planeInd = i then
          ResAFV[i] := plane[i]
        else
        begin
          ResAFV[i] := rayStart[i] + MaxDist[planeInd] * rayVector[i];
          result := (ResAFV[i] >= aMinExtent[i]) and
            (ResAFV[i] <= aMaxExtent[i]);
          if not result then
            Exit;
        end;
      if intersectPoint <> nil then
        intersectPoint^ := ResAFV;
    end;
  end;
end;

// SphereVisibleRadius
//
function SphereVisibleRadius(distance, radius: Single): Single;
var
  d2, r2, ir, tr: Single;
begin
  { ir² + r² = d²
    r² + tr² = vr²
    vr² + d² = (ir+tr)² = ir² + 2.ir.tr + tr²

    ir² + 2.ir.tr + tr² = d² + r² + tr²
    2.ir.tr = d² + r² - ir² }
  d2 := distance * distance;
  r2 := radius * radius;
  ir := Sqrt(d2 - r2);
  tr := (d2 + r2 - Sqr(ir)) / (2 * ir);

  result := Sqrt(r2 + Sqr(tr));
end;

// IntersectLinePlane
//
function IntersectLinePlane(const point, direction: TVector;
  const plane: THmgPlane; intersectPoint: PVector = nil): Integer;
var
  a, b: Extended;
  T: Single;
begin
  a := VectorDotProduct(plane, direction);
  // direction projected to plane normal
  b := PlaneEvaluatePoint(plane, point); // distance to plane
  if a = 0 then
  begin // direction is parallel to plane
    if b = 0 then
      result := -1 // line is inside plane
    else
      result := 0; // line is outside plane
  end
  else
  begin
    if Assigned(intersectPoint) then
    begin
      T := -b / a; // parameter of intersection
      intersectPoint^ := point;
      // calculate intersection = p + t*d
      CombineVector(intersectPoint^, direction, T);
    end;
    result := 1;
  end;
end;

// TriangleBoxIntersect
//
function IntersectTriangleBox(const p1, p2, p3, aMinExtent,
  aMaxExtent: TAffineVector): Boolean;
var
  RayDir, iPoint: TAffineVector;
  BoxDiagPt, BoxDiagPt2, BoxDiagDir, iPnt: TVector;
begin
  // Triangle edge (p2, p1) - Box intersection
  VectorSubtract(p2, p1, RayDir);
  result := RayCastBoxIntersect(p1, RayDir, aMinExtent, aMaxExtent, @iPoint);
  if result then
    result := VectorNorm(VectorSubtract(p1, iPoint)) <
      VectorNorm(VectorSubtract(p1, p2));
  if result then
    Exit;

  // Triangle edge (p3, p1) - Box intersection
  VectorSubtract(p3, p1, RayDir);
  result := RayCastBoxIntersect(p1, RayDir, aMinExtent, aMaxExtent, @iPoint);
  if result then
    result := VectorNorm(VectorSubtract(p1, iPoint)) <
      VectorNorm(VectorSubtract(p1, p3));
  if result then
    Exit;

  // Triangle edge (p2, p3) - Box intersection
  VectorSubtract(p2, p3, RayDir);
  result := RayCastBoxIntersect(p3, RayDir, aMinExtent, aMaxExtent, @iPoint);
  if result then
    result := VectorNorm(VectorSubtract(p3, iPoint)) <
      VectorNorm(VectorSubtract(p3, p2));
  if result then
    Exit;

  // Triangle - Box diagonal 1 intersection
  BoxDiagPt := VectorMake(aMinExtent);
  VectorSubtract(aMaxExtent, aMinExtent, BoxDiagDir);
  result := RayCastTriangleIntersect(BoxDiagPt, BoxDiagDir, p1, p2, p3, @iPnt);
  if result then
    result := VectorNorm(VectorSubtract(BoxDiagPt, iPnt)) <
      VectorNorm(VectorSubtract(aMaxExtent, aMinExtent));
  if result then
    Exit;

  // Triangle - Box diagonal 2 intersection
  BoxDiagPt := VectorMake(aMinExtent[0], aMinExtent[1], aMaxExtent[2]);
  BoxDiagPt2 := VectorMake(aMaxExtent[0], aMaxExtent[1], aMinExtent[2]);
  VectorSubtract(BoxDiagPt2, BoxDiagPt, BoxDiagDir);
  result := RayCastTriangleIntersect(BoxDiagPt, BoxDiagDir, p1, p2, p3, @iPnt);
  if result then
    result := VectorNorm(VectorSubtract(BoxDiagPt, iPnt)) <
      VectorNorm(VectorSubtract(BoxDiagPt, BoxDiagPt2));
  if result then
    Exit;

  // Triangle - Box diagonal 3 intersection
  BoxDiagPt := VectorMake(aMinExtent[0], aMaxExtent[1], aMinExtent[2]);
  BoxDiagPt2 := VectorMake(aMaxExtent[0], aMinExtent[1], aMaxExtent[2]);
  VectorSubtract(BoxDiagPt, BoxDiagPt, BoxDiagDir);
  result := RayCastTriangleIntersect(BoxDiagPt, BoxDiagDir, p1, p2, p3, @iPnt);
  if result then
    result := VectorLength(VectorSubtract(BoxDiagPt, iPnt)) <
      VectorLength(VectorSubtract(BoxDiagPt, BoxDiagPt));
  if result then
    Exit;

  // Triangle - Box diagonal 4 intersection
  BoxDiagPt := VectorMake(aMaxExtent[0], aMinExtent[1], aMinExtent[2]);
  BoxDiagPt2 := VectorMake(aMinExtent[0], aMaxExtent[1], aMaxExtent[2]);
  VectorSubtract(BoxDiagPt, BoxDiagPt, BoxDiagDir);
  result := RayCastTriangleIntersect(BoxDiagPt, BoxDiagDir, p1, p2, p3, @iPnt);
  if result then
    result := VectorLength(VectorSubtract(BoxDiagPt, iPnt)) <
      VectorLength(VectorSubtract(BoxDiagPt, BoxDiagPt));
end;

// IntersectSphereBox
//
function IntersectSphereBox(const SpherePos: TVector;
  const SphereRadius: Single; const BoxMatrix: TMatrix;
  // Up Direction and Right must be normalized!
  // Use CubDepht, CubeHeight and CubeWidth
  // for scale TGLCube.
  const BoxScale: TAffineVector; intersectPoint: PAffineVector = nil;
  normal: PAffineVector = nil; depth: PSingle = nil): Boolean;

  function dDOTByColumn(const v: TAffineVector; const M: TMatrix;
    const aColumn: Integer): Single;
  begin
    result := v[0] * M[0, aColumn] + v[1] * M[1, aColumn] + v[2] *
      M[2, aColumn];
  end;

  function dDotByRow(const v: TAffineVector; const M: TMatrix;
    const aRow: Integer): Single;
  begin
    // Equal with: Result := VectorDotProduct(v, AffineVectorMake(m[aRow]));
    result := v[0] * M[aRow, 0] + v[1] * M[aRow, 1] + v[2] * M[aRow, 2];
  end;

  function dDotMatrByColumn(const v: TAffineVector; const M: TMatrix)
    : TAffineVector;
  begin
    result[0] := dDOTByColumn(v, M, 0);
    result[1] := dDOTByColumn(v, M, 1);
    result[2] := dDOTByColumn(v, M, 2);
  end;

  function dDotMatrByRow(const v: TAffineVector; const M: TMatrix)
    : TAffineVector;
  begin
    result[0] := dDotByRow(v, M, 0);
    result[1] := dDotByRow(v, M, 1);
    result[2] := dDotByRow(v, M, 2);
  end;

var
  tmp, l, T, p, Q, r: TAffineVector;
  FaceDistance, MinDistance, Depth1: Single;
  mini, i: Integer;
  isSphereCenterInsideBox: Boolean;
begin
  // this is easy. get the sphere center `p' relative to the box, and then clip
  // that to the boundary of the box (call that point `q'). if q is on the
  // boundary of the box and |p-q| is <= sphere radius, they touch.
  // if q is inside the box, the sphere is inside the box, so set a contact
  // normal to push the sphere to the closest box face.

  p[0] := SpherePos[0] - BoxMatrix[3, 0];
  p[1] := SpherePos[1] - BoxMatrix[3, 1];
  p[2] := SpherePos[2] - BoxMatrix[3, 2];

  isSphereCenterInsideBox := True;
  for i := 0 to 2 do
  begin
    l[i] := 0.5 * BoxScale[i];
    T[i] := dDotByRow(p, BoxMatrix, i);
    if T[i] < -l[i] then
    begin
      T[i] := -l[i];
      isSphereCenterInsideBox := False;
    end
    else if T[i] > l[i] then
    begin
      T[i] := l[i];
      isSphereCenterInsideBox := False;
    end;
  end;

  if isSphereCenterInsideBox then
  begin

    MinDistance := l[0] - Abs(T[0]);
    mini := 0;
    for i := 1 to 2 do
    begin
      FaceDistance := l[i] - Abs(T[i]);
      if FaceDistance < MinDistance then
      begin
        MinDistance := FaceDistance;
        mini := i;
      end;
    end;

    if intersectPoint <> nil then
      intersectPoint^ := AffineVectorMake(SpherePos);

    if normal <> nil then
    begin
      tmp := NullVector;
      if T[mini] > 0 then
        tmp[mini] := 1
      else
        tmp[mini] := -1;
      normal^ := dDotMatrByRow(tmp, BoxMatrix);
    end;

    if depth <> nil then
      depth^ := MinDistance + SphereRadius;

    result := True;
  end
  else
  begin
    Q := dDotMatrByColumn(T, BoxMatrix);
    r := VectorSubtract(p, Q);
    Depth1 := SphereRadius - VectorLength(r);
    if Depth1 < 0 then
    begin
      result := False;
    end
    else
    begin
      if intersectPoint <> nil then
        intersectPoint^ := VectorAdd(Q, AffineVectorMake(BoxMatrix[3]));
      if normal <> nil then
      begin
        normal^ := VectorNormalize(r);
      end;
      if depth <> nil then
        depth^ := Depth1;
      result := True;
    end;
  end;
end;

// ExtractFrustumFromModelViewProjection
//
function ExtractFrustumFromModelViewProjection(const modelViewProj: TMatrix)
  : TFrustum;
begin
  with result do
  begin
    // extract left plane
    pLeft[0] := modelViewProj[0][3] + modelViewProj[0][0];
    pLeft[1] := modelViewProj[1][3] + modelViewProj[1][0];
    pLeft[2] := modelViewProj[2][3] + modelViewProj[2][0];
    pLeft[3] := modelViewProj[3][3] + modelViewProj[3][0];
    NormalizePlane(pLeft);
    // extract top plane
    pTop[0] := modelViewProj[0][3] - modelViewProj[0][1];
    pTop[1] := modelViewProj[1][3] - modelViewProj[1][1];
    pTop[2] := modelViewProj[2][3] - modelViewProj[2][1];
    pTop[3] := modelViewProj[3][3] - modelViewProj[3][1];
    NormalizePlane(pTop);
    // extract right plane
    pRight[0] := modelViewProj[0][3] - modelViewProj[0][0];
    pRight[1] := modelViewProj[1][3] - modelViewProj[1][0];
    pRight[2] := modelViewProj[2][3] - modelViewProj[2][0];
    pRight[3] := modelViewProj[3][3] - modelViewProj[3][0];
    NormalizePlane(pRight);
    // extract bottom plane
    pBottom[0] := modelViewProj[0][3] + modelViewProj[0][1];
    pBottom[1] := modelViewProj[1][3] + modelViewProj[1][1];
    pBottom[2] := modelViewProj[2][3] + modelViewProj[2][1];
    pBottom[3] := modelViewProj[3][3] + modelViewProj[3][1];
    NormalizePlane(pBottom);
    // extract far plane
    pFar[0] := modelViewProj[0][3] - modelViewProj[0][2];
    pFar[1] := modelViewProj[1][3] - modelViewProj[1][2];
    pFar[2] := modelViewProj[2][3] - modelViewProj[2][2];
    pFar[3] := modelViewProj[3][3] - modelViewProj[3][2];
    NormalizePlane(pFar);
    // extract near plane
    pNear[0] := modelViewProj[0][3] + modelViewProj[0][2];
    pNear[1] := modelViewProj[1][3] + modelViewProj[1][2];
    pNear[2] := modelViewProj[2][3] + modelViewProj[2][2];
    pNear[3] := modelViewProj[3][3] + modelViewProj[3][2];
    NormalizePlane(pNear);
  end;
end;

// IsVolumeClipped
//
function IsVolumeClipped(const objPos: TAffineVector; const objRadius: Single;
  const Frustum: TFrustum): Boolean;
var
  negRadius: Single;
begin
  negRadius := -objRadius;
  result := (PlaneEvaluatePoint(Frustum.pLeft, objPos) < negRadius) or
    (PlaneEvaluatePoint(Frustum.pTop, objPos) < negRadius) or
    (PlaneEvaluatePoint(Frustum.pRight, objPos) < negRadius) or
    (PlaneEvaluatePoint(Frustum.pBottom, objPos) < negRadius) or
    (PlaneEvaluatePoint(Frustum.pNear, objPos) < negRadius) or
    (PlaneEvaluatePoint(Frustum.pFar, objPos) < negRadius);
end;

// IsVolumeClipped
//
function IsVolumeClipped(const objPos: TVector; const objRadius: Single;
  const Frustum: TFrustum): Boolean;
begin
  result := IsVolumeClipped(PAffineVector(@objPos)^, objRadius, Frustum);
end;

// IsVolumeClipped
//
function IsVolumeClipped(const min, max: TAffineVector;
  const Frustum: TFrustum): Boolean;
begin
  // change box to sphere
  result := IsVolumeClipped(VectorScale(VectorAdd(min, max), 0.5),
    VectorDistance(min, max) * 0.5, Frustum);
end;

// MakeParallelProjectionMatrix
//
function MakeParallelProjectionMatrix(const plane: THmgPlane;
  const dir: TVector): TMatrix;
// Based on material from a course by William D. Shoaff (www.cs.fit.edu)
var
  dot, invDot: Single;
begin
  dot := plane[0] * dir[0] + plane[1] * dir[1] + plane[2] * dir[2];
  if Abs(dot) < 1E-5 then
  begin
    result := IdentityHmgMatrix;
    Exit;
  end;
  invDot := 1 / dot;

  result[0][0] := (plane[1] * dir[1] + plane[2] * dir[2]) * invDot;
  result[1][0] := (-plane[1] * dir[0]) * invDot;
  result[2][0] := (-plane[2] * dir[0]) * invDot;
  result[3][0] := (-plane[3] * dir[0]) * invDot;

  result[0][1] := (-plane[0] * dir[1]) * invDot;
  result[1][1] := (plane[0] * dir[0] + plane[2] * dir[2]) * invDot;
  result[2][1] := (-plane[2] * dir[1]) * invDot;
  result[3][1] := (-plane[3] * dir[1]) * invDot;

  result[0][2] := (-plane[0] * dir[2]) * invDot;
  result[1][2] := (-plane[1] * dir[2]) * invDot;
  result[2][2] := (plane[0] * dir[0] + plane[1] * dir[1]) * invDot;
  result[3][2] := (-plane[3] * dir[2]) * invDot;

  result[0][3] := 0;
  result[1][3] := 0;
  result[2][3] := 0;
  result[3][3] := 1;
end;

// MakeShadowMatrix
//
function MakeShadowMatrix(const planePoint, planeNormal,
  lightPos: TVector): TMatrix;
var
  planeNormal3, dot: Single;
begin
  // Find the last coefficient by back substitutions
  planeNormal3 := -(planeNormal[0] * planePoint[0] + planeNormal[1] *
    planePoint[1] + planeNormal[2] * planePoint[2]);
  // Dot product of plane and light position
  dot := planeNormal[0] * lightPos[0] + planeNormal[1] * lightPos[1] +
    planeNormal[2] * lightPos[2] + planeNormal3 * lightPos[3];
  // Now do the projection
  // First column
  result[0][0] := dot - lightPos[0] * planeNormal[0];
  result[1][0] := -lightPos[0] * planeNormal[1];
  result[2][0] := -lightPos[0] * planeNormal[2];
  result[3][0] := -lightPos[0] * planeNormal3;
  // Second column
  result[0][1] := -lightPos[1] * planeNormal[0];
  result[1][1] := dot - lightPos[1] * planeNormal[1];
  result[2][1] := -lightPos[1] * planeNormal[2];
  result[3][1] := -lightPos[1] * planeNormal3;
  // Third Column
  result[0][2] := -lightPos[2] * planeNormal[0];
  result[1][2] := -lightPos[2] * planeNormal[1];
  result[2][2] := dot - lightPos[2] * planeNormal[2];
  result[3][2] := -lightPos[2] * planeNormal3;
  // Fourth Column
  result[0][3] := -lightPos[3] * planeNormal[0];
  result[1][3] := -lightPos[3] * planeNormal[1];
  result[2][3] := -lightPos[3] * planeNormal[2];
  result[3][3] := dot - lightPos[3] * planeNormal3;
end;

// MakeReflectionMatrix
//
function MakeReflectionMatrix(const planePoint, planeNormal
  : TAffineVector): TMatrix;
var
  pv2: Single;
begin
  // Precalcs
  pv2 := 2 * VectorDotProduct(planePoint, planeNormal);
  // 1st column
  result[0][0] := 1 - 2 * Sqr(planeNormal[0]);
  result[0][1] := -2 * planeNormal[0] * planeNormal[1];
  result[0][2] := -2 * planeNormal[0] * planeNormal[2];
  result[0][3] := 0;
  // 2nd column
  result[1][0] := -2 * planeNormal[1] * planeNormal[0];
  result[1][1] := 1 - 2 * Sqr(planeNormal[1]);
  result[1][2] := -2 * planeNormal[1] * planeNormal[2];
  result[1][3] := 0;
  // 3rd column
  result[2][0] := -2 * planeNormal[2] * planeNormal[0];
  result[2][1] := -2 * planeNormal[2] * planeNormal[1];
  result[2][2] := 1 - 2 * Sqr(planeNormal[2]);
  result[2][3] := 0;
  // 4th column
  result[3][0] := pv2 * planeNormal[0];
  result[3][1] := pv2 * planeNormal[1];
  result[3][2] := pv2 * planeNormal[2];
  result[3][3] := 1;
end;

// PackRotationMatrix
//
function PackRotationMatrix(const mat: TMatrix): TPackedRotationMatrix;
var
  Q: TQuaternion;
const
  cFact: Single = 32767;
begin
  Q := QuaternionFromMatrix(mat);
  NormalizeQuaternion(Q);
{$HINTS OFF}
  if Q.RealPart < 0 then
  begin
    result[0] := Round(-Q.ImagPart[0] * cFact);
    result[1] := Round(-Q.ImagPart[1] * cFact);
    result[2] := Round(-Q.ImagPart[2] * cFact);
  end
  else
  begin
    result[0] := Round(Q.ImagPart[0] * cFact);
    result[1] := Round(Q.ImagPart[1] * cFact);
    result[2] := Round(Q.ImagPart[2] * cFact);
  end;
{$HINTS ON}
end;

// UnPackRotationMatrix
//
function UnPackRotationMatrix(const packedMatrix
  : TPackedRotationMatrix): TMatrix;
var
  Q: TQuaternion;
const
  cFact: Single = 1 / 32767;
begin
  Q.ImagPart[0] := packedMatrix[0] * cFact;
  Q.ImagPart[1] := packedMatrix[1] * cFact;
  Q.ImagPart[2] := packedMatrix[2] * cFact;
  Q.RealPart := 1 - VectorNorm(Q.ImagPart);
  if Q.RealPart < 0 then
    Q.RealPart := 0
  else
    Q.RealPart := Sqrt(Q.RealPart);
  result := QuaternionToMatrix(Q);
end;

// BarycentricCoordinates
//
function BarycentricCoordinates(const V1, V2, V3, p: TAffineVector;
  var u, v: Single): Boolean;
var
  a1, a2: Integer;
  n, e1, e2, pt: TAffineVector;
begin
  // calculate edges
  VectorSubtract(V1, V3, e1);
  VectorSubtract(V2, V3, e2);

  // calculate p relative to v3
  VectorSubtract(p, V3, pt);

  // find the dominant axis
  n := VectorCrossProduct(e1, e2);
  AbsVector(n);
  a1 := 0;
  if n[1] > n[a1] then
    a1 := 1;
  if n[2] > n[a1] then
    a1 := 2;

  // use dominant axis for projection
  case a1 of
    0:
      begin
        a1 := 1;
        a2 := 2;
      end;
    1:
      begin
        a1 := 0;
        a2 := 2;
      end;
  else // 2:
    a1 := 0;
    a2 := 1;
  end;

  // solve for u and v
  u := (pt[a2] * e2[a1] - pt[a1] * e2[a2]) /
    (e1[a2] * e2[a1] - e1[a1] * e2[a2]);
  v := (pt[a2] * e1[a1] - pt[a1] * e1[a2]) /
    (e2[a2] * e1[a1] - e2[a1] * e1[a2]);

  result := (u >= 0) and (v >= 0) and (u + v <= 1);
end;

{ ***************************************************************************** }

// VectorMake functions
// 2x
function Vector2fMake(const x, y: Single): TVector2f;
begin
  result[0] := x;
  result[1] := y;
end;

function Vector2iMake(const x, y: Longint): TVector2i;
begin
  result[0] := x;
  result[1] := y;
end;

function Vector2sMake(const x, y: SmallInt): TVector2s;
begin
  result[0] := x;
  result[1] := y;
end;

function Vector2dMake(const x, y: Double): TVector2d;
begin
  result[0] := x;
  result[1] := y;
end;

function Vector2bMake(const x, y: Byte): TVector2b;
begin
  result[0] := x;
  result[1] := y;
end;

// **************

function Vector2fMake(const Vector: TVector3f): TVector2f;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

function Vector2iMake(const Vector: TVector3i): TVector2i;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

function Vector2sMake(const Vector: TVector3s): TVector2s;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

function Vector2dMake(const Vector: TVector3d): TVector2d;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

function Vector2bMake(const Vector: TVector3b): TVector2b;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

// **********

function Vector2fMake(const Vector: TVector4f): TVector2f;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

function Vector2iMake(const Vector: TVector4i): TVector2i;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

function Vector2sMake(const Vector: TVector4s): TVector2s;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

function Vector2dMake(const Vector: TVector4d): TVector2d;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

function Vector2bMake(const Vector: TVector4b): TVector2b;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
end;

{ ***************************************************************************** }

// 3x
function Vector3fMake(const x, y, z: Single): TVector3f;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
end;

function Vector3iMake(const x, y, z: Longint): TVector3i;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
end;

function Vector3sMake(const x, y, z: SmallInt): TVector3s;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
end;

function Vector3dMake(const x, y, z: Double): TVector3d;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
end;

function Vector3bMake(const x, y, z: Byte): TVector3b;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
end;

// *******

function Vector3fMake(const Vector: TVector2f; const z: Single): TVector3f;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
end;

function Vector3iMake(const Vector: TVector2i; const z: Longint): TVector3i;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
end;

function Vector3sMake(const Vector: TVector2s; const z: SmallInt): TVector3s;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
end;

function Vector3dMake(const Vector: TVector2d; const z: Double): TVector3d;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
end;

function Vector3bMake(const Vector: TVector2b; const z: Byte): TVector3b;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
end;

// *******

function Vector3fMake(const Vector: TVector4f): TVector3f;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
end;

function Vector3iMake(const Vector: TVector4i): TVector3i;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
end;

function Vector3sMake(const Vector: TVector4s): TVector3s;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
end;

function Vector3dMake(const Vector: TVector4d): TVector3d;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
end;

function Vector3bMake(const Vector: TVector4b): TVector3b;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
end;

{ ***************************************************************************** }

// 4x
function Vector4fMake(const x, y, z, w: Single): TVector4f;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
  result[3] := w;
end;

function Vector4iMake(const x, y, z, w: Longint): TVector4i;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
  result[3] := w;
end;

function Vector4sMake(const x, y, z, w: SmallInt): TVector4s;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
  result[3] := w;
end;

function Vector4dMake(const x, y, z, w: Double): TVector4d;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
  result[3] := w;
end;

function Vector4bMake(const x, y, z, w: Byte): TVector4b;
begin
  result[0] := x;
  result[1] := y;
  result[2] := z;
  result[3] := w;
end;

// ********

function Vector4fMake(const Vector: TVector3f; const w: Single): TVector4f;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
  result[3] := w;
end;

function Vector4iMake(const Vector: TVector3i; const w: Longint): TVector4i;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
  result[3] := w;
end;

function Vector4sMake(const Vector: TVector3s; const w: SmallInt): TVector4s;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
  result[3] := w;
end;

function Vector4dMake(const Vector: TVector3d; const w: Double): TVector4d;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
  result[3] := w;
end;

function Vector4bMake(const Vector: TVector3b; const w: Byte): TVector4b;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := Vector[2];
  result[3] := w;
end;

// *******

function Vector4fMake(const Vector: TVector2f; const z: Single; const w: Single)
  : TVector4f;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
  result[3] := w;
end;

function Vector4iMake(const Vector: TVector2i; const z: Longint;
  const w: Longint): TVector4i;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
  result[3] := w;
end;

function Vector4sMake(const Vector: TVector2s; const z: SmallInt;
  const w: SmallInt): TVector4s;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
  result[3] := w;
end;

function Vector4dMake(const Vector: TVector2d; const z: Double; const w: Double)
  : TVector4d;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
  result[3] := w;
end;

function Vector4bMake(const Vector: TVector2b; const z: Byte; const w: Byte)
  : TVector4b;
begin
  result[0] := Vector[0];
  result[1] := Vector[1];
  result[2] := z;
  result[3] := w;
end;

{ ***************************************************************************** }

// 2
function VectorEquals(const V1, V2: TVector2f): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]);
end;

function VectorEquals(const V1, V2: TVector2i): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]);
end;

function VectorEquals(const V1, V2: TVector2d): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]);
end;

function VectorEquals(const V1, V2: TVector2s): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]);
end;

function VectorEquals(const V1, V2: TVector2b): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]);
end;

{ ***************************************************************************** }

// 3
function VectorEquals(const V1, V2: TVector3i): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]);
end;

function VectorEquals(const V1, V2: TVector3d): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]);
end;

function VectorEquals(const V1, V2: TVector3s): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]);
end;

function VectorEquals(const V1, V2: TVector3b): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]);
end;

{ ***************************************************************************** }

// 4
function VectorEquals(const V1, V2: TVector4i): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]) and
    (V1[3] = V2[3]);
end;

function VectorEquals(const V1, V2: TVector4d): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]) and
    (V1[3] = V2[3]);
end;

function VectorEquals(const V1, V2: TVector4s): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]) and
    (V1[3] = V2[3]);
end;

function VectorEquals(const V1, V2: TVector4b): Boolean;
begin
  result := (V1[0] = V2[0]) and (V1[1] = V2[1]) and (V1[2] = V2[2]) and
    (V1[3] = V2[3]);
end;

{ ***************************************************************************** }

// 3x3f
function MatrixEquals(const Matrix1, Matrix2: TMatrix3f): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and
    VectorEquals(Matrix1[2], Matrix2[2]);
end;

// 3x3i
function MatrixEquals(const Matrix1, Matrix2: TMatrix3i): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and
    VectorEquals(Matrix1[2], Matrix2[2]);
end;

// 3x3d
function MatrixEquals(const Matrix1, Matrix2: TMatrix3d): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and
    VectorEquals(Matrix1[2], Matrix2[2]);
end;

// 3x3s
function MatrixEquals(const Matrix1, Matrix2: TMatrix3s): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and
    VectorEquals(Matrix1[2], Matrix2[2]);
end;

// 3x3b
function MatrixEquals(const Matrix1, Matrix2: TMatrix3b): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and
    VectorEquals(Matrix1[2], Matrix2[2]);
end;

{ ***************************************************************************** }

// 4x4f
function MatrixEquals(const Matrix1, Matrix2: TMatrix4f): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and VectorEquals(Matrix1[2], Matrix2[2]
    ) and VectorEquals(Matrix1[3], Matrix2[3]);
end;

// 4x4i
function MatrixEquals(const Matrix1, Matrix2: TMatrix4i): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and VectorEquals(Matrix1[2], Matrix2[2]
    ) and VectorEquals(Matrix1[3], Matrix2[3]);
end;

// 4x4d
function MatrixEquals(const Matrix1, Matrix2: TMatrix4d): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and VectorEquals(Matrix1[2], Matrix2[2]
    ) and VectorEquals(Matrix1[3], Matrix2[3]);
end;

// 4x4s
function MatrixEquals(const Matrix1, Matrix2: TMatrix4s): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and VectorEquals(Matrix1[2], Matrix2[2]
    ) and VectorEquals(Matrix1[3], Matrix2[3]);
end;

// 4x4b
function MatrixEquals(const Matrix1, Matrix2: TMatrix4b): Boolean;
begin
  result := VectorEquals(Matrix1[0], Matrix2[0]) and
    VectorEquals(Matrix1[1], Matrix2[1]) and VectorEquals(Matrix1[2], Matrix2[2]
    ) and VectorEquals(Matrix1[3], Matrix2[3]);
end;

{ ***************************************************************************** }

// Vector comparison functions:
// 3f
function VectorMoreThen(const SourceVector, ComparedVector: TVector3f)
  : Boolean; overload;
begin
  result := (SourceVector[0] > ComparedVector[0]) and
    (SourceVector[1] > ComparedVector[1]) and
    (SourceVector[2] > ComparedVector[2]);
end;

function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector3f)
  : Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedVector[0]) and
    (SourceVector[1] >= ComparedVector[1]) and
    (SourceVector[2] >= ComparedVector[2]);
end;

function VectorLessThen(const SourceVector, ComparedVector: TVector3f)
  : Boolean; overload;
begin
  result := (SourceVector[0] < ComparedVector[0]) and
    (SourceVector[1] < ComparedVector[1]) and
    (SourceVector[2] < ComparedVector[2]);
end;

function VectorLessEqualThen(const SourceVector, ComparedVector: TVector3f)
  : Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedVector[0]) and
    (SourceVector[1] <= ComparedVector[1]) and
    (SourceVector[2] <= ComparedVector[2]);
end;

// 4f
function VectorMoreThen(const SourceVector, ComparedVector: TVector4f)
  : Boolean; overload;
begin
  result := (SourceVector[0] > ComparedVector[0]) and
    (SourceVector[1] > ComparedVector[1]) and
    (SourceVector[2] > ComparedVector[2]) and
    (SourceVector[3] > ComparedVector[3]);
end;

function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector4f)
  : Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedVector[0]) and
    (SourceVector[1] >= ComparedVector[1]) and
    (SourceVector[2] >= ComparedVector[2]) and
    (SourceVector[3] >= ComparedVector[3]);
end;

function VectorLessThen(const SourceVector, ComparedVector: TVector4f)
  : Boolean; overload;
begin
  result := (SourceVector[0] < ComparedVector[0]) and
    (SourceVector[1] < ComparedVector[1]) and
    (SourceVector[2] < ComparedVector[2]) and
    (SourceVector[3] < ComparedVector[3]);
end;

function VectorLessEqualThen(const SourceVector, ComparedVector: TVector4f)
  : Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedVector[0]) and
    (SourceVector[1] <= ComparedVector[1]) and
    (SourceVector[2] <= ComparedVector[2]) and
    (SourceVector[3] <= ComparedVector[3]);
end;

// 3i
// Vector comparison functions:
function VectorMoreThen(const SourceVector, ComparedVector: TVector3i)
  : Boolean; overload;
begin
  result := (SourceVector[0] > ComparedVector[0]) and
    (SourceVector[1] > ComparedVector[1]) and
    (SourceVector[2] > ComparedVector[2]);
end;

function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector3i)
  : Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedVector[0]) and
    (SourceVector[1] >= ComparedVector[1]) and
    (SourceVector[2] >= ComparedVector[2]);
end;

function VectorLessThen(const SourceVector, ComparedVector: TVector3i)
  : Boolean; overload;
begin
  result := (SourceVector[0] < ComparedVector[0]) and
    (SourceVector[1] < ComparedVector[1]) and
    (SourceVector[2] < ComparedVector[2]);
end;

function VectorLessEqualThen(const SourceVector, ComparedVector: TVector3i)
  : Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedVector[0]) and
    (SourceVector[1] <= ComparedVector[1]) and
    (SourceVector[2] <= ComparedVector[2]);
end;

// 4i
function VectorMoreThen(const SourceVector, ComparedVector: TVector4i)
  : Boolean; overload;
begin
  result := (SourceVector[0] > ComparedVector[0]) and
    (SourceVector[1] > ComparedVector[1]) and
    (SourceVector[2] > ComparedVector[2]) and
    (SourceVector[3] > ComparedVector[3]);
end;

function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector4i)
  : Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedVector[0]) and
    (SourceVector[1] >= ComparedVector[1]) and
    (SourceVector[2] >= ComparedVector[2]) and
    (SourceVector[3] >= ComparedVector[3]);
end;

function VectorLessThen(const SourceVector, ComparedVector: TVector4i)
  : Boolean; overload;
begin
  result := (SourceVector[0] < ComparedVector[0]) and
    (SourceVector[1] < ComparedVector[1]) and
    (SourceVector[2] < ComparedVector[2]) and
    (SourceVector[3] < ComparedVector[3]);
end;

function VectorLessEqualThen(const SourceVector, ComparedVector: TVector4i)
  : Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedVector[0]) and
    (SourceVector[1] <= ComparedVector[1]) and
    (SourceVector[2] <= ComparedVector[2]) and
    (SourceVector[3] <= ComparedVector[3]);
end;

// 3s
// Vector comparison functions:
function VectorMoreThen(const SourceVector, ComparedVector: TVector3s)
  : Boolean; overload;
begin
  result := (SourceVector[0] > ComparedVector[0]) and
    (SourceVector[1] > ComparedVector[1]) and
    (SourceVector[2] > ComparedVector[2]);
end;

function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector3s)
  : Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedVector[0]) and
    (SourceVector[1] >= ComparedVector[1]) and
    (SourceVector[2] >= ComparedVector[2]);
end;

function VectorLessThen(const SourceVector, ComparedVector: TVector3s)
  : Boolean; overload;
begin
  result := (SourceVector[0] < ComparedVector[0]) and
    (SourceVector[1] < ComparedVector[1]) and
    (SourceVector[2] < ComparedVector[2]);
end;

function VectorLessEqualThen(const SourceVector, ComparedVector: TVector3s)
  : Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedVector[0]) and
    (SourceVector[1] <= ComparedVector[1]) and
    (SourceVector[2] <= ComparedVector[2]);
end;

// 4s
function VectorMoreThen(const SourceVector, ComparedVector: TVector4s)
  : Boolean; overload;
begin
  result := (SourceVector[0] > ComparedVector[0]) and
    (SourceVector[1] > ComparedVector[1]) and
    (SourceVector[2] > ComparedVector[2]) and
    (SourceVector[3] > ComparedVector[3]);
end;

function VectorMoreEqualThen(const SourceVector, ComparedVector: TVector4s)
  : Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedVector[0]) and
    (SourceVector[1] >= ComparedVector[1]) and
    (SourceVector[2] >= ComparedVector[2]) and
    (SourceVector[3] >= ComparedVector[3]);
end;

function VectorLessThen(const SourceVector, ComparedVector: TVector4s)
  : Boolean; overload;
begin
  result := (SourceVector[0] < ComparedVector[0]) and
    (SourceVector[1] < ComparedVector[1]) and
    (SourceVector[2] < ComparedVector[2]) and
    (SourceVector[3] < ComparedVector[3]);
end;

function VectorLessEqualThen(const SourceVector, ComparedVector: TVector4s)
  : Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedVector[0]) and
    (SourceVector[1] <= ComparedVector[1]) and
    (SourceVector[2] <= ComparedVector[2]) and
    (SourceVector[3] <= ComparedVector[3]);
end;

// ComparedNumber
// 3f
function VectorMoreThen(const SourceVector: TVector3f;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] > ComparedNumber) and
    (SourceVector[1] > ComparedNumber) and (SourceVector[2] > ComparedNumber);
end;

function VectorMoreEqualThen(const SourceVector: TVector3f;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedNumber) and
    (SourceVector[1] >= ComparedNumber) and (SourceVector[2] >= ComparedNumber);
end;

function VectorLessThen(const SourceVector: TVector3f;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] < ComparedNumber) and
    (SourceVector[1] < ComparedNumber) and (SourceVector[2] < ComparedNumber);
end;

function VectorLessEqualThen(const SourceVector: TVector3f;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedNumber) and
    (SourceVector[1] <= ComparedNumber) and (SourceVector[2] <= ComparedNumber);
end;

// 4f
function VectorMoreThen(const SourceVector: TVector4f;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] > ComparedNumber) and
    (SourceVector[1] > ComparedNumber) and (SourceVector[2] > ComparedNumber)
    and (SourceVector[3] > ComparedNumber);
end;

function VectorMoreEqualThen(const SourceVector: TVector4f;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedNumber) and
    (SourceVector[1] >= ComparedNumber) and (SourceVector[2] >= ComparedNumber)
    and (SourceVector[3] >= ComparedNumber);
end;

function VectorLessThen(const SourceVector: TVector4f;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] < ComparedNumber) and
    (SourceVector[1] < ComparedNumber) and (SourceVector[2] < ComparedNumber)
    and (SourceVector[3] < ComparedNumber);
end;

function VectorLessEqualThen(const SourceVector: TVector4f;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedNumber) and
    (SourceVector[1] <= ComparedNumber) and (SourceVector[2] <= ComparedNumber)
    and (SourceVector[3] <= ComparedNumber);
end;

// 3i
function VectorMoreThen(const SourceVector: TVector3i;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] > ComparedNumber) and
    (SourceVector[1] > ComparedNumber) and (SourceVector[2] > ComparedNumber);
end;

function VectorMoreEqualThen(const SourceVector: TVector3i;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedNumber) and
    (SourceVector[1] >= ComparedNumber) and (SourceVector[2] >= ComparedNumber);
end;

function VectorLessThen(const SourceVector: TVector3i;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] < ComparedNumber) and
    (SourceVector[1] < ComparedNumber) and (SourceVector[2] < ComparedNumber);
end;

function VectorLessEqualThen(const SourceVector: TVector3i;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedNumber) and
    (SourceVector[1] <= ComparedNumber) and (SourceVector[2] <= ComparedNumber);
end;

// 4i
function VectorMoreThen(const SourceVector: TVector4i;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] > ComparedNumber) and
    (SourceVector[1] > ComparedNumber) and (SourceVector[2] > ComparedNumber)
    and (SourceVector[3] > ComparedNumber);
end;

function VectorMoreEqualThen(const SourceVector: TVector4i;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedNumber) and
    (SourceVector[1] >= ComparedNumber) and (SourceVector[2] >= ComparedNumber)
    and (SourceVector[3] >= ComparedNumber);
end;

function VectorLessThen(const SourceVector: TVector4i;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] < ComparedNumber) and
    (SourceVector[1] < ComparedNumber) and (SourceVector[2] < ComparedNumber)
    and (SourceVector[3] < ComparedNumber);
end;

function VectorLessEqualThen(const SourceVector: TVector4i;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedNumber) and
    (SourceVector[1] <= ComparedNumber) and (SourceVector[2] <= ComparedNumber)
    and (SourceVector[3] <= ComparedNumber);
end;

// 3s
function VectorMoreThen(const SourceVector: TVector3s;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] > ComparedNumber) and
    (SourceVector[1] > ComparedNumber) and (SourceVector[2] > ComparedNumber);
end;

function VectorMoreEqualThen(const SourceVector: TVector3s;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedNumber) and
    (SourceVector[1] >= ComparedNumber) and (SourceVector[2] >= ComparedNumber);
end;

function VectorLessThen(const SourceVector: TVector3s;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] < ComparedNumber) and
    (SourceVector[1] < ComparedNumber) and (SourceVector[2] < ComparedNumber);
end;

function VectorLessEqualThen(const SourceVector: TVector3s;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedNumber) and
    (SourceVector[1] <= ComparedNumber) and (SourceVector[2] <= ComparedNumber);
end;

// 4s
function VectorMoreThen(const SourceVector: TVector4s;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] > ComparedNumber) and
    (SourceVector[1] > ComparedNumber) and (SourceVector[2] > ComparedNumber)
    and (SourceVector[3] > ComparedNumber);
end;

function VectorMoreEqualThen(const SourceVector: TVector4s;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] >= ComparedNumber) and
    (SourceVector[1] >= ComparedNumber) and (SourceVector[2] >= ComparedNumber)
    and (SourceVector[3] >= ComparedNumber);
end;

function VectorLessThen(const SourceVector: TVector4s;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] < ComparedNumber) and
    (SourceVector[1] < ComparedNumber) and (SourceVector[2] < ComparedNumber)
    and (SourceVector[3] < ComparedNumber);
end;

function VectorLessEqualThen(const SourceVector: TVector4s;
  const ComparedNumber: Single): Boolean; overload;
begin
  result := (SourceVector[0] <= ComparedNumber) and
    (SourceVector[1] <= ComparedNumber) and (SourceVector[2] <= ComparedNumber)
    and (SourceVector[3] <= ComparedNumber);
end;

// --------------------------------------------------------------
// --------------------------------------------------------------
// --------------------------------------------------------------
initialization

// --------------------------------------------------------------
// --------------------------------------------------------------
// --------------------------------------------------------------

{$IFNDEF GEOMETRY_NO_ASM}
try
  // detect 3DNow! capable CPU (adapted from AMD's "3DNow! Porting Guide")
  asm
    pusha
    mov  eax, $80000000
    db $0F,$A2               /// cpuid
    cmp  eax, $80000000
    jbe @@No3DNow
    mov  eax, $80000001
    db $0F,$A2               /// cpuid
    test edx, $80000000
    jz @@No3DNow
    mov vSIMD, 1
  @@No3DNow:
    popa
  end;
except
  // trap for old/exotics CPUs
  vSIMD := 0;
end;
{$ELSE}
  vSIMD := 0;
{$ENDIF}

end.
