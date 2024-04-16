function() 1
function() {}
function(arg1, arg2) {
  arg2
}

function(x, y) return(y)

function(x, ...) f(...)

function(arg1, arg2 = 2) {}

function(x,
  y,
  z = 3) {
}

function()


  1

function() function() {}

function(x = function() {}) {}

# With missing RHS in inner function
function(x = function()) {}

# With no intermediate `{` scope
function() for(i in 1:5) i

# function(x, y)

# x <- function(x, y)

a <- \(arg) arg
b <- \(arg1, arg2) paste0(arg1, arg2)
c <- \(fun, ...) fun(...)
1:3 |> {\(x, y = 1) x + y}() |> {\(x) sum(x)}()
{\(a = 1) a + 1}()
\() 1 + 2
\()

  1 + 2

a == b
a > b
a < b
a >= b
a <= b
a != b

a ==
  b

a + b
a - b
a * b
a / b
a ^ b
a ** b

a +
  b

a *
  b

!a
+a
-a
foo(!a, +b)
foo(-a, bar)

!
  a
-  b

2+a*2
2+a+2
!a + !b
a <= 2 && 2 >= d
a[1] <- foo || bar
a && b(c) && d
val <- foo %>% bar(1) %>% baz()

x %% y
x %/% y
x %+% y
x %>% y
x %>% 2 %>% z
x %some text% y
x %//% y

# Not specials, but hard to test errors `%\%`, `%%%`

x |> print()

x |> foo() %>% bar() |> baz()

x |> foo() |> bar() + baz()

x |> {function(x) x}()

foo |> bar(x, y = _)
foo |> bar() |> baz(data = _)

foo[bar]
foo[1, 2]
foo[1, ]
foo[1,, ]
foo[1,,2]
foo[x=1,,y=3,4]
foo[]

foo[[x]]
foo[[x, y]]
foo[[x,]]
foo[[x,,]]
foo[[x,,y]]
foo[[]]

a[[b[1]]]
a[b[[1]]]

if (x)
  log(y)

if (a.b) {
  log(c)
  d
}

if (x)
  y else if (a)
    b

if (x)
  y else if (a)
    b else d

if (a) {
  c
  d
} else {
  e
}

# Invalid at top level due to newline before `else`, so not a real if statement
# if (TRUE) {
#   1
# }
# else {
#   2
# }

# # Invalid for same reason as above
# if (TRUE)
#   1
# else
# 2

# Valid inside `{` only due to special `else` handling with newlines
{
  if (TRUE) {
    1
  }
  else {
    2
  }
}

# Valid with comments in special newline territory
{
  if (TRUE) {
    1
  }
    # hi there

    # another one!

  else {
    2
  }
}

for (x in y)
  f

for (x in 5:6) {
  for (y in ys) {
    z
  }
}

for (x in y) for (y in z) x + y

for (i in 1:5)

  while(TRUE)
    bar

while(x > 0)
  x <- x - 1

while(TRUE)
  break

while(TRUE)
  next

while (a < b)

  repeat 1

repeat
  
  switch(foo,
    x = 1,
    "y" = 2,
    z = ,
    3
  )

foo$bar
foo$bar$baz
foo$bar@baz
foo$bar()
foo$"bar"
foo$bar()$baz[[1]]$bam

# foo$

foo@bar
foo@bar$baz
foo@bar()
# foo@"bar"

# foo@

# foo::
foo::bar
foo::bar(1)

# foo:::
foo:::bar
foo:::bar(1)

# It's nice that `::` allows an optional RHS and enforces that it can only be a
# string or identifier, so this gives us a pretty clean tree even though it is
# invalid R code.
# https://github.com/r-lib/tree-sitter-r/issues/65
# library(dplyr::)

library()


1
2
3

# These nodes allows an optional RHS, and the RHS must be a string/identifier,
# so we nicely get a true node here alongside the braces. Even if that's not
# parsable R code, it's useful for completions and highlighting.
foo${bar}
foo@{bar}
foo::{bar}
foo:::{bar}

# The RHS's of these nodes are restricted to strings and identifiers, and the RHS
# is optional. This ends up trying to match to an `if_statement` node, leaving the RHS
# empty, and then the `if_statement` node errors because it doesn't have a `(`. This
# is actually pretty decent behavior.
foo$if
foo@if
foo::if
foo:::if

x <- 1
x = 1
x := 1
x <<- 1
1 ->> x
1 -> x
x <- y(1)
y(1) -> x

f()
f(x)
f(1+1)
f(1 ~ 1)
f(x, )
f(x,,y)
f(x, y)
f(x, y = 2)
f(x = 1 + 1)
f(x, y =)
f(f2(x, y))
f(,)
f(x,)
f(,y)
f(x=,)
f("x"=,)
f(... = ,)
f(,y=)

{}

{1}

{1; 2}

{1;
  2}

{1
  2
}

{
  1
  2
}

1:2
(1 + 1):-5

~x
y~x

a ? b
a ? b <- 1
?a

repeat if (1) TRUE else repeat 42
if (TRUE) if (FALSE) 2 else NULL
a::b$c[[d]] <- e
TRUE ~ FALSE ~ NULL ? NA ? NaN
if (TRUE) FALSE
else NA
(if (TRUE) FALSE
else NA)
a = TRUE ? FALSE
TRUE <- FALSE = NA
TRUE <- FALSE ? NA
TRUE = FALSE ? NA
TRUE ? FALSE = NA

A$"B"^NA
a::b$c
a$b?c

apple
(banana)

{
  apple
  (banana)
}

(
  apple
    (banana)
)

# }

# )

# ]

# Parenthesis is "not valid" so it isn't matched by the external scanner, and
# instead falls through to the `)` rule in the grammar. 
# {)

# (}

# (]

# x[[2]

# x[y[[2]

# x[[y[2]

# x[[y[2]]
