(*Тесты покрывают:
Парсинг JSON
Создание JSON-структур
Манипуляции с данными
Поиск по пути
Удаление
Работу с файлами
Экранирование строк
Клонирование и слияние
Валидацию JSON
Производительность *)
unit Test_Primitiv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, JsonEasy;

type

  TTestPrimitiv = class( TTestCase )
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreateJsonObjectRoot;

    procedure TestSet;
    procedure TestSetForce;

    procedure TestGetValues;
    procedure TestAddRemoveProperties;

    procedure FindPath;

    //Объект начинается с имени
    procedure ParseObj_Nachinaetsya_s_imeni;
    //Объект начинается со скобки
    procedure ParseObj_Nachinaetsya_so_skobki;
    procedure ParseObj_bez_kavyhchek;
    procedure ParseObj_2string;
    procedure ParseObj_Chisla_s_podchyorkivaniem;
    procedure ParseObj_Hex;
    {В старый объект добавить данные из нового объекта}
    procedure ParseObj_v_OldObj_add_znacheniya_obj2;
    (*В объекте находится второй объект *)
    procedure ParseObj_obj_v_obj;

    //Присвоение через Value
    procedure TestParse_Value;

    procedure Object_Create;

    procedure Kavyhchki_Dvojnyhe;
    procedure Kavyhchki_Odinarnyhe;

    procedure Merge_bez_zamenyh;
    procedure Merge_bez_zamenyh_2;
    procedure Merge_s_zamenoj;
    procedure Merge_s_zamenoj_2;
    procedure MergeArray_bez_zamenyh;
    procedure MergeArray_s_zamenoj;
    //procedure TestCloneJson;

    procedure TestSaveLoadFromFile;

    procedure TestJsonToString;
    //procedure TestEscapeUnescape;
    procedure TestValidateJson;
    procedure TestPerformance;
  end;

var
  Json, JE: TJsonNode;
  saveName: string;


implementation

procedure TTestPrimitiv.SetUp;
begin
  Json      := TJsonNode.Create;

  JE        := TJsonNode.Create;
  saveName  := 'TestPrimitiv.json';
end;

procedure TTestPrimitiv.TearDown;
begin
  Json.Root.Free;
  JE.Root.Free;
end;

//--------------------------------------------------------------------

procedure TTestPrimitiv.TestCreateJsonObjectRoot;
begin
  AssertEquals( 'Корень должен быть объектом. Root should be an object',
    Ord( nkObject ), Ord( Json.Kind ) );
  AssertEquals( 'Корень должен быть пустым. Root should be empty', 0, Json.Count );
end;

//--------------------------------------------------------------------

procedure TTestPrimitiv.TestSet;
begin
  Json.AddElm( 'name', 'Alice' );
  Json.AddElm( 'age', 32 );

  Json.AddObj( 'объект' ).AddElm( 'active', True );
  Json.AddObj( 'объект' ).AddElm( 'name', 'Olya' );

  Json.AddArrElm( 'balance', 987.65 );
  Json.AddArrElm( 'balance', null ).AddArrElm( 'total' );
  Json.AddArr( 'balance' ).AddElm( '-', 445 );

  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );


  AssertEquals( 'Имя "Alice"', 'Alice', Json.Find( 'name', '' ) );
  AssertEquals( 'Integer value set', 32, Json.Find( 'age', 0 ) );

  AssertEquals( 'В объекте свойство', True, Json.Find( 'объект/active', False ) );
  AssertEquals( 'В объекте свойство', 'Olya', Json.Find( 'объект/name', '-' ) );

  //AssertEquals( 'Массив', 987.65, Json.Find( 'balance\0', 0.0 ), 0.001 );
  //AssertEquals( 'Массив', Null, Json.Find( 'balance', '-'));
  //AssertEquals( 'Массив', 'total', Json.Find( 'balance', 'total'));
  //AssertEquals( 'Массив', 445, Json.Find( 'balance', 0 ));
end;


procedure TTestPrimitiv.TestSetForce;
begin
  Json.Force( 'name' ).Value  := 'Alice';
  Json.Force( 'adres' ).Value := Null;
  Json.Force( 'obj0/name', 'Alice' );
  Json.Force( 'obj0/avto', True );
  Json.Force( 'obj1' ).AddElm( 'age', 25 );
  Json.Force( 'obj2' ).AddElm( 'active', True );
  Json.Force( 'obj2' ).AddElm( 'balance', 987.65 );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'String value set', 'Alice', Json.Find( 'obj0/name', '' ) );
  AssertEquals( 'Integer value set', 25, Json.Find( 'obj1/age', 0 ) );
  AssertEquals( 'Boolean value set', True, Json.Find( 'obj2/active', False ) );
  AssertEquals( 'Float value set', 987.65, Json.Find( 'obj2/balance', 0.0 ), 0.001 );
end;


//--------------------------------------------------------------

procedure TTestPrimitiv.TestGetValues;
begin
  Json.Force( 'obj1/obj2' ).AddElm( 'name', 'Alice' );
  Json.Force( 'obj1/age', 25 );
  Json.Force( 'obj1/obj2/active', True );
  Json.Force( '/obj1' ).AddElm( 'balance', 987.65 );
  Json.Force( '/obj1' ).AddElm( 'balance2', 5 / 2 );
  Json.Force( 'obj1/obj2/obj3' ).AddElm( 'name', 'Ivan' );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'String value set', 'Alice', Json.Find( 'obj1/obj2/name', '' ) );
  AssertEquals( 'Integer value set', 25, Json.Find( 'obj1/age', 0 ) );
  AssertEquals( 'Boolean value set', True, Json.Find( 'obj1/obj2/active', False ) );
  AssertEquals( 'Float value set', 987.65, Json.Find( 'obj1/balance', 0.0 ), 0.001 );
  AssertEquals( 'Float value set', 2.5, Json.Find( 'obj1/balance2', 0.0 ), 0.001 );
end;

procedure TTestPrimitiv.TestAddRemoveProperties;
begin
  // Добавление свойств
  Json.AddElm( 'name', 'John' );
  Json.AddElm( 'age', 30 );

  AssertEquals( 'Должен иметь 2 свойства. Should have 2 properties', 2, Json.Count );
  AssertTrue( 'Должно содержать свойство "name". Should contain "name" property',
    Json.Exists( 'name' ) );
  AssertTrue( 'Должно содержать свойство "age". Should contain "age" property',
    Json.Exists( 'age' ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  // Удаление свойства
  Json.Delete( 'age' );
  AssertEquals( 'Должно быть 1 свойство после удаления. Should have 1 property after removal',
    1, Json.Count );
  AssertFalse( 'Не должно содержать "возраст" после удаления. Should not contain "age" after removal',
    Json.Exists( 'age' ) );
  AssertTrue( 'Должно остаться свойство "name". ', Json.Exists( 'name' ) );

  Json.Force( 'obj1/obj2' ).AddElm( 'name', 'Ivan' );
  Json.Force( 'obj1/obj2' ).AddElm( 'active', True );
  AssertTrue( 'Save to file', Json.SaveToFile( 'TestGetR1.json', jfCompact ) );

  AssertEquals( 'Должен иметь 2 свойства. Should have 2 properties', 2,
    Json.Find( 'obj1/obj2' ).Count );
  Json.Find( 'obj1/obj2/name' ).Delete;
  AssertEquals( 'Должно остаться 1 свойство.', 1,
    Json.Find( 'obj1/obj2' ).Count );

  AssertEquals( 'Должен иметь 1 свойство. Should have 2 properties', 1,
    Json.Find( 'obj1' ).Count );
  Json.Find( 'obj1/obj2' ).Delete;
  AssertEquals( 'Должен иметь 0 свойств. Should have 2 properties', 0,
    Json.Find( 'obj1' ).Count );

  AssertTrue( 'Save to file', Json.SaveToFile( 'TestGetR2.json', jfCompact ) );
end;

//--------------------------------------------------------------------

procedure TTestPrimitiv.FindPath;
var
  node: TJsonNode;
begin
  Json.Force( 'person/name', 'John' );
  Json.Force( 'person/age', 30 );
  Json.Force( 'obj1' ).AddArr( 'cars' ).AddArrElm( 'Ford' ).AddArrElm( 'BMW' ).AddArrElm( 'Fiat' );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  // Поиск по пути
  node := Json.Find( 'person/name' );
  AssertNotNull( 'Следует найти узел по пути. Should find node by path', node );
  AssertEquals( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    'John', node.Value );

  node := Json.Find( 'obj1/cars/0' );
  AssertNotNull( 'Следует найти элемент массива по пути. Should find array element by path', node );
  AssertEquals( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    'Ford', node.Value );
  node := Json.Find( 'obj1/cars/2' );
  AssertNotNull( 'Следует найти элемент массива по пути. Should find array element by path', node );
  AssertEquals( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    'Fiat', node.Value );

  // Несуществующий путь
  node := Json.Find( 'person/address/city' );
  AssertNull( 'Должен возвращать nil для несуществующего пути. Should return nil for non-existent path', node );
end;

//--------------------------------------------------------------------

procedure TTestPrimitiv.ParseObj_Nachinaetsya_s_imeni;
var
  s: string;
begin
  s := '"Person" :    {"name":"John","age":30,"cars":True}';

  //Json.Force( 'obj1/age', 25 );

  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован. '
    + s + ' Valid JSON should parse successfully', Json.Parse( s ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertTrue( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    Json.Find( 'person/cars' ).Value );
end;

procedure TTestPrimitiv.ParseObj_Nachinaetsya_so_skobki;
var
  s: string;
begin
  s := '{"name":"John","age":30,"cars":True}';

  //Json.Force( 'obj1/age', 25 );

  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован. '
    + s + ' Valid JSON should parse successfully', Json.Parse( s ) );
  AssertTrue( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    Json.Find( 'cars' ).Value );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );
end;

procedure TTestPrimitiv.ParseObj_bez_kavyhchek;
var
  s: string;
begin
  s := 'Person :    {name:"John",age:30,cars:True}';

  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован. '
    + s + ' Valid JSON should parse successfully', Json.Parse( s ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertTrue( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    Json.Find( 'person/cars' ).Value );
end;

procedure TTestPrimitiv.ParseObj_2string;
var
  s: string;
begin
  s := 'Person :    {name:"John' + #10 + 'Stiv",age:30,cars:True}';

  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован. '
    + s + ' Valid JSON should parse successfully', Json.Parse( s ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertTrue( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    Json.Find( 'person/cars' ).Value );
  AssertEquals( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    'John' + #10 + 'Stiv', Json.Find( 'person/name' ).Value );
end;

procedure TTestPrimitiv.ParseObj_Chisla_s_podchyorkivaniem;
var
  s: string;
begin
  s := '"a0":500, "a1":1_000, "a2":3_0_0, "a3": 3.0_01';

  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован. '
    + s + ' Valid JSON should parse successfully', Json.Parse( s ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    1000, Json.Find( 'a1' ).Value );
  AssertEquals( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    300, Json.Find( 'a2' ).Value );
  AssertEquals( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    3.001, Json.Find( 'a3' ).Value, 0.001 );
end;

procedure TTestPrimitiv.ParseObj_Hex;
var
  s: string;
begin
  s := '"a":0, "a0":0x5, "a1":0xa, "a2":0xA, "a3": 0x054,' +   ///
    '"a4":0x0A5, "a5":+0xa7, "a6":-0xA5, "a7": 0x0a50,' +      ///
    '"a8":0x, "a9":+0x.a7, "a10":5, "a11": .04, a12: 26%, a13: -5_0.6E-2';

  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован. '
    + s + ' Valid JSON should parse successfully', Json.Parse( s ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'Должно быть число', 0, Json.Find( 'a' ).Value );
  AssertEquals( 'Должно быть число', $5, Json.Find( 'a0' ).Value );
  AssertEquals( 'Должно быть число', $a, Json.Find( 'a1' ).Value );
  AssertEquals( 'Должно быть число', $a, Json.Find( 'a2' ).Value );
  AssertEquals( 'Должно быть число', $054, Json.Find( 'a3' ).Value );
  AssertEquals( 'Должно быть число', $0A5, Json.Find( 'a4' ).Value );
  AssertEquals( 'Должно быть число', $a7, Json.Find( 'a5' ).Value );
  AssertEquals( 'Должно быть число', -$a5, Json.Find( 'a6' ).Value );
  AssertEquals( 'Должно быть число', $0a50, Json.Find( 'a7' ).Value );
  AssertEquals( 'Должно быть число', '0x', Json.Find( 'a8' ).Value );
  AssertEquals( 'Должно быть число', '+0x.a7', Json.Find( 'a9' ).Value );
  AssertEquals( 'Должно быть число', 5, Json.Find( 'a10' ).Value );
  AssertEquals( 'Должно быть число', 0.04, Json.Find( 'a11' ).Value );
  AssertEquals( 'Должно быть число', '26%', Json.Find( 'a12' ).Value );
  AssertEquals( 'Должно быть число', -0.506, Json.Find( 'a13' ).Value );
end;

{В старый объект добавить данные из нового объекта}
procedure TTestPrimitiv.ParseObj_v_OldObj_add_znacheniya_obj2;
var
  s: string;
  b: boolean;
begin
  Json.AddElm( 'obj', '"Старый объект"' );
  s := '{"name":"John","age":30,"cars":True}, parametr: "End"';
  b := Json.Parse( s );

  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован: "'
    + s + '" Valid JSON should parse successfully', b );
  AssertTrue( 'Найденный узел должен иметь правильное значение. Found node should have correct value',
    Json.Find( 'cars' ).Value );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );
end;

(*В объекте находится второй объект *)
procedure TTestPrimitiv.ParseObj_obj_v_obj;
var
  s: string;
  b: boolean;
begin
  s := '{"name":"John","age":30,"cars":True, "Name":"Pol",' + ///
    '"part":{"name": "Ivan", "age":33}}';
  b := Json.Parse( s );

  AssertTrue( 'Допустимый JSON должен быть успешно проанализирован. '
    + s + ' Valid JSON should parse successfully', b );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'Имя перезаписывается на Pol', 'Pol', Json.Find( 'Name' ).Value );
  AssertEquals( 'Другое имя в объекте', 'Ivan', Json.Find( 'part/name' ).Value );
  AssertEquals( 'Число во 2м объекте', 33, Json.Find( 'part/age' ).Value );
end;


//--------------------------------------------------------------------


procedure TTestPrimitiv.TestParse_Value;
begin
  Json.AddElm( 'age' ).Value  := 25;
  Json.AddElm( 'age1' ).Value := '32';

  Json.AddElm( 'name' ).Value := 'Egor45';
  Json.AddElm( 'Name', 'Egor' );
  Json.AddElm( 'Name1', 'Ivan' );

  Json.AddElm( 'par1', '56' );
  Json.AddElm( 'par2', 'True' );
  Json.AddElm( 'par3', 66 );

  Json.AddObj( 'obj' ).AddElm( 'elm1', 'значение' ).AddElm( 'elm2', 'значение' ).Value := 45;

  Json.AddElm( 'Petrov', '{name:Ivan,ege:33, car:"Lada"}' );
  Json.AddElm( 'arr', '[один,два, три ,	 четыре]' );
  Json.AddElm( 'Иванов',
    '{имя:Егор,лет:33, авто:Калина,счёт:[123456789,321654987,0X15FB5ac] }' );

  Json.AddObj( 'Сидоров' ).Value := '{name:Сергей,ege:44, car:Москвич}';
  Json.AddObj( 'Петров' ).Value   :=
    'паспорт:{name:Иван,ege:75, car:[Ягуар, Москвич]}';

  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );


  AssertEquals( 'число', 25, Json.Find( 'age' ).Value );
  AssertEquals( 'число', 32, Json.Find( 'age1' ).Value );

  AssertEquals( 'строка', 'Egor', Json.Find( 'name' ).Value );
  AssertEquals( 'строка', 'Ivan', Json.Find( 'name1' ).Value );

  AssertEquals( 'число', 56, Json.Find( 'par1' ).Value );
  AssertTrue( 'логическое', Json.Find( 'par2' ).Value );

  AssertEquals( 'строка', 'значение', Json.Find( 'obj/elm2' ).Value );
  AssertEquals( 'число объекта', 45, Json.Find( 'obj' ).Value );

  AssertEquals( 'строка', 'Lada', Json.Find( 'Petrov/car' ).Value );
  AssertEquals( 'строка', 'три', Json.Find( 'arr/2' ).Value );
  AssertEquals( 'строка', 'Егор', Json.Find( 'Иванов/имя' ).Value );
  AssertEquals( 'число', 321654987, Json.Find( 'Иванов/счёт/1' ).Value );
  AssertEquals( 'строка', 'Москвич', Json.Find( 'Сидоров/car' ).Value );
  AssertEquals( 'строка', 'Иван', Json.Find( 'Петров/паспорт/name' ).Value );
  AssertEquals( 'строка', 'Ягуар', Json.Find( 'Петров/паспорт/car/0' ).Value );
end;


//--------------------------------------------------------------------

procedure TTestPrimitiv.Object_Create;
var
  nod: TJsonNode;
begin
  //Создаём новый узел и запоминаем его в переменной
  nod := Json.AddObj( 'Объект' ).AddObj( 'ObName' );
  nod.AddElm( 'параметр', 'значение' );
  nod.AddElm( 'parametr' ).Value := 'value';

  Json.AddObj( 'Объект' ).Value := '{name:Сергей,ege:44, car:Москвич}';

  //Создаём новый узел и запоминаем его в переменной
  nod := Json.Force( 'Объект/ObName2' );
  nod.AddElm( 'параметр', 85 );
  nod.AddElm( 'Параметр2', True );



  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'Должен быть объектом. Should be an object',
    Ord( nkObject ), Ord( nod.Kind ) );

  AssertEquals( 'Строка', 'значение', Json.Find(
    'Объект/ObName/параметр' ).Value );
  AssertEquals( 'Строка', 'value', Json.Find( 'Объект/ObName/parametr' ).Value );
  AssertEquals( 'Строка', 44, Json.Find( 'Объект/ege' ).Value );
  AssertEquals( 'Строка', 85, Json.Find( 'Объект/ObName2/Параметр' ).Value );
end;


//--------------------------------------------------------------------
procedure TTestPrimitiv.Kavyhchki_Dvojnyhe;
begin
  Json.AddElm( '"name1"', '"Значение в кавычках 1111"' );
  Json.AddElm( 'name1' ).Value := '"Значение в кавычках"';
  Json.AddElm( 'name2', 'Имя_и_Значение_без_кавычек' );
  Json.AddElm( '"name3"', '"Имя и Значение в кавычках' + #10 +
    'С новой строки"' );
  //3.1
  Json.AddElm( '"Имя' + #10 + 'на второй строке"',
    'Имя_на_дух_строках_в_кавычках' );
  //3.2
  Json.AddElm( '"Имя2' + #10 + 'на второй строке"',
    '"Имя и значение на\nдвух строках в кавычках"' );
  Json.AddElm( 'age', 222 );
  Json.AddElm( 'age' ).Value := 32;
  Json.AddElm( '"name4"', '"Значение со знаком :"' );
  Json.AddElm( '"name[5]"', '"Один, два {Два}"' );
  Json.AddElm( '"name: 6"', '"Один, два\n{новая строка}"' );

  Json.AddObj( 'объект' ).AddElm( 'active', True );
  Json.AddObj( 'объект' ).AddElm( 'name', '"Olya\nSveta"' );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );


  AssertEquals( 'name1', 'Значение в кавычках', Json.Find( 'name1', '' ) );
  AssertEquals( 'name2', 'Имя_и_Значение_без_кавычек', Json.Find( 'name2', '' ) );
  AssertEquals( 'name3', 'Имя и Значение в кавычках' + #10 +
    'С новой строки',
    Json.Find( 'name3', '' ) );
  AssertEquals( 'name3.1', 'Имя_на_дух_строках_в_кавычках',
    Json.Find( 'Имя' + #10 + 'на второй строке', '' ) );
  AssertEquals( 'name3.2', 'Имя и значение на' + #10 +
    'двух строках в кавычках', Json.Find( 'Имя2' + #10 +
    'на второй строке', '' ) );
  AssertEquals( 'name4', 'Значение со знаком :', Json.Find( 'name4', '' ) );
  AssertEquals( 'name[5]', 'Один, два {Два}', Json.Find( 'name[5]', '' ) );
  AssertEquals( 'name: 6', 'Один, два' + #10 + '{новая строка}',
    Json.Find( 'name: 6', '' ) );

  AssertEquals( 'Integer value set', 32, Json.Find( 'age', 0 ) );

  AssertEquals( 'В объекте свойство', True, Json.Find( 'объект/active', False ) );
  AssertEquals( 'В объекте свойство', 'Olya' + #10 + 'Sveta', Json.Find(
    'объект/name', '-' ) );
end;



procedure TTestPrimitiv.Kavyhchki_Odinarnyhe;
begin
  Json.AddElm( '''name1''', '''Значение в кавычках''' );
  Json.AddElm( 'name2', 'Имя_и_Значение_без_кавычек' );
  Json.AddElm( '''name3''', '''Имя и Значение в кавычках' +
    #10 + 'С новой строки''' );
  //3.1
  Json.AddElm( '''Имя' + #10 + 'на второй строке''',
    'Имя_на_дух_строках_в_кавычках' );
  //3.2
  Json.AddElm( '''Имя2' + #10 + 'на второй строке''',
 '''Имя и значение на\nдвух строках в кавычках''' );
  Json.AddElm( '''name: 6''', '''Один, два\n{новая строка}''' );

  Json.AddObj( 'объект' ).AddElm( 'active', True );
  Json.AddObj( 'объект' ).AddElm(
    'name', '''Значение в объекте\nна двух строках в кавычках''' );

  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );


  AssertEquals( 'name1', 'Значение в кавычках', Json.Find( 'name1', '' ) );
  AssertEquals( 'name2', 'Имя_и_Значение_без_кавычек', Json.Find( 'name2', '' ) );

  AssertEquals( 'name3', 'Имя и Значение в кавычках' + #10 + 'С новой строки',
    Json.Find( 'name3', '' ) );
  AssertEquals( 'name3.1', 'Имя_на_дух_строках_в_кавычках',
    Json.Find( 'Имя' + #10 + 'на второй строке', '' ) );
  AssertEquals( 'name3.2', 'Имя и значение на' + #10 +
    'двух строках в кавычках', Json.Find( 'Имя2' + #10 +
    'на второй строке', '' ) );

  AssertEquals( 'name: 6', 'Один, два' + #10 + '{новая строка}', Json.Find( 'name: 6', '' ) );

  AssertEquals( 'В объекте свойство', True, Json.Find( 'объект/active', False ) );
  AssertEquals( 'В объекте свойство',
    'Значение в объекте' + #10 + 'на двух строках в кавычках',
    Json.Find( 'объект/name', '-' ) );
end;


//--------------------------------------------------------------------

procedure TTestPrimitiv.Merge_bez_zamenyh;
var
  nod: TJsonNode;
begin
  Json.AddObj( 'Объект' ).Value := '{name:Сергей,ege:44, car:Москвич }';

  nod := TJsonNode.Create;
  nod.AddObj( 'Объект' ).AddElm( 'car', 'BMW' );
  nod.Force( 'Объект/parametr' ).Value := 'value';

  //объединяем элементы в объекте без замены
  Json.Find( 'Объект' ).AddMerge( nod.Find( 'Объект' ), False );

  //AssertTrue( 'Save to file', nod.SaveToFile( saveName + '1', jfCompact ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'кол-во параметров', 2, nod.Find( 'Объект' ).Count );
  AssertEquals( 'кол-во параметров', 4, Json.Find( 'Объект' ).Count );

  AssertEquals( 'Строка', 'value', nod.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Должна перенестись в новый объект',
    'value', Json.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Строка', 'Сергей', Json.Find( 'Объект/name' ).Value );
  AssertEquals( 'Должен остаться "Москвич"', 'Москвич',
    Json.Find( 'Объект/car' ).Value );
  nod.Free;
end;

procedure TTestPrimitiv.Merge_bez_zamenyh_2;
var
  nod: TJsonNode;
begin
  Json.AddObj( 'Объект' ).Value := '{name:Сергей,ege:44, car:Москвич }';

  nod := TJsonNode.Create;
  nod.AddObj( 'Объект' ).AddElm( 'car', 'BMW' );
  nod.Force( 'Объект/parametr' ).Value := 'value';

  //объединение вложенных элементов без замены
  Json.AddMerge( nod, False );

  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'кол-во параметров', 2, nod.Find( 'Объект' ).Count );
  AssertEquals( 'кол-во параметров', 4, Json.Find( 'Объект' ).Count );

  AssertEquals( 'Строка', 'value', nod.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Должна перенестись в новый объект',
    'value', Json.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Строка', 'Сергей', Json.Find( 'Объект/name' ).Value );
  AssertEquals( 'Должен остаться "Москвич"', 'Москвич',
    Json.Find( 'Объект/car' ).Value );
  nod.Free;
end;

procedure TTestPrimitiv.Merge_s_zamenoj;
var
  nod: TJsonNode;
begin
  Json.AddObj( 'Объект' ).Value := '{name:Сергей,ege:44, car:Москвич }';

  nod := TJsonNode.Create;
  nod.AddObj( 'Объект' ).AddElm( 'car', 'BMW' );
  nod.Force( 'Объект/parametr' ).Value := 'value';

  //объединяем элементы в объекте
  Json.Find( 'Объект' ).AddMerge( nod.Find( 'Объект' ), True );

  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'кол-во параметров', 2, nod.Find( 'Объект' ).Count );
  AssertEquals( 'кол-во параметров', 4, Json.Find( 'Объект' ).Count );

  AssertEquals( 'Строка', 'value', nod.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Должна перенестись в новый объект',
    'value', Json.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Строка', 'Сергей', Json.Find( 'Объект/name' ).Value );
  AssertEquals( '"Москвич" должен замениться на "BMW"', 'BMW',
    Json.Find( 'Объект/car' ).Value );
  nod.Free;
end;

procedure TTestPrimitiv.Merge_s_zamenoj_2;
var
  nod: TJsonNode;
begin
  Json.AddObj( 'Объект' ).Value := '{name:Сергей,ege:44, car:Москвич }';

  nod := TJsonNode.Create;
  nod.AddObj( 'Объект' ).AddElm( 'car', 'BMW' );
  nod.Force( 'Объект/parametr' ).Value := 'value';

  //объединение вложенных элементов
  Json.AddMerge( nod, True );

  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'кол-во параметров', 2, nod.Find( 'Объект' ).Count );
  AssertEquals( 'кол-во параметров', 4, Json.Find( 'Объект' ).Count );

  AssertEquals( 'Строка', 'value', nod.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Должна перенестись в новый объект',
    'value', Json.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Строка', 'Сергей', Json.Find( 'Объект/name' ).Value );
  AssertEquals( '"Москвич" должен замениться на "BMW"', 'BMW',
    Json.Find( 'Объект/car' ).Value );
  nod.Free;
end;

procedure TTestPrimitiv.MergeArray_bez_zamenyh;
var
  nod: TJsonNode;
begin
  Json.AddObj( 'Объект' ).Value := '{name:Сергей,ege:44, car:[111,112] }';

  nod := TJsonNode.Create;
  nod.AddObj( 'Объект' ).AddArrElm( 'car', 221 );
  nod.AddObj( 'Объект' ).AddArrElm( 'car', '111' );
  nod.Force( 'Объект/parametr' ).Value := 'value';

  //объединяем элементы без замены
  Json.AddMerge( nod, False );

  AssertTrue( 'Save to file', nod.SaveToFile( saveName + '1', jfCompact ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'кол-во параметров', 2, nod.Find( 'Объект/car' ).Count );
  AssertEquals( 'кол-во параметров', 4, Json.Find( 'Объект/car' ).Count );
  AssertEquals( 'кол-во параметров', 4, Json.Find( 'Объект' ).Count );

  AssertEquals( 'Строка', 'value', nod.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Должна перенестись в новый объект',
    'value', Json.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Строка', 'Сергей', Json.Find( 'Объект/name' ).Value );
  AssertEquals( 'Должено добавиться в массив', 221,
    Json.Find( 'Объект/car/2' ).Value );
  nod.Free;
end;

procedure TTestPrimitiv.MergeArray_s_zamenoj;
var
  nod: TJsonNode;
begin
  Json.AddObj( 'Объект' ).Value := '{name:Сергей,ege:44, car:[111,112] }';

  nod := TJsonNode.Create;
  nod.AddObj( 'Объект' ).AddArrElm( 'car', 111 );
  nod.AddObj( 'Объект' ).AddArrElm( 'car', '111' );
  nod.AddObj( 'Объект' ).AddArrElm( 'car', 223 );
  nod.Force( 'Объект/parametr' ).Value := 'value';

  //объединяем элементы без замены
  Json.AddMerge( nod, True );

  AssertTrue( 'Save to file', nod.SaveToFile( saveName + '1', jfCompact ) );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  AssertEquals( 'кол-во параметров', 3, nod.Find( 'Объект/car' ).Count );
  AssertEquals( 'кол-во параметров', 4, Json.Find( 'Объект/car' ).Count );
  AssertEquals( 'кол-во параметров', 4, Json.Find( 'Объект' ).Count );

  AssertEquals( 'Строка', 'value', nod.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Должна перенестись в новый объект',
    'value', Json.Find( 'Объект/parametr' ).Value );
  AssertEquals( 'Строка', 'Сергей', Json.Find( 'Объект/name' ).Value );
  AssertEquals( 'Должено добавиться в массив', '111',
    Json.Find( 'Объект/car/2' ).Value );
  nod.Free;
end;


//--------------------------------------------------------------------

 //procedure TTestPrimitiv.TestCloneJson;
 //var
 //  clone: TJsonNode;
 //begin
 //  Json.Parse( '{"a":1,"b":[1,2,3]}' );
 //  clone := Json.Clone;
 //    try
//    AssertEquals( 'Клон должен иметь такое же содержимое. Clone should have same content', Json.ToString, clone.ToString );
//    AssertTrue( 'Клонировать должен другой объект. Clone should be different object',
 //      Json <> clone );
 //    finally
 //    clone.Free;
 //    end;
 //end;

procedure TTestPrimitiv.TestSaveLoadFromFile;
var
  json2: TJsonNode;
begin
  Json.Parse( '{"test":"data","value":42, car:[Москвич, BMW]}' );

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

procedure TTestPrimitiv.TestJsonToString;
var
  s, expected: string;
begin
  expected := '{"name":"John","age":30}';
  Json.Parse( expected );
  s := Json.JsonToText( jfCompressed );
  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );

  // Удаляем пробелы для сравнения, так как форматирование может отличаться
  AssertEquals( 'JsonStr должен выдавать допустимый JSON. ToString should produce valid JSON',
    StringReplace( expected, ' ', '', [rfReplaceAll] ),
    StringReplace( s, ' ', '', [rfReplaceAll] ) );
end;

 // procedure TTestPrimitiv.TestEscapeUnescape;
 // var
 //   s, escaped, unescaped: string;
 // begin
 //   s       := 'Line1'#13#10'Line2 "quoted"';
 //   escaped := TJsonNode.EscapeString( s );
 //   unescaped := TJsonNode.UnescapeString( escaped );

//  AssertEquals( 'Неэкранированный должен соответствовать оригиналу. Unescaped should match original', s, unescaped );
//end;

procedure TTestPrimitiv.TestValidateJson;
begin
  AssertTrue( 'Valid JSON object. Допустимый объект JSON', JsonNumberValidate(
    '1_000E+3' ) );
  AssertTrue( 'Valid JSON string', JsonStringValidate( '"test строка"' ) );
  AssertTrue( 'Valid JSON array', JsonValidate( 'mas:[1,2,3]' ) );
end;

procedure TTestPrimitiv.TestPerformance;
var
  i:       integer;
  bigJson: TJsonNode;
  start:   QWord;
begin
  // Тест производительности для больших JSON
  start := GetTickCount64;

  bigJson := Json.AddArr( 'arrr' );
  for i := 1 to 1000 do
    bigJson.AddArrElm( i );

  AssertEquals( 'Большой JSON должен содержать 1000 элементов. Big JSON should have 1000 elements',
    1000, bigJson.Count );
  AssertTrue( 'Проверка производительности должна быть завершена в разумные сроки. Performance test should complete in reasonable time',
    GetTickCount64 - start < 500 ); // менее 0,5 секунды

  AssertTrue( 'Save to file', Json.SaveToFile( saveName, jfCompact ) );
end;

initialization
  RegisterTest( TTestPrimitiv );
end.
