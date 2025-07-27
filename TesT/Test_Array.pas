(*Тесты покрывают:
Парсинг JSON-массивов
массив/объект в массиве
Создание массивов
Тест производительности для больших JSON
*)
unit Test_Array;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, JsonEasy, Math;

type

  TTestArray = class( TTestCase )
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published

    procedure TestParseArr_Nachinaetsya_s_imeni;
    procedure TestParseArr_Nachinaetsya_s_imeni_bez_kavyhchek;
    procedure TestParseArr_massiv_v_massive;
    procedure TestParseArr_smeshennyhe_dannyhe;
    procedure TestParseObjArr;
    procedure TestCreateJsonArray;

    procedure Test_Performance_menee_1sec;
  end;

var
  Json, JE: TJsonNode;
  saveName: string;

implementation

procedure TTestArray.SetUp;
begin
  JE        := TJsonNode.Create;
  Json      := TJsonNode.Create;
  saveName  := 'TestArray.json';
  Json.Name := 'Root';
end;

procedure TTestArray.TearDown;
begin
  Json.Root.Free;
  JE.Root.Free;
end;


//--------------------------- Array -----------------------------------------

procedure TTestArray.TestParseArr_Nachinaetsya_s_imeni;
begin
  Json.Parse( '"cars":["Ford","BMW" , "Fiat"]' );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'String value', 'Fiat', Json.Find( 'cars/2' ).Value );
end;

procedure TTestArray.TestParseArr_Nachinaetsya_s_imeni_bez_kavyhchek;
begin
  Json.Parse( 'cars  :  ["Ford",BMW , Fiat]' );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'String value', 'Fiat', Json.Find( 'cars/2' ).Value );
end;

procedure TTestArray.TestParseArr_massiv_v_massive;
begin
  Json.Parse( '"Array":["Ford","BMW",["one","два","три"], "Fiat"]' );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'String value', 'два', Json.Find( 'Array/2/1' ).Value );
end;

procedure TTestArray.TestParseArr_smeshennyhe_dannyhe;
begin
  Json.Parse( '"cars":["Ford","BMW","Fiat", 30,true,1234.56]' );
  Json.Find( 'cars/1' ).Value := 'Moscvich';
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'String value', 'Moscvich', Json.Find( 'cars/1' ).Value );
  AssertEquals( 'Число', 30, Json.Find( 'cars/3' ).Value );
  AssertEquals( 'Boolean value', True, Json.Find( 'cars/4', False ) );
  AssertEquals( 'Float value', 1234.56, Json.Find( 'cars/5', 0.0 ), 0.001 );

  // Значения по умолчанию
  AssertEquals( 'Значение по умолчанию для отсутствующей строки. Default for missing string', 'Unknown',
    Json.Find( 'address', 'Unknown' ) );
  AssertEquals( 'Значение по умолчанию для пропущенного целого числа. Default for missing integer', -1,
    Json.Find( 'height', -1 ) );
end;


procedure TTestArray.TestParseObjArr;
var
  s: string;
begin
  s := '{"name":"John","age":30,"cars":["Ford","BMW","Fiat"],"part":{"name1":"Ivan"}}';
  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован. '
    + s + ' Valid JSON should parse successfully', Json.Parse( s ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'Число', 30, Json.Find( 'age' ).Value );
  AssertEquals( 'Ячейка', 'Fiat', Json.Find( 'cars/2' ).Value );
  AssertEquals( 'строка', 'Ivan', Json.Find( 'part/name1' ).Value );
end;


//--------------------------------------------------------------------

procedure TTestArray.TestCreateJsonArray;
var
  s: string;
begin
  s    := 'Один';
  Json := Json.AddArr( 'Obarr' ).AddArrElm( s );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'Должен быть массив. Should be an array', Ord( nkArray ), Ord( Json.Kind ) );
  AssertEquals( 'Значение в массиве должно совпадать. New array should be empty',
    1, Json.Count );
  AssertEquals( 'Значение в массиве должно совпадать. New array should be empty',
    'Один', Json.Find( '0' ).Value );
end;

procedure TTestArray.Test_Performance_menee_1sec;
var
  i:     integer;
  start: QWord;
begin
  // Тест производительности для больших JSON
  start := GetTickCount64;
  Json.AddArr( 'arrr' );
  for i := 1 to 1000 do
    Json.AddArr( 'arrr' ).AddArrElm( i );

  AssertEquals( 'Большой JSON должен содержать 1000 элементов. Big JSON should have 1000 elements' + #10 + ///
    format( 'а содержит: %d)', [Json.AddArr( 'arrr' ).Count] ),
    1000, Json.AddArr( 'arrr' ).Count );
  AssertTrue( 'Проверка производительности должна быть завершена в разумные сроки. Performance test should complete in reasonable time' + #10 + ///
    format( 'Прошло времени: %d)', [GetTickCount64 - start] ),
    GetTickCount64 - start < 1000 ); // менее 1 секунды
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );
end;


initialization
  RegisterTest( TTestArray );
end.
