//
//  Score+CoreDataClass.swift
//  Match Emojis
//
//  Created by Mike Retondo on 8/24/19.
//

import CoreData

class Score: NSManagedObject
{
    public static var highScore: Int64? {
        get {
            let moc = AppDelegate.shared.coreDataStack.moc
            let request = fetchRequest()

            do {
                let scores = try moc.fetch(request)
                assert(scores.count <= 1, "highScore - scores count isn't <= 1")

                if scores.count == 1 {
                    return scores[0].highScore
                } else {
                    return nil
                }
            } catch {
                return nil
            }
        }

        set(newValue) {
            if let newValue = newValue {
                // get high score from this Entity
                let highScore = highScore

                if highScore == nil || newValue > highScore! {
                    let moc = AppDelegate.shared.coreDataStack.moc

                    // NOTE: no data is retrieved here, the database only retrieves the Entities record count
                    if let count = try? moc.count(for: Score.fetchRequest()), count == 0 {
                        // set first high score into empty Entity
                        let score = Score(context: moc)
                        score.highScore = newValue
                    } else {
                        // modify previous saved high score
                        let request: NSFetchRequest<Score> = Score.fetchRequest()
                        do {
                            if let highScores = try? moc.fetch(request) {
                                let score = highScores[0]   // there's only one score in the Entity
                                score.highScore = newValue
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
        AppDelegate.shared.coreDataStack.moc.perform {
            // no data is retrieved, the database only retrieves the record count
            if let count = try? AppDelegate.shared.coreDataStack.moc.count(for: fetchRequest()) {
                print ("\(count) Score\n")
            } else {
                print ("No Score\n")
            }
        }
        #endif
    }
}
