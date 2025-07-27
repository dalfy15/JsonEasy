(* Тесты покрывают:
	   передвижение по узлам
     перемещение узлов *)
unit Test_Nex;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, JsonEasy;

type

  { TTestNext }

  TTestNext = class( TTestCase )
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published

    procedure _Next;
    procedure _Prev;
    procedure _Move;
  end;

var
  Json:     TJsonNode;
  saveName: string;

implementation

procedure TTestNext.SetUp;
begin
  Json     := TJsonNode.Create;
  saveName := 'TestNext.json';
end;

procedure TTestNext.TearDown;
begin
  Json.Root.Free;
end;


procedure TTestNext._Next;
var
  w: TJsonNode;
begin
  Json.Parse( '{a1:a1,' +               ///
    '           a2:{b1:{v1:v1},' +      ///
    '               b2:b2,' +           ///
    '               b3:{v1:v1,' +       ///
    '                   v2:v2}},' +     ///
    '           a3:a3}' );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName ) );
  w := Json.Root;

  w := w.GetFirstChild;
  AssertEquals( 'a1', w.Name );
  w := w.GetNext;
  AssertEquals( 'a2', w.Name );
  w := w.GetNextSibling;
  AssertEquals( 'a3', w.Name );

  w := w.GetFirstSibling;
  AssertEquals( 'a1', w.Name );

  w := w.GetNext;
  w := w.GetFirstChild;
  AssertEquals( 'b1', w.Name );

  w := w.GetNext; //b1:v1
  AssertEquals( 'v1', w.Name );
  w := w.GetNext;
  AssertEquals( 'b2', w.Name );
  w := w.GetNext;
  AssertEquals( 'b3', w.Name );
  AssertTrue( w.GetNextSibling = nil );

  w := w.GetFirstChild;
  AssertEquals( 'v1', w.Name );
  w := w.GetNextSibling;
  AssertEquals( 'v2', w.Name );

  w := w.GetNext;
  AssertEquals( 'a3', w.Name );
end;

procedure TTestNext._Prev;
var
  w: TJsonNode;
begin
  Json.Parse( '{a1:a1,a2:{b1:{v1:v1},b2:b2,b3:{v1:v1,v2:v2}},a3:a3}' );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName ) );
  w := Json.Root;

  w := w.GetLastChild;
  AssertEquals( 'a3', w.Name );
  w := w.GetPrevSibling;
  AssertEquals( 'a2', w.Name );
  w := w.GetPrevSibling;
  AssertEquals( 'a1', w.Name );
  AssertTrue( w.GetPrevSibling = nil );

  w := w.GetLastSibling;
  AssertEquals( 'a3', w.Name );

  w := w.GetPrevSibling;
  w := w.GetLastChild; //a2-b3
  AssertEquals( 'b3', w.Name );

  w := w.GetPrev; //b2
  AssertEquals( 'b2', w.Name );
  w := w.GetPrev; //b1-v1
  AssertEquals( 'v1', w.Name );
  w := w.GetPrev;
  AssertEquals( 'b1', w.Name );

  w := w.GetPrev;
  AssertEquals( 'a2', w.Name );
  w := w.GetPrev;
  AssertEquals( 'a1', w.Name );
  AssertTrue( w.GetPrevSibling = nil );
  w := w.GetPrev;
  AssertTrue( w.GetPrev = nil );
end;

procedure TTestNext._Move;
var
  w, w1: TJsonNode;
  s:     string;
begin
  s := '{a1:a1,' +               ///
    '    a2:{b1:{v1:v1},' +      ///
    '        b2:b2,' +           ///
    '        b3:{v1:v1,' +       ///
    '            v2:v2}},' +     ///
    '    a3:a3}';
  Json.Parse( s );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName ) );

  w  := Json.Find( 'a2' );
  w1 := Json.Find( 'a2/b3' );
  AssertFalse( w.MoveTo( w1 ) );

  w  := Json.Find( 'a2/b2' );
  w1 := Json.Find( 'a2' );
  AssertTrue( w.MoveTo( w1, nmAddNext ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName ) );
  AssertEquals( 2, Json.Find( 'a2' ).Count );
  AssertEquals( 4, Json.Root.Count );

  w  := Json.Find( 'a2/b3' );
  w1 := Json.Find( 'b2' );
  AssertTrue( w.MoveTo( w1, nmAddFirst ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName ) );
  AssertEquals( 1, Json.Find( 'a2' ).Count );

  w  := Json.Find( 'a3' );
  AssertTrue( w.MoveTo( Json.Find( 'a2' ), nmAddChildLast ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName ) );
  AssertEquals( 4, Json.Root.Count );
  AssertEquals( 2, Json.Find( 'a2' ).Count );
end;



initialization
  RegisterTest( TTestNext );
end.
