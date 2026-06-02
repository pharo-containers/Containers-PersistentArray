"
A CTPersistentArray is a fully persistent, indexed data structure modeled as a complete, fully balanced binary tree. 

Unlike a standard array, every update operation (e.g., `at:put:`) does not modify the existing array; instead, it returns a new version of the CTPersistentArray, while efficiently sharing unchanged nodes with the previous versions. This makes it an ideal data structure for maintaining historical state without heavy memory overhead.

The data structure guarantees optimal logarithmic time complexity - O(log N) - for both access and update operations.

# Structure and Invariants

A CTPersistentArray manages an ordered sequence of nodes (`CTPersistentArrayNode`). The structure of this sequence maintains several invariants that guarantee performance:

1. Strict Balance: The underlying tree structure is always a complete binary tree. This means every node has either 0 children (a leaf) or exactly 2 children (internal node). The depth of the tree is strictly bounded by O(log N).
2. Path Copying Persistence: Update operations are non-destructive. Only the path from the root to the target node is copied (O(log N) nodes), while all other branches are shared with the parent version. This ensures updates are memory-efficient.
3. Indexed Access: Elements are accessed and updated via continuous, non-negative integer indices. Indices are resolved by traversing the tree based on the bits of the target index.

# Key Operations

The core public API consists of:

* creation: use `CTPersistentArray class>>#buildFrom:` to instantiate a persistent array from a standard Smalltalk collection.
* accessing: use 'at:version:' to retrieve a value from a historical version (starting at 0 for the initial state).
* updating: use 'at:put:' to generate a new version. This method returns the value added, while the array internally stores the new version.

# Complexity Analysis

| Operation | Complexity | Note |
| --- | --- | --- |
| Access | O(log N) | Strictly bounded by tree height. |
| Update | O(log N) | Generates a new version, sharing most data. |
| Creation | O(N) | Optimal construction complexity. |
| Space | O(log N) | Only paths are copied per update. |

# Usage Example

Here is a basic example demonstrating persistence:

```smalltalk
""1. Create the initial version (Version 0)""
arr := CTPersistentArray buildFrom: #( 'Apple' 'Banana' 'Cherry' ). 

""2. Update index 1 (internally creates Version 1)""
arr at: 1 put: 'Avocado'.

""3. Both versions exist in the same object""
arr at: 1 version: 0. ""=> 'Apple'""
arr at: 1 version: 1. ""=> 'Avocado'""
```
"
Class {
	#name : 'CTPersistentArray',
	#superclass : 'Object',
	#instVars : [
		'roots',
		'size'
	],
	#category : 'Containers-PersistentArray',
	#package : 'Containers-PersistentArray'
}

{ #category : 'comparing' }
CTPersistentArray >> = anObject [
	self == anObject ifTrue: [ ^ true ].
	self class == anObject class ifFalse: [ ^ false ].
	self size == anObject size ifFalse: [ ^ false ].
	
	self with: anObject do: [ :a :b | a = b ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'enumerating' }
CTPersistentArray >> anySatisfy: aBlock [
	"return true if aBlock evaluates to true for any of my elements"
	| found |
	found := true.
	self do: [ :each | 
		(aBlock value: each) ifTrue: [ ^ found ] ].
	^ false
]

{ #category : 'converting' }
CTPersistentArray >> asArray [
	"Default to convert the latest version"
	^ self asArrayVersion: self latestVersion
]

{ #category : 'converting' }
CTPersistentArray >> asArrayVersion: versionNumber [
	"convert a historical version into a standard Array"
	^ Array streamContents: [ :stream | 
		self do: [ :each | stream nextPut: each ] version: versionNumber ]
]

{ #category : 'accessing' }
CTPersistentArray >> at: anIndex [
	"Default to reading from the most recent version"
	^ self at: anIndex version: self latestVersion
]

{ #category : 'accessing' }
CTPersistentArray >> at: anIndex put: aValue [
	| currentRoot newRoot |
	
	self checkIndex: anIndex.
	
	"Always build off the most recent version"
	currentRoot := roots last.
	
	"Tell the root to start the path-copying process"
	newRoot := currentRoot at: anIndex put: aValue within: (1 to: size).
	
	"Save the new root as our latest version"
	roots add: newRoot.
	
	^ aValue
]

{ #category : 'accessing' }
CTPersistentArray >> at: anIndex put: aValue version: versionNumber [
	| targetRoot newRoot |
	
	self checkIndex: anIndex.
	
	"Fetch the specific historical root to branch from (0-based to 1-based)"
	targetRoot := roots at: versionNumber + 1.
	
	"Tell the root to start the path-copying process"
	newRoot := targetRoot at: anIndex put: aValue within: (1 to: size).
	
	"Save the new root as our latest version"
	roots add: newRoot.
	
	^ aValue
]

{ #category : 'accessing' }
CTPersistentArray >> at: anIndex version: versionNumber [
	| root |
	
	self checkIndex: anIndex.
	
	"In our system, Version 0 is stored at index 1 of the roots collection"
	root := roots at: versionNumber + 1. 
	
	^ root at: anIndex within: (1 to: size)
]

{ #category : 'instance creation' }
CTPersistentArray >> buildFrom: aCollection [
	| initialArray |
	initialArray := aCollection asArray. 
	
	size := initialArray size.
	roots := OrderedCollection new.
	
	"Start the recursion from index 1 to the end"
	roots add: (self buildTreeFrom: initialArray left: 1 right: size).
]

{ #category : 'private' }
CTPersistentArray >> buildTreeFrom: anArray left: leftIndex right: rightIndex [
	| mid leftNode rightNode parentNode |
	
	leftIndex > rightIndex ifTrue: [ ^ nil ].
	
	"Base case: return a Leaf Node"
	leftIndex = rightIndex ifTrue: [ 
		^ CTPersistentLeafNode new 
			value: (anArray at: leftIndex);
			yourself ].
			
	"Recursive case: split and build an Internal Node"
	mid := (leftIndex + rightIndex) // 2.
	
	leftNode := self buildTreeFrom: anArray left: leftIndex right: mid.
	rightNode := self buildTreeFrom: anArray left: mid + 1 right: rightIndex.
	
	parentNode := CTPersistentInternalNode new.
	parentNode leftChild: leftNode.
	parentNode rightChild: rightNode.
	
	^ parentNode
]

{ #category : 'private' }
CTPersistentArray >> checkIndex: anIndex [
	(anIndex between: 1 and: size) 
		ifFalse: [ SubscriptOutOfBounds signalFor: anIndex ]
]

{ #category : 'enumerating' }
CTPersistentArray >> collect: aBlock [
	"Evaluate aBlock with each of my elements,
	Collect the resulting values into a standard Array"
	^ Array streamContents: [ :stream |
		self do: [ :each | stream nextPut: (aBlock value: each) ] ]
]

{ #category : 'copying' }
CTPersistentArray >> copy [
	"Persistent structures are immutable and structurally shared. 
	 Copying is simply returning the identical object in O(1) time."
	^ self
]

{ #category : 'enumerating' }
CTPersistentArray >> do: aBlock [
	"Default iteration over the latest version"
	self do: aBlock version: self latestVersion
]

{ #category : 'enumerating' }
CTPersistentArray >> do: aBlock version: versionNumber [
	| root |
	root := roots at: versionNumber + 1.
	root ifNotNil: [ root do: aBlock ]
]

{ #category : 'accessing' }
CTPersistentArray >> first [
	"Return the first element of the latest version."
	| firstIndex |
	firstIndex := 1.
	^ self at: firstIndex
]

{ #category : 'comparing' }
CTPersistentArray >> hash [
	| hash |
	"Start with a base hash from the class and size"
	hash := self class hash bitXor: self size hash.
	
	"Incorporate every element so that changing a value changes the hash"
	self do: [ :each | 
		hash := (hash + each hash) hashMultiply ].
		
	^ hash
]

{ #category : 'accessing' }
CTPersistentArray >> last [
	"Return the last element of the latest version."
	| currentSize |
	currentSize := self size.
	^ self at: currentSize
]

{ #category : 'accessing' }
CTPersistentArray >> latestVersion [
	"Return the index of the last root in our history"
	^ roots size - 1
]

{ #category : 'printing' }
CTPersistentArray >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' ('.
	self do: [ :each | aStream print: each; space ].
	aStream nextPut: $)
]

{ #category : 'accessing' }
CTPersistentArray >> roots [
	^ roots
]

{ #category : 'enumerating' }
CTPersistentArray >> select: aBlock [
	"Evaluate aBlock with each of my elements,
	Return a collection of those elements that satisfy the block"
	^ Array streamContents: [ :stream |
		self do: [ :each |
			(aBlock value: each) ifTrue: [ stream nextPut: each ] ] ]
]

{ #category : 'accessing' }
CTPersistentArray >> size [
	"Return the number of elements in the array"
	^ size
]

{ #category : 'enumerating' }
CTPersistentArray >> with: aCollection do: aBlock [
	"Iterate over both collections simultaneously"
	1 to: self size do: [ :index |
		aBlock value: (self at: index) value: (aCollection at: index) ]
]
