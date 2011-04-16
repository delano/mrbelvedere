require 'mrbelvedere'


## MrBelvedere.new
mb = MrBelvedere.new :tryouts, :test
mb.src
#=> :tryouts

## MrBelvedere.default
MrBelvedere.default.src
#=> :default

## Time at #1
t = MrBelvedere.time_at_the_next 5.minutes, 1302986017
t.to_i
#=> 1302986100

## Time at #2
t = MrBelvedere.time_at_the_next 20.minutes, 1302986017
t.to_i
#=> 1302986400

## Time at #3
t = MrBelvedere.time_at_the_next 1.day, 1302986017
t.to_i
#=> 1302998400

