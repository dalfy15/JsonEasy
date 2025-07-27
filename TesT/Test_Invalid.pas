(*Тесты покрывают:
*   Валидацию JSON
*)
unit Test_Invalid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, JsonEasy;

type

  { TTestInvalid }

  TTestInvalid = class( TTestCase )
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published

    procedure Test_Value;
    procedure Test_Array;
    procedure Test_errorJsonString;
    procedure Test_comment;
    procedure Test_Move;
  end;

var
  Json, JE: TJsonNode;
  saveName: string;

implementation

procedure TTestInvalid.SetUp;
begin
  JE        := TJsonNode.Create;
  saveName  := 'TestInvalid.json';
  Json      := TJsonNode.Create;
  Json.Name := 'Root';
end;

procedure TTestInvalid.TearDown;
begin
  Json.Root.Free;
  JE.Root.Free;
end;

//--------------------------------------------------------------------

procedure TTestInvalid.Test_Value;
var
  s, er: string;
begin
  er := 'корню JSON нельзя присвоить значение (иначе изменится на elm)';
    try
    Json.Value := 55;
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;

  er := 'AddElm(x, y) - возвращает родительский объект/массив, а не сам элемент';
    try
    Json.AddElm( 'name', 'Ivan' ).Value := 'Egor';
    AssertEquals( er, 'Ivan', Json.Find( 'name' ).Value );
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;
end;

procedure TTestInvalid.Test_Array;
var
  s, er: string;
begin
  er := 'Неправильный JSON (лишнее число у age)';
  s  := '{"name":"John",age:30 20}';
    try
    AssertFalse( er, Json.Parse( s ) );
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;

  er := 'Mассив в массиве';
    try
    AssertTrue( er, Json.Parse( '["Ford",[1,2,3], "BMW","Fiat"]' ) );
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;
end;

procedure TTestInvalid.Test_errorJsonString;
var
  er: string;
begin
    try
    er := 'Пропущено имя <{:1}>';
    AssertFalse( er, Json.Parse( '{:1}' ) );
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;

    try
    er := 'Invalid JSON - trailing comma. Недопустимая запятая в JSON <{"a":,1}>';
    AssertFalse( er, Json.Parse( '{"a":,1}' ) );
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;

    try
    er := 'Invalid JSON - incorrect brackets. Недопустимый JSON - неправильные скобки <a:[1,2,3}>';
    AssertFalse( er, Json.Parse( 'a:[1,2,3}' ) );
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;
end;


procedure TTestInvalid.Test_comment;
var
  er: string;
begin
    try
    er := 'Пропущены кавычки в комментарии <{"test":"data",//Сколько лет,value:42}>';
    Json.Parse( '{"test":"data",//Сколько лет,value:42}' );
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;
end;

procedure TTestInvalid.Test_Move;
var
  er: string;
begin
  Json.Parse( '{a1:a1, a2:a2}' );
    try
    er := 'Нельзя перемещать узел в простой подъузел.';
    Json.Find( 'a1' ).MoveTo( Json.Find( 'a2' ), nmAddChildLast );
    raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    except
    on EJsonException do ;
    else
      raise Exception.CreateFmt( 'Тест не прошёл: "%s"', [er] );
    end;
end;


initialization
  RegisterTest( TTestInvalid );
end.
