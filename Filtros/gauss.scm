#lang racket

(require "../filtro_base.scm")


(define gaussian-blur
	(lambda (seccion)
		(gaussian-blur-aux seccion 9 3.0)
	)
)

(define gaussian-blur-aux
	(lambda (seccion K sigma)
		(map inexact->exact
			(map round
				(matriz-sum
					seccion
					(normalizar
						(matriz-gaussiana K sigma)
						(suma-matriz (matriz-gaussiana K sigma))
					)
				)
			)
		)
	)
)

(define matriz-sum
	(lambda (M MG)
		(cond
			((or (null? M) (null? MG))
				'(0.0 0.0 0.0)
			)
			(else
				(map +
					(linea-sum (car M) (car MG))
					(matriz-sum (cdr M) (cdr MG))
				)
			)
		)
	)
)

(define linea-sum
	(lambda (L LG)
		(cond
			((or (null? L) (null? LG))
				'(0.0 0.0 0.0)
			)
			(else
				(map +
					(suma-pixel (car L) (car LG))
					(linea-sum (cdr L) (cdr LG))
				)
			)
		)
	)
)

(define suma-pixel
	(lambda (P vG)
		(map (lambda (i) (* i vG)) P)
	)
)

(define matriz-gaussiana
	(lambda (K sigma)
		(matriz-gaussiana-aux
			K
			K
			(- 0 (quotient K 2))
			sigma
		)
	)
)

(define matriz-gaussiana-aux
	(lambda (K N y sigma)
		(cond
			((zero? N)
				'()
			)
			(else
				(cons
					(linea-gaussiana
						K
						(- 0 (quotient K 2))
						y
						sigma
					)
					(matriz-gaussiana-aux
						K
						(- N 1)
						(+ y 1)
						sigma
					)
				)
			)
		)
	)
)

(define linea-gaussiana
	(lambda (N x y sigma)
		(cond
			((zero? N)
				'()
			)
			(else
				(cons
					(valor-gaussiano x y sigma)
					(linea-gaussiana
						(- N 1)
						(+ x 1)
						y
						sigma
					)
				)
			)
		)
	)
)


(define valor-gaussiano
	(lambda (x y sigma)
		(*
			(/
				1.0
				(*
					2.0
					pi
					(* sigma sigma)
				)
			)
			(exp (/
					(+
						(* x x)
						(* y y)
					)
					(*
						-2
						(* sigma sigma)
					)
			))
		)
	)
)

(define suma-matriz
	(lambda (M)
		(apply + (map (lambda (L) (apply + L)) M))
	)
)

(define normalizar
	(lambda (M v)
		(map (lambda (L) (map (lambda (x) (/ x v)) L)) M)
	)
)


(procesar gaussian-blur)

; main:procesar("cube3.ppm", "blurR.ppm", "gauss.scm", 8).
