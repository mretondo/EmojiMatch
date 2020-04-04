//
//  MathHelpers.swift
//  Match Emojis
//
//  Created by Mike Retondo on 1/7/20.
//

import Foundation

extension Double{
    func integerPart() -> Int { Int(self) }

    func fractionalPart(toNumberOfPlaces: Int = 2) -> Int {
        // truncatingRemainder(dividingBy: 1) is basicly the % operator
        let valDecimal = self.truncatingRemainder(dividingBy: 1)
        let powerOfTen = Double(pow(10, toNumberOfPlaces))

        return Int(valDecimal * powerOfTen)
    }
}

// using Swift 5.0
// pow() able to take Int or UInt values
func pow<T: BinaryInteger>(_ base: T, _ power: T) -> T {
    func expBySq(_ y: T, _ x: T, _ n: T) -> T {
        precondition(n >= 0)

        if n == 0 {
            return y
        } else if n == 1 {
            return y * x
        } else if n.isMultiple(of: 2) {
            return expBySq(y, x * x, n / 2)
        } else { // n is odd
            return expBySq(y * x, x * x, (n - 1) / 2)
        }
    }

    return expBySq(1, base, power)
}

extension Int {
    var random: Int {
        if self > 0 {
            return Int.random(in: 0 ..< self)
        }
        else if self < 0 {
            // get random number in positive range then negate it
            return -Int.random(in: 0 ..< abs(self))
        }
        else {
            // no emoji to randomise
            return 0
        }
    }
}


