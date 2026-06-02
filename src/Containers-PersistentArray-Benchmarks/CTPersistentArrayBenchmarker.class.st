"
I am a custom benchmarking tool designed to measure block execution time and garbage collection (GC) activity precisely.

Standard time profilers can suffer from the observer effect, where adding profiling code changes the execution itself, and they rely on sampling at specific yield points rather than ground truth. 

To avoid this, I wrap a target block of code and use fast primitives (like `Time primMillisecondClock`) to capture highly accurate start and end times. 
I simultaneously track VM parameters to capture both full GC time (large generation cleanup) and incremental/scavenge GC time (small generation cleanup). 

Upon completion, I return a `PersistentArrayBenchmarkerResult` containing the gathered metrics.
"
Class {
	#name : 'CTPersistentArrayBenchmarker',
	#superclass : 'Object',
	#instVars : [
		'block'
	],
	#category : 'Containers-PersistentArray-Benchmarks',
	#package : 'Containers-PersistentArray-Benchmarks'
}

{ #category : 'as yet unclassified' }
CTPersistentArrayBenchmarker >> benchmark [

	| executionTime fullGCTime incrementalGCTime |
	fullGCTime := Smalltalk vm totalFullGCTime.
	incrementalGCTime := Smalltalk vm totalIncrementalGCTime.
	executionTime := Time primUTCMicrosecondsClock.

	block value.

	executionTime := Time primUTCMicrosecondsClock - executionTime.
	"Multiply by 1000 to convert millisecond GC time into microseconds"
	fullGCTime := (Smalltalk vm totalFullGCTime - fullGCTime) * 1000.
	incrementalGCTime := (Smalltalk vm totalIncrementalGCTime - incrementalGCTime) * 1000.

	^ CTPersistentArrayBenchmarkerResult new
		  executionTime: executionTime;
		  fullGCTime: fullGCTime;
		  incrementalGCTime: incrementalGCTime;
		  yourself
]

{ #category : 'as yet unclassified' }
CTPersistentArrayBenchmarker >> blockToExecute: aBlock [

	block := aBlock
]
