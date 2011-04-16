require 'mrbelvedere'


## MrBelvedere.new
mb = MrBelvedere.new :tryouts, :test
p MrBelvedere::VERSION
mb.src
#=> :tryouts

## MrBelvedere.default
MrBelvedere.default.src
#=> :default


