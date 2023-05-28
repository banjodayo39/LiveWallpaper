//
//  ViewController.swift
//  Example
//
//  Created by Dayo Banjo on 5/28/23.
//

import UIKit
import LiveWallpaper

class ViewController: UIViewController {
  
  let shadersNames = ["Monterey", "Vorey"]
  enum Section {
    case main
  }
  var dataSource: UICollectionViewDiffableDataSource<Section, String>! = nil
  var collectionView: UICollectionView! = nil
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "List"
    configureHierarchy()
    configureDataSource()
  }
}
extension ListController {
  /// - Tag: List
  private func createLayout() -> UICollectionViewLayout {
    let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    return UICollectionViewCompositionalLayout.list(using: config)
  }
}
extension ListController {
  private func configureHierarchy() {
    collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(collectionView)
    collectionView.delegate = self
  }
  private func configureDataSource() {
    
    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { (cell, indexPath, item) in
      var content = cell.defaultContentConfiguration()
      content.text =  item   //"\(item)"
      cell.contentConfiguration = content
    }
    
    dataSource = UICollectionViewDiffableDataSource<Section, String>(collectionView: collectionView) {
      (collectionView: UICollectionView, indexPath: IndexPath, identifier: String) -> UICollectionViewCell? in
      
      return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
    }
    // initial data
    var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
    snapshot.appendSections([.main])
    snapshot.appendItems(shadersNames)
    dataSource.apply(snapshot, animatingDifferences: false)
  }
  
  func showLiveWallpaper() {
    
    let renderController = LiveWallpaperController()
    self.navigationController?.pushViewController(renderController, animated: false)
  }
}

extension ViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    let effect: LWBaseEffect
    
    if indexPath.row == 0  {
      effect = LWBaseEffect(vertexFunctionName: "basic_vertex",
                            fragmentFunctionName: "vortex_fragment")
    } else {
      effect =  LWBaseEffect(vertexFunctionName: "basic_vertex",
                             fragmentFunctionName: "color_fragment")
    }
    
    let renderController = RendererViewController()
    renderController.effect = effect
    self.navigationController?.pushViewController(renderController, animated: false)
  }
}
