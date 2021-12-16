//
//  MessagePayload.swift
//
//
//  Created by Corey Roberts on 11/8/21.
//

import UIKit

public enum MessagePayload {
    case standard(String), success(String), failure(String)

    public var message: String {
        switch self {
        case let .standard(string):
            return string
        case let .success(string):
            return string
        case let .failure(string):
            return string
        }
    }

    var feedbackType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .standard:
            return .success
        case .success:
            return .success
        case .failure:
            return .error
        }
    }
}
