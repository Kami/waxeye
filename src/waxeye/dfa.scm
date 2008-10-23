;;; Waxeye Parser Generator
;;; www.waxeye.org
;;; Copyright (C) 2008 Orlando D. A. R. Hill
;;;
;;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;;; this software and associated documentation files (the "Software"), to deal in
;;; the Software without restriction, including without limitation the rights to
;;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is furnished to do
;;; so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be included in all
;;; copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;;; SOFTWARE.

(module
dfa
mzscheme

(require (lib "ast.ss" "waxeye")
         (lib "fa.ss" "waxeye")
         (lib "set.ss" "waxeye")
         (only (lib "list.ss" "mzlib") filter memf)
         "debug.scm" "gen.scm" "nfa.scm" "set.scm" "util.scm")
(provide make-automata)


(define (make-automata grammar)
  (reset-nfa-builder)
  (let ((dfas (map make-dfa (ast-c grammar)))
        (unwind-dfas (map make-unwind-dfa unwinds))
        (nt-table (make-hash-table 'equal))
        (i 0))
    ;; Replace each non-term string reference in the state with the non-term's index
    (define (nt-edges state)
      (set-state-edges! state (map (lambda (a)
                                     (if (or (string? (edge-t a)) (integer? (edge-t a))) ;; If the transition is a non-terminal or unwind
                                         (make-edge (hash-table-get nt-table (edge-t a)) (edge-s a) (edge-v a)) ;; Create edge using the new index
                                         a)) ;; Otherwise, leave as it is
                                   (state-edges state))))
    (for-each (lambda (a) (hash-table-put! nt-table (car a) i) (set! i (+ i 1))) dfas) ;; Hash the nt indexes against their names
    ;; Hash the unwind indexes against their old index
    (let loop ((u-dfas unwind-dfas) (j 0))
      (when (not (null? u-dfas))
            (hash-table-put! nt-table j i)
            (set! i (+ i 1))
            (loop (cdr u-dfas) (+ j 1))))
    (set! dfas (append dfas unwind-dfas))
    (for-each (lambda (a) (for-each nt-edges (cadr a))) dfas) ;; Replace the non-term names with indexes
    (list->vector (map (lambda (a)
                         (make-fa (if (string? (car a))
                                      (string->symbol (car a))
                                      (car a))
                                  (list->vector (cadr a)) (caddr a)))
                       dfas))))


(define (make-unwind-dfa unwind-nfa)
  (let ((type (car unwind-nfa))
        (nfa (cdr unwind-nfa)))
    (debug
     (display-ln type " NFA:")
     (display-states (vector->list nfa))
     (newline))
    (let ((dfa (nfa->dfa nfa)))
      (debug
       (display-ln type " DFA:")
       (display-states dfa)
       (newline))
      (list type dfa 'voidArrow))))


;; Creates an automaton from a non-term definition
;; Returns a list of the non-term's name followed by the states of the automaton
(define (make-dfa nt)
  (let ((nfa (make-nfa nt)))
    (debug
     (display-ln "NFA:")
     (display-states (vector->list nfa))
     (newline))
    (let ((dfa (nfa->dfa nfa)))
      (debug
       (display-ln "DFA:")
       (display-states dfa)
       (newline))
      (list (get-non-term nt) dfa (get-arrow nt)))))


(define (nfa->dfa nfa)
  (let ((state-table (make-hash-table 'equal)) (state-list '()) (state-count 0) (e-table (make-hash-table 'equal)))

    ;; Returns a list of states reachable by 'e' moves
    ;; This includes the starting state
    (define (e-closure state-index)
      (define (e-closure-relative state-index relative)
        (let ((hv (hash-table-get e-table (cons relative state-index) #f)))
          (if hv
              hv
              (let ((l (list state-index)))
                (hash-table-put! e-table (cons relative state-index) '())
                (for-each (lambda (a)
                            (when (and (equal? (edge-t a) 'e) (not (member (edge-s a) l)))
                                  (set! l (append l (e-closure-relative (edge-s a) relative)))))
                          (state-edges (vector-ref nfa state-index)))
                (hash-table-put! e-table (cons relative state-index) l)
                l))))
      (e-closure-relative state-index state-index))

    (define (make-dfa-edges state-set)
      (map (lambda (a)
             (make-edge (edge-t a)
                        (get-dfa-state (list-concat (map (lambda (b)
                                                           (e-closure b))
                                                         (edge-s a))))
                        (edge-v a)))
           (group-edges (compact-edges (get-edges nfa state-set)))))

    (define (get-dfa-state state-set)
      (let ((state-num (hash-table-get state-table state-set #f)))
        (if state-num
            state-num
            (begin
              (hash-table-put! state-table state-set state-count)
              (set! state-num state-count)
              (set! state-count (+ state-count 1))
              (let ((new-state (make-state #f
                                           ;; Is our state-set an end state?
                                           (not (not (memf (lambda (a)
                                                             (state-match (vector-ref nfa a)))
                                                           state-set))))))
                ;; Ensure prefix traversal
                (set! state-list (cons new-state state-list))

                (set-state-edges! new-state (make-dfa-edges state-set)))
              state-num))))

    (get-dfa-state (e-closure 0))
    (reverse state-list)))


;; Group adjacent edges that have the same transition
(define (group-edges edge-list)
  (if (null? edge-list)
      '()
      (let ((cur-edge (car edge-list)) (rest (group-edges (cdr edge-list))))
        (if (null? rest)
            (list (make-edge (edge-t cur-edge) (list (edge-s cur-edge)) (edge-v cur-edge)))
            (let ((next-edge (car rest)))
              ;; If the transition is the same
              (if (and (equal? (edge-t cur-edge) (edge-t next-edge))
                       (equal? (edge-v cur-edge) (edge-v next-edge)))
                  ;; Merge the edges
                  (cons (make-edge (edge-t cur-edge) (cons (edge-s cur-edge) (edge-s next-edge)) (edge-v cur-edge)) (cdr rest))
                  (cons (make-edge (edge-t cur-edge) (list (edge-s cur-edge)) (edge-v cur-edge)) rest)))))))


;; Remove duplicate edges and edges with transitions that are subsets of others
(define (compact-edges edges)
  (if (null? edges)
      '()
      (let* ((e (car edges)) (et (edge-t e)) (es (edge-s e)) (ev (edge-v e)))
        (cons e (compact-edges (filter (lambda (a)
                                         (let ((t (edge-t a)) (s (edge-s a)) (v (edge-v a)))
                                           (cond
                                            ((not (and (equal? s es) (equal? v ev))) #t)
                                            ((equal? t et) #f)
                                            ((and (list? et) (list? t) (subset? et t)) #f)
                                            ((and (list? et) (char? t) (within-set? et t)) #f)
                                            (else #t))))
                                       (cdr edges)))))))


;; Get the edges of each state in the state set
;; Doesn't get those with an 'e' transition since those states were got from e-closure
(define (get-edges state-vector state-set)
  (if (null? state-set)
      '()
      (append (filter (lambda (a)
                        (not (equal? (edge-t a) 'e)))
                      (state-edges (vector-ref state-vector (car state-set))))
              (get-edges state-vector (cdr state-set)))))


(define (display-states state-vector)
  (for-each (lambda (a)
              (display "(")
              (for-each (lambda (b)
                          (display "(")
                          (print (edge-t b))
                          (display " ")
                          (print (edge-s b))
                          (display " ")
                          (print (edge-v b))
                          (display ") "))
                        (state-edges a))
              (display-ln ") " (state-match a)))
            state-vector))

)
