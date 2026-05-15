//
//  Score+CoreDataClass.swift
//  Match Emojis
//
//  Created by Mike Retondo on 8/24/19.
//

import CoreData

@MainActor
class Score: NSManagedObject
{
    public static var highScore: Int64? {
        get {
            let moc = AppEnvironment.shared.coreDataStack.moc
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
            if let newValue {
                // get current high score from this Entity
                let currentHighScore = Self.highScore

                if currentHighScore == nil || newValue > currentHighScore! {
                    let moc = AppEnvironment.shared.coreDataStack.moc

                    // NOTE: no data is retrieved here, the database only retrieves the Entities record count
                    if let count = try? moc.count(for: Score.fetchRequest()), count == 0 {
                        // set first high score into empty Entity
                        let score = Score(context: moc)
                        score.highScore = newValue
                    } else {
                        // modify previous saved high score
                        let request: NSFetchRequest<Score> = Score.fetchRequest()
                        if let highScores = try? moc.fetch(request), !highScores.isEmpty {
                            let score = highScores[0]   // there's only one score in the Entity
                            score.highScore = newValue
                        }
                    }
                    
                    // Save the changes to disk
                    AppEnvironment.shared.coreDataStack.saveMoc()
                }
            }

            printScoreTableStats()
        }
    }

    public static func printScoreTableStats() {
        #if DEBUG
        // Asynchronously performs the Closure on the context’s queue, in this case the main thread
        let moc = AppEnvironment.shared.coreDataStack.moc

        moc.perform {
            let request = NSFetchRequest<Score>(entityName: "Score")
            // no data is retrieved, the database only retrieves the record count
            if let count = try? moc.count(for: request) {
                print ("\(count) Score\n")
            } else {
                print ("No Score\n")
            }
        }
        #endif
    }
}
