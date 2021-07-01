(in-package :one-more-re-nightmare)

(trivia:defun-ematch gensym-history (history)
  ((tag-set s)
   (tag-set (gensym-position-assignments s)))
  ((empty-set) (empty-set)))

(define-hash-consing-table *derivative*)

(defun derivative (re set)
  "Compute the derivative of a regular expression with regards to the set (i.e. the regular expression should be matched after a character in the set is matched)."
  (with-hash-consing (*derivative* (list re set))
    (trivia:ematch re
      ((or (empty-string) (empty-set) (tag-set _)) (empty-set))
      ((literal matching-set)
       (if (set-null (set-intersection matching-set set))
           (empty-set)
           (empty-string)))
      ((join r s)
       (let ((r* (derivative r set))
             (s* (derivative s set)))
         (either (join r* s) (join (nullable r) s*))))
      ((kleene r)
       (join (derivative r set) (kleene r)))
      ((either r s)
       (either (derivative r set) (derivative s set)))
      ((both r s)
       (both (derivative r set) (derivative s set)))
      ((invert r)
       (invert (derivative r set)))
      ((grep r s)
       (let* ((r* (derivative r set))
              (n (nullable r*)))
         (if (eq n (empty-set))
             (grep (either r* (unique-tags s))
                   s)
             r*)))
      ((alpha r old-tags)
       (let* ((r* (derivative r set))
              (nullable (nullable r)))
         (alpha r* (either nullable (gensym-history old-tags))))))))

(defun derivative* (re sequence)
  (map 'nil
       (lambda (element)
         (let ((new-re (derivative re (symbol-set element))))
           (format t "~&~a~&  ~:c ~a"
                   re
                   element
                   (new-tags new-re re))
           (setf re new-re)))
       sequence)
  re)
