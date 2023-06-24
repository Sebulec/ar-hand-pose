import Foundation

class OperationManager {
    private let semaphore = DispatchSemaphore(value: 1)
    private var isOperationInProgress = false

    func performOperation(action: () -> Void) {
        // Try to acquire the semaphore, allowing only one operation to proceed
        if semaphore.wait(timeout: .now()) == .success {
            if !isOperationInProgress {
                isOperationInProgress = true
                
                // Perform your operation here
                action()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    // Release the semaphore and reset the flag
                    self.isOperationInProgress = false
                    self.semaphore.signal()
                }
            } else {
                // Operation is already in progress, ignore the call
                print("Ignoring operation")
                semaphore.signal()
            }
        } else {
            // Operation already in progress by another thread, ignore the call
            print("Ignoring operation")
        }
    }
}
