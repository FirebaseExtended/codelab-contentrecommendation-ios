// Copyright 2020 Google LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

private let reuseIdentifier = "Cell"

class LikedMoviesCollectionViewController: UICollectionViewController {
  private let reuseIdentifier = "MovieCell"
  private let itemsPerRow: CGFloat = 2

  private let sectionInsets = UIEdgeInsets(top: 50.0,
                                           left: 16.0,
                                           bottom: 50.0,
                                           right: 16.0)

  private lazy var paddingSpace = sectionInsets.left * (itemsPerRow + 1)
  private lazy var availableWidth = view.frame.width - paddingSpace
  private lazy var widthPerItem = availableWidth / itemsPerRow

  func getMovies() -> [MovieItem] {
    let barController = self.tabBarController as! TabBarController
    return barController.movies.filter { $0.liked == true }
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let cell = collectionView.cellForItem(at: indexPath) as! MovieCell
    let movie = getMovies().filter { $0.id == cell.id }[0]
    movie.liked = !(movie.liked ?? false)
  }
}

private extension LikedMoviesCollectionViewController {
  func movie(for indexPath: IndexPath) -> MovieItem {
    return getMovies()[indexPath.row]
  }
}

extension LikedMoviesCollectionViewController {
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
    return getMovies().count
  }

  override func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView
      .dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MovieCell

    let movie = getMovies()[indexPath.item]
    cell.movieLabel.text = movie.title
    cell.movieLabel.widthAnchor.constraint(equalToConstant: widthPerItem - 50).isActive = true
    cell.likeButton.isSelected = movie.liked ?? false
    cell.id = movie.id
    cell.backgroundColor = .lightGray
    return cell
  }
}

// MARK: - Collection View Flow Layout Delegate
extension LikedMoviesCollectionViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {

    return CGSize(width: widthPerItem, height: 70)
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInsets
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInsets.left
  }
}
