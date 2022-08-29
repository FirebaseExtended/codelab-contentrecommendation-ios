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

  // TODO: Implement ModelLoader methods

  enum DownloadError: Error {

      // The download couldn't be initialized because Firebase has not been configured
      case firebaseNotInitialized

      // The download couldn't be initialized because a download is already in progress
      case downloadInProgress

      // An error occurred while downloading the model
      case downloadFailed(underlyingError: Error)
    }

    // DOWNLOAD MODEL HERE
}
