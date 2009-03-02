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


module Monad
  def bind(&block)
    map(&block).join
  end
end


### STAGE 2 ###
# First attempt at a Ruby-like encapsulation of the Maybe monad functions

class Maybe
  class << self
    def [](val)
      val ? Something.new(val) : Nothing
    end

    def zero; Nothing; end
  end
end

class NothingClass
  include Monad

  def initialize(); end
  def map; self; end
  def join; self; end
  def it; nil; end
end
Nothing = NothingClass.new

class Something
  include Monad

  class << self; alias :[] :new; end
  attr_reader :it
  def initialize(val)
    @it = val
  end
  def map; Something[yield(@it)]; end
  def join; @it; end
end


# Use the Maybe monad to calculate an expression like
# xs.first.last.first
# returning nil if any intermediate result is nil.
# Equivalent to xs.andand.first.andand.last.andand.first
#
# Syntax clearly needs a bit of work...
def maybeFLO(xs)
  Maybe[xs].bind do |ys|
    Maybe[ys.first].bind do |zs|
      Maybe[zs.last].bind do |qs|
        raise "Not only child!" unless qs.length == 1
        Maybe[qs.first]
      end
    end
  end.it
end


### STAGE 3 ###
# Implementation of the Choice monad and backtracking from the same article

class Choice
  include Monad

  class << self
    def [](*choices); new(choices); end

    def zero; self[]; end
  end

  def initialize(choices)
    @them = choices
  end

  attr_reader :them

  def map(&f)
    Choice.new(@them.map(&f))
  end

  def join
    Choice.new(@them.inject([]) {|some, more| some + more.them })
  end
end

def guard(proc)
  if proc.call
    return Choice[nil]
  else
    Choice.zero
  end
end

# the backtracking search example given: find numbers
# x in [1, 2, 3],
# y in [4, 5, 6]
# such that x * y == 8

Choice[1, 2, 3].bind do |x|
  Choice[4, 5, 6].bind do |y|
    guard(lambda { x * y == 8 }).bind do |_|
      Choice[[x, y]]
    end
  end
end.them

# e.g. such_that([1, 2, 3], [4, 5, 6]) {|x, y| x * y == 8 } => [[2, 4]]
def such_that(xs, ys, &block)
  Choice.new(xs).bind do |x|
    Choice.new(ys).bind do |y|
      guard(lambda { block.call(x, y) }).bind do |_|
        Choice[[x, y]]
      end
    end
  end.them
end
