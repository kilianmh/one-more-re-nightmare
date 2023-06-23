#lang scribble/base
@require["spec-macros.scrbl" "bibliography.rkt"]

@title{Interface}

@section{Syntax}

We currently use our own syntax for regular expressions, since the
POSIX syntax does not allow for expressing complements or
intersections of regular expressions.

@centered-block[
@bnf[
@rule["E"
      "E | E" "union"
      "E & E" "intersection"
      "E E" "concatenate"
      "¬E" "complement"
      "~E" "complement"
      "E*" "zero or more repeats"
      "E+" "one or more repeats"
      "E?" "zero or one repeats"
      "E{j,j}" "repeat"
      "«E»" "submatch"
      "(E)" "change precedence"
      "[r]" "character range"
      "[¬r]" "complement ranges"
      "[^r]" "complement ranges"
      "$" "every character"
      "c" "literal character"
      "<empty string>" ""]
@rule["r" "<empty range>" "empty range"
          "cr" "single character"
          "c-cr" "character range"
          "[:<name>:r]" "character class"]
@rule["j" "<integer>" "bound"
          "<empty string>" "no bound"]
@rule["c" "<single character>" ""]
]
]

Rules higher on this list are "looser" than rules lower on the list.
For example, the expression @cl{ab&cd|ef} is equivalent to
@cl{((ab)&(cd))|(ef)}.

@section{Semantics}

Matches and submatches are performed using the semantics for 
POSIX regular expressions @~cite[posix], with additional rules pertaining
to intersection and complements.

Submatches on both sides of an intersection operator are matched. For
example,

@lisp-code{
(first-string-match "«a»b&a«b»" "ab") ; => #("ab" "a" "b")
}

No submatches in a complement can ever be matched, including in the
complement of a complement. Thus @cl{¬¬A} is not the same as @cl{A}:

@lisp-code{
(first-match "¬¬«a»" "a") ; => #(0 1 NIL NIL)
(first-match "«a»" "a") ; => #(0 1 0 1)
}

@section{Matching}

Note that one-more-re-nightmare can avoid a cache lookup (involving
acquiring a lock and hash table searching) if the regular expression
is a literal string, or a constant variable bound to a string.

@definitions{
@defun["first-match"]{regular-expression string @param{@&key start end}}

@defun["first-string-match"]{regular-expression string @param{@&key start end}}

Find the first match for @cl{regular-expression} in @cl{string}
between @cl{start} and @cl{end}.

@cl{first-match} returns a simple vector, where each element is a
@concept{register}, or @cl{nil} when there is no match. The first two
registers are always the start and end of the match, and then
subsequent registers are the start and end of each submatch. A
register is either a bounding index of @cl{string} or @cl{nil} when
there is no submatch.

@cl{first-string-match} either returns a simple vector, every element
of which is a fresh string or @cl{nil} (when there is no submatch), or
@cl{nil} if there is no match.

@definition-section["Examples"]{
@lisp-code{
(first-match "[0-9]([0-9]| )+" "Phone: 632 3003")
;; => #(6 15)
(first-string-match "[0-9]([0-9]| )+" "Phone: 632 3003")
;; => "632 3003"

(first-match
 "«[0-9]+»x«[0-9]+»|«[0-9]+»p"
 "Foobar 1920x1080 17-inch display")
;; => #(7 16 7 11 12 16 NIL NIL)
(first-string-match
 "«[0-9]+»x«[0-9]+»|«[0-9]+»p"
 "Foobar 1920x1080 17-inch display")
;; => #("1920x1080" "1920" "1080" NIL)
}
}
}

@definitions{
@defun["all-matches"]{regular-expression string @param{@&key start end}}

@defun["all-string-matches"]{regular-expression string @param{@&key start end}}

Find all matches for @cl{regular-expression} in @cl{string} between
@cl{start} and @cl{end}.

Both functions return a list of matches; @cl{all-matches} represents
matches as @cl{first-match} does, and @cl{all-string-matches}
represents matches as @cl{first-string-match} does.

@definition-section["Examples"]{
@lisp-code{
(all-matches
 "«[0-9]+»x«[0-9]+»|«[0-9]+»p"
 "Foobar 1920x1080 17-inch display or Quux 19-inch 720p display?")
;; => (#(7 16 7 11 12 16 NIL NIL) #(49 53 NIL NIL NIL NIL 49 52))
(all-string-matches
 "«[0-9]+»x«[0-9]+»|«[0-9]+»p"
 "Foobar 1920x1080 17-inch display or Quux 19-inch 720p display?")
;; => (#("1920x1080" "1920" "1080" NIL) #("720p" NIL NIL "720"))
}
}
}

@definitions{
@defmacro["do-matches"]{((@param{@&rest registers}) regular-expression
                        string @param{@&key start end})
                        @param{@&body body}}

@cl{do-matches} iterates over all matches for @cl{regular-expression}
across @cl{string}. The @cl{registers} variables are bound to the
@term{registers} produced, as described for @cl{first-match}.

It is possible to provide fewer variables than registers in the
regular expression, but an error will be signalled if there are more
variables than registers.
}

@section{Compiling}

The compiler may be run manually, when the regular expression is not
known at compile time, and the code cache takes too long to search.
(The latter can happen if many threads are accessing the code cache,
and the time taken searching is sufficiently short, as lookups grab a
global lock currently.)

@definitions{
@defclass["compiled-regular-expression"]

An object representing a compiled regular expression. An instance of
this class can be provided as a regular expression to all the searching
functions, instead of a string.
}

@definitions{
@defun["compile-regular-expression"]{expression}

Compile a regular expression, returning an instance of
@cl{compiled-regular-expression}.

An error is signalled if the expression has invalid syntax.
}
