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
import TensorFlowLite

class RecommendationsViewController: UITableViewController {
  private let reuseIdentifier = "RecommendationCell"
  private var interpreter: Interpreter?
  private var recommendations = [Recommendation]()

  func loadModel() {
    // Download the model from Firebase
    print("Fetching recommendations model...")
    ModelLoader.downloadModel(named: "recommendations") { (customModel, error) in
      guard let customModel = customModel else {
        if let error = error {
          print(error)
        }
        return
      }

      print("Recommendations model download complete")
      self.loadInterpreter(path: customModel.path)
    }
  }

  func getMovies() -> [MovieItem] {
    let barController = self.tabBarController as! TabBarController
    return barController.movies
  }

  func getLikedMovies() -> [MovieItem] {
    let barController = self.tabBarController as! TabBarController
    return barController.movies.filter { $0.liked == true }
  }

  // Given a list of selected items, preprocess to get tflite input.
  func preProcess() -> Data {
    let likedMovies = getLikedMovies().map { (MovieItem) -> Int32 in
      return MovieItem.id
    }
    var inputData = Data(copyingBufferOf: Array(likedMovies.prefix(10)))

    // Pad input data to have a minimum of 10 context items (4 bytes each)
    while inputData.count < 10*4 {
      inputData.append(0)
    }
    return inputData
  }

  func loadInterpreter(path: String) {
    do {
      interpreter = try Interpreter(modelPath: path)

      // Allocate memory for the model's input `Tensor`s.
      try interpreter?.allocateTensors()

      let inputData = preProcess()

      // Copy the input data to the input `Tensor`.
      try self.interpreter?.copy(inputData, toInputAt: 0)

      // Run inference by invoking the `Interpreter`.
      try self.interpreter?.invoke()

      // Get the output `Tensor`
      let confidenceOutputTensor = try self.interpreter?.output(at: 0)
      let idOutputTensor = try self.interpreter?.output(at: 1)

      // Copy output to `Data` to process the inference results.
      let confidenceOutputSize = confidenceOutputTensor?.shape.dimensions.reduce(1, {x, y in x * y})

      let idOutputSize = idOutputTensor?.shape.dimensions.reduce(1, {x, y in x * y})

      let confidenceResults =
        UnsafeMutableBufferPointer<Float32>.allocate(capacity: confidenceOutputSize!)
      let idResults =
        UnsafeMutableBufferPointer<Int32>.allocate(capacity: idOutputSize!)
      _ = confidenceOutputTensor?.data.copyBytes(to: confidenceResults)
      _ = idOutputTensor?.data.copyBytes(to: idResults)

      postProcess(idResults, confidenceResults)

      print("Successfully ran inference")
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    } catch {
      print("Error occurred creating model interpreter: \(error)")
    }
  }

  // Postprocess to get results from tflite inference.
  func postProcess(_ idResults: UnsafeMutableBufferPointer<Int32>, _ confidenceResults: UnsafeMutableBufferPointer<Float32>) {
    for i in 0..<10 {
      let id = idResults[i]
      let movieIdx = getMovies().firstIndex { $0.id == id }
      let title = getMovies()[movieIdx!].title
      recommendations.append(Recommendation(title: title, confidence: confidenceResults[i]))
    }
  }

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
