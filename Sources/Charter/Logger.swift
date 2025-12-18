extension Charter {
    public class Logger {
        private var printLogs: Bool
        public var logs: [String]

        public func log(_ msg: String) {
            if (printLogs) {
                print(msg)
            }
            logs.append(msg)
        }

        public func logValue(_ key: String, _ value: Any) {
            let msg = "\u{001B}[36m\(key):\u{001B}[0m \u{001B}[33m\(value)\u{001B}[0m"
            if (printLogs) {
                print(msg)
            }
            logs.append(msg)
        }

        public init(print printLogs: Bool = false) {
            self.printLogs = printLogs
            logs = []
        }
    }
}
