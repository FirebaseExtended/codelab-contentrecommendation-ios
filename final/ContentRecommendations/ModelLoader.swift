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
import FirebaseCore
import FirebaseMLModelDownloader

class ModelLoader {

  // Since ML uses global notifications we can't allow multiple downloads simultaneously.
  private static var success: NSObjectProtocol? {
    didSet {
      if let value = oldValue {
        NotificationCenter.default.removeObserver(value)
      }
    }
  }
  private static var failure: NSObjectProtocol? {
    didSet {
      if let value = oldValue {
        NotificationCenter.default.removeObserver(value)
      }
    }
  }

  // TODO: Implement ModelDownloader methods

  enum DownloadError: Error {

      // The download couldn't be initialized because Firebase has not been configured
      case firebaseNotInitialized

      // The download couldn't be initialized because a download is already in progress
      case downloadInProgress

      // An error occurred while downloading the model
      case downloadFailed(underlyingError: Error)
    }

  static func downloadModel(named name: String,
                            completion: @escaping (CustomModel?, DownloadError?) -> Void) {
    guard FirebaseApp.app() != nil else {
      completion(nil, .firebaseNotInitialized)
      return
    }
    guard success == nil && failure == nil else {
      completion(nil, .downloadInProgress)
      return
    }
    let conditions = ModelDownloadConditions(allowsCellularAccess: false)
    ModelDownloader.modelDownloader().getModel(name: name, downloadType: .localModelUpdateInBackground, conditions: conditions) { result in
            switch (result) {
            case .success(let customModel):
                    // Download complete.
                    // The CustomModel object contains the local path of the model file,
                    // which you can use to instantiate a TensorFlow Lite classifier.
                    return completion(customModel, nil)
            case .failure(let error):
                // Download was unsuccessful. Notify error message.
              completion(nil, .downloadFailed(underlyingError: error))
            }
    }
  }
}
