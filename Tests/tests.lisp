(in-package :one-more-re-nightmare-tests)

(parachute:define-test one-more-re-nightmare)

(defmacro first-match (haystack &body body)
  `(progn
     ,@(loop for (re result-vector) on body by #'cddr
             collect `(parachute:is equalp
                                    ,result-vector
                                    (one-more-re-nightmare:first-match ,re ,haystack)))))

(defmacro all-string-matches (haystack &body body)
  `(progn
     ,@(loop for (re result-vector) on body by #'cddr
             collect `(parachute:is equalp
                                    ,result-vector
                                    (one-more-re-nightmare:all-string-matches ,re ,haystack)))))

(parachute:define-test easy-stuff
  :parent one-more-re-nightmare
  (first-match "Hello world"
    "Hello"  #(0 5)
    "world"  #(6 11)
    "[a-z]+" #(1 5)
    "(h|l)o" #(3 5))
  ;; The engine should finish the match at the right spot.
  ;; (The first OMRN compiler would not do this correctly.)
  (first-match "ababa"
    "ab"  #(0 2)
    "ab+" #(0 4))
  ;; The engine should also restart just after the actual match.
  (all-string-matches "ababc"
    "ab"     '(#("ab") #("ab"))
    "ab(c|)" '(#("ab") #("abc")))
  ;; Per HAKMEM item #176.
  (all-string-matches "banana"
    "ana"    '(#("ana")))
  (all-string-matches "aaa"
    "a+"     '(#("aaa"))
    ;; Make sure we match the empty string at the end of the haystack..
    ;; One program used at university would loop indefinitely, because
    ;; it would not advance past the zero-length match at the end.
    "a*"     '(#("aaa") #(""))))

(parachute:define-test annoying-submatches
  :parent one-more-re-nightmare
  ;; Per footnote #14 on page #12 of gilberth's paper.
  (first-match "aaaaa"
    "«a|aa»+" #(0 5 4 5))
  (first-match "aaaaaa"
    "«a|aa»+" #(0 6 4 6))
  (first-match "aaaaaaaa"
    "«a|aa»+" #(0 8 6 8))
  ;; Per <https://github.com/haskell-hvr/regex-tdfa/issues/2>
  (first-match "ab"
    ;; This involves clearing registers after each iteration of
    ;; repetition due to * or +.
    ;; We only should match here:
    ;;      |   |
    ;;      V   V
    "«««a*»|b»|b»+" #(0 2 1 2 1 2 nil nil)
    "«««a*»|b»|b»*" #(0 2 1 2 1 2 nil nil))
  ;; Per <https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html>:
  ;; "For this purpose, a null string shall be considered to be longer
  ;; than no match at all."
  (first-match ""
    "«a*»*" #(0 0 0 0)))

(defun compiler-macroexpand-1 (form)
  (funcall (compiler-macro-function (first form))
           form
           nil))
(defmacro compiler-macro-warns (form type reason)
  ;; I mean, it doesn't really _fail_ if it just signals a
  ;; warning. But okay.
  `(parachute:fail (compiler-macroexpand-1 ',form) ,type
                   "~A" ,reason))
(defmacro macro-warns (form type reason)
  `(parachute:fail (macroexpand-1 ',form) ,type
                   "~A" ,reason))

(deftype full-warning () '(and warning (not style-warning)))

(parachute:define-test user-interface
  :parent one-more-re-nightmare
  (compiler-macro-warns
   (one-more-re-nightmare:all-matches "a|«a»" s)
   style-warning
   "A style-warning should be generated for dead submatches.")
  (compiler-macro-warns
   (one-more-re-nightmare:all-matches "a&b" s)
   style-warning
   "A style-warning should be generated for dead REs.")
  (compiler-macro-warns
   (one-more-re-nightmare:all-matches "«a" s)
   full-warning
   "A full warning should be generated for invalid RE syntax.")
  (macro-warns
   (one-more-re-nightmare:do-matches ((start end s1 e1) "Hello" s)
     (print (list s1 e1)))
   full-warning
   "A full warning should be generated by trying to address registers that don't exist."))

(defun run-tests ()
  (parachute:test 'one-more-re-nightmare))
