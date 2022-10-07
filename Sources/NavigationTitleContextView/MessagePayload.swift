//
//  MessagePayload.swift
//
//
//  Created by Corey Roberts on 11/8/21.
//

import UIKit

public enum MessagePayload: Equatable, Hashable {
    case standard(String), success(String), warning(String), failure(String)

    public var message: String {
        switch self {
        case let .standard(string):
            return string
        case let .success(string):
            return string
        case let .warning(string):
            return string
        case let .failure(string):
            return string
        }
    }

    var feedbackType: UINotificationFeedbackGenerator.FeedbackType? {
        switch self {
        case .standard:
            return nil
        case .success:
            return .success
        case .warning:
            return .warning
        case .failure:
            return .error
        }
    }

    public static func ==(lhs: MessagePayload, rhs: MessagePayload) -> Bool {
        switch (lhs, rhs) {
        case let (.standard(lhsString), .standard(rhsString)):
            return lhsString == rhsString
        case let (.success(lhsString), .success(rhsString)):
            return lhsString == rhsString
        case let (.warning(lhsString), .warning(rhsString)):
            return lhsString == rhsString
        case let (.failure(lhsString), .failure(rhsString)):
            return lhsString == rhsString
        default:
            return false
        }
    }
}
