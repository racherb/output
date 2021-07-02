# Estudio de casos

## Elementos del lenguaje

- **Block**: Define un bloque dentro del contenido del output.
- **Record**: Es un registro cuyo patron se repite en un Bloque determinado.
- **Text**: Es un texto libre sin formato.
- **Format**: Es un contenido estucturado en un formato JSON u otro conocido.
- **Schema**: Es un contenido determinado por una estructura conocida de documento.
- **Pattern**: Patron.
- **Location**: Proporciona una ubicacion exacta para la extraccion.
- **Hashtag**: Es determinado por el simbolo '#' y es un marcado de contenido que habilita un contador sobre dicho elemento.
- **Variables**: $(var-name) Determina el nombre de una variable dentro del output.

### Block

Sintaxis EBNF

```BNF
Block ::= ('block:' | 'b:') Block_Name '{' (((Pattern | Text | Record | Block | JSON) ',')*) '}' (| Location)
```

Ejemplos:

```
block:PingResponse {
    record:PING {
        p:Info ~64 bytes from %%(server) %%(ip): icmp_seq=$$(seq) ttl=%%(ttl) time=%%(time) %%(um)~,
        p:NameResolutionFail ~ping: %%(server): Temporary failure in name resolution~
    }
}
```

**Pattern value sintax**

El valor del patron se define entre ~pattern_value~ y tiene la forma general LPEG:

```
pattern_value -> value * value * ... * value
```

Caracteristicas generales:

- Cada pattern value esta conformado por strings separados por un espacio.
- Los espacios entre strings son funciones en si mismas:
  - 1 espacio en blanco representa un espacio en blanco
  - 2 espacios en blanco representa uno o varios espacios en blanco
  - 3 espacios en blanco representa uno o varios espacios de tipo " \t \v"
- ...

- **$(name:type)**: Es un tipo, un nombre de variable o un patron lpeg
- **$(.name x, y)**: Es una funcion

Ejemplo:

```
~$(:int) bytes from $(server:hostname) $(ip:ip4): icmp_seq=$(:int) ttl=$(ttl) time=$(time:float) $(um)~
```

- *$(:int)*: Valida que el valor es de tipo *integer* y no captura su valor,
- *$(server:hostname)*: Valida que el valor es de tipo *hostname* y captura el valor en la variable *server*.
- *$(ip:ip4)*: Valida que es de tipo *ip4* y captura el valor en la variable *ip*.
- *$(seq:seq)*: Valida que el valor es de tipo *secuencia* y guarda el valor en la variable *seq*.
- *$(time:float)*: Valida que el valor es de tipo *float* y captura su valor en la variable *time*.
- *$(um)*: Obtiene el valor en la variable *um*.

Tipos:

- any: Cualquier tipo o cualquier caracter
- lower:
- upper:
- alpha:
- alphanum:
- hostname:
- ip4:
- int:
- float:
- zeros:
- ones:
- inc: Incremento
- seq: Secuencia de incremento 1

Funciones:

- wsp n: Inserta n espacios en blanco
- maybe a: Funcion que indica que valor podria estar presente o no.
- or a b: Funcion logica que valida la existencia de a o de b
- word n:
- lines n:
- back nL, nC: Back n chars

### Text

Texto libre sin formato.

```BNF
Hashtag ::= ('#' Hashtag_Name  (| ':' Value))*
Block ::= ('block' | 'b') (| (':' Block_Name)) '{' (((Pattern | Text | Record | Block | JSON) ',')*) '}' (| Location)
Record ::= ('record:' | 'r:') Record_Name '{' ((Pattern | Text | Block) ',')* '}' (| Location)
Location ::= ('location:' | 'l:') (| Loc_Name) (('from' | 'to' | 'after' | 'before' | 'move' | 'not') (RefLoc (| Name | Index) (| ('+' | '-') Value))*)*
Text ::= ('text:' | 't:') (| TextName) Content (| Location)
Extract ::= 'extract:' (Block | Record | Location | Text) Name 
Ignore ::= 'ignore:' (Block | Record | Location | Text) Name 
RefLoc ::= 'Block' | 'Record' | 'Text' | 'Location' | 'Lines' | 'Chars' | 'Word' | 'Integer' | 'Float' | 'Record' | 'End'
```

### Hashtag

Sintaxis EBNF

```BNF
Hashtag  ::= ( '#' Hashtag_Name ( ':' Value )? )*
```

Ejemplos:

- **#ClienteSinContrato**: 'Andre Lillo'
- **#ClienteSinContrato**: 'Vivian Mirran'

#### Type, Count y List

- **type**(ClienteSinContrato): String
- **count**(ClienteSinContrato): 2
- **list**(ClienteSinContrato): {'Andre Lillo', 'Vivian Mirran'}

#### Sum, Min, Max y Media

Aplicable para hashtags de tipo numericos. Por ejemplo:

- **#montoImpago**: 245
- **#montoImpago**: 199

- **type**(montoImpago): numeric
- **count**(montoImpago): 2
- **list**(montoImpago): {245, 199}
- **sum**(montoImpago): 344
- **min**(montoImpago): 199

## Salida ping de Unix

$b:H1-1(
    PING github.com (140.82.113.3) 56(84) bytes of data.
)
$b:B2-n(
    64 bytes from lb-140-82-113-3-iad.github.com (140.82.113.3): icmp_seq=1 ttl=49 time=261 ms
    64 bytes from lb-140-82-113-3-iad.github.com (140.82.113.3): icmp_seq=2 ttl=49 time=181 ms
    64 bytes from lb-140-82-113-3-iad.github.com (140.82.113.3): icmp_seq=3 ttl=49 time=209 ms
    64 bytes from lb-140-82-113-3-iad.github.com (140.82.113.3): icmp_seq=4 ttl=49 time=170 ms
    64 bytes from lb-140-82-113-3-iad.github.com (140.82.113.3): icmp_seq=5 ttl=49 time=175 ms
)
$b:Fn-3(
    --- github.com ping statistics ---
    12 packets transmitted, 11 received, 8,33333% packet loss, time 11040ms
    rtt min/avg/max/mdev = 169.725/198.765/260.611/31.727 ms
)

Resumen:
12 packets transmitted, 11 received, 8,33333% packet loss, time 11040ms
rtt min/avg/max/mdev = 169.725/198.765/260.611/31.727 ms

Excepciones:
ping: srv_alcapax: Temporary failure in name resolution

rhernandez@hpenvy:~$ curl -I -L http://tarantool.io
HTTP/1.1 301 Moved Permanently
Server: nginx/1.9.2
Date: Sun, 23 May 2021 02:36:39 GMT
Content-Type: text/html
Content-Length: 184
Connection: keep-alive
Location: https://www.tarantool.io/
X-XSS-Protection: 0

HTTP/1.1 302 Found
Connection: keep-alive
Server: gunicorn/20.0.4
Date: Sun, 23 May 2021 02:36:42 GMT
Content-Type: text/html; charset=utf-8
Location: /en/
Vary: Cookie
X-Content-Type-Options: nosniff
X-Xss-Protection: 1; mode=block
Via: 1.1 vegur

HTTP/1.1 200 OK
Connection: keep-alive
Server: gunicorn/20.0.4
Date: Sun, 23 May 2021 02:36:42 GMT
Content-Type: text/html; charset=utf-8
X-Frame-Options: DENY
Vary: Cookie
Content-Length: 83828
Content-Language: en
X-Content-Type-Options: nosniff
X-Xss-Protection: 1; mode=block
Set-Cookie: csrftoken=T3ws3npUJOcasg9NOxBy7qcLRmPZjOjMQ7Oet9HDFXrUiasrW9sVkqF6eECSFmKl; expires=Sun, 22 May 2022 02:36:42 GMT; Max-Age=31449600; Path=/; SameSite=Lax
Via: 1.1 vegur
