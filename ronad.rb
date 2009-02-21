### STAGE 1 ###
# Simplistic translations of the definitions in
# http://www.randomhacks.net/articles/2007/03/12/monads-in-15-minutes
# of the three monad functions return, map and join for the Maybe monad

# a -> Maybe a
def returnMaybe(x)
  x
end

# ((a -> b), Maybe a) -> Maybe b
def mapMaybe(f, m)
  if m.nil?
    nil
  else
    f.call(m)
  end
end

# (Maybe a, &(a -> b)) -> Maybe b
def mapMaybe2(m)
  if m.nil?
    nil
  else
    yield m
  end
end

# Maybe (Maybe a) -> Maybe a
def joinMaybe(mm)
  if mm.nil?
    nil
  else
    mm
  end
end


class Monad
  class << self
    def bind(choices, &block)
      join(map(choices, &block))
    end
  end
end


### STAGE 2 ###
# First attempt at a Ruby-like encapsulation of the Maybe monad functions

class Maybe < Monad
  class << self
    def return(x)
      x
    end

    # so that Maybe[3] is a Maybe
    alias :[] :return

    def map(m)
      if m.nil?
        nil
      else
        yield m
      end
    end

    def join(mm)
      if mm.nil?
        nil
      else
        mm
      end
    end
  end
end


# Use the Maybe monad to calculate an expression like
# xs.first.last.first
# returning nil if any intermediate result is nil.
# Equivalent to xs.andand.first.andand.last.andand.first
#
# Syntax clearly needs a bit of work...
def maybeFLO(xs)
  Maybe.class_eval do
    bind(xs) do |ys|
      bind(ys.first) do |zs|
        bind(zs.last) do |qs|
          raise "Not only child!" unless qs.length == 1
          self[qs.first]
        end
      end
    end
  end
end


### STAGE 3 ###
# Implementation of the Choice monad and backtracking from the same article

class Array
  # mimic Haskell's 'concat' for lists
  # like Array#flatten but only flattens one level
  # e.g. [[1, 2, 3], [4, [5, 6]]].crunch => [1, 2, 3, 4, [5, 6]]
  def crunch
    inject([]) {|some, more| some + more }
  end
end

class Choice < Monad
  class << self
    def return(x)
      [x]
    end
    alias :[] :return

    def map(choices, &f)
      choices.map(&f)
    end

    def join(choices_of_choices)
      choices_of_choices.crunch
    end

    def zero
      []
    end
  end
end

def choose(xs)
  xs
end

def guard(*args, &block)
  if !block_given? || block.call(args)
    return [nil]
  else
    Choice.zero
  end
end

# the backtracking search example given: find numbers
# x in [1, 2, 3],
# y in [4, 5, 6]
# such that x * y == 8

Choice.class_eval do
  bind(choose([1, 2, 3])) do |x|
    bind(choose([4, 5, 6])) do |y|
      bind(guard(x, y) {|a, b| a * b == 8 }) do |_|
        self[[x, y]]
      end
    end
  end
end

# e.g. such_that([1, 2, 3], [4, 5, 6]) {|x, y| x * y == 8 } => [[2, 4]]
def such_that(xs, ys, &block)
  Choice.class_eval do
    bind(choose(xs)) do |x|
      bind(choose(ys)) do |y|
        bind(guard(x, y, &block)) do |_|
          self[[x, y]]
        end
      end
    end
  end
end
