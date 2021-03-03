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
    public static var highScore: Int? {
        get {
            let context = AppDelegate.viewContext
            let request: NSFetchRequest<Score> = Score.fetchRequest()

            do {
                let scores = try context.fetch(request)
                assert(scores.count <= 1, "highScore - scores count isn't <= 1")

                if scores.count == 1 {
                    return Int(scores[0].highScore)
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        }

        set(newValue) {
            if let newValue = newValue {
                let highestScore = highScore

                if highestScore == nil || newValue > highestScore! {
                    let context = AppDelegate.viewContext

                    // no data is retrieved here, the database only retrieves the record count
                    if let count = try? context.count(for: Score.fetchRequest()), count == 0 {
                        // save first highest score into empty table
                        let score = Score(context: context)
                        score.highScore = Int64(newValue)
                    } else {
                        // modify previous saved highest score
                        let request: NSFetchRequest<Score> = Score.fetchRequest()
                        do {
                            if let highestScores = try? context.fetch(request) {
                                let score = highestScores[0]    // there's only one score in the table
                                score.highScore = Int64(newValue)
                            }
                        }
                    }
                }
            }

            printScoreTableStats()
        }
    }

    public static func printScoreTableStats() {
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
