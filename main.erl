-module(main).
-export([procesar/5]).



procesar(In, Out, Filtro, Procs, Contx) ->
    {ok, Img} = file:read_file(In),
        
    
    {Ancho, Alto, MaxVal, Pixeles} = leer_archivo(Img),
    
    {Start, _} = erlang:statistics(wall_clock),

    Filas = agrupar_filas(Pixeles, Ancho),
    Secciones = agrupar_secciones(Filas, Alto div Procs, Alto rem Procs, Contx),

    Padre = self(),
    crear_procesos(Secciones, 1, Padre, Filtro, Ancho),

    Resultados = obtener_resultados(Procs, []),
    Ordenados = quick_sort(Resultados),
    NuevosPixeles = desempacar_secciones(Ordenados),
    
    {End, _} = erlang:statistics(wall_clock),    
    TimeMs = End - Start,

    escribir_archivo(Out, Ancho, Alto, MaxVal, NuevosPixeles),
    io:format("Total Time: ~p ms~n", [TimeMs]),
    ok.


leer_archivo(<<"P3", Data0/binary>>) ->
    {Ancho, Data1}  = leer_numero(trim(Data0)),
    {Alto, Data2}   = leer_numero(trim(Data1)),
    {MaxVal, Data3} = leer_numero(trim(Data2)),

    Pixeles = leer_pixeles(trim(Data3), Ancho * Alto),

    {Ancho, Alto, MaxVal, Pixeles}.


trim(<<C, Rest/binary>>) when C == $\s; C == $\n; C == $\t; C == $\r ->
    trim(Rest);
trim(Data) -> Data.

trim_str([C | Rest]) when C == $\s; C == $\n; C == $\t; C == $\r ->
    trim_str(Rest);
trim_str(Data) -> Data.


leer_numero(Data) -> leer_numero(Data, []).
leer_numero(<<C, Rest/binary>>, Acum) when C >= $0, C =< $9 ->
    leer_numero(Rest, Acum ++ [C]);
leer_numero(Data, Acum) -> {list_to_integer(Acum), Data}.


leer_pixeles(_Data, 0) -> [];
leer_pixeles(Data0, NumPixeles) ->
    {R, Data1} = leer_numero(trim(Data0)),
    {G, Data2} = leer_numero(trim(Data1)),
    {B, Data3} = leer_numero(trim(Data2)),

    [{R, G, B} | leer_pixeles(Data3, NumPixeles - 1)].


agrupar_filas([], _Ancho) -> [];
agrupar_filas(Pixeles, Ancho) ->
    {Fila, Resto} = empacar(Pixeles, Ancho),
    [Fila | agrupar_filas(Resto, Ancho)].


empacar(Pixeles, 0) -> {[], Pixeles};
empacar([Pixel | Rest0], Ancho) ->
    {Fila, Rest1} = empacar(Rest0, Ancho - 1),
    {[Pixel | Fila], Rest1}.


agrupar_secciones([], _Base, _Extra, _Contx) -> [];
agrupar_secciones(Filas, Base, Extra, Contx) ->
    TamSeccion = cant_filas_seccion(Base, Extra),

    {_Propias, RestoSiguiente} = empacar(Filas, TamSeccion),

    SeccionConContexto = primeras_filas(TamSeccion + Contx, Filas),

    [{TamSeccion, SeccionConContexto} | agrupar_secciones(RestoSiguiente, Base, max(0, Extra - 1), Contx)].


cant_filas_seccion(Base, 0) -> Base;
cant_filas_seccion(Base, _Extra) -> Base + 1.


primeras_filas(0, _Filas) -> [];
primeras_filas(_N, []) -> [];
primeras_filas(N, [Fila | Rest]) -> [Fila | primeras_filas(N - 1, Rest)].


crear_procesos([], _ID, _Padre, _Filtro, _Ancho) -> ok;
crear_procesos([{TamSeccion, Seccion} | Rest], ID, Padre, Filtro, Ancho) ->
    spawn(
    	fun() -> procesar_seccion(ID, TamSeccion, Seccion, Padre, Filtro, Ancho)
	end),
    crear_procesos(Rest, ID + 1, Padre, Filtro, Ancho).


procesar_seccion(ID, TamSeccion, Seccion, Padre, Filtro, Ancho) ->
    Port = open_port({spawn, "racket " ++ Filtro}, [stream, {line, 1024}]),

    Alto = length(Seccion),
    Port ! {self(), {command, io_lib:format("~p~n~p~n", [Ancho, Alto])}},

    mandar_seccion(Port, Seccion),
    NuevosPixeles = recibir_pixeles(Port, Ancho * Alto),

    catch port_close(Port),

    NuevaSeccionCompleta = agrupar_filas(NuevosPixeles, Ancho),
    NuevaSeccion = primeras_filas(TamSeccion, NuevaSeccionCompleta),

    Padre ! {resultado, ID, NuevaSeccion}.


mandar_seccion(_Port, []) -> ok;
mandar_seccion(Port, [Fila | Rest]) ->
    mandar_fila(Port, Fila),
    mandar_seccion(Port, Rest).


mandar_fila(_Port, []) -> ok;
mandar_fila(Port, [{R, G, B} | Rest]) ->
    Port ! {self(), {command, io_lib:format("~p ~p ~p~n", [R, G, B])}},
    mandar_fila(Port, Rest).


recibir_pixeles(_Port, 0) -> [];
recibir_pixeles(Port, N) ->
    receive
        {Port, {data, {eol, Linea}}} ->
            [extraer_canales(Linea) | recibir_pixeles(Port, N - 1)]
    end.


extraer_canales(Linea) ->
    {R, Data1} = leer_numero_str(trim_str(Linea)),
    {G, Data2} = leer_numero_str(trim_str(Data1)),
    {B, _Data3} = leer_numero_str(trim_str(Data2)),
    {R, G, B}.


leer_numero_str(Data) -> leer_numero_str(Data, []).
leer_numero_str([C | Rest], Acum) when C >= $0, C =< $9 ->
    leer_numero_str(Rest, Acum ++ [C]);
leer_numero_str(Data, Acum) -> {list_to_integer(Acum), Data}.


obtener_resultados(0, Acum) -> Acum;
obtener_resultados(Procs, Acum) ->
    receive
        {resultado, ID, NuevaSeccion} -> obtener_resultados(Procs - 1, [{ID, NuevaSeccion} | Acum])
    end.


quick_sort([]) -> [];
quick_sort([{ID, Pixeles} | Rest]) ->
    Menores = [{IDmen, P} || {IDmen, P} <- Rest, IDmen < ID],
    Mayores = [{IDmay, P} || {IDmay, P} <- Rest, IDmay >= ID],
    quick_sort(Menores) ++ [{ID, Pixeles}] ++ quick_sort(Mayores).
    

desempacar_secciones([]) -> [];
desempacar_secciones([{_ID, Seccion} | Rest]) ->
    desempacar_filas(Seccion) ++ desempacar_secciones(Rest).


desempacar_filas([]) -> [];
desempacar_filas([Fila | Rest]) ->
    Fila ++ desempacar_filas(Rest).


escribir_archivo(Out, Ancho, Alto, MaxVal, Pixeles) ->
    {ok, Img} = file:open(Out, [write]),
    io:format(Img, "P3~n~p ~p~n~p~n", [Ancho, Alto, MaxVal]),

    escribir_pixeles(Img, Pixeles),

    file:close(Img).


escribir_pixeles(_Archivo, []) -> ok;
escribir_pixeles(Archivo, [{R, G, B} | Rest]) ->
    io:format(Archivo, "~p ~p ~p~n", [R, G, B]),
    escribir_pixeles(Archivo, Rest).
    
    
    
% main:procesar("Imagenes/cube3.ppm", "Imagenes/nuevoCubo.ppm", "Filtros/grises.scm", 1).
