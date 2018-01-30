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
	echo "Generating Snapshots. This is expected to throw test failures."
	bundle exec xcodebuild clean test \
	 	-workspace Concorde.xcworkspace \
		-scheme Concorde \
		-destination "platform=iOS Simulator,name=iPhone 8 Plus" \
		GENERATE_SNAPSHOTS=YES \
		| xcpretty -c
	echo "Running tests..."
	bundle exec xcodebuild test \
		-workspace Concorde.xcworkspace \
		-scheme Concorde \
		-destination 'platform=iOS Simulator,name=iPhone 8 Plus' \
		| xcpretty -c; exit ${PIPESTATUS[0]}
