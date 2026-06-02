"
I am a branch in the persistent array tree.
I hold references to a left and right child. When an update is requested, I clone myself and delegate the update to the appropriate child, maintaining the O(log N) structural sharing.
"
Class {
	#name : 'CTPersistentInternalNode',
	#superclass : 'CTPersistentAbstractNode',
	#instVars : [
		'leftChild',
		'rightChild'
	],
	#category : 'Containers-PersistentArray',
	#package : 'Containers-PersistentArray'
}

{ #category : 'accessing' }
CTPersistentInternalNode >> at: targetIndex put: aValue within: aRange [
	| mid clone |
	mid := (aRange first + aRange last) // 2.
	
	"Create a new branch node to represent the updated state"
	clone := self class new.
	
	targetIndex <= mid
		ifTrue: [ 
			clone leftChild: (leftChild at: targetIndex put: aValue within: (aRange first to: mid)).
			clone rightChild: rightChild ]
		ifFalse: [ 
			clone leftChild: leftChild.
			clone rightChild: (rightChild at: targetIndex put: aValue within: (mid + 1 to: aRange last)) ].
			
	^ clone
]

{ #category : 'accessing' }
CTPersistentInternalNode >> at: targetIndex within: aRange [
	| mid |
	mid := (aRange first + aRange last) // 2.
	
	^ targetIndex <= mid
		ifTrue: [ leftChild at: targetIndex within: (aRange first to: mid) ]
		ifFalse: [ rightChild at: targetIndex within: (mid + 1 to: aRange last) ]
]

{ #category : 'enumerating' }
CTPersistentInternalNode >> do: aBlock [
	"Traverse left, then right. Guard against nil children for non-power-of-2 arrays."
	leftChild ifNotNil: [ leftChild do: aBlock ].
	rightChild ifNotNil: [ rightChild do: aBlock ].
]

{ #category : 'accessing' }
CTPersistentInternalNode >> leftChild [
	^ leftChild
]

{ #category : 'accessing' }
CTPersistentInternalNode >> leftChild: aNode [
	leftChild := aNode
]

{ #category : 'accessing' }
CTPersistentInternalNode >> rightChild [
	^ rightChild
]

{ #category : 'accessing' }
CTPersistentInternalNode >> rightChild: aNode [
	rightChild := aNode
]
