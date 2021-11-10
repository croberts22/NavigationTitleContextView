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
        case .standard(let string):
            return string
        case .success(let string):
            return string
        case .failure(let string):
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
