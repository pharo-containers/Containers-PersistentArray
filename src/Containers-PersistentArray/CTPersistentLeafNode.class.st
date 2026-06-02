"
I am a leaf in the persistent array tree.
I sit at the bottom level and hold the actual value. When an update reaches me, I return a completely new leaf node with the new value to preserve the previous version.
"
Class {
	#name : 'CTPersistentLeafNode',
	#superclass : 'CTPersistentAbstractNode',
	#instVars : [
		'value'
	],
	#category : 'Containers-PersistentArray',
	#package : 'Containers-PersistentArray'
}

{ #category : 'accessing' }
CTPersistentLeafNode >> at: anIndex put: aValue within: aRange [
	"Return a new leaf node with the updated value."
	^ self class new
		value: aValue;
		yourself
]

{ #category : 'accessing' }
CTPersistentLeafNode >> at: anIndex within: aRange [
	"I am a leaf, so I hold the value for this exact position."
	^ value
]

{ #category : 'enumerating' }
CTPersistentLeafNode >> do: aBlock [
	aBlock value: value
]

{ #category : 'accessing' }
CTPersistentLeafNode >> value: anObject [
	value := anObject
]
