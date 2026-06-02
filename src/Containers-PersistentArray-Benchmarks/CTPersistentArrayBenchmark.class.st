"
I provide a suite of reproducible benchmarks and stress tests for CTPersistentArray.

My main goal is to generate adversarial workloads that verify strict O(log N) complexity in both time and memory, ensuring the complete absence of hidden O(N) deep-copies. I am specifically designed to be used with the Illimani (FiLiP) memory profiler and the AndreasSystemProfiler.

Key Workloads:
- #runAdversarialStressTest: Simulates heavy star-branching off deep historical states (Worst-case version-tree fan-out).
- #runBestCaseBenchmark: Updates the same index repeatedly to maximize CPU cache hits.
- #runHighBranchingBenchmark: Creates 10,000 divergent timelines from a single base version.
- #runLinearBenchmark: Tests sequential updates to evaluate simple path-copying overhead.
- #runNormalReadHeavyBenchmark: Simulates a standard 90% read / 10% write application state.
- #runNormalSlidingWindowBenchmark: Updates small, localized chunks sequentially before moving to the next chunk (Spatial locality).
- #runRandomBenchmark: Updates completely random indices to simulate average-case workloads.
- #runWorstCaseBenchmark: Alternates opposite ends of the tree to force maximum CPU cache misses.
- #runTraversalForSize:: Measures the time to traverse from the root to specific leaf nodes across the 1 to n range, comparing standard memory access against tree traversal.
- #runInsertionForSize:: Evaluates the cost of functional updates (path-copying) by measuring execution time and the resulting Garbage Collection (GC) overhead.
- #runShopInventorySimulation: A real-world simulation proving the utility of persistent arrays by maintaining an immutable audit ledger of 50,000 inventory transactions.
"
Class {
	#name : 'CTPersistentArrayBenchmark',
	#superclass : 'Object',
	#category : 'Containers-PersistentArray-Benchmarks',
	#package : 'Containers-PersistentArray-Benchmarks'
}

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runAdversarialStressTest [
    | st h |
    st := CTPersistentArray new.
    st buildFrom: (Array new: 50000 withAll: 0).
    h := 25000.
    
    1 to: h do: [ :i | st at: i put: i ].
    
    1 to: 5000 do: [ :i |
        st at: 1 put: i version: h - 1.
    ].
]

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runBestCaseBenchmark [
    "Updates the same index repeatedly to maximize CPU cache hits"
    | st size |
    size := 100000.
    st := CTPersistentArray new buildFrom: (Array new: size withAll: 0).
    
    1 to: 10000 do: [ :i | 
        st at: 1 put: i 
    ].
]

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runHighBranchingBenchmark [
    "Creates 10,000 versions from a single base version"
    | st base |
    st := CTPersistentArray new buildFrom: (Array new: 100000 withAll: 0).
    base := st at: 1 put: 1. "This is our version 0"
    
    1 to: 10000 do: [ :i |
        "Always branch from the same base version"
        st at: 50000 put: i version: 1. 
    ].
]

{ #category : 'benchmarking' }
CTPersistentArrayBenchmark >> runInsertionForSize: size [
    | normalArray persistentArray benchmarker resultNormal resultPersistent |
    
    "Setup data"
    normalArray := (1 to: size) asArray.
    
    "Initialize the persistent array using your buildFrom: method"
    persistentArray := CTPersistentArray new.
    persistentArray buildFrom: normalArray.
    
    "Set up benchmarker"
    benchmarker := CTPersistentArrayBenchmarker new.
    
    "Benchmark Normal Array"
    benchmarker blockToExecute: [ 
        1 to: size do: [ :i | normalArray at: i put: i * 2 ] 
    ].
    resultNormal := benchmarker benchmark.
    
    "Benchmark Persistent Array"
	benchmarker blockToExecute: [ 
   	 	1 to: size do: [ :i | 
        	persistentArray at: i put: i * 2 
    	] 
	].
    resultPersistent := benchmarker benchmark.
    
    "Report"
   Transcript 
    show: '--- Benchmark (N='; show: size asString; show: ') ---'; cr;
    show: 'Normal Array -> Time: '; show: resultNormal executionTime asString; show: 'µs | GC: '; show: resultNormal relativeGCTime; cr;
    show: 'Persistent Array -> Time: '; show: resultPersistent executionTime asString; show: 'µs | GC: '; show: resultPersistent relativeGCTime; cr; cr.
]

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runLinearBenchmark [
    "Tests sequential updates to evaluate simple path-copying overhead"
    | st size |
    size := 100000.
    st := CTPersistentArray new buildFrom: (Array new: size withAll: 0).
    1 to: 10000 do: [ :i | st at: i put: i ].
]

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runNormalReadHeavyBenchmark [
    "Simulates a standard application: mostly querying data, occasionally updating it"
    | st size r dummy |
    size := 100000.
    st := CTPersistentArray new buildFrom: (Array new: size withAll: 0).
    r := Random new.
    
    1 to: 10000 do: [ :i |
        "If it is a multiple of 10, do a write Otherwise, do a read"
        (i \\ 10 = 0)
            ifTrue: [ st at: (r nextInteger: size) put: i ]
            ifFalse: [ dummy := st at: (r nextInteger: size) ].
    ].
]

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runNormalSlidingWindowBenchmark [
    "Updates small, localized chunks sequentially before moving to the next chunk"
    | st size windowSize |
    size := 100000.
    windowSize := 100.
    st := CTPersistentArray new buildFrom: (Array new: size withAll: 0).
    
    0 to: 99 do: [ :chunk |
        1 to: windowSize do: [ :i |
            st at: (chunk * windowSize) + i put: i.
        ]
    ].
]

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runRandomBenchmark [
    "Updates completely random indices"
    | st size r |
    size := 100000.
    st := CTPersistentArray new buildFrom: (Array new: size withAll: 0).
    r := Random new.
    
    1 to: 10000 do: [ :i | 
        st at: (r nextInteger: size) put: i 
    ].
]

{ #category : 'benchmarking' }
CTPersistentArrayBenchmark >> runShopInventorySimulation [
    | inventorySize transactions normalInventory persistentInventory benchmarker resultNormal resultPersistent benchmarkBlock |
    
    inventorySize := 10000.
    transactions := 50000.
    
    "Setup Initial Stock"
    normalInventory := Array new: inventorySize withAll: 100.
    persistentInventory := CTPersistentArray new.
    persistentInventory buildFrom: normalInventory.
    
    benchmarker := CTPersistentArrayBenchmarker new.
    benchmarkBlock := [ :collection |
        1 to: transactions do: [ :saleIndex | 
            | itemID currentStock |
            itemID := (saleIndex \\ inventorySize) + 1. 
            currentStock := collection at: itemID.
            collection at: itemID put: currentStock - 1
        ] 
    ].

    "Normal Array Simulation (The old data is destroyed on every sale)"
    benchmarker blockToExecute: [ benchmarkBlock value: normalInventory ].
    resultNormal := benchmarker benchmark.
    
   "Persistent Array Simulation (Building the immutable tree)"
    benchmarker blockToExecute: [ benchmarkBlock value: persistentInventory ].
    resultPersistent := benchmarker benchmark.
    
   ^ { resultNormal . resultPersistent }
]

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runTimeTravelComparisonSize: arraySize updates: numUpdates [
	| benchmarker benchmarkBlock normalArray persistentArray historyNormal historyPersistent resultNormal resultPersistent |
	
	benchmarker := CTPersistentArrayBenchmarker new.
	
	benchmarkBlock := [ :collection :historyList |
        | current |
        current := collection.
        1 to: numUpdates do: [ :i |
            | nextVersion |
            nextVersion := current copy. 
            nextVersion at: (i \\ arraySize + 1) put: i.
            historyList add: nextVersion.
            current := nextVersion.
        ]
    ].
	
	"Normal Array with Full Copy"
	normalArray := Array new: arraySize.
    historyNormal := OrderedCollection new: numUpdates + 1.
    historyNormal add: normalArray.
    
    benchmarker blockToExecute: [ benchmarkBlock value: normalArray value: historyNormal ].
    resultNormal := benchmarker benchmark.
	
	"Persistent Array (Path Copying)"
	persistentArray := CTPersistentArray new buildFrom: (Array new: arraySize).
    historyPersistent := OrderedCollection new: numUpdates + 1.
    historyPersistent add: persistentArray.
    
    benchmarker blockToExecute: [ benchmarkBlock value: persistentArray value: historyPersistent ].
    resultPersistent := benchmarker benchmark.

	^ { resultNormal . resultPersistent }
]

{ #category : 'benchmarking' }
CTPersistentArrayBenchmark >> runTraversalForSize: size [
    | normalArray persistentArray benchmarker resultNormal resultPersistent |
    
    "Setup data"
    normalArray := (1 to: size) asArray.
    
    "Initialize the persistent array using your buildFrom: method"
    persistentArray := CTPersistentArray new.
    persistentArray buildFrom: normalArray.
    
    "Set up benchmarker"
    benchmarker := CTPersistentArrayBenchmarker new.
    
    "Benchmark Normal Array"
    benchmarker blockToExecute: [ 
        1 to: size do: [ :i | normalArray at: i ] 
    ].
    resultNormal := benchmarker benchmark.
    
    "Benchmark Persistent Array"
    benchmarker blockToExecute: [ 
        1 to: size do: [ :i | persistentArray at: i ] 
    ].
    resultPersistent := benchmarker benchmark.
    
    "Report"
    Transcript 
    show: '--- Benchmark (N='; show: size asString; show: ') ---'; cr;
    show: 'Normal Array -> Time: '; show: resultNormal executionTime asString; show: 'µs | GC: '; show: resultNormal relativeGCTime; cr;
    show: 'Persistent Array -> Time: '; show: resultPersistent executionTime asString; show: 'µs | GC: '; show: resultPersistent relativeGCTime; cr; cr.
]

{ #category : 'benchmarks' }
CTPersistentArrayBenchmark >> runWorstCaseBenchmark [
    "Alternates opposite ends of the tree to force maximum memory traversal and cache misses"
    | st size |
    size := 100000.
    st := CTPersistentArray new buildFrom: (Array new: size withAll: 0).
    
    1 to: 5000 do: [ :i |
        st at: i put: i.
        st at: (size - i + 1) put: i.
    ].
]
