// Copyright (C) 2019 Parrot Drones SAS
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import Foundation

/// Removable user storage backend.
public protocol RemovableUserStorageCoreBackend: class {
    /// Request a format of the media.
    ///
    /// - Parameter newMediaName: the new name that should be given to the media.
    /// - Returns: true if the format has been asked, false otherwise.
    func format(formattingType: FormattingType, newMediaName: String?) -> Bool
}

/// Internal removable user storage peripheral implementation
public class RemovableUserStorageCore: PeripheralCore, RemovableUserStorage {

    /// Internal implementation of the Media Info
    class MediaInfo: RemovableUserStorageMediaInfo {
        fileprivate(set) var name: String

        fileprivate(set) var capacity: Int64

        /// Constructor
        ///
        /// - Parameters:
        ///   - name: the name of the media
        ///   - capacity: the capacity of the media
        init(name: String, capacity: Int64) {
            self.name = name
            self.capacity = capacity
        }
    }

    private(set) public var state = RemovableUserStorageState.noMedia

    public var mediaInfo: RemovableUserStorageMediaInfo? {
        return _mediaInfo
    }
    /// private backend value of `mediaInfo`
    private var _mediaInfo: MediaInfo?

    private(set) public var availableSpace: Int64 = -1

    private(set) public var canFormat = false

    private(set) public var supportedFormattingTypes: Set<FormattingType> = [.full]

    private(set) public var formattingState: FormattingState?

    /// Implementation backend
    private unowned let backend: RemovableUserStorageCoreBackend

    /// Constructor
    ///
    /// - Parameters:
    ///    - store: store where this peripheral will be stored
    ///    - backend: System info backend
    public init(store: ComponentStoreCore, backend: RemovableUserStorageCoreBackend) {
        self.backend = backend
        super.init(desc: Peripherals.removableUserStorage, store: store)
    }

    public func format(formattingType: FormattingType, newMediaName: String) -> Bool {
        if canFormat {
            return backend.format(formattingType: formattingType, newMediaName: newMediaName)
        }
        return false
    }

    public func format(formattingType: FormattingType) -> Bool {
        if canFormat {
            return backend.format(formattingType: formattingType, newMediaName: nil)
        }
        return false
    }
}

/// Objc support
extension RemovableUserStorageCore: GSRemovableUserStorage {
    public func isFormattingTypeSupported(_ formattingType: FormattingType) -> Bool {
         return supportedFormattingTypes.contains(formattingType)
    }
}

/// Backend callback methods
extension RemovableUserStorageCore {

    /// Updates the user storage state
    ///
    /// - Parameter state: the new state
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(state newState: RemovableUserStorageState) -> RemovableUserStorageCore {
        if state != newState {
            state = newState
            if state == .noMedia {
                _mediaInfo = nil
                availableSpace = -1
            }
            if state != .formatting {
                formattingState = nil
            }
            markChanged()
        }
        return self
    }

    /// Updates the media information
    ///
    /// - Parameters:
    ///   - name: the new name
    ///   - capacity: the new capacity, in bytes
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(name: String, capacity: Int64) -> RemovableUserStorageCore {
        if let mediaInfo = _mediaInfo {
            if mediaInfo.name != name || mediaInfo.capacity != capacity {
                mediaInfo.name = name
                mediaInfo.capacity = capacity
                markChanged()
            }
        } else {
            _mediaInfo = MediaInfo(name: name, capacity: capacity)
            markChanged()
        }
        return self
    }

    /// Updates the available space on the media
    ///
    /// - Parameter availableSpace: the new available space
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(availableSpace newSpace: Int64) -> RemovableUserStorageCore {
        if availableSpace != newSpace {
            availableSpace = newSpace
            markChanged()
        }
        return self
    }

    /// Updates current ability to format the media.
    ///
    /// - Parameter canFormat: `true` if the media can be formatted
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(canFormat: Bool) -> RemovableUserStorageCore {
        if canFormat != self.canFormat {
            self.canFormat = canFormat
            markChanged()
        }
        return self
    }

    /// Updates supported formatting types
    ///
    /// - Parameter supportedFormattingTypes: formatting types
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(supportedFormattingTypes: Set<FormattingType>) -> RemovableUserStorageCore {
        if supportedFormattingTypes != self.supportedFormattingTypes {
            self.supportedFormattingTypes = supportedFormattingTypes
            markChanged()
        }
        return self
    }

    /// Updates supported formatting step
    ///
    /// - Parameters:
    ///   - formattingStep: formatting step
    ///   - formattingProgress : formatting progress
    /// - Returns: self to allow call chaining
    /// - Note: Changes are not notified until notifyUpdated() is called.
    @discardableResult public func update(formattingStep: FormattingStep, formattingProgress: Int)
        -> RemovableUserStorageCore {
            if let formattingState = self.formattingState {
                if formattingStep != formattingState.step || formattingProgress != formattingState.progress {
                    formattingState.step = formattingStep
                    formattingState.progress = formattingProgress
                    markChanged()
                }
            } else {
                self.formattingState = FormattingState()
                self.formattingState?.step = formattingStep
                self.formattingState?.progress = formattingProgress
                markChanged()
            }
        return self
    }
}
