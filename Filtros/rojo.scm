#lang racket

(require "../filtro_base.scm")

(define rojo
	(lambda (seccion)
		(list
			255
			(cadr (caar seccion))
			(caddr (caar seccion))
		)
	)
)


(procesar rojo)
