#lang racket

(require "../filtro_base.scm")

(define inversion
	(lambda (seccion)
		(list
			(- 255 (car (caar seccion)))
			(- 255 (cadr (caar seccion)))
			(- 255 (caddr (caar seccion)))
		)
	)
)

(procesar inversion)
