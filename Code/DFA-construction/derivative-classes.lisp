(in-package :one-more-re-nightmare)

(defun merge-sets (sets1 sets2)
  "Produce a list of every subset of sets1 and sets2."
  (let ((sets (make-hash-table :test 'equal)))
    (loop for set1 in sets1
          do (loop for set2 in sets2
                   for intersection = (csum-intersection set1 set2)
                   do (setf (gethash intersection sets) t)))
    (alexandria:hash-table-keys sets)))


(define-hash-consing-table *derivative-classes*)

(defun derivative-classes (re)
  "Produce a list of the 'classes' (sets) of characters that compiling the regular expression would have to dispatch on."
  (with-hash-consing (*derivative-classes* re)
    (trivia:ematch re
      ((literal set) (list set (csum-complement set)))
      ((or (empty-string)
           (tag-set _))
       (list +universal-set+))
      ((join r s)
       (if (eq (nullable r) (empty-set))
           (derivative-classes r)
           (merge-sets (derivative-classes r)
                       (derivative-classes s))))
      ((or (either r s) (both r s)
           (grep r s))
       (merge-sets (derivative-classes r)
                   (derivative-classes s)))
      ((or (invert r) (repeat r _ _ _))
       (derivative-classes r))
      ((alpha r _)
       (derivative-classes r)))))
