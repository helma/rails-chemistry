all: DisplayStructure.class

%.class: %.java
	javac -Xlint:deprecation -Xlint:unchecked -classpath ./:./cdk-1.0.1.jar $<
