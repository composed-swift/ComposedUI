<img src="composed.png" width=20%/>

**ComposedUI** builds upon [`Composed`](http://github.com/composed-swift/composed) by adding user interface features that allow you to power the screens in an application.

> If you prefer to look at code, there's a demo project here: [ComposedDemo](http://github.com/composed-swift/composed-demo)

The library is comprised of 4 key types for each view type, as well as various protocols for providing optional functionality.

`UICollectionView` implementations are prefixed with `Collection`
`UITableView` implementations are prefixed with `Table`
`UIStackView` implementations are prefixed with `Stack`

For example, a `UICollectionView`'s types are defined as follows:

**CollectionSectionProvider**
In order for your section to be used in a `UICollectionView`, your section needs to conform to this protocol. It has only 1 requirement, a function that returns a `CollectionSection`

**CollectionSection**
This type encapsulates 3 `CollectionElement` instances. A cell, as well as optional header and footer elements.

**CollectionElement**
An element defines how a cell or supplementary view should be registered, dequeued and configured for display.

**CollectionCoordinator**
The coordinator is responsible for coordinating all of the events between a provider (via its mapping) and its view. Its typically both the `delegate` & `dataSource` of the corresponding view as well as the `updateDelegate` for the root provider.

## Getting Started

Lets define a simple section to hold our contacts:

```swift
struct Person {
	var kind: String // family or friend
}

final class ContactsSection: ArraySection<Person> { }
```

Now we can extend this so we can show it in a collection view:

```swift
extension ContactsSection: CollectionSectionProvider {

	func section(with traitCollection: UITraitCollection) -> CollectionSection {
		/*
		Notes:
		The `dequeueMethod` signals to the coordinator how to register and dequeue the cell
		The element is generic to that cell type
		*/
		let cell = CollectionCellElement(section: self, dequeueMethod: .fromNib(PersonCell.self)) { cell, index, section in
			// Since everything is generic, we know both the cell and the element types
			cell.prepare(with: element(at: index))
		}

		return CollectionSection(section: self, cell: cell, header: header)
	}
	
}
```

Finally we need to retain a coordinator on our view controller:

```swift
final class ContactsViewController: UICollectionViewController {
	
	private var coordinator: CollectionCoordinator?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let contacts = ContactsSection()
		// contacts.append(...)
		
		// this single line is all that's needed to connect a collection view to our provider
		coordinator = CollectionCoordinator(collectionView: collectionView, sections: contacts)
	}

}
```

Now if we build and run, our collection view should be populated with our contacts as expected. Simple!

## Protocols

ComposedUI also includes various protocols for enabling opt-in behaviour for your sections. Lets add support for selection events to our section above:

```swift
extension ContactsSection: CollectionSelectionHandler {
	
	func didSelect(at index: Int, cell: UICollectionViewCell) {
		print(element(at: index))
		deselect(at: index)
	}
	
}
```

That's it! Our coordinator already handles selection, so when a selection occurs it uses the indexPath to determine which section the selection occured in, it then attempts to cast that section to the protocol and on success, calls the associated method for us. As you can see this is an extremel powerful approach, yet extremely simple and elegant API that has 2 major benefits:

1. You opt-in to the features you want rather than inherit them by default
2. You can provide your own protocols and use the same infrastructure provided by Composed

## Advanced Usage

So far we've built a relativel simple example that shows a single section. Lets update our view controller above to use a SectionProvider – and make things more interesting.

```swift
override func viewDidLoad() {
	super.viewDidLoad()
	
	// ... create our contacts (family and friends)
	
	let provider = ComposedSectionProvider()
	provider.append(family)
	provider.append(friends)
	
	// this single line is all that's needed to connect a collection view to our provider
	coordinator = CollectionCoordinator(collectionView: collectionView, provider: provider)
}
```

If we now run our example again, we'll see everything works as it did before, except we now have 2 sections.

This has a number of benefits already:

1. We didn't need to manage indexPaths or section indexes
2. We were able to reuse our existing section
3. Our section has no knowledge that its now inside of a larger structure

Now lets add some custom behaviour depending on the data:

```swift
extension ContactsSection: CollectionSelectionHandler {
	var allowsMultipleSelection: Bool { return isFamily }
}
```
Lets run the project again and we can see that the Family section now allows multiple selection, whereas the Friend section does not. This is another great benefit of using ComposedUI because the Coordinator is able to perform more advanced logic without needing to understand the underlying structure.
