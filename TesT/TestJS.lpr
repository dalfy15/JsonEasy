program TestJS;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  GuiTestRunner,
  JsonEasy,
  Test_CreatBig,
  Test_Primitiv,
  Test_Array,
  Test_Commentarii,
  Test_Nex,
  Test_Cache,
  Test_Invalid;

  {$R *.res}

begin
  //SetHeapTraceOutput( 'heaptrace.trc' );
  globalSkipIfNoLeaks := true;
  RequireDerivedFormResource := True;

  Application.Initialize;
  Application.CreateForm( TGuiTestRunner, TestRunner );
  Application.Run;
end.
