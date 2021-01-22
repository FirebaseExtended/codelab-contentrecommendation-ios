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

class RecommendationsViewController: UITableViewController {
  private let reuseIdentifier = "RecommendationCell"
  private var recommendations = [Recommendation]()
  //DEFINE INTERPRETER HERE


  func loadModel() {
    // LOAD MODEL HERE
  }

  // GET MOVIES HERE

  func getLikedMovies() -> [MovieItem] {
    let barController = self.tabBarController as! TabBarController
    return barController.movies.filter { $0.liked == true }
  }

  // PREPROCESS HERE

  // LOAD INTERPRETER HERE

  // POSTPROCESS HERE

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadModel()
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    loadModel()
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    // #warning Incomplete implementation, return the number of sections
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    // #warning Incomplete implementation, return the number of rows
    return recommendations.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

    let recommendation = recommendations[indexPath.row]

    let displayText = "Title: \(recommendation.title)\nConfidence: \(recommendation.confidence)\n"

    cell.textLabel?.text = displayText.trimmingCharacters(in: .whitespacesAndNewlines)
    cell.textLabel?.numberOfLines = 0

    return cell
  }
}

struct Recommendation {
  let title: String
  let confidence: Float32
}

extension Int32 {
  var data: Data {
    var int = self
    return Data(bytes: &int, count: MemoryLayout<Int>.size)
  }
}

extension Data {
  /// Creates a new buffer by copying the buffer pointer of the given array.
  ///
  /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
  ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
  ///     data from the resulting buffer has undefined behavior.
  /// - Parameter array: An array with elements of type `T`.
  init<T>(copyingBufferOf array: [T]) {
    self = array.withUnsafeBufferPointer(Data.init)
  }
  /// Convert a Data instance to Array representation.
  func toArray<T>(type: T.Type) -> [T] where T: AdditiveArithmetic {
    var array = [T](repeating: T.zero, count: self.count / MemoryLayout<T>.stride)
    _ = array.withUnsafeMutableBytes { self.copyBytes(to: $0) }
    return array
  }
}
