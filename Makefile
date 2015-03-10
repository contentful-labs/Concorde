:PHONY: all doc setup test

all: test

doc:
	bundle exec pod lib docstats

setup:
	bundle install
	bundle exec pod install

test:
	bundle exec pod lib coverage
