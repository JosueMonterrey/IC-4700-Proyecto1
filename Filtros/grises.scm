#lang racket

(require "../filtro_base.scm")

(define escala-grises
	(lambda (seccion)
		(map (lambda (p) (quotient (apply + (caar seccion)) 3)) '(0 0 0))
	)
)

(procesar escala-grises)
