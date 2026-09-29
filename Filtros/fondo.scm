#lang racket

(require "../filtro_base.scm")

(define fondo
	(lambda (seccion)
		(cond
			((>=
				(quotient
					(+
						(car (caar seccion))
						(cadr (caar seccion))
						(caddr (caar seccion)))
				3)
			200)
				'(0 0 0)
			)
			(else
				(caar seccion)
			)
		)	
	)
)

(procesar fondo)
