# JsonEasy
Небольшой парсер JSON на основе Free Pascal в одном модуле без зависимостей.
A small pascal based json parser in one unit with no dependencies.

JsonNode - это класс, используемый для анализа, создания и навигации по документу в формате json.
  Вам следует только создать и освободить корневой узел вашего документа. Корневой
узел будет управлять временем жизни всех дочерних узлов с помощью таких методов,
как Add, Delete и Clear.
    Когда Вы создаете узел TJsonNode, у него не будет родительского элемента, и он будет считаться
корневым узлом. Корневой узел должен быть либо массивом, либо объектом. Попытки
  преобразование root во что-либо, отличное от массива или объекта, вызовет исключение.
     Примечание: Синтаксический анализатор поддерживает Unicode путем преобразования символов Unicode,
  экранированных как \u20AC. Если в вашей строке JSON есть экранированный символ Unicode, он
не будет экранирован при преобразовании в строку pascal.


//-----------------------------------------------

* Создаём экземпляр и включаем кэширование путей:
   jCfg := TJsonNode.Create;
   jCfg.CachePathEnabled := True; //Enable Cache

* Создаём новый узел и запоминаем его в переменной ( nod := jCfg.AddObj )
   1) jCfg.AddElm( 'Petrov', 'Ivan Ivanovich' );   //Petrov:Ivan Ivanovich
   2) jCfg.AddElm( 'Petrov', '"Ivan Ivanovich"' ); //Petrov:"Ivan Ivanovich"
   3) jCfg.AddElm( 'Petrov', '{name:Ivan,ege:33}' ); => Petrov:{name:Ivan,ege:33}
   4) jCfg.AddElm( 'Petrov'+#10+'two', 'Ivan'+#10+'Ivanovich' );

   5) nod := jCfg.AddObj( 'Obj' ).AddObj( 'ObName' );
   6) nod := jCfg.Force( 'Obj/ObName2' );

   7) jCfg.Force( 'obj/name', 'Alice' );
   8) jCfg.Force( 'obj name/name first' ).AddElm( 'age', 25 );
   9) jCfg.Force( 'name' ).Value  := 'Alice';
   10) jCfg.Force( 'Person/Object' ).Parse('{name:"John' +#10+ 'Stiv",age:30,cars:True}');

   11) jCfg.Parse( 'Obj:ObName' );
   12) jCfg.Parse( a1:1_000_0, a2: -3.0_01, a3: -0x054, a4:.04, a5: -5_00.6E-2 );

* Создаём массив и добавляем элементы:
   1) jCfg.Parse( '"cars":["Ford","BMW" , "Fiat"]' );
   2) jCfg.AddArr( 'arr' );
      jCfg.AddArr( 'arr', 'Moscvich' );
      jCfg.AddArr( 'arr' ).AddArrElm( 'Ford' );
      jCfg.AddArr( 'arr' ).AddArrElm( 'BMW' ).AddArrElm( 'Fiat' );
   3) jCfg.AddArr( 'arr2' ).Parse := ('2, two only    , true' ); arr2:[2, "two only", true]
   4) jCfg.AddArr( 'arr' ).Count

* Oбъединяем элементы в объекте ( AddMerge )
   1) jCfg.Find( 'Obj' ).AddMerge( nod.Find( 'Obj' ), True ); // без замены
   2) jCfg.AddMerge( nod, True );  // с заменой внутренних параметров

* Поиск по пути:
   1) node := jCfg.Find( 'person/name' );
   2) Form1.Width  := jCfg.Find('main window/width all', 800); //800 - Default

* Саздание комментариев:
    1) jCfg.AddComment('Сколько лет: ');
    2) jCfg.Parse( '{//"Сколько лет:",value:42, //авто моё, car:[Москвич, BMW]}' );

* Сохранить/загрузить в файл:
    1) jCfg.SaveToFile( 'config.json' );
    2) jCfg2.LoadFromFile( 'config.json' );
    3) s := jCfg.JsonToText( jfCompressed );

* Перебор всех параметров узла:
    1) for Node in JsonObjectOrArray do
     2) Node := Node.First, next, pred, Last, ChildFirst, ChildLast

* Освободить память:
   jCfg.Root.Free;
