"
I define the standard interface for nodes in a persistent array.
My subclasses implement the core path-copying logic to guarantee O(log N) updates while keeping old versions intact without needing external conditional checks.
"
Class {
	#name : 'CTPersistentAbstractNode',
	#superclass : 'Object',
	#category : 'Containers-PersistentArray',
	#package : 'Containers-PersistentArray'
}

{ #category : 'accessing' }
CTPersistentAbstractNode >> at: anIndex put: aValue within: aRange [
	"I should return a new version of myself with the updated value."
	self subclassResponsibility
]

{ #category : 'accessing' }
CTPersistentAbstractNode >> at: anIndex within: aRange [
	"I should return the value at the given index."
	self subclassResponsibility
]

{ #category : 'enumerating' }
CTPersistentAbstractNode >> do: aBlock [
	self subclassResponsibility
]
