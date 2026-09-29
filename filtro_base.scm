#lang racket

(provide procesar)

(define procesar
	(lambda (filtro)
		(escribir-seccion
			(aplicar-filtro-seccion
				; read-line #1 = ancho, read-line #2 = alto
				(leer-seccion (string->number (read-line)) (string->number (read-line)))
				filtro
			)
		)
		(flush-output)
	)
)


(define aplicar-filtro-seccion
	(lambda (M filtro)
		(cond
			((null? M)
				'()
			)
			(else
				(cons
					(aplicar-filtro-linea (car M) M filtro)
					(aplicar-filtro-seccion (cdr M) filtro)
				)
			)
		)
	)
)


(define aplicar-filtro-linea
	(lambda (linea seccion filtro)
		(cond
			((null? linea)
				'()
			)
			(else
				(cons
					(filtro seccion)
					(aplicar-filtro-linea (cdr linea) (map cdr seccion) filtro)
				)
			)
		)
	)
)


(define escribir-seccion
	(lambda (M)
		(cond
			((null? M)
				(void)
			)
			(else
				(escribir-linea (car M))
				(escribir-seccion (cdr M))
			)
		)
	)
)

(define escribir-linea
	(lambda (linea)
		(cond
			((null? linea)
				(void)
			)
			(else
				(escribir-pixel (car linea))
				(escribir-linea (cdr linea))
			)
		)
	)
)

(define escribir-pixel
	(lambda (pixel)
		(display (car pixel))
		(display " ")
		(display (cadr pixel))
		(display " ")
		(display (caddr pixel))
		(display "\n")
	)
)


(define leer-seccion
	(lambda (ancho alto)
		(cond
			((zero? alto)
				'()
			)
			(else
				(cons
					(leer-fila ancho)
					(leer-seccion ancho (- alto 1))
				)
			)
		)
    )
)


(define leer-fila
	(lambda (ancho)
		(cond
			((zero? ancho)
				'()
			)
			(else
				(cons
					(map string->number (string-split (read-line)))
					(leer-fila (- ancho 1))
				)
			)
		)
	)
)
; main:procesar("port.ppm", "g.ppm", "gauss.scm", 4).
