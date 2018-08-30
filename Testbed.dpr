program Testbed;

uses
//  FastMM4 in 'FastMM\FastMM4.pas',
//  FastMM4Messages in 'FastMM\FastMM4Messages.pas',
  Vcl.Forms,
  MainU in 'MainU.pas' {MainForm},
  dglOpenGL in 'dglOpenGL.pas',
  SceneManager in 'SceneManager.pas',
  TriangleStripMesh in 'TriangleStripMesh.pas',
  DiamondSquareEngine in 'DiamondSquareEngine.pas',
  TDxInput_TLB in 'TDxInput_TLB.pas',
  Controller in 'Controller.pas',
  GLHelpers in 'GLHelpers.pas',
  ColladaLoader in 'ColladaLoader.pas',
  FontEngine in 'FontEngine.pas',
  WavefrontLoader in 'WavefrontLoader.pas',
  SceneObjects in 'SceneObjects.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
