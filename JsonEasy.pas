 (********************************************************)
 (*                                                      *)
 (*  Json Easy Tools Pascal Unit                         *)
 (*  A small json parser with no dependencies            *)
 (*                                                      *)
 (*  http://www.JsonEasy                                 *)
 (*  Dual licence GPLv3 LGPLv3 released Aprel 2025       *)
 (*  Copyrate: santig9@ya.ru, Кандауров А. & DeepSeek    *)
 (*                                                      *)
 (********************************************************)
 (* На основании: http://www.getlazarus.org/json         *)
 (********************************************************)


(* Создаём экземпляр и включаем кэширование путей:
   jCfg := TJsonNode.Create;
   jCfg.CachePathEnabled := True;

* Создаём новый узел и запоминаем его в переменной ( nod := jCfg.AddObj )
   1) jCfg.Parse( 'Obj:ObName' );
   2) nod := jCfg.AddObj( 'Obj' ).AddObj( 'ObName' );
   3) nod := jCfg.Force( 'Obj/ObName2' );
   4) jCfg.Force( 'obj/name', 'Alice' );
   5) jCfg.Force( 'obj' ).AddElm( 'age', 25 );
   6) jCfg.Force( 'name' ).Value  := 'Alice';
   7) jCfg.Force( 'Person/Object' ).Value:= '{name:"John' +#10+ 'Stiv",age:30,cars:True}';
   8) jCfg.AddElm( 'Petrov', '{name:Ivan,ege:33, car:"Lada"}' );
   9) jCfg.Parse( a1:1_000_0, a2: -3.0_01, a3: -0x054, a4:.04, a5: -5_00.6E-2 );

* Создаём массив и добавляем элементы:
   1) jCfg.Parse( '"cars":["Ford","BMW" , "Fiat"]' );
   2) jCfg.AddArr( 'arr' );
      jCfg.AddArr( 'arr', 'Moscvich' );
      jCfg.AddArr( 'arr' ).AddArrElm( 'Ford' );
      jCfg.AddArr( 'arr' ).AddArrElm( 'BMW' ).AddArrElm( 'Fiat' );
   jCfg.AddArr( 'arr' ).Count

* Oбъединяем элементы в объекте ( AddMerge )
   1) jCfg.Find( 'Obj' ).AddMerge( nod.Find( 'Obj' ), True ); // без замены
   2) jCfg.AddMerge( nod, True );  // с заменой внутренних параметров

* Поиск по пути:
   1) node := jCfg.Find( 'person/name' );
   2) Form1.Width  := jCfg.Find('ui/main_window/width', 800); //800 - по умолчанию

* Саздание комментариев:
    1) jCfg.AddComment('Сколько лет: ');
    2) jCfg.Parse( '{//"Сколько лет:",value:42, //авто, car:[Москвич, BMW]}' );

* Сохранить/загрузить в файл:
    1) jCfg.SaveToFile( 'config.json' );
    2) jCfg2.LoadFromFile( 'config.json' );
    3) s := jCfg.JsonToText( jfCompressed );

* Перебор всех параметров узла:
    1) for Node in JsonObjectOrArray do
     2) Node := Node.First, next, pred, Last, ChildFirst, ChildLast

* Освободить память:
   jCfg.Root.Free;

*********************************************************)

unit JsonEasy;

{$mode objfpc}{$H+}{$X+}{$codepage UTF8}
{$ModeSwitch advancedrecords}// что бы можно было записывать в record методы
{$inline on}
{$define VARIANTINLINE}
{$optimization autoinline}
{$enumerate 2}

interface

uses
  Classes, SysUtils, StrUtils, Variants, contnrs, LazUTF8;

{ EJsonException - это тип исключения, используемый Jsonnode. Оно генерируется
во время синтаксического анализа, если строка является недопустимой в формате json
или если предпринята попытка получить доступ к коллекции, отличной от имени или индекса. }

type
  EJsonException = class( Exception );
  TJsonNode = class;
  TJsonStringBuilder = class;

  { TJsonNodeKind is 1 of 6 possible values described below }

  TJsonNodeKind = (
    nkObject,   // Object such as { }
    nkArray,    // Array  such as [ ]
    nkElm,      // Простой элемент
    nkComment   // Комментарий
    );

  //TJsonValueType = ( jvNull, jvBool, jvInt, jvFloat, jvStr );
  //TJsonValue     = record
  //  case Typ: TJsonValueType of
  //    jvNull: ( );
  //    jvBool: ( B: boolean );
  //    jvInt: ( I: int64 );
  //    jvFloat: ( F: double );
  //    jvStr: ( S:UTF8String {ansistring} ); // UTF8
  //end;

  //Перемещение текущего узла в область узла Destinatiоn
  TJsonNodeAttachMode = (
    nmAddNext,       //после узла         - add as sibling of Destination
    nmAddPred,       //перед узлом        - add as sibling of Destination
    nmAddFirst,      //первым в ветке     - add as first sibling of Destnation
    nmAddLast,       //последним в ветке  - add as last sibling of Destination
    nmAddChildFirst, //первым в дочерней ветке    - add as first child of Destination
    nmAddChildLast   //последним в дочерней ветке - add as last child of Destination
    );

  TJSONFormat = (
    jfExpand,    // Развёрнуты формат
    jfCompact,   // Компактный
    jfCompressed // Сжатый
    );

  { TJsonNodeEnumerator is used to enumerate 'for ... in' statements }

  TJsonNodeEnumerator = record
  private
    FNode:  TJsonNode;
    FIndex: integer;
  public
    procedure Init( Node: TJsonNode );
    function GetCurrent: TJsonNode;
    function MoveNext: boolean;
    property Current: TJsonNode read GetCurrent;
  end;

{ JsonNode - это класс, используемый для анализа, создания и навигации по документу в формате json.
  Вам следует только создать и освободить корневой узел вашего документа. Корневой
узел будет управлять временем жизни всех дочерних узлов с помощью таких методов,
как Add, Delete и Clear.
    Когда вы создаете узел TJsonNode, у него не будет родительского элемента, и он будет считаться
корневым узлом. Корневой узел должен быть либо массивом, либо объектом. Попытки
  преобразование root во что-либо, отличное от массива или объекта, вызовет исключение.
     Примечание: Синтаксический анализатор поддерживает unicode путем преобразования символов unicode,
  экранированных как \u20AC. Если в вашей строке json есть экранированный символ unicode, он
не будет экранирован при преобразовании в строку pascal.

  Смотрите также:
  JsonStringDecode преобразует символы \uxxxx в JSON в обычную UTF-8 строку
  JsonStringEncode преобразует UTF-8 строку в строку JSON с \uxxxx }

  TJsonNode = class
  private
    FStack:     integer;        // Глубина вложенности
    FParent:    TJsonNode;      // Родительский узел
    FName:      string;         // Имя узла
    FKind:      TJsonNodeKind;  // Тип узла
    FValue:     variant;        // Значение этого узла (содержимое)
    FItems:     TFPObjectList;  // Ссылки на др. узлы или элм. массива
    FCacheUsePath: boolean;     // Флаг использования кэша
    FCachePath: TFPHashList;    // Кэш путей для быстрого доступа

    // Парсинг. Приходит уже без скобки { или [
    procedure ParseJSON( var pJS: pchar );
    // Обновление кэша при изменениях (privat)
    procedure CacheUpdatePath( );
    procedure CacheEnablePath( Enabled: boolean );

    // Вспомогательные методы

    //Добавить новый узел (private) и вернуть его
    function AddNode( AKind: TJsonNodeKind; const aName: string; AValue: variant ): TJsonNode;
    //принадлежит ли узел структуре?
    function nkStrukt: boolean; inline;
    procedure SetKind( AKind: TJsonNodeKind );
    procedure Error( const Msg: string = '' );

    // Геттеры/сеттеры свойств
    function GetRoot: TJsonNode;
    function GetValue: variant;
    procedure SetValue( AValue: variant );
    function GetName: string;
    procedure SetName( const AValue: string );
    function GetCount: integer;
  public //в private внешнего класса
    //для обратного поиска и сортировки, которые удобны при исследовании неизвестных структур JSON.
    function JSONKindToString( Node: TJsonNode ): string;
    function JSONPathToString( Node: TJsonNode ): string;

    ///
  public
    {  Родительский узел владеет всеми дочерними узлами. Уничтожайте узел только в том случае,
      если у него нет родительского элемента.
      Чтобы уничтожить дочерний узел, используйте вместо этого методы Delete или Clear.
      A parent node owns all children. Only destroy a node if it has no parent.
      To destroy a child node use Delete or Clear methods instead. }
    destructor Destroy; override;


    // Загрузка/сохранение
    function LoadFromStream( Stream: TStream ): boolean;
    procedure SaveToStream( Stream: TStream; JSFotmat: TJSONFormat = jfCompact );
    function LoadFromFile( const FileName: string ): boolean;
    function SaveToFile( const FileName: string; JSFotmat: TJSONFormat = jfCompact ): boolean;

    // Перечисление для: 'for ... in'
    function GetEnumerator: TJsonNodeEnumerator;

    { Работа с узлами }

    //Добавить новый параметр в объект или массив
    //Result - добавленный параметр
    function AddElm( const elmName: string ): TJsonNode;
    //Добавить новый параметр в объект или массив
    //Result - исходный (текущий) объект или массив
    function AddElm( const elmName: string; AValue: variant ): TJsonNode; overload;
    //Добавить дочерний узел в объект или в массив по указанному Пути (создастся)
    //nameElm - для массива не учитывается
    function AddPath( const pathName: string; nameElm: string; AValue: variant ): TJsonNode;
    //Добавить пустой Объект в сложный элемент. Возвращает добавленный объект
    function AddObj( const nameObject: string ): TJsonNode;
    //Добавить/заменить Json-узел
    function AddJSON( const aJSON: TJsonNode ): TJsonNode;
    //Добавить пустой Массив (в массиве - имя не учитывается, только в Объекте)
    function AddArr( const nameArray: string ): TJsonNode;
    //Добавить Элемент в массив. Вернуть массив, а не элемент
    function AddArrElm( AValue: variant ): TJsonNode; overload;
    //Добавить Элемент в массив (в переди стоящий или на нём или в нём), создастся при необходимости
    function AddArrElm( const nameArray: string; AValue: variant ): TJsonNode; overload;
    // Получить значение из массива
    function GetArrElm( AIndex: integer ): variant;
    function GetArrElm( const AArrayPath: string; AIndex: integer ): variant; overload;
    //Перемещает текущий узел в область узла Destinatiоn
    //TJsonNodeAttachMode = (nmAddNext, nmAddPred, nmAddFirst, nmAddLast, nmAddChildFirst, nmAddChildLast);
    function MoveTo( const Destinations: TJsonNode; Mode: TJsonNodeAttachMode = nmAddLast ): boolean;
      virtual;
    //Добавить комментарий
    function AddComment( const nameComment: string ): TJsonNode;

    //true, если расшифровка JSONString прошла успешно
    function Parse( const JSONString: string ): boolean;
    //Слить два Json-узла (объект или массив)
    function AddMerge( const NodeStruktMerge: TJsonNode; SZamenoj: boolean = True ): TJsonNode;

    //удалить текущий узел и последующие
    procedure Delete;
    //Удаляет дочерний узел по индексу или имени
    procedure Delete( Index: integer ); overload;
    procedure Delete( const Name: string ); overload;
    //Очистить все дочерние узлы и FValue установить в Null.
    function Clear: TJsonNode;

    // Навигация
    {  Получить дочерний узел по индексу. Исключение EJsonException возникает,
     если узел не является массивом или объектом или если индекс находится
     за пределами допустимых значений.
     Смотрите также: Count
      Get a child node by index. EJsonException is raised if node is not an
      array or object or if the index is out of bounds.      See also: Count }
    function Child( Index: integer ): TJsonNode; overload;
    { Получить дочерний узел по имени. Если узел не найден, будет возвращено значение nil.
    Get a child node by name. If no node is found nil will be returned. }
    function Child( const Name: string ): TJsonNode; overload;
    { Найдите узел, используя строку пути, и верните значение true, если оно существует.
    Search for a node using a path string and return true if exists }
    function Exists( const Path: string ): boolean;
    // Найдите узел, используя строку пути. Search for a node using a path string
    //Начинается с '/' - начать поиск с корня. Равен '/' - возвращает корень
    function Find( const Path: string ): TJsonNode; overload;
    // Найдите значение узла, используя строку пути, если поиск =nil, то вернёт AValueDefault
    function Find( const Path: string; const AValueDefault: variant ): variant; overload;
    { Найдите узел, используя строку пути, и верните значение true, если он существует.
      Search for a node using a path string and return true if exists }
    function Find( const Path: string; out Node: TJsonNode ): boolean; overload;
    // Принудительно создать ряд узлов (Объектов) и вернуть конечный узел.
    {Начинается с '/' - начать поиск с корня. Равен '/' - возвращает корень
     Path='' - Добавить объект.
     Force a series of nodes to exist and return the end node }
    function Force( const Path: string ): TJsonNode; overload;
    // Принудительно создать ряд узлов (Объект), добавить переменную в последний узел
    //и вернуть последний узел.
    function Force( const Path: string; aValue: variant ): TJsonNode; overload;
    // Принудительно создать ряд узлов (Объект), добавить Объект в последний узел
    //и вернуть последний узел.
    function Force( const Path: string; aValue: TJsonNode ): TJsonNode; overload;

    {перемещения по узлам}

    //Возвращает первый узел на текущем уровне
    function GetFirstSibling: TJsonNode;
    //Возвращает последний узел на текущем уровне
    function GetLastSibling: TJsonNode;
    //Возвращается первый узел списка потомков или nil, если нет подузлов
    function GetFirstChild: TJsonNode;
    //Возвращает последний подузел или nil, если нет подузлов
    function GetLastChild: TJsonNode;
    //следующий узел относительно текущего, с вхождением
    function GetNext: TJsonNode;
    //предыдущий узел относительно текущего, с вхождением
    function GetPrev: TJsonNode;
    //следующий узел относительно узла-потомка Value
    function GetNextChild( AValue: TJsonNode ): TJsonNode;
    //предыдущий узел относительно узла-потомка Value
    function GetPrevChild( AValue: TJsonNode ): TJsonNode;
    //следующий узел на текущем уровене
    function GetNextSibling: TJsonNode;
    //предыдущий узел на текущем уровене
    function GetPrevSibling: TJsonNode;
    //true, если aValue – совпадает с каким-то родительским узлом
    function HasAsParent( AValue: TJsonNode ): boolean;


    {методы работы с кэшем}

    // Очистка кэша при необходимости
    procedure CacheClearPath;

    //Преобразовать Json в текст (по ум. - jfCompact) .
    function JsonToText( JSONFormats: TJSONFormat = jfCompact ): string;
    ///

  public   // Свойства
   { Корневой узел доступен только для чтения. Узел является корневым,
      если у него нет родительского узла. Root node is read only. A node the root when it has no parent. }
    property Root: TJsonNode read GetRoot;
    { Родительский узел доступен только для чтения. Parent node is read only }
    property Parent: TJsonNode read FParent;
    { Kind также можно изменить с помощью методов As.
      Примечание: Изменения в Kind приводят к сбросу значения по умолчанию.
      Kind can also be changed using the As methods.
      Note: Changes to Kind cause Value to be reset to a default value. }
    property Kind: TJsonNodeKind read FKind write SetKind;
    { Имя является уникальным в пределах области видимости. Name is unique within the scope }
    property Name: string read GetName write SetName;
    { Количество дочерних узлов. Если узел не является объектом или массивом, это
      свойство вернет значение 0.
      The number of child nodes. If node is not an object or array this property will return 0.}
    property Count: integer read GetCount;

    // Значение узла.
    property Value: variant read GetValue write SetValue;

    property CachePathEnabled: boolean read FCacheUsePath write CacheEnablePath;
  end;


type
  { TJsonStringBuilder }
  TJsonStringBuilder = class
  private
    FBuffer:   array of string;
    FCount:    integer;
    FCapacity: integer;
    procedure Grow;
  public
    constructor Create( InitialCapacity: integer = 16 );
    destructor Destroy; override;

    procedure Add( const S: string );
    procedure AddLine( const S: string );
    procedure Clear;
    function ToString: string; override;

    property Count: integer read FCount;
  end;

  // Вспомогательные функции

{ JsonValidate проверяет, содержит ли строка допустимый формат json.
JsonValidate tests if a string contains a valid json format }
function JsonValidate( const JSONString: string ): boolean;
{ JsonNumberValidate проверяет, содержит ли строка допустимый номер в формате json.
  JsonNumberValidate tests if a string contains a valid json formatted number }
function JsonNumberValidate( const JSONnumer: string ): boolean;
{ JsonStringValidate проверяет, содержит ли строка допустимую строку в формате json.
JsonStringValidate tests if a string contains a valid json formatted string  }
function JsonStringValidate( const JSONString: string ): boolean;
//Добавляет Кавычки. JsonStringEncode преобразует строку pascal в строку json. JsonStringEncode converts a pascal string to a json string
function JsonStringEncode( const S: string ): string;
// преобразует строку json в строку pascal. JsonString converts a json string to a pascal string
function JsonStringDecode( const S: string ): string;
{ JsonToXml преобразует строку json в xml. JsonToXml converts a json string to xml }
function JsonToXml( const S: string ): string;

procedure FormatExpand( Obj: TJsonNode; probel: integer; var Result: TJsonStringBuilder );
procedure FormatCompact( Obj: TJsonNode; probel: integer; var Result: TJsonStringBuilder );
procedure FormatCompressed( Obj: TJsonNode; var Result: TJsonStringBuilder );


implementation

uses Math, TypInfo, LConvEncoding;

resourcestring
  errNotCollection =
    'Узел не является объектом или массивом (Node is not a container).';
  errRootNodeKind =
    'Корневой узел должен быть объектом. (Root node must be object).';
  errRootValue    =
    'Вы пытаетесь присвоить значение (Value) корню - измените логику присвоения';
  errIndexOutOfBounds = 'Индекс выходит за границы (Index out of bounds).';
  errNotArray     = 'Объект не является массивом';
  errParsingError = 'Ошибка при разборе текста (Error while parsing text).';
  errNilElement   = 'Обект не существует (=nil) ';
  errZnachenie    = 'Ожидалось: значение свойства или "{" или "[" в ';
  errColumn       = 'Ожидалось ":" в ';
  errStackMax     =
    'Если значение допустимое, то далее должно следовать: "," или "]"';

type

  TJsonTokenKind = ( tkEnd, tkError, tkObjectOpen, tkObjectClose, tkArrayOpen,
    tkArrayClose, tkColon, tkComma, tkNull, tkFalse, tkTrue, tkString, tkNumber,
    tkNumber_, tkFloat, tkFloat_, tkNaN, tkHex, tkElm, tkComment );

  { TJsonToken }

  TJsonToken = record
    Head: pchar;
    Tail: pchar;
    Kind: TJsonTokenKind;
    function Value: variant;
  end;


const
  stackMax  = 1000000;
  HexDigit  = ['0'..'9', 'A'..'F', 'a'..'f'];
  HexDigits = '0123456789ABCDEFabcdef';

var
  DefFormatSettings: TFormatSettings;
  JSONFormat:        TJSONFormat = jfCompact;


  //=======================================================================

function varIsNullEmpty( V: variant ): boolean; inline;
begin
  Result := ( TVarData( V ).vType = varNull ) or ( TVarData( V ).vType = varEmpty ) or VarIsClear( V );
end;

{ TJsonToken }

function TJsonToken.Value: variant;
var
  s:    string;
  ErrorVal, ii32: integer;
  ii64: IntPtr;
  ee:   double;

//Убрать подчёркивание
  procedure num_;
  var
    n:        byte = 0;
    p, start: pchar;
  begin
    start := PChar( s );
    p     := start;
    while p^ <> #0 do
      begin
      if p^ = '_' then
        Inc( n )
      else
        ( p -n )^ := p^;

      Inc( p );
      end;
    //SetLength( s, p - start - n );
    ( p -n )^ := #0;
  end;

begin
  case Kind of
    tkString, tkComment:
      begin //Кавычки уже обрезаны
      SetString( s, Head, Tail - Head );
      Result := JsonStringDecode( s );
      end;
    tkEnd, tkError: Result := #0;
    tkObjectOpen: Result   := '{';
    tkObjectClose: Result  := '}';
    tkArrayOpen: Result    := '[';
    tkArrayClose: Result   := ']';
    tkColon: Result        := ':';
    tkComma: Result        := ',';

    tkNumber, tkNumber_:
      begin
      SetString( s, Head, Tail - Head );
      if Kind = tkNumber_ then
        num_;

      Val( s, ii32, ErrorVal );
      if ErrorVal = 0 then
        Result := ii32{%H}
      else
        begin
        Val( s, ii64, ErrorVal );
        if ErrorVal = 0 then
          Result := ii64{%H}
        else
          Result := NaN;
        end;
      end;
    tkFloat, tkFloat_:
      begin
      SetString( s, Head, Tail - Head );
      if Kind = tkFloat_ then
        num_;

      if TryStrToFloat( s, ee, DefFormatSettings ) = True then
        Result := ee{%H}
      else
        Result := NaN;
      end;
    tkNull: Result  := Null;
    tkFalse: Result := False;
    tkTrue: Result  := True;
    tkNaN: Result   := NaN;
    else
      Result := VarAsType( Result, varEmpty );
    end;
end;



{ TJsonNodeEnumerator }

procedure TJsonNodeEnumerator.Init( Node: TJsonNode );
begin
  FNode  := Node;
  FIndex := -1;
end;

function TJsonNodeEnumerator.GetCurrent: TJsonNode;
begin
  if ( FNode.FItems <> nil ) and ( FIndex >= 0 ) and ( FIndex < FNode.FItems.Count ) then
    Result := TJsonNode( FNode.FItems[FIndex] )
  else
    Result := nil;
end;

function TJsonNodeEnumerator.MoveNext: boolean;
begin
  Inc( FIndex );
  Result := ( FNode.FItems <> nil ) and ( FIndex < FNode.FItems.Count );
end;

function TJsonNode.GetEnumerator: TJsonNodeEnumerator;
begin
  Result.Init( Self );
end;


// ======================================================================

{ TJsonNode }

destructor TJsonNode.Destroy;
var
  I: integer;
begin
  if Assigned( FCachePath ) then
    FCachePath.Free;
  if Assigned( FItems ) then
    try
    FItems.Free;
    except
    FItems.List.Free;
    end;
  inherited;
end;

procedure TJsonNode.Error( const Msg: string = '' );
begin
  FStack := 0;
  if Msg = '' then
    raise EJsonException.Create( errParsingError )
  else
    raise EJsonException.Create( Msg );
end;


// -----------------  Методы парсинга --------------------------


// Кавычки обрезаются если есть
procedure ParseStringToken( var pJS: pchar; out Token: TJsonToken );
label
  U1, U2, U3;
var
  Start: pchar;
  Skip:  integer;
  s0:    char;
  s:     string[5];

  procedure endToken; inline;
  begin
    Token.Head := Start;
    Token.Tail := pJS;
    Token.Kind := tkString;
  end;

begin
  Token.Kind := tkError;
  s0 := pJS^;
  if ( pJS^ = '"' ) or ( pJS^ = '''' ) then
    Inc( pJS );// Пропускаем открывающую кавычку
  Start := pJS;

  while True do
    case pJS^ of
      '\': // Обработка escape-последовательностей
        begin
        Inc( pJS );
        if pJS^ = #0 then Exit;

        case pJS^ of
          '"', '''', '\', '/', 'b', 'f', 'n', 'r', 't': Inc( pJS ); //экранирование
          'u':
            begin
            // Unicode символ \uXXXX
            if not ( ( pJS[1] in HexDigit ) and ( pJS[2] in HexDigit ) and
              ( pJS[3] in HexDigit ) and ( pJS[4] in HexDigit ) ) then
              Exit;

            s := Utf8ToAnsi( Copy( pJS, 0, 5 ) );
            Inc( pJS, 5 );

            //обработка Unicode символов
            case s of
              '"', '''': goto U1;
              ' ', '{', '}', '[', ']', ',', ':', #0: goto U2;
              #10: goto U3;
              else;
              end;

            end;
          else
            Exit; // Недопустимый escape-символ
          end;
        end;

      '"', '''':     // в начале была одна из кавычек
        U1:
          if s0 in ['"', ''''] then
            // конец - если начиналось на '"', иначе можно в середине слова
            begin
            endToken;
            Inc( pJS );
            Exit;
            end
          else
            Inc( pJS );

      ' ', '{', '}', '[', ']', ',', ':', #0: // - допускается внутри кавычек
        U2:
          if not ( ( s0 <> '"' ) xor ( s0 <> '''' ) ) then
            begin
            endToken;
            Exit;
            end
          else
            Inc( pJS );

      #10:           //допускаем перенос строк в " или в '
        U3:
          if s0 in ['"', ''''] then
            begin
            if ( pJS + 1 )^ = #13 then  //перенос для win
              Inc( pJS );
            Inc( pJS );
            end
          else
            Exit;    // Недопустимый управляющий символ

      #1..#9, #11..#31:
        Exit;        // Недопустимый управляющий символ

      else           // Обработка UTF-8 символов
        begin
        Skip := UTF8CodepointSize( pJS );
        if Skip = 0 then Exit;        // Недопустимый UTF-8
        Inc( pJS, Skip );
        end;
      end;
end;

procedure ParseNumberToken( var pJS: pchar; out Token: TJsonToken );
const
  HexDigits: set of char = ['0'..'9', 'a'..'f', 'A'..'F', '_'];
var
  hex:  boolean = False;
  pJS2: pchar;
begin
  Token.Head := pJS;
  // Пропускаем знак
  if ( pJS^ = '-' ) or ( pJS^ = '+' ) then
    Inc( pJS );

  //если после знака или . - не число, то проверить на строку
  if not ( ( ( pJS^ >= '0' ) and ( pJS^ <= '9' ) ) or ( pJS^ = '.' ) ) then
    begin
    pJS := Token.Head;
    ParseStringToken( pJS, Token );
    Exit;
    end;

  // Проверяем что после 0x есть хотя бы одна hex цифра
  if ( pJS^ = '0' ) then
    if ( ( pJS + 1 )^ in ['x', 'X'] ) and ( ( pJS + 2 )^ in HexDigits - ['_'] )///
      and ( Token.Head^ <> '.' ) then
      begin
      // Обработка шестнадцатеричного числа
      hex        := True;
      Token.Kind := tkNumber;
      Inc( pJS, 2 );
      while pJS^ in HexDigits do
        begin
        if pJS^ = '_' then
          Token.Kind := tkNumber_;
        Inc( pJS );
        end;
      Token.Tail := pJS;
      Exit;
      end
    else
      if ( ( pJS + 1 )^ in ['x', 'X'] ) then
        begin
        pJS := Token.Head;
        ParseStringToken( pJS, Token );
        Exit;
        end;

  Token.Kind := tkNumber;
  // Разбираем целую часть
  while ( pJS^ >= '0' ) and ( pJS^ <= '9' ) or ( pJS^ = '_' ) do
    begin
    if pJS^ = '_' then
      Token.Kind := tkNumber_;
    Inc( pJS );
    end;

  // Разбираем дробную часть
  if pJS^ = '.' then //or ( pJS^ = ',' ) then
    begin
    if Token.Kind = tkNumber_ then
      Token.Kind := tkFloat_
    else
      Token.Kind := tkFloat;
    Inc( pJS );
    while ( pJS^ >= '0' ) and ( pJS^ <= '9' ) or ( pJS^ = '_' ) do
      begin
      if pJS^ = '_' then
        Token.Kind := tkFloat_;
      Inc( pJS );
      end;
    end;

  // Разбираем экспоненту
  if ( pJS^ = 'e' ) or ( pJS^ = 'E' ) then
    begin
    Inc( pJS );
    if ( pJS^ = '+' ) or ( pJS^ = '-' ) then Inc( pJS );
    while ( pJS^ >= '0' ) and ( pJS^ <= '9' ) or ( pJS^ = '_' ) do Inc( pJS );
    end;

  //if pJS^ = '%' then Inc( pJS ); - % не работает

  //наверное это строка начинающаяся на число
  //if (not (Token.Kind in [tkNumber_, tkFloat, tkFloat_)) and (hex=False)
  pJS2 := pJS;
  // Пропускаем пробелы, табуляции, энтеры...
  while ( pJS2^ <= ' ' ) and ( pJS2^ <> #0 ) do
    Inc( pJS2 );
  if pJS2^ in [#0, '{', '}', '[', ']', ',', ':', '"', ''''] then //конец параметра
    Token.Tail := pJS
  else
    begin
    pJS        := Token.Head;
    Token.Kind := tkError;
    ParseStringToken( pJS, Token );
    end;
end;


//true - успешное взятие токена
function NextToken( var pJS: pchar; out Token: TJsonToken ): boolean;

  // Проверить на ключевое слово, например: tTrRuUeE
  function keyEq( keyStr2: pchar ): boolean;
  var
    n: byte = 0;
  begin
    if keyStr2 = #0 then Exit( False );
    Result := False;
    while keyStr2^ <> #0 do
      if ( ( Token.Head + n )^ = keyStr2^ ) or ( ( Token.Head + n )^ = ( keyStr2 + 1 )^ ) then
        begin
        Inc( keyStr2, 2 );
        Inc( n );
        end
      else
        Exit( False );
    Result := True;
  end;

  ////проверка UTF8 на ключевые слова
  //function keyUTF8( keyStr: shortstring ): boolean;
  //begin
  //  // Unicode символ \uXXXX
  //  if not ( ( pJS[1] in HexDigit ) and ( pJS[2] in HexDigit ) and ( pJS[3] in HexDigit ) and
  //    ( pJS[4] in HexDigit ) ) then
  //    Exit;
  //  s := Utf8ToAnsi( Copy( pJS, 0, 5 ) );
  //  Inc( pJS, 5 );
  //end;
var
  comment: boolean = False;
begin
  // Пропускаем пробелы, табуляции, энтеры...
  while ( pJS^ <= ' ' ) and ( pJS^ <> #0 ) do Inc( pJS );

  Token.Head := pJS;
  Token.Tail := pJS;
  Token.Kind := tkError;
  if pJS^ = #0 then
    begin
    Token.Kind := tkEnd;
    Exit( False );
    end;

  case pJS^ of
    '{': begin
      Inc( pJS );
      Token.Kind := tkObjectOpen;
      end;
    '}': begin
      Inc( pJS );
      Token.Kind := tkObjectClose;
      end;
    '[': begin
      Inc( pJS );
      Token.Kind := tkArrayOpen;
      end;
    ']': begin
      Inc( pJS );
      Token.Kind := tkArrayClose;
      end;
    ':': begin
      Inc( pJS );
      Token.Kind := tkColon;
      end;
    ',': begin
      Inc( pJS );
      Token.Kind := tkComma;
      end;

    '"', '''': ParseStringToken( pJS, Token );  // Разбор строки

    '0'..'9', '.', '-', '+': ParseNumberToken( pJS, Token ); // Разбор числа

    #0..#31: ;

    else   // иначе это строка

      // Разбор комментариев
      if ( pJS^ = '/' ) and ( ( pJS + 1 )^ = '/' ) then
        begin
        Inc( pJS, 2 );
        comment := True;
        //Token.Head := pJS;
        //Token.Kind := tkComment;
        //while not ( pJS^ in [#0, #10, #13] ) do
        //  if ( pJS^ in ['"', '{', '['] ) and ( ( pJS - 1 )^ <> '\' ) then
        //    begin
        //    Dec( pJS );
        //    Break;
        //    end
        //  else
        //    Inc( pJS );
        end;


      //проверка UTF8 на ключевые слова
      //else if ( pJS^ = '\' ) and ( ( pJS + 1 )^ = 'u' ) then
      //if keyUTF8(PChar( 'true' ) ) then       // true


      //строка

      ParseStringToken( pJS, Token ); //Разбор строки

      if Token.Kind <> tkError then
        if comment then
          Token.Kind := tkComment
        else
          case Token.Head^ of
            't', 'T': if ( Token.Tail - Token.Head ) = 4 then
                if keyEq( PChar( 'tTrRuUeE' ) ) then       // true
                  Token.Kind := tkTrue;

            'f', 'F': if ( Token.Tail - Token.Head ) = 5 then
                if keyEq( PChar( 'fFaAlLsSeE' ) ) then   // false
                  Token.Kind := tkFalse;

            'n', 'N':
              case ( Token.Tail - Token.Head ) of
                3: if keyEq( PChar( 'nNaAnN' ) ) then   // NaN
                    Token.Kind := tkNaN;
                4: if keyEq( PChar( 'nNuUlLlL' ) ) then   // null
                    Token.Kind := tkNull
                end;
            end;
    end;
  Result := Token.Kind <> tkError;
end;


//===========================================================================

// Парсинг. Приходит уже без скобки { или [
procedure TJsonNode.ParseJSON( var pJS: pchar );
var
  Token:    TJsonToken;
  NodeName: string = '';

//создать массив в массиве или в объекте, скобка уже открыта
  procedure arrayNew( NodeParent: TJsonNode );
  var
    NodeChild: TJsonNode;
  begin
    // Создаём пустой массив
    NodeChild := NodeParent.AddArr( NodeName );

    //Заполняем массив элементами
    while NextToken( pJS, Token ) do
      case Token.Kind of
        tkNull, tkTrue, tkFalse, tkString, tkNumber, tkFloat, tkNaN, tkNumber_,
        tkFloat_: NodeChild.AddArrElm( Token.Value );

        tkComma{, tkObjectClose}: Continue;
        tkArrayClose: Break;
        tkObjectOpen: NodeChild.AddObj( '' ).ParseJSON( pJS );
        tkArrayOpen: arrayNew( NodeChild );
        else
          Error( errStackMax );
        end;
  end;

begin
  if Self = nil then Exit;
  // Убеждаемся, что текущий узел является структурой
  if not nkStrukt then
    Error( errNotCollection );

  while NextToken( pJS, Token ) do
    case Token.Kind of
      tkString:
        begin
        //имя объекта/значения
        NodeName := JsonStringDecode( Token.Value );

        // Ожидается: ":"
        if not NextToken( pJS, Token ) then
          Error( errColumn + NodeName );

        // Ожидается: Значение, "{", "["
        if NextToken( pJS, Token ) then
          case Token.Kind of
            tkNull, tkTrue, tkFalse, tkString, tkNumber, tkFloat,
            tkNumber_, tkFloat_, tkNaN:
              AddNode( nkElm, NodeName, Token.Value );

            tkObjectOpen: AddObj( NodeName ).ParseJSON( pJS );
            tkArrayOpen: arrayNew( Self )
            else
              Error( errParsingError );
            end
        else
          Error( errZnachenie + NodeName );
        end;

      tkComma: Continue;      // Переходим к следующему свойству

      //разбор начинается с "{" - добавляем объект.
      tkObjectOpen:
        if FKind = nkObject then
          // Если мы в объекте - добавляем новые значения в текущий объект
          Continue
        else
          AddObj( NodeName ).ParseJSON( pJS );

      //разбор начинается с "[" - добавляем массив
      tkArrayOpen:
        if FKind = nkArray then
          arrayNew( Self )
        else
          Error( errNotArray );

      tkObjectClose, tkArrayClose: Break;

      tkComment:
        AddNode( nkcomment, GUIDToString( TGuid.NewGuid ), Token.Value );

      tkEnd: Break;

      else
        Error;
      end;
end;

//true, если расшифровка JSONString прошла успешно
function TJsonNode.Parse( const JSONString: string ): boolean;
var
  pJS: pchar;
begin
  Result := False;
  pJS    := PChar( JSONString );
    try
    ParseJSON( pJS );
    Result := True;
    finally;
    //FCachePath.Free;
    end;
end;


// ------------  Загрузка/сохранение -------------------------------

function TJsonNode.LoadFromStream( Stream: TStream ): boolean;
var
  S: string;
  I: int64;
begin
  Result := False;
  I      := Stream.Size - Stream.Position;
  S      := '';
  SetLength( S, I );
    try
    Stream.Read( PChar( S )^, I );
    except
    Error( errParsingError );
    end;

  Result := Parse( S );
end;

function TJsonNode.LoadFromFile( const FileName: string ): boolean;
var
  F: TFileStream;
begin
  F := TFileStream.Create( FileName, fmOpenRead );
    try
    Result := LoadFromStream( F );
    finally
    F.Free;
    end;
end;


procedure TJsonNode.SaveToStream( Stream: TStream; JSFotmat: TJSONFormat = jfCompact );
var
  S: string;
  I: int64;
begin
  S := JsonToText( JSFotmat );
  I := Length( S );
  Stream.Write( PChar( S )^, I );
end;

function TJsonNode.SaveToFile( const FileName: string; JSFotmat: TJSONFormat = jfCompact ): boolean;
var
  F: TFileStream;
begin
  F := TFileStream.Create( FileName, fmCreate );
    try
    SaveToStream( F, JSFotmat );
    Result := True;
    finally
    F.Free;
    end;
end;


//-------------------- Работа с узлами -----------------------------

 //Добавить Пустой параметр в объект или массив
 //Result - добавленный параметр
function TJsonNode.AddElm( const elmName: string ): TJsonNode;
var
  aVar: variant;
begin
  if Self = nil then Exit( nil );

  if nkStrukt then
    begin
    aVar   := VarAsType( aVar, varEmpty );
    Result := AddNode( nkElm, elmName, aVar );
    end
  else
    Error( errNotCollection );
end;

 //Добавить новый параметр в объект или массив
 //Result - исходный (текущий) объект или массив
function TJsonNode.AddElm( const elmName: string; AValue: variant ): TJsonNode;
begin
  if Self = nil then Exit( nil );
  Result := Self;

  if nkStrukt then
    begin
    if VarIsStr( AValue ) then
      begin
      if not Parse( elmName + ':' + VarToStr( AValue ) ) then
        Error( errParsingError + ': ' + elmName + ':' + VarToStr( AValue ) );
      end
    else
      AddNode( nkElm, elmName, AValue );
    end
  else
    Error( errNotCollection );
end;

//Добавить дочерний узел в объект или в массив по указанному Пути (создастся)
//nameElm - для массива не учитывается
function TJsonNode.AddPath( const pathName: string; nameElm: string; AValue: variant ): TJsonNode;
begin
  Result := Force( pathName );
  if Result <> nil then
    case Result.FKind of
      nkObject: Result.AddNode( nkElm, nameElm, AValue );
      nkArray: Result.AddArrElm( AValue );
      else
        Error( errNotCollection );
      end;
end;

//Добавить пустой Объект в сложный элемент. Возвращает добавленный объект
function TJsonNode.AddObj( const nameObject: string ): TJsonNode;
var
  aVar: variant;
begin
  if Self = nil then Exit( nil );
  if nkStrukt then
    begin
    aVar   := VarAsType( aVar, varEmpty );
    Result := AddNode( nkObject, nameObject, aVar );
    end
  else
    Error( errNotCollection );
end;

//Добавить/заменить Json-узел
function TJsonNode.AddJSON( const aJSON: TJsonNode ): TJsonNode;
var
  n:   integer = -1;
  nod: TJsonNode;
begin
  if Self = nil then Exit( nil );
  if nkStrukt then
    begin
    //если уже есть этот объект - то удалить его, дабы записать снова
    if FItems <> nil then
      begin
      n := FItems.IndexOf( aJSON );
      if n >= 0 then
        Delete( n );
      end;

    //объект не найден - создаём (Без else - вдруг удалили последний объект)
    if FItems = nil then
      FItems := TFPObjectList.Create( True );
    nod      := aJSON;
    nod.FParent := Self;
    FItems.Add( nod );
    end
  else
    Error( errNotCollection );
end;

//Добавить пустой Массив (в массиве - имя не учитывается, только в Объекте)
function TJsonNode.AddArr( const nameArray: string ): TJsonNode;
var
  aVar: variant;
begin
  if Self = nil then Exit( nil );
  if nkStrukt then
    begin
    aVar   := VarAsType( aVar, varEmpty );
    Result := AddNode( nkArray, nameArray, aVar );
    end
  else
    Error( errNotArray );
end;

//Добавить Элемент в массив. Вернуть массив, а не элемент
function TJsonNode.AddArrElm( AValue: variant ): TJsonNode;
var
  newElm: TJsonNode;
begin
  if Self = nil then Exit( nil );
  Result := Self;
  if FKind = nkArray then
    begin
    if FItems = nil then
      FItems := TFPObjectList.Create( True );
    // создать экземпляр класса и добавить в список
    newElm   := TJsonNode.Create;
    FItems.Add( newElm );
    newElm.FParent := Self;
    newElm.FName   := IntToStr( FItems.Count );
    newElm.FKind   := nkElm;
    newElm.FValue  := AValue;
    end
  else
    Error( errNotArray );
end;

//Добавить Элемент в массив (в переди стоящий или на нём или в нём), создастся при необходимости
function TJsonNode.AddArrElm( const nameArray: string; AValue: variant ): TJsonNode;
var
  bAdd: boolean = False;
  Nod:  TJsonNode;
  aVar: variant;
begin
  if Self = nil then Exit( nil );

  //Стоим на этом массиве
  if ( FKind = nkArray ) and ( FName = nameArray ) then
    begin
    AddArrElm( AValue );
    bAdd := True;
    end
  else
    //найти вложенный массив
    begin
    //Стоим перед массивом
    if nkStrukt then
      begin
      Nod := Child( nameArray );
      if ( Nod <> nil ) and ( Nod.FKind = nkArray ) then
        begin
        Nod.AddArrElm( AValue );
        bAdd := True;
        end;
      end;

    //Стоим в ячейке этого массива
    if not bAdd then
      if ( Parent <> nil ) and ( Parent.FKind = nkArray ) and ( Parent.FName = nameArray ) then
        begin
        Parent.AddArrElm( AValue );
        bAdd := True;
        end;
    end;

  if not bAdd then
    if nkStrukt then
      begin
      aVar   := VarAsType( aVar, varEmpty );
      Result := AddNode( nkArray, nameArray, aVar ).AddArrElm( AValue );
      end
    else
      Error( errNotArray );
end;

//Добавить комментарий
function TJsonNode.AddComment( const nameComment: string ): TJsonNode;
begin
  if Self = nil then Exit( nil );
  if nkStrukt then
    Result := AddNode( nkComment, GUIDToString( TGuid.NewGuid ), nameComment )
  else
    Error( errNotCollection );
end;

//Добавить новый узел (private) и вернуть его
function TJsonNode.AddNode( AKind: TJsonNodeKind; const aName: string; AValue: variant ): TJsonNode;
begin
  if not nkStrukt then Error( errNotCollection );
  //Получить дочерний узел по имени - не для массива
  if FKind <> nkArray then
    Result := Child( aName )
  else
    Result := nil;

  //если нету - создать экземпляр класса и добавить в список
  if Result = nil then
    begin
    Result := TJsonNode.Create;
    // Проверяем глубину стека
    if FStack >= stackMax then
      Error( 'Превышена максимальная глубина вложенности' )
    else
      Result.FStack := FStack + 1;

    Result.FKind   := AKind;
    Result.FParent := Self;
    if FItems = nil then
      FItems := TFPObjectList.Create( True );
    FItems.Add( Result );
    end;
  Result.FValue := AValue;

  //Для массива своё имя
  if FKind = nkArray then
    Result.FName := IntToStr( FItems.Count )
  else
    //если найдём этот узел, то можно поменять Значение или высоту букв в имени
    Result.FName := aName;

  CacheUpdatePath; // Очищаем кэш при изменениях
end;

//принадлежит ли узел структуре?
function TJsonNode.nkStrukt: boolean; inline;
begin
  Result := ( FKind = nkObject ) or ( FKind = nkArray );
end;

//Слить два Json-узла (объект или массив)
function TJsonNode.AddMerge( const NodeStruktMerge: TJsonNode; SZamenoj: boolean = True ): TJsonNode;
var
  nodeMerge, nodeChild, nodeFor: TJsonNode;
  i, j:     integer;
  valueVar: variant;
  b:        boolean;
begin
  if self = nil then Exit( nil );
  if NodeStruktMerge = nil then Exit( self );
  Result := self;

  //сливаем только объект-объект или массив-массив
  if nkStrukt and ( FKind = NodeStruktMerge.FKind ) then
    begin
    //перебираем все параметры нового объекта и добавляем их в текущий
    for i := 0 to NodeStruktMerge.Count - 1 do
      begin
      nodeMerge := TJsonNode( NodeStruktMerge.FItems[i] );

      //если попалась структура, то сливаем её
      if nodeMerge.nkStrukt then
        begin
        nodeChild := Child( nodeMerge.FName );
        //создаём узел, если его не было
        if nodeChild = nil then
          if nodeMerge.FKind = nkObject then
            nodeChild := AddObj( nodeMerge.FName )
          else
            nodeChild := AddArr( nodeMerge.FName );

        nodeChild.AddMerge( nodeMerge, SZamenoj );
        end

      // иначе просто добавляем узел
      else

      //если это массив
        if FKind = nkArray then
          begin
          valueVar  := nodeMerge.FValue;
          nodeChild := nil;
          //перебираем все элементы текущего массива
          for j := 0 to Count - 1 do
            begin
            nodeFor := TJsonNode( FItems[j] );
            b       := True;
            (*в variant при сравнении типы преобразуются к единому типу*)
            if VarIsStr( valueVar ) and VarIsStr( nodeFor.FValue ) then
              b := False;
            if b and VarIsNumeric( valueVar ) and VarIsNumeric( nodeFor.FValue ) then
              b := False;
            if b and VarIsBool( valueVar ) and VarIsBool( nodeFor.FValue ) then
              b := False;
            if b and varIsNullEmpty( valueVar ) and varIsNullEmpty( nodeFor.FValue ) then
              b := False;
            if not b and ( nodeFor.FValue = valueVar ) then
              begin
              nodeChild := nodeFor;
              Break;
              end;
            end;

          //если есть, то пропускаем, иначе добавляем
          if nodeChild = nil then
            AddNode( nodeMerge.FKind, nodeMerge.FName, nodeMerge.FValue )
          else
            Continue;
          end

        //если это объекты. Найти простой парамeтр в текущем узле
        else
          begin
          nodeChild := Child( nodeMerge.FName );

          //если есть то проверить на замену
          if nodeChild <> nil then
            if SZamenoj then
              nodeChild.Delete
            else
              Continue;

          AddNode( nodeMerge.FKind, nodeMerge.FName, nodeMerge.FValue );
          end;
      end;

    end
  else
    Error( errNotCollection );
end;


function TJsonNode.GetValue: variant;
var
  aVar: variant;
begin
  aVar := VarAsType( aVar, varEmpty );
  if self = nil then Exit( aVar );
  if varIsNullEmpty( FValue ) then
    Result := Null
  else
    Result := FValue;
end;

procedure TJsonNode.SetValue( AValue: variant );
var
  pJS: pchar;
  Token, TokenColon: TJsonToken;
begin
  if Self = nil then Error( errNilElement );

  //в строке могут быть переносы
  if VarIsStr( AValue ) then
    begin
    pJS := PChar( VarToStr( AValue ) );
    if NextToken( pJS, Token ) then
      case Token.Kind of
        tkNull, tkTrue, tkFalse, tkString, tkNumber, tkFloat,
        tkNumber_, tkFloat_, tkNaN:
          if Self <> Root then
            if NextToken( pJS, TokenColon ) and ( TokenColon.Kind = tkColon ) then
              Parse( AValue )
            else
              begin
              if Token.Kind = tkComment then
                FKind := nkComment
              else
                if ( FKind = nkObject ) and VarIsEmpty( FValue ) and ( FItems = nil ) then
                  FKind := nkElm;

              if FKind = nkArray then
                AddArrElm( Token.Value )
              else
                FValue := Token.Value;
              end
          else
            Error( errRootValue + '(' + VarToStrDef( AValue, '' ) + ')' );

        //строка оказалась JSON-строка - разбираем её
        tkObjectOpen, tkArrayOpen:
          if nkStrukt then
            Parse( AValue )
          else
            Error( FName + ': ' + errNotCollection );
        end
    else
      Error( errZnachenie + Name );
    end

  else
  //если не строка (число, нил, ...), то просто присвоить
    if Self <> Root then
      begin
      if ( FKind = nkObject ) and VarIsEmpty( FValue ) and ( FItems = nil ) then
        FKind := nkElm;

      if FKind = nkArray then
        AddArrElm( AValue )
      else
        FValue := AValue;
      end
    else
      Error( errRootValue );
end;

function TJsonNode.GetCount: integer;
begin
  if ( self <> nil ) and ( FItems <> nil ) then
    Result := FItems.Count
  else
    Result := 0;
end;

//удалить текущий узел и последующие
procedure TJsonNode.Delete;
begin
  if Self = nil then Exit;
  if ( Parent <> nil ) and ( Parent.FItems <> nil ) then
    Parent.Delete( Parent.FItems.IndexOf( Self ) );
end;

procedure TJsonNode.Delete( Index: integer );
begin
  if ( Self = nil ) or ( FItems = nil ) or ( Index < 0 ) or ( Index >= FItems.Count ) then
    Exit;

  FItems.Delete( Index );
  if ( FItems <> nil ) and ( FItems.Count = 0 ) then
    begin
    FItems.Free;
    FItems := nil;
    end;

  CacheUpdatePath; // Очищаем кэш при изменениях
end;

procedure TJsonNode.Delete( const Name: string );
var
  Node: TJsonNode;
begin
  if ( Self = nil ) or ( FItems = nil ) then
    Exit;

  Node := Child( Name );
  if Node <> nil then
    Delete( FItems.IndexOf( Node ) );
end;


//Очистить все дочерние узлы и FValue установить в Null.
function TJsonNode.Clear: TJsonNode;
begin
  if self = nil then Exit( nil );
  Result := Self;
  FItems.Free;

  if Parent <> nil then
    FValue := Null;
end;

procedure TJsonNode.SetKind( AKind: TJsonNodeKind );
begin
  if self = nil then Exit;
  if FKind = AKind then Exit;

  if nkStrukt then
    Clear;
  FKind := AKind;
end;

function TJsonNode.GetName: string;
begin
  if self = nil then Exit( '' );
  if ( FKind <> nkObject ) and ( FParent <> nil ) and ( FParent.FKind = nkArray ) then
    Result := IntToStr( FParent.FItems.IndexOf( Self ) )
  else
    Result := FName;
end;

procedure TJsonNode.SetName( const AValue: string );
begin
  if self = nil then
    begin
    Error( errNilElement );
    Exit;
    end;
  if ( FParent <> nil ) and ( FParent.FKind = nkArray ) then
    begin
    if ( FParent.FParent = nil ) or ///
      ( ( FParent.FParent <> nil ) and ( FParent.FParent.FKind <> nkArray ) ) then
      FParent.FName := AValue;
    exit;
    end;
  FName := AValue;
end;

// Получить значение из массива
function TJsonNode.GetArrElm( AIndex: integer ): variant;
var
  ArrayNode: TJsonNode = nil;
begin
  if ( Self = nil ) then Result := VarAsType( Result, varEmpty );

  if ( FKind = nkArray ) then
    begin
    ArrayNode := Child( AIndex );
    if ArrayNode = nil then
      Result := VarAsType( Result, varEmpty )
    else
      Result := ArrayNode.Value;
    end
  else if ( fParent <> nil ) and ( FParent.FKind = nkArray ) then
      Result := FValue
    else
      Result := VarAsType( Result, varEmpty );
end;

// Получить значение из массива
function TJsonNode.GetArrElm( const AArrayPath: string; AIndex: integer ): variant;
begin
  Result := Find( AArrayPath ).GetArrElm( AIndex );
end;

 //Перемещает текущий узел в область узла Destinatiоn
 //Mode = (nmAddNext, nmAddPred, nmAddFirst, nmAddLast, nmAddChildFirst, nmAddChildLast);
function TJsonNode.MoveTo( const Destinations: TJsonNode; Mode: TJsonNodeAttachMode = nmAddLast ): boolean;
 {nmAddNext:       после узла         - add as sibling of Destination
  nmAddPred:       перед узлом        - add as sibling of Destination
  nmAddFirst:      первым в ветке     - add as first sibling of Destnation
  nmAddLast:       последним в ветке  - add as last sibling of Destination
  nmAddChildFirst: первым в дочерней ветке    - add as first child of Destination
  nmAddChildLast:  последним в дочерней ветке - add as last child of Destination
  }
var
  Destination, DSP: TJsonNode;
  n: integer;
begin
  Result      := False;
  Destination := Destinations;
  if ( Destination = nil ) then
    // and not ( Mode in [nmAddNext, nmAddPred, nmAddChildFirst, nmAddChildLast] ) then
    Error( 'TJsonNode.MoveTo Destination=nil' );

  DSP := Destination.FParent;
  //родительский узел нельзя перетащить в дочерний
  if ( DSP <> nil ) and ( not Destination.HasAsParent( Self ) ) then
    try
    //вставляем в Destination
    case Mode of
      nmAddNext: DSP.FItems.Insert( DSP.FItems.IndexOf( Destination ) + 1, Self );
      nmAddPred: DSP.FItems.Insert( DSP.FItems.IndexOf( Destination ), Self );
      nmAddFirst: DSP.FItems.Insert( 0, Self );
      nmAddLast: DSP.FItems.Insert( DSP.FItems.Count, Self );
      nmAddChildFirst:
        if Destination <> Self then
          begin
          if not Destination.nkStrukt then
            Error( errNotCollection );
          if Destination.FItems = nil then
            Destination.FItems := TFPObjectList.Create( True );
          Destination.FItems.Insert( 0, Self );
          end
        else
          Exit;
      nmAddChildLast:
        if Destination <> Self then
          begin
          if not Destination.nkStrukt then
            Error( errNotCollection );
          if Destination.FItems = nil then
            Destination.FItems := TFPObjectList.Create( True );
          Destination.FItems.Insert( Destination.FItems.Count, Self );
          end
        else
          Exit;
      end;

    //удалить связь из старого места
    if FParent <> nil then
      begin
      FParent.FItems.OwnsObjects := False;
      FParent.FItems.Remove( Self );
      FParent.FItems.OwnsObjects := True;
      end;

    //прописать родителя для Destination
    if Mode in [nmAddChildFirst, nmAddChildLast] then
      begin
      Self.FParent := Destination;
      Self.FStack  := Destination.FStack + 1;
      end
    else
      begin
      Self.FParent := DSP;
      Self.FStack  := DSP.FStack + 1;
      end;

    Result := True;
    except;
    end;
end;


//-------------------- Навигация -----------------------------------

//Получить дочерний узел по индексу
function TJsonNode.Child( Index: integer ): TJsonNode;
begin
  Result := nil;
  if ( FItems <> nil ) and nkStrukt then
    begin
    if ( Index < 0 ) or ( Index > FItems.Count - 1 ) then
      Error( errIndexOutOfBounds );
    Result := TJsonNode( FItems[Index] );
    end;
end;

//Получить дочерний узел по имени
function TJsonNode.Child( const Name: string ): TJsonNode;
var
  Nod: TJsonNode = nil;
  I:   integer;
  Names, NodName: string;
begin
  Result := nil;
  if ( Self <> nil ) and ( FItems <> nil ) then
    case FKind of
      nkArray:
        begin
        I := StrToIntDef( Name, -1 );
        if ( I >= 0 ) and ( I < FItems.Count ) then
          Result := TJsonNode( FItems[I] );
        end;
      nkObject:
        begin
        Names := UTF8LowerCase( Name );
        for I := 0 to FItems.Count - 1 do
          begin
          Nod     := TJsonNode( FItems[I] );
          NodName := UTF8LowerCase( Nod.FName );
          if ( Length( NodName ) = Length( Names ) ) and///
            ( CompareByte( NodName[1], Names[1], Length( NodName ) ) = 0 ) then
            Exit( Nod );
          end;
        end;
      end;
end;

function TJsonNode.Exists( const Path: string ): boolean;
begin
  Result := Find( Path ) <> nil;
end;

// Найдите узел, используя строку пути. Search for a node using a path string
(*Начинается с '/' - начать поиск с корня. Равен '/' - возвращает корень *)
function TJsonNode.Find( const Path: string ): TJsonNode;
var
  Node: TJsonNode;
  A, B: pchar;
  S:    string;
  CachedPath: string;
begin
  Result := nil;

  if Path = '' then  Exit( Child( '' ) );

  // Используем кэш если включен
  if FCacheUsePath and Assigned( FCachePath ) then
    begin
    CachedPath := IfThen( Path[1] = '/', Path, '/' + Path );
    Result     := TJsonNode( FCachePath.Find( CachedPath ) );
    if Assigned( Result ) then
      Exit;
    end;

  if Path[1] = '/' then
    Node := Root//Result := TJsonNode( FCachePath.Find( Path ) );
  //if Result <> nil then Exit( nil );
  else
    Node := Self;

  //// В Find проверяем кэш:
  //if Node = Root then
  //  begin
  //  Result := TJsonNode( FCachePath.Find( '/' + Path ) );
  //  if Result <> nil then  Exit( nil );
  //  CacheBool := True;
  //  end;

  A := PChar( Path );
  if A^ = '/' then
    begin
    Inc( A );
    if A^ = #0 then
      Exit( Node );
    end;
  if A^ = #0 then
    Exit( Node.Child( '' ) );
  B := A;

  while B^ > #0 do
    if B^ = '/' then
      begin
      SetString( S, A, B - A );
      Node := Node.Child( S );
      if Node = nil then
        Break;
      A := B + 1;
      B := A;
      end
    else
      begin
      Inc( B );
      if B^ = #0 then
        begin
        SetString( S, A, B - A );
        Node := Node.Child( S );
        end;
      end;
  Result := Node;

  // Сохраняем в кэш если нашли
  if FCacheUsePath and Assigned( FCachePath ) and Assigned( Result ) then
    if Path[1] = '/' then
      FCachePath.Add( Path, Result )
    else
      FCachePath.Add( '/' + Path, Result );
end;

{ Найдите значение узла, используя строку пути, если поиск =nil, то вернёт AValueDefault }
function TJsonNode.Find( const Path: string; const AValueDefault: variant ): variant;
var
  Node: TJsonNode;
begin
  Node := Find( Path );
  if Assigned( Node ) then
    Result := Node.Value
  else
    Result := AValueDefault;
end;

{ Найдите узел, используя строку пути, и верните значение true, если он существует.
      Search for a node using a path string and return true if exists }
function TJsonNode.Find( const Path: string; out Node: TJsonNode ): boolean;
begin
  Node   := Find( Path );
  Result := Node <> nil;
end;


// Принудительно создать ряд узлов (Объектов) и вернуть конечный узел.
{Начинается с '/' - начать поиск с корня. Равен '/' - возвращает корень
 Path='' - Добавить объект.
Force a series of nodes to exist and return the end node }
function TJsonNode.Force( const Path: string ): TJsonNode;
var
  Nod:  TJsonNode;
  A, B: pchar;
  aVar: variant;
  //CacheBool: boolean = False;

  procedure addPathName;//( endPath: Boolean);
  var
    S:    string;
    Nod1: TJsonNode;
  begin
    SetString( S, A, B - A );
    Nod1 := Nod.Child( S );
    //если есть дочерний, то заменяем на него, иначе остаётся прежний узел
    if Nod1 <> nil then
      begin
      Nod := Nod1;
      Exit;
      end;

    if Nod.nkStrukt then
      Nod := Nod.AddNode( nkObject, S, aVar )
    else
      Error( errNotCollection + ': "' + S + '"' );
  end;

begin
  Result := nil;
  A      := PChar( Path );
  // начать поиск с корня
  if Path[1] = '/' then
    begin
    if Path = '/' then
      Exit( Root )
    else
      begin
      //// Проверяем кэш:
      //  begin
      //  Result := TJsonNode( FCachePath.Find( Path ) );
      //  if Result <> nil then  Exit(Result);
      //  CacheBool := True;
      //  end;
      ;
      Nod := Root;
      Inc( A );
      end;
    end
  else
    begin
    //// Проверяем кэш:
    //if Self = Root then
    //  begin
    //  Result := TJsonNode( FCachePath.Find( '/' + Path ) );
    //  if Result <> nil then  Exit(Result);
    //  CacheBool := True;
    //  end;
    ;
    Nod := Self;
    end;

  B    := A;
  aVar := VarAsType( aVar, varEmpty );
  //если путь пустой - попытаемся добавить объект в текущий
  if Path = '' then
    addPathName;//( True );

  while B^ > #0 do
    if B^ = '/' then
      begin
      addPathName;//( False );

      A := B + 1;
      B := A;
      end
    else
      begin
      Inc( B );
      if B^ = #0 then
        addPathName;//(True );
      end;
  Result := Nod;

  ////добавляем в кэш
  //if CacheBool then
  //  if Path[1] = '/' then
  //    FCachePath.Add( Path, Result )
  //  else
  //    FCachePath.Add( '/' + Path, Result );
end;

// Принудительно создать ряд узлов (Объект), добавить переменную в последний узел
//и вернуть последний узел.
function TJsonNode.Force( const Path: string; aValue: variant ): TJsonNode;
begin
  Result       := Force( Path );
  Result.Value := aValue;
end;

// Принудительно создать ряд узлов (Объект), добавить Объект в последний узел
//и вернуть последний узел.
function TJsonNode.Force( const Path: string; aValue: TJsonNode ): TJsonNode;
begin
  Result := Force( Path );
  Result.AddJSON( aValue );
end;


 //-------------------------------------------------------------------------
 //Получиь самый верхний узел
function TJsonNode.GetRoot: TJsonNode;
begin
  Result := Self;
  while Result.FParent <> nil do
    Result := Result.FParent;
end;


//Возвращает первый узел на текущем уровне
function TJsonNode.GetFirstSibling: TJsonNode;
begin
  if Parent = nil then
    Result := nil
  else
    Result := TJsonNode( Parent.FItems[0] );
end;

//Возвращает последний узел на текущем уровне
function TJsonNode.GetLastSibling: TJsonNode;
begin
  if Parent = nil then
    Result := nil
  else
    Result := TJsonNode( Parent.FItems[Parent.FItems.Count - 1] );
end;


//Возвращается первый узел списка потомков или nil, если нет подузлов
function TJsonNode.GetFirstChild: TJsonNode;
begin
  if FItems <> nil then
    Result := TJsonNode( FItems[0] )
  else
    Result := nil;
end;

//Возвращает последний подузел или nil, если нет подузлов
function TJsonNode.GetLastChild: TJsonNode;
begin
  if FItems <> nil then
    Result := TJsonNode( FItems[FItems.Count - 1] )
  else
    Result := nil;
end;

//-------

//следующий узел относительно текущего, с вхождением
function TJsonNode.GetNext: TJsonNode;
var
  n:    integer;
  Node: TJsonNode;
begin
  Result := GetFirstChild;
  if Result = nil then
    begin
    Node := Self;
    while Node.Parent <> nil do
      begin
      n := Node.Parent.FItems.IndexOf( Node );
      if n < 0 then Break;
      if n = Node.Parent.Count - 1 then
        Node := Node.Parent
      else
        begin
        Result := TJsonNode( Node.Parent.FItems[n + 1] );
        Break;
        end;
      end;
    end;
end;

//предыдущий узел относительно текущего, с вхождением
function TJsonNode.GetPrev: TJsonNode;
var
  ANode: TJsonNode;
begin
  Result := GetPrevSibling;
  if Result <> nil then
    begin
    ANode := Result;
    repeat
      Result := ANode;
      ANode  := Result.GetLastChild;
    until ANode = nil;
    end
  else
    Result := Parent;
end;

//следующий узел относительно узла-потомка Value
function TJsonNode.GetNextChild( AValue: TJsonNode ): TJsonNode;
begin
  if AValue <> nil then
    Result := AValue.GetNextSibling
  else
    Result := nil;
end;

//предыдущий узел относительно узла-потомка Value
function TJsonNode.GetPrevChild( AValue: TJsonNode ): TJsonNode;
begin
  if AValue <> nil then
    Result := AValue.GetPrevSibling
  else
    Result := nil;
end;

//Возвращает следующий узел на текущем уровене
function TJsonNode.GetNextSibling: TJsonNode;
var
  n: integer;
begin
  if Parent = nil then exit( nil );
  n := Parent.FItems.IndexOf( self );
  //если это последний узел или дочерний не найден в родительском
  if ( n = Parent.Count - 1 ) or ( n < 0 ) then
    Result := nil
  else
    Result := TJsonNode( Parent.FItems[n + 1] );
end;


//предыдущий узел на текущем уровене
function TJsonNode.GetPrevSibling: TJsonNode;
var
  n: integer;
begin
  if Parent = nil then exit( nil );
  n := Parent.FItems.IndexOf( self );
  if n <= 0 then
    Result := nil
  else
    Result := TJsonNode( Parent.FItems[n - 1] );
end;

//true, если aValue – совпадает с каким-то родительским узлом
function TJsonNode.HasAsParent( AValue: TJsonNode ): boolean;
var
  Node: TJsonNode;
begin
  if AValue = nil then
    Result := True
  else
    begin
    Result := False;
    Node   := Self;
    while Node.Parent <> nil do
      (*можно перемещать самого в себя*)
      if Node.Parent = AValue then
        begin
        Result := True;
        Break;
        end
      else
        Node := Node.Parent;
    end;
end;


//-------------------------------------------------------------------------

// Json в виде строки.
function TJsonNode.JsonToText( JSONFormats: TJSONFormat = jfCompact ): string;
var
  OldFormatSettings: char;
  Buffer: TJsonStringBuilder;
begin
  Result     := ' {}';
  //записать глобальную переменную, для рекурсии
  JSONFormat := JSONFormats;
  OldFormatSettings := DefaultFormatSettings.DecimalSeparator;
  DefaultFormatSettings.DecimalSeparator := '.';
  Buffer     := TJsonStringBuilder.Create;
    try
    case JSONFormats of
      jfExpand: FormatExpand( Self, 1, Buffer );
      jfCompact: FormatCompact( Self, 0, Buffer );
      jfCompressed: FormatCompressed( Self, Buffer );
      end;

    //если начинается не с объекта или массива
    if not ( ( FParent = nil ) and nkStrukt ) then
      case JSONFormats of
        jfExpand, jfCompact: Result := ' {' + LineEnding + Buffer.ToString + LineEnding + ' }';
        jfCompressed:
          begin
          Result := ' {' + Buffer.ToString + ' }';
          Result := StringReplace( Result, LineEnding, '', [rfReplaceAll] );
          end
        end
    else
      Result := Buffer.ToString;

    finally
    Buffer.Free;
    DefaultFormatSettings.DecimalSeparator := OldFormatSettings;
    end;
end;

// ------------  методы работы с кэшем -------------------------------

// Обновление кэша при изменениях (privat)
procedure TJsonNode.CacheUpdatePath( );
begin
  if FCacheUsePath and Assigned( FCachePath ) then
    FCachePath.Clear;
end;

// Очистка кэша при необходимости
procedure TJsonNode.CacheClearPath;
begin
  if Assigned( FCachePath ) then
    FCachePath.Clear;
end;

procedure TJsonNode.CacheEnablePath( Enabled: boolean );
begin
  FCacheUsePath := Enabled;
  if Enabled and not Assigned( FCachePath ) then
    FCachePath := TFPHashList.Create
  else if not Enabled and Assigned( FCachePath ) then
      FreeAndNil( FCachePath );
end;

// ---------------------- Преобразование -------------------

procedure FormatExpand( Obj: TJsonNode; probel: integer; var Result: TJsonStringBuilder );
var
  i:     integer;
  Child: TJsonNode;
  CurrentLine: string = '';
  IndentStr: string = '';
  CurrentEnd: string;
begin
  if Obj = nil then Exit;

  // Подготовка отступов
  IndentStr := StringOfChar( ' ', probel );

  // не элементы массива и не комментарий
  if ( ( Obj.FParent <> nil ) and ( Obj.FParent.FKind <> nkArray ) ) then ///
    if ( Obj.FKind <> nkComment ) then
      begin
      CurrentLine := JsonStringEncode( Obj.FName ) + ': ';
      probel      += UTF8Length( CurrentLine );
      end;
  CurrentEnd  := IndentStr + StringOfChar( ' ', UTF8Length( CurrentLine ) );
  CurrentLine := IndentStr + CurrentLine;

  case Obj.FKind of
    nkObject, nkArray:
      begin
      // Открывающий символ
      if Obj.FKind = nkObject then
        Result.AddLine( CurrentLine + '{' )
      else
        Result.AddLine( CurrentLine + '[' );

      // Обработка дочерних элементов
      for i := 0 to Obj.Count - 1 do
        begin
        Child := TJsonNode( Obj.FItems[i] );

        // Обработать вложенные объекты
        FormatExpand( Child, probel, Result );

        // Добавляем запятую, если это не последний элемент
        if i < Obj.Count - 1 then
          Result.AddLine( ',' )
        else
          Result.AddLine( '' );
        end;

      // Закрывающий символ
      if Obj.FKind = nkObject then
        Result.Add( CurrentEnd + '}' )
      else
        Result.Add( CurrentEnd + ']' );
      end;


      //Простые значения
    else
      if obj.FKind = nkComment then
        Result.Add( CurrentLine + '//' + JsonStringEncode( VarToStrDef( obj.FValue, '' ) ) )
      else
        if VarIsStr( obj.FValue ) then
          Result.Add( CurrentLine + JsonStringEncode( VarToStrDef( obj.FValue, '' ) ) )
        else
          if VarIsBool( obj.FValue ) then
            if obj.FValue = True then
              Result.Add( CurrentLine + 'true' )
            else
              Result.Add( CurrentLine + 'false' )
          else if VarIsEmpty( obj.FValue ) or VarIsNull( obj.FValue ) or VarIsClear( obj.FValue ) then
              Result.Add( CurrentLine + 'null' )
            //else if VarIsNumeric( obj.FValue ) then
            //    try
            //    Result.Add(Bufer + FormatFloat( '0.' + StringOfChar( '#', 15 ), obj.FValue, DefFormatSettings ));
            //    except
            //    Result.Add(Bufer + 'nan');
            //    end
            else
              Result.Add( CurrentLine + VarToStrDef( obj.FValue, 'null' ) );
    end;
end;

procedure FormatCompact( Obj: TJsonNode; probel: integer; var Result: TJsonStringBuilder );
var
  i:     integer;
  Child: TJsonNode;
  CurrentLine: string = '';
  IndentStr: string = '';
  CurrentEnd: string;
  b:     boolean;
begin
  if Obj = nil then Exit;

  // Подготовка отступов
  IndentStr := StringOfChar( ' ', probel );

  // не элементы массива
  if ( Obj.FParent <> nil ) and ( Obj.FParent.FKind <> nkArray ) then
    begin
    if Obj.FKind <> nkComment then
      begin
      CurrentLine := JsonStringEncode( Obj.FName ) + ': ';
      probel      += UTF8Length( CurrentLine );
      end;
    CurrentLine := IndentStr + CurrentLine;
    CurrentEnd  := IndentStr + StringOfChar( ' ', UTF8Length( CurrentLine ) );
    end
  else
    if Obj.FKind = nkObject then
      CurrentEnd := StringOfChar( ' ', probel );

  case Obj.Kind of
    nkObject, nkArray:
      begin
      // Открывающий символ
      if Obj.FKind = nkObject then
        Result.AddLine( CurrentLine + '{' )
      else
        Result.Add( CurrentLine + '[' );

      // Обработка дочерних элементов
      b := True;
      for i := 0 to Obj.Count - 1 do
        begin
        Child := TJsonNode( Obj.FItems[i] );

        if b and ( Obj.FKind = nkArray ) and ( Child <> nil ) and ( Child.FKind = nkObject ) then
          begin
          probel += 3;
          CurrentLine := LineEnding + StringOfChar( ' ', probel );
          b := False;
          end;

        // Обработать вложенные объекты
        FormatCompact( Child, probel, Result );

        // Добавляем запятую, если это не последний элемент
        if i < Obj.Count - 1 then
          //в массиве не переносим элементы
          if Obj.FKind = nkArray then
            //объекты переносим
            if ( Child <> nil ) and ( Child.FKind = nkObject ) then
              Result.Add( ', ' + CurrentLine )
            else
              Result.Add( ', ' )//внутри массива, перед элементом
          else
            // м/ж элементами в объекте, кроме последнего
            Result.AddLine( ',' )
        else
          if Obj.FKind <> nkArray then
            //после массива или объекта в массиве
            Result.AddLine( '' );
        end;

      // Закрывающий символ
      if Obj.FKind = nkObject then
        Result.Add( CurrentEnd + '}' )
      else
        Result.Add( ']' );
      end;


      //Простые значения
    else
      if obj.FKind = nkComment then
        Result.Add( CurrentLine + '//' + JsonStringEncode( VarToStrDef( obj.FValue, '' ) ) )
      else
        if VarIsStr( obj.FValue ) then
          Result.Add( CurrentLine + JsonStringEncode( VarToStrDef( obj.FValue, '' ) ) )
        else
          if VarIsBool( obj.FValue ) then
            if obj.FValue = True then
              Result.Add( CurrentLine + 'true' )
            else
              Result.Add( CurrentLine + 'false' )
          else if VarIsEmpty( obj.FValue ) or VarIsNull( obj.FValue ) or VarIsClear( obj.FValue ) then
              Result.Add( CurrentLine + 'null' )
            //else if VarIsNumeric( obj.FValue ) then
            //    try
            //    Result.Add(Bufer + FormatFloat( '0.' + StringOfChar( '#', 15 ), obj.FValue, DefFormatSettings ));
            //    except
            //    Result.Add(Bufer + 'nan');
            //    end
            else
              Result.Add( CurrentLine + VarToStrDef( obj.FValue, 'null' ) );
    end;
end;

procedure FormatCompressed( Obj: TJsonNode; var Result: TJsonStringBuilder );
var
  i:     integer;
  Child: TJsonNode;
  CurrentLine: string = '';
begin
  if Obj = nil then Exit;
  // не элементы массива
  if ( ( Obj.FParent <> nil ) and ( Obj.FParent.FKind <> nkArray ) ) then ///
    if ( Obj.FKind <> nkComment ) then
      CurrentLine := JsonStringEncode( Obj.FName ) + ':';

  case Obj.FKind of
    nkObject, nkArray:
      begin
      // Открывающий символ
      if Obj.FKind = nkObject then
        Result.Add( CurrentLine + '{' )
      else
        Result.Add( CurrentLine + '[' );

      // Обработка дочерних элементов
      for i := 0 to Obj.Count - 1 do
        begin
        Child := TJsonNode( Obj.FItems[i] );

        // Обработать вложенные объекты
        FormatCompressed( Child, Result );

        // Добавляем запятую, если это не последний элемент
        if i < Obj.Count - 1 then
          Result.Add( ',' );
        end;

      // Закрывающий символ
      if Obj.FKind = nkObject then
        Result.Add( '}' )
      else
        Result.Add( ']' );
      end;


      //Простые значения
    else
      if obj.FKind = nkComment then
        Result.Add( CurrentLine + '//' + JsonStringEncode( VarToStrDef( obj.FValue, '' ) ) )
      else
        if VarIsStr( obj.FValue ) then
          Result.Add( CurrentLine + JsonStringEncode( VarToStrDef( obj.FValue, '' ) ) )
        else
          if VarIsBool( obj.FValue ) then
            if obj.FValue = True then
              Result.Add( CurrentLine + 'true' )
            else
              Result.Add( CurrentLine + 'false' )
          else if VarIsEmpty( obj.FValue ) or VarIsNull( obj.FValue ) or VarIsClear( obj.FValue ) then
              Result.Add( CurrentLine + 'null' )
            //else if VarIsNumeric( obj.FValue ) then
            //    try
            //    Result.Add(Bufer + FormatFloat( '0.' + StringOfChar( '#', 15 ), obj.FValue, DefFormatSettings ));
            //    except
            //    Result.Add(Bufer + 'nan');
            //    end
            else
              Result.Add( CurrentLine + VarToStrDef( obj.FValue, 'null' ) );
    end;
end;

//----------------------------------------


{ Json helper routines }

function JsonValidate( const JSONString: string ): boolean;
var
  Nod: TJsonNode;
begin
  Result := False;
  Nod    := TJsonNode.Create;
    try
    Result := Nod.Parse( JSONString );
    finally
    Nod.Free;
    end;
end;

function JsonNumberValidate( const JSONnumer: string ): boolean;
var
  pJS:   pchar;
  Token: TJsonToken;
begin
  Result := False;
  pJS    := PChar( JSONnumer );
  if NextToken( pJS, Token ) then
    begin
    if ( ( Token.Kind = tkObjectOpen ) or ( Token.Kind = tkArrayOpen ) ) then
      if not NextToken( pJS, Token ) then
        exit( False );

    Result := ( ( Token.Kind = tkNumber ) or ( Token.Kind = tkFloat ) or
      ( Token.Kind = tkNumber_ ) or ( Token.Kind = tkFloat_ ) );
    end;
end;

function JsonStringValidate( const JSONString: string ): boolean;
var
  pJS:   pchar;
  Token: TJsonToken;
begin
  Result := False;
  pJS    := PChar( JSONString );
  if NextToken( pJS, Token ) then
    begin
    if ( ( Token.Kind = tkObjectOpen ) or ( Token.Kind = tkArrayOpen ) ) then
      if not NextToken( pJS, Token ) then
        exit( False );
    Result := ( Token.Kind = tkString );// and ( Token.Value = JSONString );
    end;
end;

{ Convert a json string to a pascal string }
function UnicodeToString( C: longword ): string; inline;
begin
  if C = 0 then
    Result := #0
  else if C < $80 then
      Result := Chr( C )
    else if C < $800 then
        Result := Chr( ( C shr $6 ) + $C0 ) + Chr( ( C and $3F ) + $80 )
      else if C < $10000 then
          Result := Chr( ( C shr $C ) + $E0 ) + Chr( ( ( C shr $6 ) and $3F ) + $80 ) +
            Chr( ( C and $3F ) + $80 )
        else if C < $200000 then
            Result := Chr( ( C shr $12 ) + $F0 ) + Chr( ( ( C shr $C ) and $3F ) + $80 ) +
              Chr( ( ( C shr $6 ) and $3F ) + $80 ) + Chr( ( C and $3F ) + $80 )
          else
            Result := '';
end;

//Добавляет Кавычки. JsonStringEncode преобразует строку pascal в строку json.
{Для работы с датами в JSON необходимо переводить их в строковый формат в соответствии со стандартом ISO 8601:
2023-08-24T20:45:03.408Z }
function JsonStringEncode( const S: string ): string;
var
  I, j:  integer;
  C:     char;
  UChar: cardinal;
begin
  if S = '' then
    Exit( '""' );

  Result := '"';
  I      := 1;
  while I <= Length( S ) do
    begin
    j := 1;
    C := S[I];
    case C of
      #8: Result       := Result + '\b';
      #9: Result       := Result + '\t';
      #10: Result      := Result + '\n';
      #12: Result      := Result + '\f';
      #13: Result      := Result + '\r';
      '"', '\': Result := Result + '\' + C;
      else
        if C < ' ' then
          Result := Result + '\u00' + HexDigits[Ord( C ) shr 4] + HexDigits[Ord( C ) and $F]
        else
          begin
          // Обработка UTF-8 символов
          //UChar := UTF8CharacterToUnicode( @S[I], Length( S ) - I + 1 );
          UChar := UTF8CodepointToUnicode( @S[I], j );
          if UChar < $80 then
            Result += C
          else
            if UChar < $800 then //10FFFF
              Result += Chr( ( UChar shr $6 ) + $C0 ) + Chr( ( UChar and $3F ) + $80 )
            //Result+=UnicodeToUTF8(UChar)
            //Result += Copy( s, i, j )
            else
              begin
              Result += '\u' + HexDigits[( UChar shr 8 ) and $F] + ///
                HexDigits[( UChar shr 4 ) and $F] + HexDigits[UChar and $F];
              Inc( I ); // Пропускаем дополнительный байт для surrogate pair
              end;


          //if UChar > $7FFF then //$FFFF then
          //  begin
          //  HexStr := '\u' + HexDigits[( UChar shr 12 ) and $F] + HexDigits[( UChar shr 8 ) and $F] +
          //    HexDigits[( UChar shr 4 ) and $F] + HexDigits[UChar and $F];
          //  Result := Result + HexStr;
          //  Inc( I ); // Пропускаем дополнительный байт для surrogate pair
          //  end;
          end;
      end;
    Inc( I, j );
    end;
  Result := Result + '"';
end;

function UnicodeToSize( C: longword ): integer; inline;
begin
  if C = 0 then
    Result := 1
  else if C < $80 then
      Result := 1
    else if C < $800 then
        Result := 2
      else if C < $10000 then
          Result := 3
        else if C < $200000 then
            Result := 4
          else
            Result := 0;
end;

function HexToByte( C: char ): byte; inline;
const
  Zero = Ord( '0' );
  UpA  = Ord( 'A' );
  LoA  = Ord( 'a' );
begin
  if C < 'A' then
    Result := Ord( C ) - Zero
  else if C < 'a' then
      Result := Ord( C ) - UpA + 10
    else
      Result := Ord( C ) - LoA + 10;
end;

function HexToInt( A, B, C, D: char ): integer; inline;
begin
  Result := HexToByte( A ) shl 12 or HexToByte( B ) shl 8 or HexToByte( C ) shl 4 or HexToByte( D );
end;

// преобразует строку json в строку pascal.
function JsonStringDecode( const S: string ): string;
var
  I:      integer = 1;
  j, Len: integer;
  C:      char;
  HexVal: integer;
  UChar:  cardinal;
begin
  if S = '' then  Exit( '' );

  Result := '';
  Len    := Length( S );
  while I <= Len do
    begin
    C := S[I];
    if C = '\' then
      begin
      Inc( I );
      if I > Len then Break;

      C := S[I];
      case C of
        'b': Result := Result + #8;
        't': Result := Result + #9;
        'n': Result := Result + #10;
        'f': Result := Result + #12;
        'r': Result := Result + #13;
        'u':
          begin
          HexVal := 0;
          for J := 1 to 4 do
            begin
            Inc( I );
            if I > Len then Break;

            C := S[I];
            case C of
              '0'..'9': HexVal := ( HexVal shl 4 ) + ( Ord( C ) - Ord( '0' ) );
              'A'..'F': HexVal := ( HexVal shl 4 ) + ( Ord( C ) - Ord( 'A' ) + 10 );
              'a'..'f': HexVal := ( HexVal shl 4 ) + ( Ord( C ) - Ord( 'a' ) + 10 );
              end;
            end;
          UChar  := HexVal;
          Result := Result + UnicodeToUTF8( UChar );
          end;
        else
          Result := Result + C;
        end;
      end
    else
      Result := Result + C;
    Inc( I );
    end;
end;

function JsonToXml( const S: string ): string;
const
  Space = '    ';

  function Kinds( N: TJsonNode ): string;
  begin
    case N.FKind of
      nkObject: Result  := ' kind="object"';
      nkArray: Result   := ' kind="array"';
      nkComment: Result := ' kind="comment"';
      else
        if VarIsStr( N.FValue ) then
          Result := ' kind="string"'
        else if VarIsNumeric( N.FValue ) then
            Result := ' kind="number"'
          else if VarIsBool( N.FValue ) then
              Result := ' kind="bool"'
            else
              Result := ' kind="null"';
      end;
  end;

  function Escape( Nod: TJsonNode ): string;
  begin
    Result := Nod.JsonToText( jfExpand );
    if VarIsStr( Nod.FValue ) then
      begin
      Result := JsonStringDecode( Result );
      Result := StringReplace( Result, '<', '&lt;', [rfReplaceAll] );
      Result := StringReplace( Result, '>', '&gt;', [rfReplaceAll] );
      end;
  end;

  //Генерировать случайное значение
  function strGen: string;
  var
    i: integer;
  begin
    Result := '';
    Randomize;
    for i := 1 to 3 do
      Result += HexDigits[RandomRange( 1, 16 )];
  end;

  function EnumNodes( P: TJsonNode; const Indent: string ): string;
  var
    Node: TJsonNode;
    S:    string;
  begin
    Result := '';
    if P.Kind = nkArray then
      S := 'item'
    else
      S := '';
    for Node in P do
      begin
      Result := Result + Indent + '<' + S + Node.Name + Kinds( Node );
      if Node.nkStrukt then
        if Node.Count > 0 then
          Result := Result + '>'#10 + EnumNodes( Node, Indent + Space ) + Indent +
            '</' + S + Node.Name + '>'#10
        else
          Result := Result + '/>'#10
      else
        if VarIsEmpty( Node.FValue ) or VarIsNull( Node.FValue ) or VarIsClear( Node.FValue ) then
          Result := Result + '/>'#10
        else
          Result := Result + '>' + Escape( Node ) + '</' + S + IfThen(
            Node.Kind = nkComment, strGen, Node.Name ) + '>'#10;
      end;
  end;

var
  Nod: TJsonNode;
begin
  Result := '';
  Nod    := TJsonNode.Create;
    try
    if Nod.Parse( S ) then
      begin
      Result :=
        '<?xml version="1.0" encoding="UTF-8"?>'#10 + '<root' + Kinds( Nod );
      if Nod.Count > 0 then
        Result := Result + '>'#10 + EnumNodes( Nod, Space ) + '</root>'
      else
        Result := Result + '/>';
      end;
    finally
    Nod.Free;
    end;
end;

//для обратного поиска и сортировки, которые удобны при исследовании неизвестных структур JSON.
function TJsonNode.JSONKindToString( Node: TJsonNode ): string;
begin
  Result := GetEnumName( TypeInfo( TJsonNodeKind ), Ord( Node.&Kind ) );
end;

function TJsonNode.JSONPathToString( Node: TJsonNode ): string;
var
  Path: string;
begin
  if Node.Parent <> nil then
    Path := JSONPathToString( Node.Parent ) + '/' + Node.Name
  else
    Path := '/' + Node.Name;

  Result := Path;
end;



//==================================================================


{ TJsonStringBuilder }

constructor TJsonStringBuilder.Create( InitialCapacity: integer );
begin
  inherited Create;
  FCapacity := InitialCapacity;
  SetLength( FBuffer, FCapacity );
  FCount := 0;
end;

destructor TJsonStringBuilder.Destroy;
begin
  SetLength( FBuffer, 0 );
  inherited Destroy;
end;

procedure TJsonStringBuilder.Grow;
begin
  FCapacity := ( FCapacity * 3 ) div 2;
  SetLength( FBuffer, FCapacity );
end;

procedure TJsonStringBuilder.Add( const S: string );
begin
  if S = '' then Exit;
  if FCount >= FCapacity then
    Grow;

  FBuffer[FCount] := S;
  Inc( FCount );
end;

procedure TJsonStringBuilder.AddLine( const S: string );
begin
  Add( S + LineEnding );
end;

procedure TJsonStringBuilder.Clear;
begin
  FCount := 0;
end;

function TJsonStringBuilder.ToString: string;
var
  TotalLength: integer;
  i: integer;
  P: pchar;
begin
  // Вычисляем общую длину
  TotalLength := 0;
  for i := 0 to FCount - 1 do
    Inc( TotalLength, Length( FBuffer[i] ) );

  // Собираем результат
  SetLength( Result, TotalLength );
  P := PChar( Result );

  for i := 0 to FCount - 1 do
    if FBuffer[i] <> '' then
      begin
      Move( PChar( FBuffer[i] )^, P^, Length( FBuffer[i] ) );
      Inc( P, Length( FBuffer[i] ) );
      end;
end;



initialization
  {$IFDEF DCC}
      DefFormatSettings := TFormatSettings.Create;
  {$ENDIF}
  DefFormatSettings := DefaultFormatSettings;
  DefFormatSettings.DecimalSeparator := '.';

end.
