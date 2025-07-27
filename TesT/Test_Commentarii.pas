(* Тесты покрывают:
		 Саздание комментариев
     парсинг с комментариями
     загрузку комментариев из файла *)
unit Test_Commentarii;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, JsonEasy;

type

  { TTestCommentarii }

  TTestCommentarii = class( TTestCase )
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published

   procedure insertComment;
   procedure SaveLoadFromFile;
  end;

var
  Json:     TJsonNode;
  saveName: string;

implementation

procedure TTestCommentarii.SetUp;
begin
  Json      := TJsonNode.Create;
  saveName  := 'TestCommentarii.json';
end;

procedure TTestCommentarii.TearDown;
begin
  Json.Root.Free;
end;


//----------------------------------------------------------------------------

procedure TTestCommentarii.insertComment;
begin
Json.AddElm('Name', 'Ivan');
Json.AddComment('Сколько лет: ');
Json.AddElm('лет', 30);
Json.AddComment('Параметр');
Json.AddElm('параметр', true);

AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );
end;

procedure TTestCommentarii.SaveLoadFromFile;
var
  json2: TJsonNode;
begin
  Json.Parse( '{"test":"data",//"Сколько лет:",value:42, //авто, car:[Москвич, BMW]}' );

  AssertTrue( 'Save to file1', Json.SaveToFile( saveName, jfExpand ) );
  AssertTrue( 'Save to file3', Json.SaveToFile( saveName, jfCompressed ) );
  AssertTrue( 'Save to file2', Json.SaveToFile( saveName, jfCompact ) );

  json2 := TJsonNode.Create;
    try
    AssertTrue( 'Load from file', json2.LoadFromFile( saveName ) );
    AssertEquals( 'Загруженный JSON из файла должен соответствовать сохраненному. Loaded JSON should match saved',
      Json.JsonToText( jfCompressed ), json2.JsonToText( jfCompressed ) );
    finally
    json2.Free;
    end;

  json2 := TJsonNode.Create;
    try
    AssertTrue( 'Load from file', json2.LoadFromFile( saveName ) );
    AssertEquals( 'Загруженный JSON из файла должен соответствовать сохраненному. Loaded JSON should match saved',
      Json.JsonToText( jfCompact ), json2.JsonToText( jfCompact ) );
    finally
    json2.Free;
    end;

  json2 := TJsonNode.Create;
    try
    AssertTrue( 'Load from file', json2.LoadFromFile( saveName ) );
    AssertEquals( 'Загруженный JSON из файла должен соответствовать сохраненному. Loaded JSON should match saved',
      Json.JsonToText( jfExpand ), json2.JsonToText( jfExpand ) );
    finally
    json2.Free;
    end;
end;


//--------------------------------------------------------------------



initialization
  RegisterTest( TTestCommentarii );
end.
