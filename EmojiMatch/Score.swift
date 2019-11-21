//
//  Score.swift
//  Match Emojis
//
//  Created by Mike Retondo on 8/24/19.
//

import UIKit
import CoreData

class Score: NSManagedObject
{
    public static var lowestScore: Int? {
        get {
            let context = AppDelegate.viewContext
            let request: NSFetchRequest<Score> = Score.fetchRequest()

            do {
                let lowestScores = try context.fetch(request)
                assert(lowestScores.count <= 1, "lowestFlips - lowestScores count doesn't equal 1")

                if lowestScores.count == 1 {
                    return Int(lowestScores[0].lowestScore)
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        }

        set(newValue) {
            if let newValue = newValue, newValue > -1 {
                let lowestFlipsScore = lowestScore

                if lowestFlipsScore == nil || newValue < lowestFlipsScore! {
                    let context = AppDelegate.viewContext

                    // no data is retrieved here, the database only retrieves the record count
                    if let count = try? AppDelegate.viewContext.count(for: Score.fetchRequest()), count == 0 {
                        // save first lowest score
                        let score = Score(context: context)
                        score.lowestScore = Int64(newValue)
                    } else {
                        // modify previous saved lowest score
                        let request: NSFetchRequest<Score> = Score.fetchRequest()
                        do {
                            let lowestScores = try? context.fetch(request)
                            let score = lowestScores![0]
                            score.lowestScore = Int64(newValue)
                        }
                    }
                }
            }

            printLowestFlipsTableStats()
        }
    }

    public static func printLowestFlipsTableStats() {
        #if DEBUG
        // Asynchronously performs the Closure on the context’s queue, in this case the main thread
        AppDelegate.viewContext.perform {
            // no data is retrieved, the database only retrieves the record count
            if let count = try? AppDelegate.viewContext.count(for: Score.fetchRequest()) {
                print ("\(count) Score\n")
            } else {
                print ("No Score\n")
            }
        }
        #endif
    }
}
