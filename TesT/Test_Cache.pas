(* Тесты покрывают:
	   работа с кэшем
     работа без кэша *)
unit Test_Cache;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, JsonEasy;

type

  { TTestCache }

  TTestCache = class( TTestCase )
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published

    procedure _Cache_All;
    procedure _No_Cache;
    procedure _s_Cache;
  end;

const
  nn = 20000;

var
  Json:     TJsonNode;
  saveName: string;

implementation

procedure TTestCache.SetUp;
begin
  Json     := TJsonNode.Create;
  saveName := 'TestCache.json';
end;

procedure TTestCache.TearDown;
begin
  Json.Root.Free;
end;

procedure TTestCache._Cache_All;
begin
  // Загружаем JSON
  Json.Parse( '{"user":{"name":"John","age":30}}' );

  // Первый доступ - без кэша
  WriteLn( Json.Find( 'user/name' ).Value );

  // Включаем кэширование путей
  Json.CachePathEnabled := True;
  // заполнение кэша
  WriteLn( Json.Find( 'user/name' ).Value );

  // Последующие доступы будут использовать кэш
  WriteLn( Json.Find( 'user/age' ).Value );
  // Очистка кэша при необходимости
  Json.CacheClearPath;

  //без кэша
  WriteLn( Json.Find( 'user/age' ).Value );
end;


procedure TTestCache._No_Cache;
var
  i: integer;
begin
  // Загружаем JSON
  Json.Parse( '{"user":{"name":"John","age":30}}' );
  // Очистка кэша при необходимости
  Json.CacheClearPath;

  // без кэша
  for i := 1 to NN do
    WriteLn( Json.Find( 'user/name' ).Value );
end;

procedure TTestCache._s_Cache;
var
  i: integer;
begin
  // Загружаем JSON
  Json.Parse( '{"user":{"name":"John","age":30}}' );

  // Включаем кэширование путей
  Json.CachePathEnabled := True;

  // c кэш
  for i := 1 to NN - 1 do
    WriteLn( Json.Find( 'user/name' ).Value );
end;



initialization
  RegisterTest( TTestCache );
end.
