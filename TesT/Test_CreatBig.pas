unit Test_CreatBig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, JsonEasy, DateUtils;

type

  { TTestCreatBig }

  TTestCreatBig = class( TTestCase )
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // Тест производительности для больших JSON
    procedure Test_Create;
    procedure Test_SaveToFile;
    procedure Test_LoadFromFile;
    procedure Test_CloseJson;
  end;

var
  FJson, json2: TJsonNode;
  saveName:     string;

implementation

procedure TTestCreatBig.SetUp;
begin
  saveName := 'CreatBig.json';
end;

procedure TTestCreatBig.TearDown;
begin
end;

// Тест производительности для больших JSON
procedure TTestCreatBig.Test_Create;
var
  i, n: integer;
  x:    string;
begin
  n     := 12000;
  FJson := TJsonNode.Create;
    try
    //fJson.AddElm('a1',456);
    //fJson.AddElm('a2','asdasd');
    //fJson.AddElm('a3',True);
    //fJson.AddElm('a4',Null);

    json2 := fJson.AddObj( 'Objects' );
    // Запись значений
    for i := 1 to n do
      begin
      x := IntToStr( i );
      FJson.AddElm( 'obj' + x, x );
      json2.AddArr( 'name' ).AddArrElm( 'AliceЦЙФ' );
      json2.AddArr( 'age' ).Value := 25;
      json2.AddArrElm( 'balance', 2.5 );
      json2.AddArrElm( 'balance', 2.5e4 );
      json2.AddArrElm( 'balance', 25 );
      json2.AddArrElm( 'balance', 2E5 );
      json2.AddArrElm( 'balance', 25e6 );
      json2.AddArrElm( 'balance', 25e-4 );
      json2.AddArrElm( 'balance', 2.5e-4 );
      json2.AddArrElm( 'balance', 2.5e+4 );
      json2.AddArrElm( 'active', True );
      end;
    finally
    end;
end;

procedure TTestCreatBig.Test_SaveToFile;
begin
  //WriteLn( fjson.Find( 'Objects/balance' ).AsJsonExpand );
  //AssertTrue( 'Save to file', FJson.SaveToFile( 'testE.json', jfExpand ) );
  AssertTrue( 'Save to file', FJson.SaveToFile( saveName, jfCompact ) );
  //AssertTrue( 'Save to file', FJson.SaveToFile( 'testCC.json', jfCompressed ) );

end;

procedure TTestCreatBig.Test_LoadFromFile;
var
  i: integer;
begin
  json2 := TJsonNode.Create;
  AssertTrue( 'Load from file', json2.LoadFromFile( saveName ) );

  //WriteLn(json2.Find('Objects/balance').AsJsonExpand);
  //WriteLn( Json2.GetArrayCount( 'asas/balance' ) );
  //ArrayNode := json2.Find( 'Objects/balance' );
  //for i := 0 to json2.GetArrayCount( 'Objects/balance' ) - 1 do
  //  WriteLn( ArrayNode.Child( i ).Value );
end;

procedure TTestCreatBig.Test_CloseJson;
begin
  if json2 <> nil then
    AssertEquals( 'Загруженный JSON должен соответствовать сохраненному.',
      FJson.ToString, json2.ToString );
  json2.Free;
  FJson.Free;

end;

initialization
  RegisterTest( TTestCreatBig );
end.
