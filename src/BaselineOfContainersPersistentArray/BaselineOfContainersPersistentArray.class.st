"
I am the Metacello baseline for the Persistent Array container.

I am responsible for defining the package structure and loading sequence, ensuring that the core `Containers-PersistentArray` package and its dedicated `Containers-PersistentArray-Tests` suite are loaded correctly into the Pharo image.
"
Class {
	#name : 'BaselineOfContainersPersistentArray',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfContainersPersistentArray',
	#package : 'BaselineOfContainersPersistentArray'
}

{ #category : 'baselines' }
BaselineOfContainersPersistentArray >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec package: 'Containers-PersistentArray'.
		spec 
			package: 'Containers-PersistentArray-Tests' 
			with: [ spec requires: #( 'Containers-PersistentArray' ) ] ]
]
