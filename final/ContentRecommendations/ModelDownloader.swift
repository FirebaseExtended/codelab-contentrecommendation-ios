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
import Firebase

class ModelDownloader {

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

    // The download returned without a valid remote model
    case downloadReturnedEmptyModel

    // The download completed with a different model name than the one specified
    case downloadReturnedWrongModel

    // MLKit-generated error
    case mlkitError(underlyingError: Error)

    // MLKit did not return an error
    case unknownError
  }

  static func downloadModel(named name: String,
                            completion: @escaping (RemoteModel?, DownloadError?) -> Void) {
    guard FirebaseApp.app() != nil else {
      completion(nil, .firebaseNotInitialized)
      return
    }
    guard success == nil && failure == nil else {
      completion(nil, .downloadInProgress)
      return
    }

    let remoteModel = CustomRemoteModel(name: name)
    let conditions = ModelDownloadConditions(allowsCellularAccess: true,
                                             allowsBackgroundDownloading: true)

    success = NotificationCenter.default.addObserver(forName: .firebaseMLModelDownloadDidSucceed,
                                                     object: nil,
                                                     queue: nil) { (notification) in
      defer { success = nil; failure = nil }
      guard let userInfo = notification.userInfo,
          let model = userInfo[ModelDownloadUserInfoKey.remoteModel.rawValue] as? RemoteModel
      else {
        completion(nil, .downloadReturnedEmptyModel)
        return
      }
      guard model.name == name else {
        completion(nil, .downloadReturnedWrongModel)
        return
      }
      completion(model, nil)
    }
    failure = NotificationCenter.default.addObserver(forName: .firebaseMLModelDownloadDidFail,
                                                     object: nil,
                                                     queue: nil) { (notification) in
      defer { success = nil; failure = nil }
      guard let userInfo = notification.userInfo,
          let error = userInfo[ModelDownloadUserInfoKey.error.rawValue] as? Error
      else {
        completion(nil, .mlkitError(underlyingError: DownloadError.unknownError))
        return
      }
      completion(nil, .mlkitError(underlyingError: error))
    }
    ModelManager.modelManager().download(remoteModel, conditions: conditions)
  }

  // Attempts to fetch the model from disk, downloading the model if it does not already exist.
  static func fetchModel(named name: String,
                         completion: @escaping (String?, DownloadError?) -> Void) {
    let remoteModel = CustomRemoteModel(name: name)
    if ModelManager.modelManager().isModelDownloaded(remoteModel) {
      ModelManager.modelManager().getLatestModelFilePath(remoteModel) { (path, error) in
        completion(path, error.map { DownloadError.mlkitError(underlyingError: $0) })
      }
    } else {
      downloadModel(named: name) { (model, error) in
        guard let model = model else {
          let underlyingError = error ?? DownloadError.unknownError
          let compositeError = DownloadError.mlkitError(underlyingError: underlyingError)
          completion(nil, compositeError)
          return
        }
        ModelManager.modelManager().getLatestModelFilePath(model) { (path, pathError) in
          completion(path, error.map { DownloadError.mlkitError(underlyingError: $0) })
        }
      }
    }
  }

}
