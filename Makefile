:PHONY: all doc setup test

all: test

doc:
	bundle exec pod lib docstats

setup:
	git submodule update --init
	bundle install
	bundle exec pod repo update
	bundle exec pod install

test:
	bundle exec xcodebuild test \
		-workspace Concorde.xcworkspace \
		-scheme Concorde \
		-destination 'platform=iOS Simulator,name=iPhone 8 Plus' \
		| xcpretty -c
