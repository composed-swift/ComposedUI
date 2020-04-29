# ComposedUI

This library builds upon `Composed` by adding user interface features that allow you to power a `UICollectionView`, `UITableView` or even a `UIStackView`.

The library is comprised of 4 key types for each implementation, as well as various protocols for providing opt-in behaviours. 

`UICollectionView` implementations are prefixed with `Collection`
`UITableView` implementations are prefixed with `Table`
`UIStackView` implementations are prefixed with `Stack`

For example, a `UICollectionView`'s types are defined as follows:

```swift
CollectionSection
CollectionSectionProvider
CollectionElement
CollectionCoordinator
```

## CollectionSectionProvider

In order for a `Section` to work with  comforming your `Section` to `CollectionSectionProvide. 
