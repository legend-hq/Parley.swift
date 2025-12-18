import Eth
import Foundation
import SwiftNumber

public protocol ActionProtocol {
    var isSupply: Bool { get }
    var isWithdraw: Bool { get }
    var isMultiAction: Bool { get }
    var isQuotePay: Bool { get }
    var isBridge: Bool { get }
    var multis: [ActionProtocol] { get }
}

extension Array where Element: ActionProtocol {
    public var importantAction: Element? {
        getImportantAction(elements: self)
    }

    private func getImportantAction(elements: [Element]) -> Element? {
        var importantAction: Element?

        // The important action should be last so we reverse here first
        for item in elements.reversed() {
            if item.isQuotePay { continue }

            importantAction = item

            if item.isMultiAction, let actions = item.multis as? [Element] {
                importantAction = actions.getImportantAction(elements: actions)
                break
                // Special case to ensure that supply always ends up more important than withdraw
                // when they are both present
            } else if importantAction!.isSupply {
                break
            } else if importantAction!.isWithdraw {
                break
            } else if !importantAction!.isBridge {
                // The last action is not bridge is the imporant action to show
                break
            }
        }

        return importantAction
    }
}
